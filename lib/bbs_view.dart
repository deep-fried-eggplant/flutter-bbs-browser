import 'package:flutter/material.dart';

import 'bbs.dart';
import 'bbs_manager.dart';

class BoardView extends StatefulWidget{
    const BoardView({super.key});

    @override
    State<BoardView> createState(){
        return _BoardViewState();
    }
}

class _BoardViewState extends State<BoardView>{

    @override
    void initState(){
        BoardManager().setDrawer(draw);
        super.initState();
    }

    @override
    Widget build(BuildContext context){
        Board? board = BoardManager().board;
        return Scaffold(
            appBar: AppBar(
                title: board == null ? const Text("") : Text(board.boardInfo.name),
                actions: [
                    IconButton(
                        onPressed: draw,
                        icon: const Icon(Icons.update)
                    )
                ],
            ),
            body: Center(
                child: FutureBuilder<Widget>(
                    future: _getContent(board),
                    builder: (context, snapshot) {
                        if(snapshot.hasData){
                            return snapshot.data!;
                        }else if(snapshot.hasError){
                            return Text(snapshot.error!.toString());
                        }else{
                            return const SizedBox();
                        }
                    },
                )
            )
        );
    }

    void draw(){
        setState(() {});
    }

    static Future<Widget> _getContent(Board? board) async{
        if(board != null){
            if(await board.update()){
                var list = List<Widget>.empty(growable: true);
                for(var item in board.threadInfoList){
                    list.add(
                        InkWell(
                            onTap: (){
                                ThreadManager().open(item);
                            },
                            child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.all(0),
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(width: 0.2))),
                                child: Text(item.title),
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
            return const SizedBox();
        }    
    }
}

class ThreadView extends StatefulWidget{
    const ThreadView({super.key});

    @override
    State<ThreadView> createState(){
        return _ThreadViewState();
    }
}
class _ThreadViewState extends State<ThreadView>{

    @override
    void initState(){
        ThreadManager().setDrawer(draw);
        super.initState();
    }

    @override
    Widget build(BuildContext context){
        var thread = ThreadManager().thread;
        return Scaffold(
            appBar: AppBar(
                title: thread == null ? const Text("") : Text(thread.threadInfo.title.replaceAll("\n", " ")),
                actions: [
                    IconButton(
                        onPressed: draw,
                        icon: const Icon(Icons.update)
                    )
                ],
            ),
            body: Center(
                child: FutureBuilder(
                    future: _getContent(thread),
                    builder: (context, snapshot) {
                        if(snapshot.hasData){
                            return snapshot.data!;
                        }else if(snapshot.hasError){
                            return Text(snapshot.error!.toString());
                        }else{
                            return const SizedBox();
                        }
                    },
                )
            ),
        );
    }

    void draw(){
        setState(() {});
    }

    static Future<Widget> _getContent(Thread? thread) async{
        RichText nameView(String name){
            var result = List<TextSpan>.empty(growable: true);
            var boldEndStrList = "<b>$name</b>".split("</b>");
            for(var boldEndStr in boldEndStrList){
                if(boldEndStr.isEmpty){
                    continue;
                }
                var boldBegin = boldEndStr.indexOf("<b>");
                if(boldBegin==0){
                    result.add(
                        TextSpan(
                            text: boldEndStr.substring("<b>".length),
                            style: const TextStyle(fontWeight: FontWeight.bold)
                        )
                    );
                }else if(boldBegin>0){
                    result.add(
                        TextSpan(text: boldEndStr.substring(0,boldBegin))
                    );
                    result.add(
                        TextSpan(
                            text: boldEndStr.substring(boldBegin+"<b>".length),
                            style: const TextStyle(fontWeight: FontWeight.bold)
                        )
                    );
                }
            }
            return RichText(
                text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: result
                )
            );
        }

        if(thread != null){
            if(await thread.update()){
                var list = List<Widget>.empty(growable: true);
                for(var item in thread.postList){
                    list.add(
                        Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(0),
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(width:0.2))),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Container(
                                                padding: const EdgeInsets.only(right: 5),
                                                child: Text(item.index.toString())
                                            ),
                                            Flexible(child: 
                                                Wrap(
                                                    children: [
                                                        nameView(item.name),
                                                        Text("[${item.mailTo}]"),
                                                        Text("${item.postAt} ${item.userId}"),
                                                    ]
                                                )
                                            )
                                        ],
                                    ),
                                    Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(5),
                                        child: Text(item.message)
                                    ),
                                ],
                            )
                        ),
                    );        
                }
                return SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: list,
                    )
                );
            }else{
                return const Text("failed to get");
            }
        }else{
            return const SizedBox();
        }
    }
}

