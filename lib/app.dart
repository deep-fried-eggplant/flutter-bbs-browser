import 'package:bbs_browser/configuration.dart';
import 'package:flutter/material.dart';
import 'bbs_thread_view.dart';
import 'bbs_board_view.dart';

class MyApp extends StatelessWidget {

    const MyApp({super.key});

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Test App',
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            home: const MyHomePage(title: 'Flutter Test App'),
        );
    }
}

class MyHomePage extends StatefulWidget {
    const MyHomePage({super.key, required this.title});

    final String title;

    @override
    State<MyHomePage> createState(){
        return _MyHomePageState();
    }
}

class _MyHomePageState extends State<MyHomePage> {
    final _sideView = const BoardView();
    final _mainView = const ThreadView();

    static final config = Config.getInstance();

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
