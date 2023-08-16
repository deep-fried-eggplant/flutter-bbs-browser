import 'package:flutter/material.dart';
import 'bbs_basedata.dart';

class PostMakerView extends StatelessWidget{
    final PostMaker _postMaker;

    PostMakerView(ThreadInfo threadInfo,{super.key}):_postMaker=PostMaker(threadInfo);

    @override
    Widget build(BuildContext context){
        // final navigatorState = Navigator.of(context);
        return SingleChildScrollView(
            child: Column(
                children: [
                    Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Container(
                                width: 200,
                                padding: const EdgeInsets.all(5),
                                child: TextField(
                                    decoration: const InputDecoration(
                                        hintText: "name"
                                    ),
                                    onChanged: (value) => _postMaker.name=value,
                                ),
                            ),
                            Container(
                                width: 100,
                                padding: const EdgeInsets.all(5),
                                child: TextField(
                                    decoration: const InputDecoration(
                                        hintText: "mail"
                                    ),
                                    onChanged: (value) => _postMaker.mailTo=value,
                                ),
                            ),
                        ],
                    ),
                    Container(
                        width: 300,
                        padding: const EdgeInsets.all(5),
                        child: TextField(
                            keyboardType: TextInputType.multiline,
                            maxLines: 5,
                            onChanged: (value) => _postMaker.message=value,
                        ),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                            TextButton(
                                onPressed: ()async{
                                    if(_postMaker.message.isEmpty){
                                        showDialog(
                                            context: context,
                                            builder: (buildContext){
                                                return AlertDialog(
                                                    content: const Text("message is empty!"),
                                                    actions: [
                                                        TextButton(
                                                            onPressed: (){
                                                                Navigator.of(buildContext).pop();
                                                            },
                                                            child: const Text("close")
                                                        )
                                                    ],
                                                );
                                            }
                                        );
                                        return;
                                    }
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (buildContext){
                                            return const AlertDialog(
                                                content: Text("sending..."),
                                            );
                                        }
                                    );
                                    await _postMaker.send().then((value)async{
                                        Navigator.of(context).pop();
                                        debugPrint(_postMaker.cookie.get().toString());
                                        final futHtml=sjisToUtf8(_postMaker.response.bodyBytes);
                                        futHtml.then((html){
                                            if(!html.contains("書き込み確認")){
                                                Navigator.of(context).pop();
                                                return;
                                            }
                                            showDialog(
                                                context: context,
                                                builder: (buildContext){
                                                    return AlertDialog(
                                                        content:Text(html.replaceAll("<br>", "\n")),
                                                        actions: [
                                                            TextButton(
                                                                child: const Text("send"),
                                                                onPressed: (){
                                                                    _postMaker.send();
                                                                    Navigator.of(buildContext).pop();
                                                                },
                                                            )
                                                        ],
                                                    );
                                                }
                                            );
                                        });
                                    });
                                    debugPrint("[REQUEST]");
                                    debugPrint(_postMaker.response.request!.toString());
                                    debugPrint("\n[STATUS CODE]");
                                    debugPrint(_postMaker.response.statusCode.toString());
                                    debugPrint("\n[HEADERS]");
                                    debugPrint(_postMaker.response.headers.toString());
                                    final html=await sjisToUtf8(_postMaker.response.bodyBytes);
                                    debugPrint("\n[BODY]");
                                    debugPrint(html);
                                    debugPrint("\n[COOKIE]");
                                    debugPrint(_postMaker.cookie.get().toString());

                                    // if(html.contains("書き込み確認")){
                                        
                                    // }
                                },
                                child: const Text("send")
                            )
                        ],
                    )
                ],
            ),
        );
    }
}

Future<void> showPostMaker(BuildContext context,ThreadInfo threadInfo) async{
    String name="",mail="",message="";
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext buildContext){
            final navigatorState = Navigator.of(buildContext);
            return AlertDialog(
                title: const Text("test test"),
                content: SingleChildScrollView(
                    child: Column(
                        children: [
                            Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Container(
                                        width: 200,
                                        padding: const EdgeInsets.all(5),
                                        child: TextField(
                                            decoration: const InputDecoration(
                                                hintText: "name"
                                            ),
                                            onChanged: (value) => name=value,
                                        ),
                                    ),
                                    Container(
                                        width: 100,
                                        padding: const EdgeInsets.all(5),
                                        child: TextField(
                                            decoration: const InputDecoration(
                                                hintText: "mail"
                                            ),
                                            onChanged: (value) => mail=value,
                                        ),
                                    ),
                                ],
                            ),
                            Container(
                                width: 300,
                                padding: const EdgeInsets.all(5),
                                child: TextField(
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 5,
                                    onChanged: (value) => message=value,
                                ),
                            )
                        ],
                    ),
                ),
                actions: [
                    TextButton(
                        onPressed: (){
                            navigatorState.pop();
                        },
                        child: const Text("cancel")
                    ),
                    TextButton(
                        onPressed: ()async{
                            if(message.isNotEmpty){
                                final postMaker=PostMaker(threadInfo);
                                postMaker.name=name;
                                postMaker.mailTo=mail;
                                postMaker.message=message;
                                await postMaker.send();
                                debugPrint(postMaker.response.request!.toString());
                                debugPrint(postMaker.response.statusCode.toString());
                                debugPrint(postMaker.response.headers.toString());
                                debugPrint(await sjisToUtf8(postMaker.response.bodyBytes));
                            }
                            navigatorState.pop();
                        },
                        child: const Text("write")
                    )
                ],
            );
        }
    );
}