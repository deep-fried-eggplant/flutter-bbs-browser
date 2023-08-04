import 'package:flutter/material.dart';
import 'user_setting.dart';
import 'bbs.dart';

class MyApp extends StatelessWidget {

    const MyApp({super.key});

    // static final themeDataLight = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey));
    // static final themeDataDart  = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white));

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

    int _counter = 0;

    void _incrementCounter() {
        setState(() {
            _counter++;
        });
    }
    void _reset(){
        setState(() {
            _counter=0;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).primaryColor,
                title: TextButton(
                    onPressed: (){
                        debugPrint("title has pressed");
                    },
                    child: const Text("App demo page"),
                ),
                actions: [
                    TextButton(
                        onPressed: _reset,
                        child: const Text("Reset"),
                    )
                ],
            ),
            body: Center(
                child: Row(
                    children: <Widget>[
                        Expanded(
                            flex: 1,
                            child: SizedBox(
                                width: 40,
                                child: FutureBuilder<List<Widget>>(
                                    future: threadList(),
                                    builder: (context, snapshot){
                                        if(snapshot.hasData){
                                            return SingleChildScrollView(
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: snapshot.data!,
                                                ),
                                            );
                                        }else if(snapshot.hasError){
                                            return const Text("failed");
                                        }else{
                                            return const Text("loading...");
                                        }
                                    },
                                )
                            )
                        ),
                        const VerticalDivider(),
                        Expanded(
                            flex: 3, 
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                    const Text(
                                        'You have pushed the button this many times:',
                                    ),
                                    Text(
                                        '$_counter',
                                        style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    Text(
                                        "comment = ${userSetting.comment.get()}"
                                    ),
                                ],
                            ),
                        )
                    ]
                )
                
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: _incrementCounter,
                tooltip: 'Increment',
                child: const Icon(Icons.add),
            ),
            bottomNavigationBar: BottomAppBar(
                child: Row(
                    children: <Widget>[
                        const Text(
                            "This is Bottom Bar",
                            // style: TextStyle(color: Colors.white),
                        ),
                        const Expanded(
                            child: SizedBox(),
                        ),
                        IconButton(
                            icon: const Icon(
                                Icons.favorite,
                            ),
                            onPressed: () {
                                debugPrint("fav!");
                            },
                        ),
                    ],
                ),
            ), // This trailing comma makes auto-formatting nicer for build methods.
        );
    }
}

Future<List<Widget>> threadList() async{
    final board=Board(BoardInfo("sannan.nl","livegalileo"));
    debugPrint("start getting");
    if(await board.update()){
        List<Widget> res=[];
        for(var item in board.threadInfoList){
            res.add(
                Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(0),
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide())),
                    child: Text(item.title),
                ),
            );
        }
        debugPrint("succeed getting");
        return res;
    }else{
        debugPrint("failed getting");
       return []; 
    }

}