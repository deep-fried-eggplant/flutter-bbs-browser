import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:charset_converter/charset_converter.dart';

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
            final htmlUnescape=HtmlUnescape();
            final dat=htmlUnescape.convert(await sjisToUtf8(response.bodyBytes));
            return _parseSubjextTxt(dat);
        }else{
            return false;
        }
    }

    bool _parseSubjextTxt(String txt){
        for(var line in txt.split("\n")){
            int keyEnd=line.indexOf("<>");
            if(keyEnd<0){
                // debugPrint("sep not found : $line");
                // return false;
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
            String title=line.substring(titleBegin,titleEnd);
            
            int? length=int.tryParse(
                line.substring(titleEnd+2,line.indexOf(")",titleEnd+2))
            );
            if(length == null){
                return false;
                // length=10;
            }
            var epoch=int.tryParse(key);
            if(epoch==null){
                debugPrint("-$key-");
                return false;
            }
            DateTime createdAt=DateTime.fromMillisecondsSinceEpoch(epoch*1000);
            threadInfoList.add(ThreadInfo(boardInfo, key, title, createdAt, length));
        }
        return true;
    }
}

class BoardInfo{
    final String server;
    final String name;

    BoardInfo(this.server,this.name);
}

class Thread{
    final ThreadInfo threadInfo;
    List<Post> postList=[];
    bool closed=false;

    Thread(this.threadInfo);

    Future<bool> update() async{
        final String uri=
            "https://${threadInfo.boardInfo.server}"
            "/${threadInfo.boardInfo.name}"
            "/dat"
            "/${threadInfo.key}";
        final response=await http.get(Uri.parse(uri));
        if(response.statusCode==200){
            
            return _parseDat(await sjisToUtf8(response.bodyBytes));
        }else{
            return false;
        }
    }

    bool _parseDat(String dat){
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
                    return line.substring(begin,end);
                }
            }
            
            String? tmp;

            // getting name
            tmp=nextSearch();
            if(tmp != null){
                name=tmp;
            }else{
                return false;
            }

            // getting mailTo
            tmp=nextSearch();
            if(tmp!=null){
                mailTo=tmp;
            }else{
                return false;
            }

            // getting postAt & id
            tmp=nextSearch();
            if(tmp!=null){
                int pId=line.indexOf("ID:");
                postAt=line.substring(begin,pId-1);
                userId=line.substring(pId,end);
            }else{
                return false;
            }

            // getting message
            tmp=nextSearch();
            if(tmp!=null){
                message=tmp;
            }else{
                return false;
            }

            postList.add(Post(index,name,mailTo,postAt,userId,message));
            return true;
        }
        
        int index=0;
        for(var line in dat.split("\n")){
            if(parseLine(++index,line)==false){
                return false;
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
    // return await CharsetConverter.decode("utf-8", enc);
}