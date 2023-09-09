import 'app_manager.dart';
import 'bbs_board.dart';
import 'bbs_thread.dart';


typedef BoardDrawerFunc = void Function();
typedef ThreadDrawerFunc = void Function();


class BoardManager{
    static final AppManager appManager = AppManager.getInstance();

    static final _instance = BoardManager._internal();

    final Set<Board> _activeList={};

    BoardManager._internal();
    factory BoardManager.getInstance() => _instance;

    void open(BoardInfo boardInfo){
        var iter = _activeList.where((element) => element.boardInfo == boardInfo);
        if(iter.isEmpty){
            var current = Board(boardInfo);
            _activeList.add(current);
            appManager.view?.openBoard(current);
        }else{
            appManager.view?.openBoard(iter.single);
        }
    }
    void close(BoardInfo boardInfo){
        var iter = _activeList.where((element) => element.boardInfo == boardInfo);
        if(iter.isNotEmpty){
            appManager.view?.closeBoard(iter.single);
            _activeList.remove(iter.single);
        }
    }
}

class ThreadManager{
    static final AppManager appManager = AppManager.getInstance();

    static final _instance = ThreadManager._internal();
    
    final Set<Thread> _activeList = {};

    ThreadManager._internal();
    factory ThreadManager.getInstance() => _instance;

    void open(ThreadInfo threadInfo){
        var iter = _activeList.where((element) => element.threadInfo.equals(threadInfo));
        
        if(iter.isEmpty){
            var current = Thread(threadInfo);
            _activeList.add(current);
            appManager.view?.openThread(current);
        }else{
            appManager.view?.openThread(iter.single);
        }
    }
    Future<bool> update(ThreadInfo threadInfo) async{
        var iter = _activeList.where((element) => element.threadInfo.equals(threadInfo));
        if(iter.isNotEmpty){
            return iter.single.update();
        }else{
            return false;
        }
    }
    void close(ThreadInfo threadInfo){
        var iter = _activeList.where((element) => element.threadInfo.equals(threadInfo));
        if(iter.isNotEmpty){
            appManager.view?.closeThread(iter.single);
            _activeList.remove(iter.single);
        }
    }
}