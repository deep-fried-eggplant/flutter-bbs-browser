
import 'package:flutter/material.dart';

enum AppViewContent{
    boardSelector,
    board,
    thread,
    setting
}

class AppViewManager{
    static final AppViewManager _instance = AppViewManager._internal();

    AppViewManager._internal();
    factory AppViewManager.getInstance() => _instance;

}

class AppView{
    Widget content;

    AppView(this.content);
}

class SingleView extends StatelessWidget{
    final AppView view;

    const SingleView(this.view,{super.key});

    @override
    Widget build(BuildContext context){
        return Container(
            child: view.content,
        );
    }
}
class DualView extends StatelessWidget{
    final AppView mainView;
    final AppView sideView;

    const DualView(this.mainView,this.sideView,{super.key});

    @override
    Widget build(BuildContext context){
        return Row(
            children: [
                Expanded(
                    flex: 1,
                    child: sideView.content,
                ),
                const VerticalDivider(width: 0.5,),
                Expanded(
                    flex: 3,
                    child: mainView.content,
                )
            ],
        );
    }
}