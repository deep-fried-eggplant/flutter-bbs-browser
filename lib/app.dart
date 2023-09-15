import 'package:flutter/material.dart';
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

class AppContent extends StatefulWidget{
    
    const AppContent({super.key});


    @override
    State<AppContent> createState(){
        return _AppContentState();
    }
}
class _AppContentState extends State<AppContent>{
    static final UserData userData = UserData.getInstance();

    bool get isMobile => MediaQuery.of(context).size.width < 600;

    @override
    void initState(){
        super.initState();

        userData.load();
    }

    @override
    Widget build(BuildContext context) {
        return 
            // const DualView();
            // const SingleView();
            MediaQuery.of(context).size.width > 600 ?
                DualView(key: widget.key,)
            : //else
                SingleView(key: widget.key,);
    }

}