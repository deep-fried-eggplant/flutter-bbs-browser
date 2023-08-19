import 'package:bbs_browser/configuration.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:charset_converter/charset_converter.dart';
import 'bbs_cookie.dart';

class Board{
    final BoardInfo boardInfo;

    List<ThreadInfo> threadInfoList=[];

    Board(this.boardInfo);

    Future<bool> update() async{
        final String uri=
            "https://${boardInfo.server}"
            "/${boardInfo.name}"
            "/subject.txt";
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
    final String server;
    final String name;
    final String? nameToShow;

    BoardInfo(this.server,this.name,{this.nameToShow});
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
            "/${threadInfo.boardInfo.name}"
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
                    // return htmlUnescape(line.substring(begin,end).replaceAll("<br>", "\n"));
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
    final ThreadInfo _threadInfo;
    ThreadInfo get threadInfo => _threadInfo;
    String name   ="";
    String mailTo ="";
    String message="";
    final String _time;

    final http.Client _client = http.Client();

    final Cookie _cookie;
    Cookie get cookie => _cookie;

    late http.Response response;

    PostMaker(this._threadInfo)
    :   _cookie=Cookie(_threadInfo.boardInfo.server),
        _time=(DateTime.now().millisecondsSinceEpoch~/1000).toString();

    Future<void> send() async{
        final uriStr = 
            "https://"
            "${_threadInfo.boardInfo.server}"
            "/test/bbs.cgi";
        final header = _makeHeader();
        final body = await _makeBody();

        response = await _client.post(Uri.parse(uriStr),
            headers: header,
            body: body,
        );

        if(response.headers.containsKey("set-cookie")){
            final cookies=splitMultiSetCookie(response.headers["set-cookie"]!);
            for(var elem in cookies){
                _cookie.set(elem);
            }
        }else if(response.headers.containsKey("Set-Cookie")){
            final cookies=splitMultiSetCookie(response.headers["Set-Cookie"]!);
            for(var elem in cookies){
                _cookie.set(elem);
            }
        }
    }

    Map<String,String> _makeHeader(){
        Map<String,String> header={};
        header["Content-Type"] = "application/x-www-form-urlencoded; charset=shift_jis";
        header["User-Agent"] = Config.getInstance().postUserAgent;
        header["Referer"] = "https://${threadInfo.boardInfo.server}/test/read.cgi"
                            "/${threadInfo.boardInfo.name}/${threadInfo.key}";
        if(_cookie.isNotEmpty){
            final list=<String>[];
            _cookie.get(_threadInfo.boardInfo.server).forEach((key, value){
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
            "bbs":_threadInfo.boardInfo.name,
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