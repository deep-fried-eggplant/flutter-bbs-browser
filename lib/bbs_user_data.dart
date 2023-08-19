import 'bbs_cookie.dart';

class UserData{
    static final UserData _instance = UserData._internal();

    UserData._internal();
    factory UserData.getInstance()=>_instance;

    final List<Cookie> cookies=[];
    
}