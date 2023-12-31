// import 'package:flutter/material.dart';
import 'app_view.dart';

typedef AppContentDrawerFunc = void Function();

class AppManager{
    static final AppManager _instance = AppManager._internal();

    AppManager._internal();
    factory AppManager.getInstance() => _instance;

    AppView? _view;
    AppView? get view => _view;

    void set(AppView appView){
        _view = appView;
    }
    void unset(){
        _view = null;
    }
}

