import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'shift_jis.dart';
import 'bbs_board.dart';
import 'bbs_post.dart';
import 'bbs_postmaker.dart';
import 'bbs_manager.dart';
import 'configuration.dart';


class Thread{
    final ThreadInfo threadInfo;
    List<Post> postList=[];
    bool closed=false;

    PostMaker postMaker;

    Thread(this.threadInfo):postMaker=PostMaker(threadInfo);

    Future<bool> update() async{
        final String uri=
            "https://${threadInfo.boardInfo.server}"
            "/${threadInfo.boardInfo.path}"
            "/dat"
            "/${threadInfo.key}.dat";
        debugPrint("Thread update URL:$uri");
        final response=await http.get(Uri.parse(uri));
        debugPrint("Thread update     -> ${response.statusCode.toString()}");
        if(response.statusCode==200){
            postList.clear();
            return _parseDat(await sjisToUtf8(response.bodyBytes));
        }else{
            return false;
        }
    }

    bool _parseDat(String dat){
        final HtmlUnescape htmlUnescapeInstance=HtmlUnescape();
        String htmlUnescape(String data)=>htmlUnescapeInstance.convert(data);

        bool parseLine(int index,String line){
            String name;
            String mailTo;
            String postAt;
            String userId;
            String message;

            int begin=0,end=-2;
            String? nextSearch(){
                begin=end+2;
                end=line.indexOf("<>",begin);
                if(end<0){
                    return null;
                }else{
                    return line.substring(begin,end).replaceAll("<br>", "\n");
                }
            }
            
            String? tmp;

            // get name
            tmp=nextSearch();
            if(tmp!=null){
                // name=tmp.trim();
                name=htmlUnescape(tmp).trim();
            }else{
                return false;
            }

            // get mailTo
            tmp=nextSearch();
            if(tmp!=null){
                // mailTo=tmp.trim();
                mailTo=htmlUnescape(tmp).trim();
            }else{
                return false;
            }

            // get postAt & id
            tmp=nextSearch();
            if(tmp!=null){
                int pId=tmp.indexOf("ID:");
                if(pId>=0){
                    postAt=htmlUnescape(tmp.substring(0,pId)).trim();
                    userId=htmlUnescape(tmp.substring(pId+"ID:".length)).trim();
                }else{
                    postAt=htmlUnescape(tmp).trim();
                    userId="";
                }
            }else{
                return false;
            }

            // get message
            tmp=nextSearch();
            if(tmp!=null){
                message=htmlUnescape(tmp.replaceAll(RegExp(r"<.*?>"), ""));
            }else{
                return false;
            }

            postList.add(Post(index,name,mailTo,postAt,userId,message));
            return true;
        }
        
        int index=0;
        for(var line in dat.split("\n")){
            if(parseLine(++index,line)==false){
                break;
            }
        }
        threadInfo.length=postList.length;
        return true;
    }
}

class ThreadInfo{
    final BoardInfo boardInfo;
    final String key;
    final String title;
    final DateTime createdAt;
    int length;
    ThreadInfo(this.boardInfo,this.key,this.title,this.createdAt,this.length);

    bool equals(ThreadInfo other){
        return boardInfo.equals(other.boardInfo) && key==other.key;
    }
}

class ThreadView extends StatefulWidget{
    final Thread? thread;
    
    const ThreadView(this.thread,{super.key});

    @override
    State<ThreadView> createState(){
        return _ThreadViewState();
    }
}
class _ThreadViewState extends State<ThreadView>{
    static final config = Config.getInstance();
    
    static final Set<ThreadView> _loadedViewList = {};

    bool _reloadFlag = false;

    @override
    void initState(){
        super.initState();
        debugPrint("threadViewState initState widget:${widget.hashCode} this:$hashCode");

        _reloadFlag = _loadedViewList.add(widget);
    }

    @override
    void didUpdateWidget(ThreadView oldWidget){
        super.didUpdateWidget(oldWidget);
        debugPrint("threadViewState didUpdateWidget oldWidget:${oldWidget.hashCode}");
        
        _reloadFlag = (_loadedViewList..remove(oldWidget)).add(widget);
    }

    @override
    Widget build(BuildContext context){
        final thread = widget.thread;
        debugPrint("threadView build widget:${widget.hashCode} key:${thread?.threadInfo.key}");

        if(_reloadFlag){
            _reloadFlag = false;
            update();
        }


        return Scaffold(
            appBar: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: AppBar(
                    backgroundColor: config.color.primary,
                    title: Text(
                        thread==null?"":thread.threadInfo.title.replaceAll("\n", " "),
                        style: TextStyle(
                            color: config.color.onPrimary
                        ),    
                    ),
                    actions: [
                        IconButton(
                            onPressed: (){
                                if(thread!=null){
                                    ThreadManager.getInstance().close(thread.threadInfo);
                                }
                            },
                            icon: Icon(Icons.close,color: config.color.onPrimary,)
                        )
                    ],
                ),
            ),
            body: Center(
                child: SizedBox(height: double.infinity, child: ThreadViewBody(thread))
                // child: Container(height: double.infinity,color: config.color.background,child: ThreadViewBody(thread),),
            ),
            bottomNavigationBar: BottomAppBar(
                color: config.color.primary,
                elevation: 0,
                height: 50,
                padding: EdgeInsets.zero,
                child: Row(
                    children: [
                        const Expanded(child: SizedBox()),
                        IconButton(
                            onPressed: (){
                                if(thread!=null){
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
                            icon: Icon(Icons.create, color: config.color.onPrimary)
                        ),
                        IconButton(
                            onPressed: update,
                            icon: Icon(Icons.refresh,color: config.color.onPrimary),
                            color: config.color.onPrimary,
                        ),
                    ],
                ),
            ),
        );
    }

    void update(){
        widget.thread?.update().then((value){
            if(value){
                setState((){});
            }else{
                debugPrint("ThreadViewState update failed");
            }
        });
    }
}

class ThreadViewBody extends StatelessWidget{
    static final Config config = Config.getInstance();

    final Thread? _thread;

    const ThreadViewBody(this._thread,{super.key});

    @override
    Widget build(BuildContext context){
        if(_thread == null){
            return Container(color: config.color.background,);
        }

        final list = List<Widget>.empty(growable: true);
        final bodyTextStyle2 = TextStyle(color: config.color.foreground2);
        for(final item in _thread!.postList){
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
                                                _nameView(item.name),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list,
            )
        );
    }
}

Widget _nameView(String name){
    final config = Config.getInstance();
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

