import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {

  late String id;
  late String authorName;
  late String authorUserName;
  late Uint8List? profilePicture;
  late String text;
  late dynamic timestamp;

  late int likeVal;
  late List<dynamic> likedBy;
  late int commentsVal;
  late List<dynamic> comments;

  Post(
      {
      required this.authorName,
      required this.authorUserName,
      required this.text,
      required this.timestamp,
      required this.likeVal,
      required this.likedBy,
      required this.commentsVal,
      required this.comments});

  Map<String, dynamic> toJSON() => {
        'authorName': authorName,
        'authorUserName': authorUserName,
        'text': text,
        'timestamp': timestamp,
        'likeVal': likeVal,
        'likedBy': [],
        'commentsVal': commentsVal,
        'comments': []
      };

  static Post? fromSnap(DocumentSnapshot snapshot) {

    if(snapshot.data() == null){
      return null;
    }
    var data = snapshot.data() as Map<String, dynamic>;

    return Post(
        authorName: data['authorName'],
        authorUserName: data['authorUserName'],
        text: data['text'],
        timestamp: data['timestamp'],
        likeVal: data['likeVal'],
        likedBy: data['likedBy'],
        commentsVal: data['commentsVal'],
        comments: data['comments']);
  }

  void setId(String id){
    this.id = id;
  }

  void setProfilePicture(Uint8List? list){
    profilePicture = list;
  }

  @override
  String toString() {
    return 'Post{authorName: $authorName, authorUserName: $authorUserName, text: $text, timestamp: $timestamp, likeVal: $likeVal, likedBy: $likedBy, commentsVal: $commentsVal, comments: $comments}';
  }
}
