import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'shift_jis.dart';
import 'bbs_board.dart';
import 'bbs_manager.dart';
import 'local_file_io.dart';
import 'configuration.dart';

class BBS{
    static final Config config = Config.getInstance();

    final String name;
    final List<BBSCategory> menu;

    BBS(this.name,this.menu);

    Future<void> save() async{
        final LocalFileIO fileIO = await LocalFileIO.getInstance();
        final String path = p.join("bbsmenu","$name.json");

        // final Map<String,Object> json = {};
        final List<Map<String,Object>> menuList = [];
        for(final category in menu){
            final List<Map<String,Object>> contentList = [];
            for(final info in category.boardInfoList){
                contentList.add({
                    "url":"${info.protocol}://${info.server}/${info.path}",
                    "category_name":category.name,
                    "board_name":info.name,
                    "directory_name":info.path
                });
            }
            menuList.add({
                "category_name":category.name,
                "category_content":contentList,
                "category_total":contentList.length
            });
        }
        final jsonString = jsonEncode({
            "menu_list":menuList
        });
        await fileIO.writeBytes(path, Uint8List.fromList(utf8.encode(jsonString)));
    }

    static Future<BBS?> load(String name,{String? bbsmenuUrl}) async{
        final LocalFileIO fileIO = await LocalFileIO.getInstance();
        final String path = p.join("bbsmenu","$name.json");
        
        if(await fileIO.exists(path)){
            final jsonString = utf8.decode((await fileIO.readBytes(path))!);
            final list = _parseBBSMenuJson(jsonString);
            return list.isEmpty ? null : BBS(name,list);
        }else if(bbsmenuUrl != null){
            final response = await http.get(
                Uri.parse(bbsmenuUrl),
                headers: {"User-Agent":config.getUserAgent}
            );
            if(response.statusCode != 200){
                return null;
            }
            if(bbsmenuUrl.endsWith(".json")){
                final list = _parseBBSMenuJson(utf8.decode(response.bodyBytes));
                if(list.isEmpty){
                    return null;
                }else{
                    return BBS(name,list)..save();
                }
            }else{
                final html = await sjisToUtf8(response.bodyBytes);
                final list = _parseBBSMenuHtml(html);
                if(list.isEmpty){
                    return null;
                }else{
                    return BBS(name,list)..save();
                }
            }
        }else{
            return null;
        }
    }

    static List<BBSCategory> _parseBBSMenuJson(String jsonString){
        final List<BBSCategory> list = [];

        final json = jsonDecode(jsonString);
        
        if(json is! Map){
            return list;
        }else if(json["menu_list"] is! List){
            return list;
        }

        final List menuList = json["menu_list"];
        for(final category in menuList){
            if(category is! Map) continue;
            final name = category["category_name"];
            final contentList = category["category_content"];

            if(name is! String || contentList is! List) continue;

            final List<BoardInfo> boardInfoList = [];
            for(final content in contentList){
                if(content is! Map) continue;
                final url = content["url"];
                final name = content["board_name"];
                if(url is String && name is String){
                    boardInfoList.add(_urlToBoardInfo(name, url));
                }
            }
            if(boardInfoList.isNotEmpty){
                list.add(BBSCategory(name, boardInfoList));
            }
        }
        return list;
    }

    static List<BBSCategory> _parseBBSMenuHtml(String html){
        List<BBSCategory> list=[];

        final matches = 
            RegExp(r"<(br|BR)><(br|BR)><(b|B)>(.*?)</(b|B)>((<(br|BR)><(a|A).*?</(a|A)>)*)").allMatches(html.replaceAll("\n", ""));
        
        for(final match in matches){
            if(match.groupCount!=10){
                continue;
            }
            
            final String catName = match[4]!;
            final List<BoardInfo> boardInfoList = [];
            final List<String> linkList = match[6]!.split(RegExp(r"<(br|BR)>"));
            for(int li=1; li<linkList.length; ++li){
                final String link = linkList[li];
                final String? url = RegExp(r'(href|HREF)="(.*?)"').firstMatch(link)?[2];
                if(url==null){
                    continue;
                }
                final String name = link.substring(
                    link.indexOf(">")+1,
                    link.indexOf("<",link.indexOf(">"))
                );
                final boardInfo = _urlToBoardInfo(name, url);
                boardInfoList.add(boardInfo);
                // // debugPrint("$name : $url");
            }
            if(boardInfoList.isNotEmpty){
                list.add(BBSCategory(catName, boardInfoList));
            }
        }

        return list;
    }
}
BoardInfo _urlToBoardInfo(String name,String url){
    final String protocol = url.substring(0,url.indexOf("://"));
    final int serverEnd = url.indexOf("/",protocol.length+"://".length);
    final String server = url.substring(protocol.length+"://".length,serverEnd);
    final int pathEnd = url.indexOf("/",serverEnd+1);
    final String path = url.substring(serverEnd+1, pathEnd<0?url.length:pathEnd);
    return BoardInfo(protocol,server,path,name);
}

class BBSCategory{
    final String name;
    final List<BoardInfo> boardInfoList;

    BBSCategory(this.name,this.boardInfoList);

}
class BoardList{
    final List<BBS> list;

    BoardList(this.list);

}

class BoardListView extends StatelessWidget{
    const BoardListView({super.key});

    @override
    Widget build(BuildContext context){
        return FutureBuilder(
            future: _build(),
            builder: (context1, snapshot) {
                if(snapshot.hasData){
                    return snapshot.data!;
                }else if(snapshot.hasError){
                    return Text(snapshot.error!.toString());
                }else{
                    return const Text("loading...");
                }
            },
        );
    }
}

Future<Widget> _build()async{
    final List<BBS> list = [];

    final bbs5ch = await BBS.load("5ch", bbsmenuUrl: "https://menu.5ch.net/bbsmenu.json");
    final bbssannan = await BBS.load("sannan",bbsmenuUrl: "https://sannan.nl/bbsmenu2.html");
    final other = await BBS.load("other");

    if(bbs5ch != null){
        list.add(bbs5ch);
        debugPrint("BBS load 5ch ok");
    }
    if(bbssannan != null){
        list.add(bbssannan);
        debugPrint("BBS load sannan ok");
    }
    if(other != null){
        list.add(other);
        debugPrint("BBS load other ok");
    }
    return _BoardListViewContent(list);
}

class _BoardListViewContent extends StatefulWidget{
    final List<BBS> _bbsList;
    
    const _BoardListViewContent(this._bbsList);

    @override
    State<_BoardListViewContent> createState(){
        return _BoardListViewContentState();
    }
}

class _BoardListViewContentState extends State<_BoardListViewContent>{
    static final config = Config.getInstance();

    List<Widget> _selectBBS = [];
    List<Widget> _selectCategory = [];
    List<Widget> _selectBoard = [];

    @override
    void initState(){
        super.initState();

        _buildSelectBBS(widget._bbsList);
    }

    @override
    Widget build(BuildContext context){
        return SizedBox(
            width: 300,
            height: 500,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Expanded(
                        flex: 1,
                        child: Column(
                            children: [
                                Container(
                                    width: double.infinity,
                                    color: config.color.primary,
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                        "BBS",
                                        style: TextStyle(
                                            color: config.color.onPrimary
                                        ),
                                    ),
                                ),
                                const SizedBox(height: 10,),
                                Expanded(
                                    child: Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: config.color.foreground3,
                                                width: 1
                                            ),
                                            borderRadius: BorderRadius.circular(10)
                                        ),
                                        child:SingleChildScrollView(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: _selectBBS,
                                            )
                                        ),
                                    )
                                )
                            ]
                        )
                    ),
                    VerticalDivider(width: 5,color: config.color.background,),
                    Expanded(
                        flex: 1,
                        child: Column(
                            children: [
                                Container(
                                    width: double.infinity,
                                    color: config.color.primary,
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                        "Category",
                                        style: TextStyle(
                                            color: config.color.onPrimary
                                        ),
                                    ),
                                ),
                                const SizedBox(height: 10,),
                                Expanded(
                                    child: Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: config.color.foreground3,
                                                width: 1
                                            ),
                                            borderRadius: BorderRadius.circular(10)
                                        ),
                                        child: SingleChildScrollView(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: _selectCategory,
                                            )
                                        ),
                                    )
                                )
                            ]
                        )
                    ),
                    VerticalDivider(width: 5,color: config.color.background,),
                    Expanded(
                        flex: 1,
                        child: Column(
                            children: [
                                Container(
                                    width: double.infinity,
                                    color: config.color.primary,
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                        "Board",
                                        style: TextStyle(
                                            color: config.color.onPrimary
                                        ),
                                    ),
                                ),
                                const SizedBox(height: 10,),
                                Expanded(
                                    child: Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: config.color.foreground3,
                                                width: 1
                                            ),
                                            borderRadius: BorderRadius.circular(10)
                                        ),
                                        child: SingleChildScrollView(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: _selectBoard,
                                            )
                                        ),
                                    )
                                )
                            ]
                        )
                    )
                ],
            )
        );
    }

    void _buildSelectBBS(List<BBS> bbsList){
        List<Widget> newList = [];
        for(final bbs in bbsList){
            newList.add(InkWell(
                onTap: (){
                    _buildSelectCategory(bbs.menu);
                },
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        border: Border.symmetric(horizontal: BorderSide(width: 0.2))
                    ),
                    child: Text(bbs.name),
                ),
            ));
        }
        setState(() {
            _selectBBS = newList;
        });
    }

    void _buildSelectCategory(List<BBSCategory> categoryList){
        List<Widget> newList = [];
        for(final category in categoryList){
            newList.add(InkWell(
                onTap: (){
                    _buildSelectBoard(category.boardInfoList);
                },
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        border: Border.symmetric(horizontal: BorderSide(width: 0.2))
                    ),
                    child: Text(category.name),
                ),
            ));
        }
        setState(() {
            _selectCategory = newList;
        });
    }

    void _buildSelectBoard(List<BoardInfo> boardInfoList){
        List<Widget> newList = [];
        for(final info in boardInfoList){
            newList.add(InkWell(
                onTap: (){
                    BoardManager.getInstance().open(info);
                    // AppManager.getInstance().view?.openBoard(info);
                    Navigator.of(context).pop();

                },
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        border: Border.symmetric(horizontal: BorderSide(width: 0.2))
                    ),
                    child: Text(info.name),
                ),
            ));
        }
        setState(() {
            _selectBoard = newList;
        });
    }
}

