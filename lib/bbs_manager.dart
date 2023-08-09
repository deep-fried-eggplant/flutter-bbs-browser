import 'bbs.dart';

typedef BoardDrawerFunc = void Function();
typedef ThreadDrawerFunc = void Function();


class BoardManager{
    static final _instance = BoardManager._constructor();

    Board? _board = Board(BoardInfo("sannan.nl","livegalileo"));
    Board? get board => _board;

    BoardDrawerFunc _drawer = () {};

    BoardManager._constructor();
    factory BoardManager() => _instance;

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
    static final _instance = ThreadManager._constructor();

    Thread? _thread;
    Thread? get thread => _thread;

    ThreadDrawerFunc _drawer = () {};

    ThreadManager._constructor();
    factory ThreadManager() => _instance;

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