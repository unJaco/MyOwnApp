import 'dart:core';

import 'package:flutter/material.dart';

import '../Model/Post.dart';

class SelectionProvider with ChangeNotifier {

  List<Post> _selectedPosts = [];

  List<Post> _selectedComments = [];

  Map<Post, String> _selectedReplies = {};

  List<Post> get selectedPosts => _selectedPosts;
  List<Post> get selectedComments => _selectedComments;
  Map<Post, String> get selectedReplies => _selectedReplies;

  bool replyMode = false;

  String? _parentOfCommentId;

  String? get parentOfCommentId => _parentOfCommentId;

  String? _replyTo;
  String? _replyToId;

  String? get replyTo => _replyTo;
  String? get replyToId => _replyToId;

  void addPost(Post post) {
    _selectedPosts.add(post);
    notifyListeners();
  }

  void removePost(Post post) {
    _selectedPosts.remove(post);
    notifyListeners();
  }

  void addComment(Post post, String parentId) {
    _selectedComments.add(post);
    _parentOfCommentId = parentId;
    notifyListeners();
  }

  void removeComment(Post post) {
    _selectedComments.remove(post);
    notifyListeners();
  }

  void addReply(Post post, String parentId) {
    _selectedReplies[post] = parentId;
    notifyListeners();
  }

  void removeReply(Post post) {
    _selectedReplies.remove(post);
    notifyListeners();
  }

  void activateCommentMode(String replyTo, String replyToId){
    replyMode = true;
    _replyTo = replyTo;
    _replyToId = replyToId;

    notifyListeners();
  }

  void deactivateCommentMode(){
    replyMode = false;
    _replyTo = null;
    _replyToId = null;

    notifyListeners();
  }

  void clear() {
    _selectedPosts = [];
    _selectedComments = [];
    _selectedReplies = {};

    _parentOfCommentId = null;

    notifyListeners();
  }


}
