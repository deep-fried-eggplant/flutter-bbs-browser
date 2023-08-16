import 'package:shared_preferences/shared_preferences.dart';

final userSettingMap = <String,dynamic>{

};

class UserSetting{

    static final UserSetting _instance=UserSetting._internal();

    UserSetting._internal();
    factory UserSetting.getInstance() => _instance;

    Future<void> load() async{
        final pref = await SharedPreferences.getInstance();
        
        void loadImpl(String parentKey,Map<String,dynamic> map){
            for(var key in map.keys){
                var curKey = parentKey.isEmpty ? key : "$parentKey.$key";
                if(map[key] is Map){
                    loadImpl(curKey, map[key]);
                }else if(pref.containsKey(curKey)){
                    map[key] = pref.get(curKey)!;
                }
            }
        }

        loadImpl("",userSettingMap);
    }
    Future<void> save() async{
        final pref = await SharedPreferences.getInstance();

        void saveImpl(String parentKey,Map<String,dynamic> map){
            for(var key in map.keys){
                var curKey = parentKey.isEmpty ? key : "$parentKey.$key";
                if(map[key] is Map){
                    saveImpl(curKey, map[key]);
                }else{
                    switch(map[key].runtimeType){
                        case int:
                        pref.setInt(curKey, map[key] as int);
                        break;

                        case double:
                        pref.setDouble(curKey, map[key] as double);
                        break;

                        case String:
                        pref.setString(curKey, map[key] as String);
                        break;

                        default:
                        break;
                    }
                }
            }
        }

        saveImpl("", userSettingMap);
    }

}

// class _UserSettingItem{
//     final Type type;
//     final String name;
//     final dynamic defaultValue;
//     late ValueWrapper<dynamic> value;

//     _UserSettingItem(this.type,this.name,this.defaultValue){
//         assert(defaultValue.runtimeType==type);
//     }

//     void initialize<T>(){
//         assert(T==type);
//         value=ValueWrapper<T>(defaultValue);
//     }
// }

// class ValueWrapper<T>{
//     T _value;

//     ValueWrapper(this._value);

//     T get() => _value;
//     void set(T value) => _value=value;
// }