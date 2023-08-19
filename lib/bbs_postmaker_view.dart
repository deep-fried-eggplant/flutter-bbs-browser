import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'bbs_basedata.dart';
// import 'package:html/parser.dart' as html;
import 'package:flutter_html/flutter_html.dart';

class PostMakerView extends StatelessWidget{
    final PostMaker _postMaker;

    const PostMakerView(this._postMaker,{super.key});

    @override
    Widget build(BuildContext context){
        final navigatorState = Navigator.of(context);
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
                                onPressed: ()=>_sendButtonOnPressed(context,navigatorState),
                                child: const Text("send")
                            )
                        ],
                    )
                ],
            ),
        );
    }

    Future<void> _sendButtonOnPressed(BuildContext context,NavigatorState navigatorState) async{
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
            debugPrint(_postMaker.cookie.toString());
            final futBody=sjisToUtf8(_postMaker.response.bodyBytes);
            futBody.then((body){
                if(!body.contains("書き込み確認")){
                    navigatorState.pop();
                    return;
                }
                debugPrint("kakikomi kakininn!!!");
                showDialog(
                    context: context,
                    builder: (buildContext){
                        return AlertDialog(
                            content:SelectableText(body.replaceAll("<br>", "\n")),
                            // content: SingleChildScrollView(
                            //     child: Html(data: body,),
                            // ),
                            actions: [
                                TextButton(
                                    child: const Text("send"),
                                    onPressed: (){
                                        _postMaker.send();
                                        Navigator.of(buildContext).pop();
                                        navigatorState.pop();
                                    },
                                )
                            ],
                        );
                    }
                );
            });
        });
        _debugPrintResponse(_postMaker.response);
    }
}

Future<void> _debugPrintResponse(Response response) async{
    final futHtml=sjisToUtf8(response.bodyBytes);
    debugPrint("[STATUS]");
    debugPrint(response.statusCode.toString());
    debugPrint("\n[HEADERS]");
    for(final key in response.headers.keys){
        final value=response.headers[key];
        debugPrint("$key\t: $value");
    }
    debugPrint("\n[BODY]");
    debugPrint(await futHtml);
}
