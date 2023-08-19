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
        String? domain;
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
            if(item.startsWith(RegExp(r"(E|e)xpires="))){
                const start="expires=".length;
                expires=_parseDateTime(item.substring(start));
            }
            if(item.startsWith(RegExp(r"(M|m)ax-(A|a)ge="))){
                const start="max-age=".length;
                expires=_maxAgeToExpire(item.substring(start));
            }
            if(item.startsWith(RegExp(r"(D|d)omain="))){
                const start="domain".length;
                domain=item.substring(start).trim();
            }
            if(item.startsWith(RegExp(r"(P|p)ath="))){
                const start="path=".length;
                path=item.substring(start).trim();
            }
        }
        _values[name]=_CookieValue(
            value   : value,
            expires : expires,
            domain  : domain,
            path    : path,
        );
        return true;
    }
    Map<String,String> get(String uri){
        final now =DateTime.now().toUtc();
        Map<String,String> cookie={};
        for(var key in _values.keys){
            final value=_values[key]!;
            if(value.expires==null){
                cookie[key]=value.value;
            }else if(value.expires!.difference(now).isNegative == false){
                cookie[key]=value.value;
            }
        }
        return cookie;
    }

    @override
    String toString(){
        final StringBuffer buffer=StringBuffer("[ ");
        for(final key in _values.keys){
            final value=_values[key]!;
            buffer.write("$key=$value");
            if(value.expires==null && value.domain==null && value.path==null){
                buffer.write(", ");
                continue;
            }
            buffer.write("( ");
            if(value.expires!=null){
                buffer.write("Exp:${value.expires!.toIso8601String() }");
            }
            if(value.domain!=null){
                buffer.write("Domain:${value.domain!} ");
            }
            if(value.path!=null){
                buffer.write("Path:${value.path!} ");
            }
            buffer.write("), ");
        }
        return buffer.toString();
    }
}

class _CookieValue{
    final String value;
    DateTime? expires;
    String? domain;
    String? path;

    _CookieValue({required this.value,this.expires,this.domain,this.path});
}

DateTime? _parseDateTime(String dateTimeString){
    const months=["dummy","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    try{
        final split=dateTimeString.split(" ");

        if(split.length==6){
            // final dayOfWeek = split[0];
            final day   =int.parse(split[1]);
            final month =months.indexOf(split[2]);
            final year  =int.parse(split[3]);
            final time  =split[4].split(":");
            final hour  =int.parse(time[0]);
            final minute=int.parse(time[1]);
            final second=int.parse(time[2]);
            // final zone  =split[5];

            return DateTime.utc(year,month,day,hour,minute,second);
        }else if(split.length==4){
            // final dayOfWeek =split[0];
            final date  =split[1].split("-");
            final day   =int.parse(date[0]);
            final month =months.indexOf(date[1]);
            final year  =int.parse(date[2]);
            final time  =split[2].split(":");
            final hour  =int.parse(time[0]);
            final minute=int.parse(time[1]);
            final second=int.parse(time[2]);
            // final zone  =split[5];

            return DateTime.utc(year,month,day,hour,minute,second);
        }else{
            throw FormatException(
                "failed to parse Set-Cookie 'Expires' attributes : $dateTimeString"
            );
        }
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