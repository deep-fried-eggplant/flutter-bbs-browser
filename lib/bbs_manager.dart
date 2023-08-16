import 'bbs_basedata.dart';


typedef BoardDrawerFunc = void Function();
typedef ThreadDrawerFunc = void Function();


class BoardManager{
    static final _instance = BoardManager._internal();

    // Board? _board = Board(BoardInfo("sannan.nl","exp1"));
    Board? _board = Board(BoardInfo("sannan.nl","unsaku"));
    Board? get board => _board;

    BoardDrawerFunc _drawer = () {};

    BoardManager._internal();
    factory BoardManager.getInstance() => _instance;

    void open(BoardInfo boardInfo){
        _board = Board(boardInfo);
        _drawer();
    }
    void close(){
        _board = null;
    }
    void setDrawer(BoardDrawerFunc func){
        _drawer = func;
    }
    void unsetDrawer(){
        _drawer = () {};
    }
}

class ThreadManager{
    static final _instance = ThreadManager._internal();

    Thread? _thread;
    Thread? get thread => _thread;

    ThreadDrawerFunc _drawer = () {};

    ThreadManager._internal();
    factory ThreadManager.getInstance() => _instance;

    void open(ThreadInfo threadInfo){
        _thread = Thread(threadInfo);
        _drawer();
    }
    void close(){
        _thread = null;
        _drawer();
    }
    void setDrawer(ThreadDrawerFunc func){
        _drawer = func;
    }
    void unsetDrawer(){
        _drawer = () {};
    }
}