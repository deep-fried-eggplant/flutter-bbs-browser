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
                        IconButton(
                            onPressed: (){
                                debugPrint("plus");
                            },
                            icon: Icon(
                                Icons.add,
                                color: config.color.onPrimary,
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
        if(board != null){
            if(await board.update()){
                var list = List<Widget>.empty(growable: true);
                for(var item in board.threadInfoList){
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
                                child: Text(
                                    item.title,
                                    style: TextStyle(
                                        color: config.color.foreground
                                    ),
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