import 'package:path/path.dart';
import 'local_file_io.dart';
import 'bbs_cookie.dart';

class UserData{
    static final UserData _instance = UserData._internal();

    UserData._internal();
    factory UserData.getInstance()=>_instance;

    final Map<String,Cookie> _cookies={};
    
    Cookie cookie(String host){
        if(_cookies.containsKey(host) == false){
            _cookies[host] = Cookie(host);
        }
        return _cookies[host]!;
    }

    Future<void> load()async{
        final LocalFileIO fileIO = await LocalFileIO.getInstance();
        await _loadCookie(fileIO);
    }

    Future<void> save()async{
        final LocalFileIO fileIO = await LocalFileIO.getInstance();

        await _saveCookie(fileIO);
    }

    Future<void> _saveCookie(LocalFileIO fileIO)async{
        final String cookieFilePath = join("user-data","cookie.txt");
        final StringBuffer buffer = StringBuffer();
        for(final key in _cookies.keys){
            buffer.writeln(key);
            for(final cookie in _cookies[key]!.toStringList()){
                buffer.writeln(cookie);
            }
            buffer.write("\n\n");
        }
        await fileIO.write(cookieFilePath, buffer.toString());
    }
    
    Future<void> _loadCookie(LocalFileIO fileIO) async{
        final String cookieFilePath = join("user-data","cookie.txt");

        _cookies.clear();

        final String? data = await fileIO.read(cookieFilePath);
        if(data==null){
            return;
        }
        
        for(final block in data.split("\n\n")){
            final lines = block.split("\n");
            if(lines.isEmpty){
                continue;
            }
            final host = lines[0];
            _cookies[host] = Cookie(host);
            for(int i=1; i<lines.length; ++i){
                _cookies[host]!.set(lines[i]);
            }
        }
    }
}

