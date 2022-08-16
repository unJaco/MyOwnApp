import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Provider/AppBarMode.dart';
import 'package:my_own_app/Provider/SelectionProvider.dart';
import 'package:my_own_app/Widgets/AppBar.dart';
import 'package:my_own_app/Widgets/CommentTile.dart';
import 'package:my_own_app/Widgets/PostTile.dart';
import 'package:provider/provider.dart';

import '../../Model/AppUser.dart';
import '../../Model/Post.dart';
import '../../Provider/ProfilePictureProvider.dart';
import '../../Provider/UserProvider.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage(
      {Key? key,
      required this.post,
      required this.data,
      required this.uid,
      required this.ownId})
      : super(key: key);

  final Post post;
  final dynamic data;
  final String uid;
  final String ownId;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final firestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;

  final scrollController = ScrollController();

  late List<dynamic> commentIdList;
  late int commentsVal;

  late String ownId;

  Map<String, Uint8List?> profilePictures = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    setUp(context);
  }

  void setUp(BuildContext context) async {

    ownId = widget.ownId;
    commentIdList = widget.data['comments'];
    commentsVal = widget.data['commentsVal'];

    profilePictures = context.read<ProfilePictureProvider>().profilePictures;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchPosts() async {
    profilePictures = context.read<ProfilePictureProvider>().profilePictures;

    firestore.collection('Posts').doc(widget.post.id).get().then((doc) {
      var data = doc.data();
      if (data != null) {
        List newCommentIds = data['comments'];

        commentIdList = newCommentIds;
      }
    });
  }

  bool selected = false;
  bool showCommentsofComments = false;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? SafeArea(
            child: Scaffold(
                appBar: MyAppbar(
                    deletePosts: (List<Post> value) {
                      setState(() {});
                    },
                    uid: widget.uid,
                    displayedText: 'Kommentare',
                    appBarMode: AppBarMode.COMMENTS),
                body: Column(children: [
                  PostTile(
                    post: widget.post,
                    data: widget.data,
                    uid: widget.uid,
                    clickable: false,
                  ),
                  const Divider(height: 3),
                  const SizedBox(height: 30),
                  const Center(child: CircularProgressIndicator())
                ])))
        : SafeArea(
            child: Scaffold(
              appBar: MyAppbar(
                deletePosts: (List<Post> value) async {
                  setState(() {
                    isLoading = true;
                  });

                  setState(() {
                    if (value.contains(widget.post)) {
                    } else {
                      for (Post p in value) {
                        commentIdList.remove(p.id);
                      }
                      commentsVal -= value.length;
                    }
                    isLoading = false;
                  });
                },

                uid: widget.uid,
                displayedText: 'Kommentare',
                appBarMode: AppBarMode.COMMENTS,
              ),
              body: Column(
                children: [
                  PostTile(
                      post: widget.post,
                      data: widget.data,
                      uid: widget.uid,
                      clickable: false),
                  const Divider(height: 3),
                  Expanded(
                      child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: commentIdList.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(height: 2),
                          itemBuilder: (context, index) {
                            return Material(
                                      child: CommentTile(
                                    postId: commentIdList[index],
                                    uid: widget.uid,
                                    parentId: widget.post.id,
                                    userOwnParent: widget.post.authorUserName == context.read<UserProvider>().user.username
                                  ));
                          })),
                  const Divider(thickness: 1, height: 1),
                  MessageFormField(
                      postId: widget.post.id,
                      onPostSend: (bool value) async {
                        await fetchPosts();
                        setState(() {});
                      })
                ],
              ),
            ),
          );
  }

  Widget HideComments() => GestureDetector(
        onTap: () {
          setState(() {
            showCommentsofComments = false;
          });
        },
        child: ListTile(
          dense: true,
          title: Row(
            children: [
              const SizedBox(width: 47),
              const Expanded(child: Divider()),
              Container(width: 5),
              const Text("Antworten ausblenden",
                  style: TextStyle(color: Colors.blue, fontSize: 14)),
              Container(width: 5),
              const Expanded(child: Divider()),
            ],
          ),
        ),
      );
}

class MessageFormField extends StatefulWidget {
  const MessageFormField(
      {Key? key, required this.postId, required this.onPostSend})
      : super(key: key);

  final String postId;

  final ValueChanged<bool> onPostSend;

  @override
  _MessageFormFieldState createState() => _MessageFormFieldState();
}

class _MessageFormFieldState extends State<MessageFormField> {
  final firestore = FirebaseFirestore.instance;

  final messagesController = TextEditingController();

  static bool replyMode = false;
  static String? replyTo;
  static String? replyToId;

  @override
  void initState() {
    super.initState();

    messagesController.addListener(() {
      setState(() {});
    });
  }

  Future insertPost(Post postToInsert, String commentOfId) async {
    await firestore
        .collection('Posts')
        .add(postToInsert.toJSON())
        .then((insertedPost) {
      firestore.collection('Posts').doc(commentOfId).update({
        'commentsVal': FieldValue.increment(1),
        'comments': FieldValue.arrayUnion([insertedPost.id])
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    replyMode = context.watch<SelectionProvider>().replyMode;
    replyTo = context.watch<SelectionProvider>().replyTo;
    replyToId = context.watch<SelectionProvider>().replyToId;

    return Column(children: [
      replyMode && replyTo != null
          ? Container(
              color: Colors.black12,
              child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Antworte auf $replyTo',
                            style: (const TextStyle(
                                color: Colors.grey, fontSize: 15))),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              context
                                  .read<SelectionProvider>()
                                  .deactivateCommentMode();
                            })
                      ])))
          : const SizedBox(),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(children: [
            Expanded(
                child: Column(children: [
              SingleChildScrollView(
                  child: TextFormField(
                      minLines: 1,
                      maxLines: 3,
                      controller: messagesController,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: "Kommentieren...",
                          suffixIcon: messagesController.text.isEmpty
                              ? Container(width: 0)
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    messagesController.clear();
                                  },
                                ))))
            ])),
            Container(width: 12),
            Container(
                child: messagesController.text.isEmpty
                    ? const Icon(Icons.send, color: Colors.grey)
                    : IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.send, color: Colors.blue),
                        splashRadius: 20,
                        onPressed: () async {
                          AppUser user = context.read<UserProvider>().user;
                          Post postToInsert = Post(
                              authorName: user.name,
                              authorUserName: user.username,
                              text: messagesController.text,
                              timestamp: FieldValue.serverTimestamp(),
                              likeVal: 0,
                              likedBy: [],
                              commentsVal: 0,
                              comments: [],);

                          messagesController.clear();

                          replyMode
                              ? await insertPost(postToInsert, replyToId!)
                              : await insertPost(postToInsert, widget.postId);
                          widget.onPostSend(true);
                          context.read<SelectionProvider>().deactivateCommentMode();
                        }))
          ]))
    ]);
  }
}
