import 'package:bbs_browser/app.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'app_manager.dart';
import 'bbs_board.dart';
import 'bbs_thread.dart';
import 'configuration.dart';

abstract class AppView{
    void openBoard(Board board);
    void closeBoard(Board board);
    void openThread(Thread thread);
    void closeThread(Thread thread);
}

class SingleView extends StatefulWidget implements AppView{
    static final _SingleViewManager _viewManager = _SingleViewManager.getInstance();

    final Widget initialContent;

    const SingleView(this.initialContent,{super.key});

    @override
    State<SingleView> createState(){
        return _SingleViewState();
    }

    @override
    void openBoard(Board info){
        _viewManager.state?.openBoardImpl(info);
    }
    @override
    void closeBoard(Board board){

    }
    
    @override
    void openThread(Thread info){
        _viewManager.state?.openThreadImpl(info);
    }
    @override
    void closeThread(Thread thread){

    }
}
class _SingleViewState extends State<SingleView>{
    static final _SingleViewManager _viewManager = _SingleViewManager.getInstance();
    static final AppManager appManager = AppManager.getInstance();

    late Widget content;

    @override
    void initState(){
        debugPrint("view initState");

        super.initState();

        content = widget.initialContent;

        register();
    }

    void register(){
        debugPrint("view register");

        _viewManager.set(this);
        appManager.set(widget);
    }

    @override
    void deactivate(){
        debugPrint("view deactivate");

        super.deactivate();
    }

    @override
    void dispose(){
        debugPrint("view dispose");

        super.dispose();
    }

    @override
    Widget build(BuildContext context){
        debugPrint("view build");

        return content;
    }

    void setContent(Widget newContent){
        setState(() {
            content = newContent;
        });
    }

    void openBoardImpl(Board board){
        if(content is BoardView){
            setContent(BoardView(board));
        }else{
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context1) {
                    // return SingleView(BoardView(Board(info)), key: widget.key);
                    return AppContent(
                        key: widget.key,
                    );
                })
            );
        }
    }

    void openThreadImpl(Thread thread){
        if(content is ThreadView){
            setContent(ThreadView(thread));
        }else{
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                    // return SingleView(ThreadView(Thread(info)), key: widget.key);
                    return AppContent(
                        key: widget.key,
                        // initialBoard: ,
                        // initialThread: Thread(info),
                    );
                })
            ).then((value) => register());
        }
    }
}
class _SingleViewManager{
    static final _SingleViewManager _instance = _SingleViewManager._internal();

    _SingleViewState? _state;
    _SingleViewState? get state => _state;
    
    _SingleViewManager._internal();
    factory _SingleViewManager.getInstance() => _instance;

    void set(_SingleViewState viewState){
        _state = viewState;
    }
    void unset(){
        _state = null;
    }
}


class DualView extends StatefulWidget implements AppView{
    static final _DualViewManager _viewManager = _DualViewManager.getInstance();

    const DualView({super.key});

    @override
    State<DualView> createState(){
        return _DualViewState();
    }

    @override
    void openBoard(Board board){
        if(_viewManager.state == null){
            return;
        }
        final state = _viewManager.state!;

        // state.setSideContent(BoardView(board));
        state.setSideContent(board);
    }

    @override
    void closeBoard(Board board){
        _viewManager.state?.closeBoard(board);
    }

    @override
    void openThread(Thread thread){
        if(_viewManager.state == null){
            return;
        }
        final state = _viewManager.state!;

        // state.setMainContent(ThreadView(thread));
        state.setMainContent(thread);
    }

    @override
    void closeThread(Thread thread){
        _viewManager.state?.closeThread(thread);
    }
}
class _DualViewState extends State<DualView>{
    static final _DualViewManager _viewManager = _DualViewManager.getInstance();
    static final AppManager appManager = AppManager.getInstance();

    late ThreadTabView mainContent;
    late BoardTabView sideContent;
    // late TabView mainContent;
    // late TabView sideContent;

    @override
    void initState(){
        super.initState();

        mainContent = ThreadTabView(key: widget.key,);
        sideContent = BoardTabView(key: widget.key,);

        register();

        debugPrint("dualViewState initState");
    }

    void register(){
        _viewManager.set(this);
        appManager.set(widget);
    }

    @override
    Widget build(BuildContext context){
        final Config config = Config.getInstance();
        final mediaWidth = MediaQuery.of(context).size.width.toInt();
        final sideWidth = max(mediaWidth~/4,250);
        const divideWidth = 1;
        final mainWidth = mediaWidth - sideWidth -1;
        return Row(
            children: [
                Expanded(
                    flex: sideWidth,
                    child: sideContent,
                ),
                VerticalDivider(
                    width: divideWidth.toDouble(),
                    color: config.color.foreground3,
                ),
                Expanded(
                    flex: mainWidth,
                    child: mainContent,
                )
            ],
        );
    }

    void setMainContent(Thread thread){
        setState(() {
            // mainContent.open(TabContent("", content));
            mainContent.open(thread);
        });
    }
    void setSideContent(Board board){
        setState(() {
            // sideContent = content;
            // sideContent.open(TabContent("board", content));
            sideContent.open(board);
        });
    }
    void closeThread(Thread thread){
        setState(() {
            mainContent.close(thread);
        });
    }
    void closeBoard(Board board){
        setState(() {
            sideContent.close(board);
        });
    }
}
class _DualViewManager{
    static final _DualViewManager _instance = _DualViewManager._internal();

    _DualViewState? _state;
    _DualViewState? get state => _state;

    _DualViewManager._internal();
    factory _DualViewManager.getInstance() => _instance;

    void set(_DualViewState viewState){
        _state = viewState;
    }
    void unset(){
        _state = null;
    }
}

class BoardTabView extends StatefulWidget{
    static final _BoardTabViewManager _manager = _BoardTabViewManager.getInstance();
    
    const BoardTabView({super.key});

    @override
    State<BoardTabView> createState(){
        return _BoardTabViewState();
    }

    void open(Board board){
        _manager.state?.openImpl(board);
    }
    void close(Board board){
        _manager.state?.closeImpl(board);
    }
}

class _BoardTabViewState extends State<BoardTabView> with TickerProviderStateMixin{
    static final Config config = Config.getInstance();

    final List<BoardView> _contentList = [];

    late TabController _tabController;

    late final BoardView emptyBoardView;

    @override
    void initState(){
        super.initState();

        emptyBoardView = BoardView(null,key: widget.key,);
        _contentList.add(emptyBoardView);

        _tabController = TabController(length: _contentList.length, vsync: this);

        _BoardTabViewManager.getInstance().initialize(this);
    }

    @override
    void dispose(){
        _tabController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: PreferredSize( 
                preferredSize: const Size.fromHeight(50),
                child: AppBar(
                    backgroundColor: config.color.primary,
                    flexibleSpace: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                            TabBar(
                                labelColor: config.color.onPrimary,
                                indicatorColor: config.color.onPrimary,
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: _contentList.map((content){
                                    return Tab(
                                        text: content.board!=null?content.board!.boardInfo.name:""
                                    );
                                }).toList(),
                                controller: _tabController,
                            )
                        ],
                    ),
                ),
            ),
            body: TabBarView(
                controller: _tabController,
                children: [..._contentList]
            ),
        );
    }

    void openImpl(Board board){
        debugPrint("boardTabViewState openImpl ${board.boardInfo.name}");
        if(_contentList.first.board==null){
            setState(() {
                _contentList.first = BoardView(board,key: widget.key);
            });
        }else{
            final index = _contentList.indexWhere((element) => element.board?.boardInfo==board.boardInfo);
            if(index < 0){
                _contentList.add(BoardView(board,key: widget.key));
                setState(() {
                    _tabController = TabController(length: _contentList.length, vsync: this);
                    _tabController.animateTo(_contentList.length-1);
                });
            }else{
                setState(() {
                    _tabController.animateTo(index);
                });
            }
        }
    }

    void closeImpl(Board board){
        final index = _contentList.indexWhere((element) => element.board?.boardInfo==board.boardInfo);
        if(index < 0){
            debugPrint("${_contentList.first.board?.boardInfo.hashCode} ${board.boardInfo.hashCode}");
            return;
        }
        _contentList.removeAt(index);
        if(_contentList.isEmpty){
            _contentList.add(emptyBoardView);
        }
        final nextIndex = index<_contentList.length ? index : _contentList.length-1;
        setState(() {
            _tabController = TabController(length: _contentList.length, vsync: this);
            _tabController.animateTo(nextIndex);
        });
    }
}

class _BoardTabViewManager{
    static final _BoardTabViewManager _instance = _BoardTabViewManager._internal();

    _BoardTabViewState? _state;
    _BoardTabViewState? get state => _state;

    _BoardTabViewManager._internal();
    factory _BoardTabViewManager.getInstance() => _instance;

    void initialize(_BoardTabViewState viewState){
        _state = viewState;
    }
}

class ThreadTabView extends StatefulWidget{
    // static final manager = _ThreadTabViewManager.getInstance();

    const ThreadTabView({super.key});

    @override
    State<ThreadTabView> createState(){
        return _ThreadTabViewState();
    }

    void open(Thread thread){
        _ThreadTabViewManager.getInstance().state?.openImpl(thread);
        // debugPrint(_ThreadTabViewManager.getInstance().state?._contentList.length.toString());
    }
    void close(Thread thread){
        _ThreadTabViewManager.getInstance().state?.closeImpl(thread);
    }
}

class _ThreadTabViewState extends State<ThreadTabView> with TickerProviderStateMixin{
    static final Config config = Config.getInstance();
    
    final List<ThreadView> _contentList = [];

    late TabController _tabController;
    
    late final ThreadView emptyThreadView;

    @override
    void initState(){
        super.initState();

        emptyThreadView = ThreadView(null,key: widget.key);
        _contentList.add(emptyThreadView);

        _tabController = TabController(length: _contentList.length, vsync: this);

        _ThreadTabViewManager.getInstance().initialize(this);

        debugPrint("tabViewState initState");
    }

    @override
    void dispose(){
        _tabController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: PreferredSize(
                preferredSize:const Size.fromHeight(50),
                child:AppBar(
                    backgroundColor: config.color.primary,
                    elevation: 0,
                    flexibleSpace: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                            TabBar(
                                labelColor: config.color.onPrimary,
                                indicatorColor: config.color.onPrimary,
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: _contentList.map((content){
                                    return Tab(
                                        text: content.thread!=null?content.thread!.threadInfo.title:""
                                    );
                                }).toList(),
                                controller: _tabController,
                            )
                        ],
                    ),
                ),
            ),
            body: TabBarView(
                controller: _tabController,
                children: [..._contentList]
            ),
        );
    }

    void openImpl(Thread thread){
        debugPrint("threadTabViewState openImpl ${thread.threadInfo.title}");
        if(_contentList.first.thread==null){
            setState(() {
                _contentList.first = ThreadView(thread,key: widget.key);
            });
        }else{
            final index = _contentList.indexWhere((element) => element.thread?.threadInfo==thread.threadInfo);
            if(index < 0){
                _contentList.add(ThreadView(thread,key: widget.key));
                setState(() {
                    _tabController = TabController(length: _contentList.length, vsync: this);
                    _tabController.animateTo(_contentList.length-1);
                });
            }else{
                setState(() {
                    _tabController.animateTo(index);
                });
            }
        }
    }

    void closeImpl(Thread thread){
        final index = _contentList.indexWhere((element) => element.thread?.threadInfo==thread.threadInfo);
        if(index < 0){
            debugPrint("${_contentList.first.thread?.threadInfo.hashCode} ${thread.threadInfo.hashCode}");
            return;
        }
        _contentList.removeAt(index);
        if(_contentList.isEmpty){
            _contentList.add(emptyThreadView);
        }
        final nextIndex = index<_contentList.length ? index : _contentList.length-1;
        setState(() {
            _tabController = TabController(length: _contentList.length, vsync: this);
            _tabController.animateTo(nextIndex);
        });
    }
}
class _ThreadTabViewManager{
    static final _ThreadTabViewManager _instance = _ThreadTabViewManager._internal();

    _ThreadTabViewManager._internal();
    factory _ThreadTabViewManager.getInstance() => _instance;

    _ThreadTabViewState? _state;
    _ThreadTabViewState? get state => _state;

    void initialize(_ThreadTabViewState viewState){
        _state = viewState;
    }
}

