import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

class UserSetting{
    static final UserSetting _instance=UserSetting._internal();

    static const String jsonFilePath="user_setting.json";

    static final List<_UserSettingItem> _list=[];
    
    static ValueWrapper<T> addItem<T>(String name,T defaultValue){
        _list.add(_UserSettingItem(T, name, defaultValue)..initialize<T>());
        return _list.last.value as ValueWrapper<T>;
    }

    final darkMode  = addItem<bool>("darkMode",false);
    final comment   = addItem<String>("comment","default comment");


    UserSetting._internal();
    factory UserSetting(){
        return _instance;
    }

    void setDefault(){
        for(var item in _list){
            item.value.set(item.defaultValue);
        }
    }

    Future<void> load() async{
        var jsonFile = File(jsonFilePath);
        if(await jsonFile.exists() == false){
            setDefault();
            await save();
            return;
        }
        var json = jsonDecode(await jsonFile.readAsString()) as Map<String,dynamic>;
        debugPrint("json = $json");

        for(var item in _list){
            if(json.containsKey(item.name)){
                if(json[item.name].runtimeType==item.type){
                    item.value.set(json[item.name]);
                }
            }
        }

    }
    Future<void> save() async{
        var json = <String,dynamic>{};
        var file = File(jsonFilePath);

        for(var item in _list){
            json[item.name]=item.value.get();
        }

        await file.writeAsString(jsonEncode(json));
        debugPrint("user-setting file has been saved at '${file.absolute}'");
    }

}

class _UserSettingItem{
    final Type type;
    final String name;
    final dynamic defaultValue;
    late ValueWrapper<dynamic> value;

    _UserSettingItem(this.type,this.name,this.defaultValue){
        assert(defaultValue.runtimeType==type);
    }

    void initialize<T>(){
        assert(T==type);
        value=ValueWrapper<T>(defaultValue);
    }
}

class ValueWrapper<T>{
    T _value;

    ValueWrapper(this._value);

    T get() => _value;
    void set(T value) => _value=value;
}