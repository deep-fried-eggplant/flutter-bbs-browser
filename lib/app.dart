import 'package:bbs_browser/configuration.dart';
import 'package:flutter/material.dart';
import 'bbs_thread_view.dart';
import 'bbs_board_view.dart';
import 'bbs_user_data.dart';

class MyApp extends StatelessWidget {

    const MyApp({super.key});

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: "${Config.appName} ver${Config.appVersion}",
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            home: const MyHomePage(),
        );
    }
}

class MyHomePage extends StatefulWidget {
    const MyHomePage({super.key});

    @override
    State<MyHomePage> createState(){
        return _MyHomePageState();
    }
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
    final _sideView = const BoardView();
    final _mainView = const ThreadView();

    static final config = Config.getInstance();
    static final userData = UserData.getInstance();

    @override
    void initState(){
        super.initState();
        WidgetsBinding.instance.addObserver(this);

        debugPrint("appInitState");

        
        userData.load();
    }

    @override
    void deactivate(){
        debugPrint("deactivate");

        super.deactivate();
    }

    @override
    void dispose(){
        debugPrint("appDispose");

        WidgetsBinding.instance.removeObserver(this);
        super.dispose();

        userData.save();

    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state){
        switch(state){
            case AppLifecycleState.resumed  :
            {
                debugPrint("App: Resumed");
            }break;
            case AppLifecycleState.inactive :
            {
                debugPrint("App: Inactive");
            }break;
            case AppLifecycleState.paused   :
            {
                debugPrint("App: Paused");
            }break;
            case AppLifecycleState.detached :
            {
                debugPrint("App: Detached");
            }break;
        }
    }

    @override
    Widget build(BuildContext context) {
        return Row(
            children: <Widget>[
                Expanded(
                    flex: 1,
                    child: _sideView,
                ),
                VerticalDivider(width: 1,color: config.color.foreground3,),
                Expanded(
                    flex: 3, 
                    child: _mainView,
                )
            ]
        );
    }
}
