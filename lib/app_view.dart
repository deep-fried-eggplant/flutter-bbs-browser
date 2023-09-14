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

    final BoardTabView _boardTabView=const BoardTabView();
    final ThreadTabView _threadTabView=const ThreadTabView();

    const SingleView({super.key});

    @override
    State<SingleView> createState(){
        return _SingleViewState();
    }

    @override
    void openBoard(Board board){
        _viewManager.state?.openBoard(board);
    }
    @override
    void closeBoard(Board board){
        _viewManager.state?.closeBoard(board);
    }
    
    @override
    void openThread(Thread thread){
        _viewManager.state?.openThread(thread);
    }
    @override
    void closeThread(Thread thread){
        _viewManager.state?.closeThread(thread);
    }
}
class _SingleViewState extends State<SingleView>{
    static final Config config = Config.getInstance();

    static final _SingleViewManager _viewManager = _SingleViewManager.getInstance();
    static final AppManager appManager = AppManager.getInstance();

    // late Widget content;
    late BoardTabView _boardTabView;
    late ThreadTabView _threadTabView;

    late List<Widget> _contentList;
    int _contentIndex =0;

    static const _contentIndexToBoard = 0;
    static const _contentIndexToThread = 1;

    @override
    void initState(){
        super.initState();

        // _boardTabView = BoardTabView(key: widget.key,);
        // _threadTabView = ThreadTabView(key: widget.key,);
        _boardTabView = widget._boardTabView;
        _threadTabView = widget._threadTabView;
        _contentList = [_boardTabView,_threadTabView];

        register();

        debugPrint("singleView initState");
    }

    void register(){
        _viewManager.set(this);
        appManager.set(widget);
    }

    @override
    Widget build(BuildContext context){
        debugPrint("singleView build");

        return Scaffold(
            key: widget.key,
            body: _contentList.elementAt(_contentIndex),
            bottomNavigationBar: BottomNavigationBar(
                backgroundColor: config.color.primary,
                items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                        icon: Icon(Icons.list, color: config.color.onPrimary,),
                        label: "Board"
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.list, color: config.color.onPrimary,),
                        label: "Thread"
                    )
                ],
                currentIndex: _contentIndex,
                onTap: (index){
                    setState(() {
                        _contentIndex = index;
                    });
                },
            ),
        );
    }

    void openBoard(Board board){
        
        setState(() {
            _contentIndex = _contentIndexToBoard;
        });
        setState(() {
            _boardTabView.open(board);
        });
    }

    void closeBoard(Board board){
        setState(() {
            _boardTabView.close(board);
        });
    }

    void openThread(Thread thread){
        setState(() {
            _contentIndex = _contentIndexToThread;
        });
        setState(() {
            _threadTabView.open(thread);
        });
    }
    void closeThread(Thread thread){
        setState(() {
            _threadTabView.close(thread);
        });
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
        _viewManager.state?.openBoard(board);
    }

    @override
    void closeBoard(Board board){
        _viewManager.state?.closeBoard(board);
    }

    @override
    void openThread(Thread thread){
        _viewManager.state?.openThread(thread);
    }

    @override
    void closeThread(Thread thread){
        _viewManager.state?.closeThread(thread);
    }
}
class _DualViewState extends State<DualView>{
    static final _DualViewManager _viewManager = _DualViewManager.getInstance();
    static final AppManager appManager = AppManager.getInstance();

    late ThreadTabView _threadTabView;
    late BoardTabView _boardTabView;

    @override
    void initState(){
        super.initState();

        _threadTabView = ThreadTabView(key: widget.key,);
        _boardTabView = BoardTabView(key: widget.key,);

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
                    child: _boardTabView,
                ),
                VerticalDivider(
                    width: divideWidth.toDouble(),
                    color: config.color.foreground3,
                ),
                Expanded(
                    flex: mainWidth,
                    child: _threadTabView,
                )
            ],
        );
    }

    void openThread(Thread thread){
        setState(() {
            _threadTabView.open(thread);
        });
    }
    void openBoard(Board board){
        setState(() {
            _boardTabView.open(board);
        });
    }
    void closeThread(Thread thread){
        setState(() {
            _threadTabView.close(thread);
        });
    }
    void closeBoard(Board board){
        setState(() {
            _boardTabView.close(board);
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
    static final _BoardTabViewManager manager = _BoardTabViewManager.getInstance();

    final List<BoardView> _contentList = [];

    late TabController _tabController;

    late final BoardView emptyBoardView;

    @override
    void initState(){
        super.initState();

        emptyBoardView = BoardView(null,key: widget.key,);
        _contentList.add(emptyBoardView);

        _tabController = TabController(length: _contentList.length, vsync: this);

        manager.set(this);
    }

    @override
    void dispose(){
        _tabController.dispose();
        super.dispose();

        manager.unset();
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

    void set(_BoardTabViewState viewState){
        _state = viewState;
    }
    void unset(){
        _state = null;
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
    static final _ThreadTabViewManager manager = _ThreadTabViewManager.getInstance();
    
    final List<ThreadView> _contentList = [];

    late TabController _tabController;
    
    late final ThreadView emptyThreadView;

    @override
    void initState(){
        super.initState();

        emptyThreadView = ThreadView(null,key: widget.key);
        _contentList.add(emptyThreadView);

        _tabController = TabController(length: _contentList.length, vsync: this);

        manager.set(this);

        debugPrint("tabViewState initState");
    }

    @override
    void dispose(){
        _tabController.dispose();
        super.dispose();

        manager.unset();
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

    void set(_ThreadTabViewState viewState){
        _state = viewState;
    }
    void unset(){
        _state = null;
    }
}

