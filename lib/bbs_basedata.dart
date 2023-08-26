import 'package:bbs_browser/configuration.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:charset_converter/charset_converter.dart';
import 'bbs_cookie.dart';
import 'bbs_user_data.dart';

class BBS{
    final List<BBSCategory> _menu=[];

    

    List<BBSCategory>? _parseBBSMenu(String html){
        List<BBSCategory> list=[];

        final matches = 
            RegExp(r"<br><br><b>(.*?)</b>((<br><a.*?</a>)*)").allMatches(html.replaceAll("\n", ""));

        for(final match in matches){
            if(match.groupCount!=3){
                continue;
            }
            
            final String catName = match[1]!;
            final List<BoardInfo> boardInfoList = [];
            // debugPrint(name);
            final List<String> linkList = match[2]!.split("<br>");
            for(int li=1; li<linkList.length; ++li){
                final String link = linkList[li];
                final String? url = RegExp(r'(href|HREF)="(.*?)"').firstMatch(link)?[2];
                if(url==null){
                    continue;
                }
                final String protocol = url.substring(0,url.indexOf("://"));
                final int sepIndex = url.indexOf("/",protocol.length+"://".length);
                final String server = url.substring(protocol.length+"://".length,sepIndex);
                final String path = url.substring(sepIndex+1);
                final String name = link.substring(
                    link.indexOf(">")+1,
                    link.indexOf("<",link.indexOf(">"))
                );
                boardInfoList.add(BoardInfo(protocol, server, path, name));
                // debugPrint("$name : $url");
            }
            if(boardInfoList.isNotEmpty){
                list.add(BBSCategory(catName, boardInfoList));
            }
        }

        return list;
    }
}

class BBSCategory{
    final String name;
    final List<BoardInfo> boardInfoList;

    BBSCategory(this.name,this.boardInfoList);

}

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
}

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
        final response=await http.get(Uri.parse(uri));
        debugPrint("$uri -> ${response.statusCode.toString()}");
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
                    // postAt=tmp.substring(0,pId).trim();
                    // userId=tmp.substring(pId+"ID:".length).trim();
                    postAt=htmlUnescape(tmp.substring(0,pId)).trim();
                    userId=htmlUnescape(tmp.substring(pId+"ID:".length)).trim();
                }else{
                    // postAt=tmp.trim();
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
                // return false;
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
}

class Post{
    final int index;
    final String name;
    final String mailTo;
    final String postAt;
    final String userId;
    final String message;

    const Post(this.index,this.name,this.mailTo,this.postAt,this.userId,this.message);
}

Future<String> sjisToUtf8(Uint8List bytes) async{
    return await CharsetConverter.decode("shift_jis",bytes);
}
Future<Uint8List> utf8Tosjis(String str) async{
    return await CharsetConverter.encode("shift_jis", str);
}

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
        debugPrint("PostMaker: Cookie : ${_cookie.toString()}");
    }

    Future<void> send() async{
        // final uriStr = 
        //     "https://"
        //     "${_threadInfo.boardInfo.server}"
        //     "/test/bbs.cgi";
        // debugPrint(uriStr);
        final header = _makeHeader();
        final body = await _makeBody();

        debugPrint(header.toString());

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
        debugPrint(_cookie.toString());
    }

    Map<String,String> _makeHeader(){
        Map<String,String> header={};
        header["Content-Type"] = "application/x-www-form-urlencoded; charset=shift_jis";
        header["User-Agent"] = Config.getInstance().postUserAgent;
        header["Referer"] = "https://${threadInfo.boardInfo.server}/test/read.cgi"
                            "/${threadInfo.boardInfo.path}/${threadInfo.key}";
        if(_cookie.isNotEmpty){
            final list=<String>[];
            _cookie.get(_destUri).forEach((key, value){
                list.add("$key=$value");
            });
            header["Cookie"]=list.join("; ");
            // debugPrint("Cookie to post: ${header}")
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