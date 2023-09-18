
class Post{
    final int index;
    final String name;
    final String mailTo;
    final String postAt;
    final String userId;
    final String message;

    final List<Post> anchorsTo = [];
    final List<Post> anchoredFrom = [];

    Post(this.index,this.name,this.mailTo,this.postAt,this.userId,this.message);
}

List<List<int>> findAnchors(String m){
    final result = <List<int>>[];
    int index = 0;
    while(true){
        index = m.indexOf(RegExp(r"(?<=>>)\d+"),index);
        if(index<0){
            break;
        }
        Match? match;
        if((match = RegExp(r"\d+\-\d+").matchAsPrefix(m,index)) != null){
            final pair = match![0]!.split("-");
            assert(pair.length==2);
            final begin = int.parse(pair[0]);
            final end = int.parse(pair[1])+1;
            final tmp = <int>[];
            for(int i=begin; i<end; ++i){
                tmp.add(i);
            }
            result.add(tmp);
        }else if((match = RegExp(r"\d+(,\d+)*").matchAsPrefix(m,index)) != null){
            final list = match![0]!.split(",");
            result.add(list.map((str)=>int.parse(str)).toList());
        }
        ++index;
    }
    return result;
}
