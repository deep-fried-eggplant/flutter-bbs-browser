import 'package:flutter/foundation.dart';

class Cookie{
    final String _host;
    String get host => _host;
    
    final Map<String,_CookieValue> _values={};
    bool get isEmpty => _values.isEmpty;
    bool get isNotEmpty => _values.isNotEmpty;

    Cookie(this._host);

    bool set(String setCookieStr){
        debugPrint("set-cookie -> $setCookieStr");
        final split = setCookieStr.split(";");
        if(split.isEmpty){
            return false;
        }
        String name,value;
        DateTime? expires;
        String? path;
        {
            final nameAndValue = split[0].split("=");
            debugPrint(nameAndValue.toString());
            if(nameAndValue.length!=2){
                return false;
            }else{
                name=nameAndValue[0].trim();
                value=nameAndValue[1].trim();
                if(value.startsWith('"') && value.endsWith('"')){
                    value = value.substring(1,value.length-1);
                }
            }
        }
        for(int i=1; i<split.length; ++i){
            final item = split[i].trim();
            if(item.startsWith(RegExp(r"(M|m)ax-(A|a)ge="))){
                const start="max-age=".length;
                expires=_maxAgeToExpire(item.substring(start));
            }
            if(item.startsWith(RegExp(r"(E|e)xpires="))){
                const start="expires=".length;
                expires=_parseDateTime(item.substring(start));
            }
        }
        _values[name]=_CookieValue(value: value,expires: expires,path: path);
        return true;
    }
    Map<String,String> get(){
        Map<String,String> cookie={};
        for(var key in _values.keys){
            final value=_values[key]!;
            if(value.expires==null){
                cookie[key]=value.value;
            }else if(value.expires!.difference(DateTime.now().toUtc()).isNegative == false){
                cookie[key]=value.value;
            }
        }
        return cookie;
    }
}

class _CookieValue{
    final String value;
    DateTime? expires;
    String? path;

    _CookieValue({required this.value,this.expires,this.path});
}

DateTime? _parseDateTime(String dateTimeString){
    try{
        final split=dateTimeString.split(" ");

        // final dayOfWeek =split[0];
        final day   =int.parse(split[1]);
        final month =int.parse(split[2]);
        final year  =int.parse(split[3]);
        final time  =split[4].split(":");
        final hour  =int.parse(time[0]);
        final minute=int.parse(time[1]);
        final second=int.parse(time[2]);
        // final zone  =split[5];

        return DateTime.utc(
            year,month,day,hour,minute,second
        );
    }on FormatException catch(e){
        debugPrint(e.message);
        return null;
    }on IndexError catch(e){
        debugPrint(e.message);
        return null;
    }
}

DateTime? _maxAgeToExpire(String maxAgeStr){
    try{
        final maxAge=int.parse(maxAgeStr);
        return DateTime.now().add(Duration(seconds: maxAge)).toUtc();
    }on FormatException catch(e){
        debugPrint(e.message);
        return null;
    }
}

List<String> splitMultiSetCookie(String setCookieStr){
    RegExp regExp = RegExp(r",(?=[^ ;]*=)");
    return setCookieStr.split(regExp);
}