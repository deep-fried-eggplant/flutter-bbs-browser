import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'shift_jis.dart';
import 'bbs_thread.dart';
import 'bbs_user_data.dart';
import 'bbs_cookie.dart';
import 'configuration.dart';

class PostMaker{
    static final userData = UserData.getInstance();
    
    final ThreadInfo _threadInfo;
    ThreadInfo get threadInfo => _threadInfo;
    String name   ="";
    String mailTo ="";
    String message="";
    final String _time;

    final http.Client _client = http.Client();

    final Cookie _cookie;
    Cookie get cookie => _cookie;

    final String _destUri;

    late http.Response response;

    PostMaker(this._threadInfo)
    :   _cookie=userData.cookie(_threadInfo.boardInfo.server),
        _time=(DateTime.now().millisecondsSinceEpoch~/1000).toString(),
        _destUri=
            "${_threadInfo.boardInfo.protocol}://${_threadInfo.boardInfo.server}/test/bbs.cgi"
    {
        debugPrint("PostMaker new cookie:${_cookie.toString()}");
    }

    Future<void> send() async{
        final header = _makeHeader();
        final body = await _makeBody();

        debugPrint("PostMaker send header:$header");

        response = await _client.post(Uri.parse(_destUri),
            headers: header,
            body: body,
        );

        if(response.headers.containsKey("set-cookie")){
            final cookies=splitMultiSetCookie(response.headers["set-cookie"]!);
            for(var elem in cookies){
                _cookie.set(elem);
            }
            userData.save();
        }else if(response.headers.containsKey("Set-Cookie")){
            final cookies=splitMultiSetCookie(response.headers["Set-Cookie"]!);
            for(var elem in cookies){
                _cookie.set(elem);
            }
            userData.save();
        }
        debugPrint("PostMaker send -> cookie:${_cookie.toString()}");
    }

    Map<String,String> _makeHeader(){
        Map<String,String> header={};
        header["Content-Type"] = "application/x-www-form-urlencoded; charset=shift_jis";
        header["User-Agent"] = Config.getInstance().postUserAgent;
        header["Referer"] = 
            "${threadInfo.boardInfo.protocol}://${threadInfo.boardInfo.server}/test/read.cgi"
            "/${threadInfo.boardInfo.path}/${threadInfo.key}";
        if(_cookie.isNotEmpty){
            final list=<String>[];
            _cookie.get(_destUri).forEach((key, value){
                list.add("$key=$value");
            });
            header["Cookie"]=list.join("; ");
        }
        return header;
    }
    Future<List<int>> _makeBody() async{
        String mapToStr(Map<String,String> map){
            var buffer = StringBuffer();
            for(var key in map.keys){
                buffer.write("$key=${map[key]}&");
            }
            return buffer.toString();
        }
        var str=mapToStr({
            "bbs":_threadInfo.boardInfo.path,
            "key":_threadInfo.key,
            "time":_time,
            "FROM":name,
            "mail":mailTo,
            "MESSAGE":message,
            "subject":"",
            "feature":"confirmed"
        });
        return await utf8Tosjis(str);
    }
}

class PostMakerView extends StatelessWidget{
    final PostMaker _postMaker;

    const PostMakerView(this._postMaker,{super.key});

    static final userData = UserData.getInstance();

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
                    content: Text("送信中..."),
                );
            }
        );
        await _postMaker.send().then((value)async{
            Navigator.of(context).pop();
            final futBody=sjisToUtf8(_postMaker.response.bodyBytes);
            futBody.then((body){
                if(!body.contains("書き込み確認")){
                    navigatorState.pop();
                    return;
                }
                showDialog(
                    context: context,
                    builder: (buildContext){
                        return AlertDialog(
                            content: SingleChildScrollView(
                                child: _htmlDialog(body),
                            ),
                            actions: [
                                TextButton(
                                    child: const Text("書き込む"),
                                    onPressed: ()async{
                                        Navigator.of(buildContext).pop();
                                        showDialog(
                                            barrierDismissible: false,
                                            context: buildContext,
                                            builder: (c){
                                                return const AlertDialog(
                                                    content: Text("送信中..."),
                                                );
                                            }
                                        );
                                        await _postMaker.send();
                                        _debugPrintResponse(_postMaker.response);
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


// Future<void> _sendAndShowResult(
//     BuildContext context,NavigatorState makerNavigator,PostMaker postMaker
// )async{
//     showDialog(
//         barrierDismissible: false,
//         context: context,
//         builder: (buildContext){
//             return const AlertDialog(
//                 content: Text("送信中..."),
//             );
//         }
//     );
//     await postMaker.send().then((value)async{
//         Navigator.of(context).pop();
//         debugPrint(postMaker.cookie.toString());
//         final futBody=sjisToUtf8(postMaker.response.bodyBytes);
//         futBody.then((body){
//             if(!body.contains("書き込み確認")){
//                 makerNavigator.pop();
//                 return;
//             }
//             showDialog(
//                 context: context,
//                 builder: (context1){
//                     return AlertDialog(
//                         content: SingleChildScrollView(
//                             child: _htmlDialog(body),
//                         ),
//                         actions: [
//                             TextButton(
//                                 child: const Text("書き込む"),
//                                 onPressed: ()async{
//                                     Navigator.of(context1).pop();
//                                     await _sendAndShowResult(
//                                         context1,
//                                         makerNavigator,
//                                         postMaker
//                                     );
//                                 },
//                             )
//                         ],
//                     );
//                 }
//             );
//         });
//     });
// }

Future<void> _debugPrintResponse(http.Response response) async{
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

Widget _htmlDialog(String data){
    final body=RegExp(r"<body[\s\S]*</body>").firstMatch(data)?[0];
    if(body==null){
        return const Text("failed");
    }
    String text = 
        body.replaceAll("\n", "")
        .replaceAll("<br>", "\n")
        .replaceAll(RegExp(r"<.*?>"), "");
    return SelectableText(text);
}