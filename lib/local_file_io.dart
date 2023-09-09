import 'package:bbs_browser/configuration.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async';


class LocalFileIO{
    static final LocalFileIO _instance = LocalFileIO._internal();

    String? _root;
    String get root => _root??"";

    LocalFileIO._internal();
    static Future<LocalFileIO> getInstance()async{
        _instance._root ??= p.join(
            (await getApplicationDocumentsDirectory()).path,
            Config.appName
        );
        
        return _instance;
    }

    Future<bool> exists(String path) async{
        final File file = File(p.join(root,path));
        return file.exists();
    }

    Future<String?> read(String path)async{
        final File file = File(p.join(root,path));
        if(await file.exists()){
            return file.readAsString();
        }else{
            return null;
        }
    }
    Future<Uint8List?> readBytes(String path)async{
        final File file = File(p.join(root,path));
        if(await file.exists()){
            return file.readAsBytes();
        }else{
            return null;
        }
    }

    Future<String?> write(String path,String data)async{
        final File file = File(p.join(root,path));
        await file.parent.create(recursive: true);

        final result = await file.writeAsString(data,flush: true);
        if(await result.exists()){
            return result.absolute.path;
        }else{
            return null;
        }
    }
    Future<String?> writeBytes(String path,Uint8List data)async{
        final File file = File(p.join(root,path));
        await file.parent.create(recursive: true);
        
        final result = await file.writeAsBytes(data,flush: true);
        if(await result.exists()){
            return result.absolute.path;
        }else{
            return null;
        }
    }
}