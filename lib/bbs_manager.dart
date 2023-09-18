import 'package:flutter/foundation.dart';
import 'app_manager.dart';
import 'bbs_board.dart';
import 'bbs_thread.dart';

class BoardManager{
    static final AppManager appManager = AppManager.getInstance();

    static final _instance = BoardManager._internal();

    final List<Board> _activeList=[];
    List<Board> get activeList => _activeList;

    int _currentIndex=-1;
    int get currentIndex => _currentIndex;

    BoardManager._internal();
    factory BoardManager.getInstance() => _instance;

    void open(BoardInfo boardInfo){
        debugPrint("BoardManager open");
        final index = _activeList.indexWhere((element) => element.boardInfo.equals(boardInfo));
        if(index<0){
            final tmp = Board(boardInfo);
            _activeList.add(tmp);
            _currentIndex = _activeList.length-1;
        }else{
            _currentIndex = index;
        }
        appManager.view?.openBoard(_activeList.elementAt(_currentIndex));
    }
    void close(BoardInfo boardInfo){
        final index = _activeList.indexWhere((element) => element.boardInfo.equals(boardInfo));
        if(index>=0){
            appManager.view?.closeBoard(_activeList.elementAt(index));
            _activeList.removeAt(index);
        }
        if(_currentIndex >= _activeList.length){
            _currentIndex = _activeList.length-1;
        }
    }
    void setCurrent(int index){
        if(_activeList.isEmpty){
            return;
        }else{
            _currentIndex = index.clamp(0, _activeList.length-1);
        }
    }
}

class ThreadManager{
    static final AppManager appManager = AppManager.getInstance();

    static final _instance = ThreadManager._internal();
    
    final List<Thread> _activeList = [];
    List<Thread> get activeList => _activeList;

    int _currentIndex=-1;
    int get currentIndex => _currentIndex;

    ThreadManager._internal();
    factory ThreadManager.getInstance() => _instance;

    void open(ThreadInfo threadInfo){
        final index = _activeList.indexWhere((element) => element.threadInfo.equals(threadInfo));
        if(index<0){
            final tmp = Thread(threadInfo);
            _activeList.add(tmp);
            _currentIndex = _activeList.length-1;
        }else{
            _currentIndex = index;
        }
        appManager.view?.openThread(_activeList.elementAt(_currentIndex));
    }
    void close(ThreadInfo threadInfo){
        final index = _activeList.indexWhere((element) => element.threadInfo.equals(threadInfo));
        if(index>=0){
            appManager.view?.closeThread(_activeList.elementAt(index));
            _activeList.removeAt(index);
        }
        if(_currentIndex>=_activeList.length){
            _currentIndex=_activeList.length-1;
        }
    }
    void setCurrent(int index){
        if(_activeList.isEmpty){
            return;
        }else{
            _currentIndex = index.clamp(0, _activeList.length-1);
        }
    }
}