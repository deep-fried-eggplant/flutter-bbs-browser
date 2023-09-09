import 'package:flutter/material.dart';
import 'bbs_board.dart';
import 'bbs_thread.dart';
import 'bbs_user_data.dart';
import 'configuration.dart';
import 'app_view.dart';

class MyApp extends StatelessWidget {

    const MyApp({super.key});

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: "${Config.appName} ver${Config.appVersion}",
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            home: const AppContent()
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
        // debugPrint(MediaQuery.of(context).size.width.toString());
        // return const DualView(BoardView(null),ThreadView(null));
        return 
            MediaQuery.of(context).size.width > 600 ?
                const DualView()
            : //else
                const SingleView(BoardView(null));
    }
}

class AppContent extends StatefulWidget{
    
    const AppContent({super.key});


    @override
    State<AppContent> createState(){
        return _AppContentState();
    }
}
class _AppContentState extends State<AppContent>{
    static final UserData       userData        = UserData.getInstance();

    // Board? board;
    // Thread? thread;
    // bool isDualView = false;
    bool get isMobile => MediaQuery.of(context).size.width < 600;

    @override
    void initState(){
        super.initState();

        userData.load();
    }

    @override
    Widget build(BuildContext context) {
        // final Board? board = boardManager.currentBoard;
        // final Thread? thread = threadManager.currentThread;

        return 
            const DualView();
            // MediaQuery.of(context).size.width > 600 ?
            //     DualView(BoardView(board), ThreadView(thread))
            // : //else
            //     SingleView(thread!=null?ThreadView(thread):BoardView(board));
    }

}