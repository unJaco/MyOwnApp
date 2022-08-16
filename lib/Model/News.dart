import 'package:cloud_firestore/cloud_firestore.dart';

class News {

  final String name;
  final String userName;
  final Timestamp timestamp;
  final String msg;
  String? referencingPostId;

  News(
      {required this.name, required this.userName, required this.timestamp, required this.msg, required this.referencingPostId});

  static News? fromSnap(DocumentSnapshot snapshot) {
    if (snapshot.data() == null) {
      return null;
    }
    var data = snapshot.data() as Map<String, dynamic>;

    return News(name: data['name'],
        userName: data['userName'],
        timestamp: data['timestamp'],
        msg: data['msg'],
        referencingPostId: data['post'] ?? 'null'

    );
  }

  @override
  bool operator == (Object other) {

    if(other is! News){
      return false;
    }
    bool same =
            referencingPostId == other.referencingPostId &&
            runtimeType == other.runtimeType &&
            name == other.name &&
            userName == other.userName &&
            msg == other.msg;

    if(!same){
      return false;
    }
    if(referencingPostId == null && other.referencingPostId == null) {
      return true;
    } else if(referencingPostId != null && other.referencingPostId == null){
      return false;
    } else if(referencingPostId == null && other.referencingPostId != null){
      return false;
    } else {
      return referencingPostId == other.referencingPostId;
    }
  }

  @override
  int get hashCode =>
      name.hashCode ^ userName.hashCode ^ msg.hashCode;
}




