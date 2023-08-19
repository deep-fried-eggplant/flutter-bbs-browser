import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bbs_basedata.dart';
import 'bbs_manager.dart';
import 'bbs_postmaker_view.dart';
import 'configuration.dart';



class ThreadView extends StatefulWidget{
    const ThreadView({super.key});

    @override
    State<ThreadView> createState(){
        return _ThreadViewState();
    }
}
class _ThreadViewState extends State<ThreadView>{
    static final config = Config.getInstance();
    static final threadManager = ThreadManager.getInstance();

    @override
    void initState(){
        super.initState();
        threadManager.setDrawer(draw);
        threadManager.thread?.update();
    }

    @override
    Widget build(BuildContext context){
        var thread = threadManager.thread;
        return Scaffold(
            appBar: AppBar(
                backgroundColor: config.color.primary,
                title: Text(
                    (thread==null) ? "" : thread.threadInfo.title.replaceAll("\n", " "),
                    style: TextStyle(
                        color: config.color.onPrimary
                    ),    
                ),
                actions: [
                    IconButton(
                        onPressed: draw,
                        icon: Icon(Icons.update,color: config.color.onPrimary,),
                        color: config.color.onPrimary,
                    ),
                    IconButton(
                        onPressed: (){
                            threadManager.close();

                        },
                        icon: Icon(Icons.close,color: config.color.onPrimary,)
                    )
                ],
            ),
            body: Center(
                child: FutureBuilder(
                    future: _buildContent(thread),
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
                            return Container(color: config.color.background,);
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
                        const Expanded(child: SizedBox()),
                        IconButton(
                            onPressed: (){
                                if(thread != null){
                                    showDialog(
                                        context: context,
                                        builder: (buildContext){
                                            return AlertDialog(
                                                title: const Text("新規書き込み"),
                                                content: PostMakerView(thread.postMaker),
                                            );
                                        }
                                    );
                                }
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

    static Future<Widget> _buildContent(Thread? thread) async{
        RichText nameView(String name){
            var result = List<TextSpan>.empty(growable: true);
            var boldEndStrList = "<b>$name</b>".split("</b>");
            final headerTextStyle = TextStyle(
                color: config.color.foreground2
            );
            final headerTextStyleBold = TextStyle(
                color: config.color.foreground2,
                fontWeight: FontWeight.bold
            );
            for(var boldEndStr in boldEndStrList){
                if(boldEndStr.isEmpty){
                    continue;
                }
                var boldBegin = boldEndStr.indexOf("<b>");
                if(boldBegin==0){
                    result.add(
                        TextSpan(
                            text: boldEndStr.substring("<b>".length),
                            style: headerTextStyleBold
                        )
                    );
                }else if(boldBegin>0){
                    result.add(
                        TextSpan(
                            text: boldEndStr.substring(0,boldBegin),
                            style: headerTextStyle
                        )
                    );
                    result.add(
                        TextSpan(
                            text: boldEndStr.substring(boldBegin+"<b>".length),
                            style: headerTextStyleBold
                        )
                    );
                }
            }
            return RichText(
                text: TextSpan(
                    children: result
                )
            );
        }

        if(thread != null){
            if(await thread.update()){
                var list = List<Widget>.empty(growable: true);
                final bodyTextStyle2 = TextStyle(color: config.color.foreground2);
                for(var item in thread.postList){
                    list.add(
                        Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(0),
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: config.color.background,
                                border: const Border.symmetric(horizontal: BorderSide(width:0.2))
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Container(
                                                padding: const EdgeInsets.only(right: 5),
                                                child: Text(
                                                    item.index.toString(),
                                                    style: bodyTextStyle2
                                                )
                                            ),
                                            Flexible(
                                                child: Wrap(
                                                    children: [
                                                        nameView(item.name),
                                                        Text(
                                                            "[${item.mailTo}]",
                                                            style: bodyTextStyle2
                                                        ),
                                                        Text(
                                                            "${item.postAt} ${item.userId}",
                                                            style: bodyTextStyle2
                                                        ),
                                                    ]
                                                )
                                            )
                                        ],
                                    ),
                                    Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(5),
                                        child: _messageView(item.message),
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
                return const Text("スレッド取得に失敗しました");
            }
        }else{
            return const SizedBox();
        }
    }
}

Widget _messageView(String message){
    final List<Widget> widgetList=[];
    final List<String> imageList=[];
    for(final line in message.split("\n")){
        widgetList.add(_messageLineView(line, imageList));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgetList,
    );
}

Widget _messageLineView(String line,List<String> imageList){
    final config=Config.getInstance();
    final normalTextStyle=TextStyle(
        color: config.color.foreground
    );
    final linkTextStyle  =TextStyle(
        color: config.color.foreground2,
        decoration: TextDecoration.underline
    );
    assert(!line.contains("\n"));
    List<TextSpan> spanList=[];
    final searchLinkRegExp=RegExp(r"(h?t)?tps?://[\w\.\+\-\$\?\(\)/:%#&~=]+");
    final normals=line.split(searchLinkRegExp);
    final links=<String>[];
    {
        final matches=searchLinkRegExp.allMatches(line);
        for(var match in matches){
            links.add(match[0]!);
        }
    }
    assert(normals.length==links.length+1);
    spanList.add(TextSpan(text: normals[0],style: normalTextStyle));
    for(int i=0; i<links.length; ++i){
        final url=
            links[i].startsWith("ttp") ? "h${links[i]}" :
            links[i].startsWith("tp") ? "ht${links[i]}" :
            links[i];
        if(url.endsWith("jpg")||url.endsWith("jpeg")||url.endsWith("png")||url.endsWith("gif")){
            imageList.add(url);
        }

        spanList.add(TextSpan(
            text: links[i],
            style: linkTextStyle,
            recognizer: TapGestureRecognizer()..onTap=(){
                launchUrl(Uri.parse(url));
            }
        ));
        spanList.add(TextSpan(text: normals[i+1],style: normalTextStyle));
    }
    return RichText(
        text: TextSpan(
            children: spanList
        )
    );
}