import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'shift_jis.dart';
import 'bbs_boardlist.dart';
import 'bbs_thread.dart';
import 'bbs_manager.dart';
import 'configuration.dart';
// import 'app_manager.dart';


class Board{
    final BoardInfo boardInfo;

    List<ThreadInfo> threadInfoList=[];

    Board(this.boardInfo);

    Future<bool> update() async{
        final String uri=
            "${boardInfo.protocol}://${boardInfo.server}/${boardInfo.path}/subject.txt";
        final response = await http.get(Uri.parse(uri));
        debugPrint("$uri -> ${response.statusCode.toString()}");
        if(response.statusCode==200){
            threadInfoList.clear();
            return _parseSubjextTxt(await sjisToUtf8(response.bodyBytes));
        }else{
            return false;
        }
    }

    bool _parseSubjextTxt(String txt){
        final HtmlUnescape htmlUnescapeInstance = HtmlUnescape();
        String htmlUnescape(String data)=>htmlUnescapeInstance.convert(data);

        for(var line in txt.split("\n")){
            int keyEnd=line.indexOf("<>");
            if(keyEnd<0){
                break;
            }
            String key=line.substring(0,keyEnd).substring(0,10);
            
            int titleBegin=keyEnd+2;
            int titleEnd=0;
            while(true){
                int tmp=line.indexOf(" (",titleEnd+2);
                if(tmp<0){
                    break;
                }else{
                    titleEnd=tmp;
                }
            }
            String title=htmlUnescape(
                line.substring(titleBegin,titleEnd).replaceAll("<br>", "\n")
            );
            
            int? length=int.tryParse(
                line.substring(titleEnd+2,line.indexOf(")",titleEnd+2))
            );
            if(length == null){
                debugPrint(line);
                return false;
            }
            var epoch=int.tryParse(key);
            if(epoch==null){
                debugPrint(line);
                return false;
            }
            DateTime createdAt=DateTime.fromMillisecondsSinceEpoch(epoch*1000);
            threadInfoList.add(ThreadInfo(boardInfo, key, title, createdAt, length));
        }
        debugPrint(threadInfoList.length.toString());
        return true;
    }
}

class BoardInfo{
    final String protocol;
    final String server;
    final String path;
    final String name;

    BoardInfo(this.protocol,this.server,this.path,this.name);

    bool equals(BoardInfo other){
        return
            protocol == other.protocol &&
            server   == other.server   &&
            path     == other.path     &&
            name     == other.name;
    }
}

class BoardView extends StatefulWidget{
    final Board? board;

    const BoardView(this.board,{super.key});

    @override
    State<BoardView> createState(){
        return _BoardViewState();
    }
}
class _BoardViewState extends State<BoardView>{
    static final config = Config.getInstance();

    static final Set<BoardView> _loadedViewList = {};

    bool _reloadFlag = false;

    @override
    void initState(){
        super.initState();
        debugPrint("boardViewState initState widget:${widget.hashCode} this:$hashCode");

        _reloadFlag = _loadedViewList.add(widget);
    }

    @override
    void didUpdateWidget(BoardView oldWidget){
        super.didUpdateWidget(oldWidget);
        debugPrint("boardViewState didUpdateWidget oldWidget:${oldWidget.hashCode}");

        _reloadFlag = (_loadedViewList..remove(oldWidget)).add(widget);
    }

    @override
    Widget build(BuildContext context){
        final TextStyle onPrimaryTextStyle = TextStyle(color: config.color.onPrimary);
        Board? board = widget.board;

        debugPrint("threadView build widget:${widget.hashCode} name:${board?.boardInfo.name}");

        if(_reloadFlag){
            _reloadFlag=false;
            update();
        }
        
        return Scaffold(
            appBar: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child:AppBar(
                    backgroundColor: config.color.primary,
                    title: Text(
                        board==null?"":board.boardInfo.name,
                        style: onPrimaryTextStyle
                    ),
                    actions: [
                        IconButton(
                            onPressed: (){
                                if(board != null){
                                    BoardManager.getInstance().close(board.boardInfo);
                                }
                            },
                            icon: Icon(Icons.close, color: config.color.onPrimary)
                        )
                    ],
                ),
            ),
            body: Center(
                child: _BoardViewBody(board,key: widget.key),
            ),
            bottomNavigationBar: BottomAppBar(
                color: config.color.primary,
                elevation: 0,
                height: 50,
                padding: EdgeInsets.zero,
                child: Row(
                    children: [
                        IconButton(
                            onPressed: (){
                                showDialog(
                                    context: context,
                                    builder: (context1){
                                        return const AlertDialog(
                                            content: BoardListView(),
                                        );
                                    }
                                );
                            },
                            icon: Icon(Icons.menu_open_outlined, color: config.color.onPrimary),
                            
                        ),
                        const Expanded(child: SizedBox(),),
                        IconButton(
                            onPressed: (){
                                debugPrint("plus");
                            },
                            icon: Icon(Icons.create,color: config.color.onPrimary),
                        ),
                        IconButton(
                            onPressed: update,
                            icon: Icon(Icons.refresh,color: config.color.onPrimary),
                        )
                    ],
                )
            )
        );
    }

    void update(){
        widget.board?.update().then((value){
            if(value){
                setState((){});
            }else{
                debugPrint("BoardViewState update failed");
            }
        });
    }
}

class _BoardViewBody extends StatelessWidget{
    static final Config config = Config.getInstance();

    final Board? _board;

    const _BoardViewBody(this._board,{super.key});

    @override
    Widget build(BuildContext context){
        if(_board==null){
            return Container(color: config.color.background,);
        }

        String dateTimeToString(DateTime dt){
            String w2(int val){
                return val.toString().padLeft(2,"0");
            }
            String w4(int val){
                return val.toString().padLeft(4,"0");
            }
            return "${w4(dt.year)}/${w2(dt.month)}/${w2(dt.day)} ${w2(dt.hour)}:${w2(dt.minute)}";
        }
        final TextStyle titleTextStyle = TextStyle(color: config.color.foreground);
        final TextStyle titleTextStyle2 = TextStyle(color: config.color.foreground3);

        final list = List<Widget>.empty(growable: true);
        for(var item in _board!.threadInfoList){
            final RegExp subTitleRegExp = RegExp(r" \[([^\]\]]*)★\]$");
            final RegExpMatch? match = subTitleRegExp.firstMatch(item.title);
            late final String mainTitle;
            late final String subTitle;
            if(match!=null){
                // final int matchLen = match[0]!.length;
                mainTitle = item.title.substring(0,item.title.length-match[0]!.length);
                subTitle = match.groupCount>=1 ? match[1]! : "";
                // subTitle = match[0]!;
            }else{
                mainTitle = item.title;
                subTitle = "";
            }
            list.add(
                InkWell(
                    onTap: (){
                        ThreadManager.getInstance().open(item);
                        // AppManager.getInstance().view?.openThread(item);
                    },
                    child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: config.color.background,
                            border: const Border.symmetric(horizontal: BorderSide(width: 0.2))
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    mainTitle,
                                    style: titleTextStyle,
                                ),
                                Row(
                                    children: [
                                        Text(
                                            dateTimeToString(item.createdAt),
                                            style: titleTextStyle2,
                                        ), 
                                        Text(
                                            subTitle,
                                            style: titleTextStyle2,
                                        ),
                                        const Expanded(child: SizedBox()),
                                        Text(
                                            item.length.toString(),
                                            style: titleTextStyle2,
                                        )
                                    ],
                                )
                            ],
                        ),
                    ),
                )
            );
        }
        return SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list,
            ),
        );
    }
}
