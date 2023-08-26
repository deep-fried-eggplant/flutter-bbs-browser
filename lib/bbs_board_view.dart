import 'package:flutter/material.dart';
import 'bbs_basedata.dart';
import 'bbs_manager.dart';
import 'configuration.dart';

class BoardView extends StatefulWidget{
    const BoardView({super.key});

    @override
    State<BoardView> createState(){
        return _BoardViewState();
    }
}

class _BoardViewState extends State<BoardView>{

    static final config = Config.getInstance();
    static final boardManager = BoardManager.getInstance();

    @override
    void initState(){
        boardManager.setDrawer(draw);
        super.initState();
    }

    @override
    Widget build(BuildContext context){
        Board? board = boardManager.board;
        return Scaffold(
            appBar: AppBar(
                backgroundColor: config.color.primary,
                title: Text(
                    board==null?"":board.boardInfo.name,
                    style: TextStyle(
                        color: config.color.onPrimary
                    ),
                ),
                actions: [
                    IconButton(
                        onPressed: draw,
                        icon: Icon(
                            Icons.update,
                            color: config.color.onPrimary,
                        )
                    )
                ],
            ),
            body: Center(
                child: FutureBuilder<Widget>(
                    future: _buildContent(board),
                    builder: (context, snapshot) {
                        if(snapshot.hasData){
                            return snapshot.data!;
                        }else if(snapshot.hasError){
                            return Container(
                                color: config.color.background,
                                child: Text(
                                    snapshot.error!.toString(),
                                    style: TextStyle(
                                        color: config.color.foreground
                                    ),
                                ),
                            );
                        }else{
                            return Container(color: config.color.background);
                        }
                    },
                )
            ),
            bottomNavigationBar: BottomAppBar(
                color: config.color.primary,
                elevation: 0,
                height: 50,
                child: Row(
                    children: [
                        const Expanded(child: SizedBox(),),
                        // IconButton(
                        //     onPressed: (){
                        //         debugPrint("plus");
                        //     },
                        //     icon: Icon(
                        //         Icons.add,
                        //         color: config.color.onPrimary,
                        //     )
                        // )
                        OutlinedButton(
                            onPressed: (){
                                debugPrint("plus");
                            },
                            // style: ButtonStyle(
                            //     for
                            // ),
                            child: Text(
                                "書き込み",
                                style: TextStyle(color: config.color.onPrimary),
                            )
                        )
                    ],
                ),
            ),
        );
    }

    void draw(){
        setState(() {});
    }

    static Future<Widget> _buildContent(Board? board) async{
        final TextStyle titleTextStyle = TextStyle(color: config.color.foreground);
        final TextStyle titleTextStyle2 = TextStyle(color: config.color.foreground3);

        String dateTimeToString(DateTime dt){
            String w2(int val){
                return val.toString().padLeft(2,"0");
            }
            String w4(int val){
                return val.toString().padLeft(4,"0");
            }
            return "${w4(dt.year)}/${w2(dt.month)}/${w2(dt.day)} ${w2(dt.hour)}:${w2(dt.minute)}";
        }

        if(board != null){
            if(await board.update()){
                var list = List<Widget>.empty(growable: true);
                for(var item in board.threadInfoList){
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
            }else{
                return const Text("failed to get");
            }
        }else{
            return Container(color: config.color.background);
        }    
    }
}