import 'package:flutter/material.dart';
import 'user_setting.dart';
import 'bbs_view.dart';

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
    final UserSetting userSetting = UserSetting()..load();

    final _sideView = const BoardView();
    final _mainView = const ThreadView();

    @override
    Widget build(BuildContext context) {
        return Row(
            children: <Widget>[
                Expanded(
                    flex: 1,
                    child: _sideView,
                ),
                const VerticalDivider(),
                Expanded(
                    flex: 3, 
                    child: _mainView,
                )
            ]
        );
    }
}
