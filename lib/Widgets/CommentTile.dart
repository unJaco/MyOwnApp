import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_own_app/Widgets/ReplyTile.dart';
import 'package:provider/provider.dart';

import '../Model/Post.dart';
import '../Provider/ProfilePictureProvider.dart';
import '../Provider/SelectionProvider.dart';
import '../Provider/UserProvider.dart';

class CommentTile extends StatefulWidget {
  const CommentTile(
      {Key? key,
      required this.postId,
      required this.uid,
      required this.parentId,
      required this.userOwnParent})
      : super(key: key);

  final String postId;
  final String uid;
  final String parentId;
  final bool userOwnParent;

  @override
  _CommentTileState createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  final firestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;

  bool isLoading = true;

  Post? nullablePost;
  late String uid;

  static bool selectionMode = false;
  bool isSelected = false;

  late bool likedByUser;

  bool hasReplies = false;
  bool showCommentsOfComments = false;

  Map<String, Uint8List?> profilePictures = {};

  late String timeStampToDisplay;
  final DateFormat format = DateFormat('dd-MM-yyyy');

  List replyList = [];

  @override
  void initState() {
    super.initState();

    setUp(context);
  }

  void setUp(BuildContext context) async {
    profilePictures = context.read<ProfilePictureProvider>().profilePictures;

    await firestore
        .collection('Posts')
        .doc(widget.postId)
        .get()
        .then((doc) async {
      Post? p = Post.fromSnap(doc);
      if (p != null) {
        p.setId(doc.id);
        if (profilePictures.keys.contains(p.authorUserName)) {
          p.setProfilePicture(profilePictures[p.authorUserName]);
        } else {
          var list = await firebaseStorage
              .ref('files/${p.authorUserName}')
              .getData()
              .onError((error, stackTrace) => null);
          context
              .read<ProfilePictureProvider>()
              .addProfilePicture(p.authorUserName, list);
          p.setProfilePicture(list);
        }
        nullablePost = p;
      }
    });

    setState(() {
      isLoading = false;
    });
  }

  void deleteNonExistingPost() async {

    firestore.collection('Posts').doc(widget.parentId).update({'commentVal' : FieldValue.increment(-1), 'comments' : FieldValue.arrayRemove([widget.postId])});
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container();
    }
    if(nullablePost == null) {

      deleteNonExistingPost();
      return Container();
    }

    Post post = nullablePost!;
    uid = widget.uid;

    Timestamp timeStamp = post.timestamp;

    int differenceMin = DateTime.now().difference(timeStamp.toDate()).inMinutes;
    int differenceHours = DateTime.now().difference(timeStamp.toDate()).inHours;
    int differenceDays = DateTime.now().difference(timeStamp.toDate()).inDays;

    if (differenceMin == 0) {
      timeStampToDisplay = '<1 min';
    } else if (differenceMin < 60) {
      timeStampToDisplay = '$differenceMin min';
    } else if (differenceHours < 24) {
      timeStampToDisplay = '$differenceHours h';
    } else if (differenceDays < 31) {
      timeStampToDisplay = '$differenceDays d';
    } else {
      final DateTime date = timeStamp.toDate();
      final String formatted = format.format(date);

      timeStampToDisplay = formatted;
    }

    isSelected =
        context.watch<SelectionProvider>().selectedComments.contains(post);
    selectionMode = context.watch<SelectionProvider>().selectedComments.isNotEmpty || context.watch<SelectionProvider>().selectedReplies.isNotEmpty;

    likedByUser = post.likedBy.contains(widget.uid);

    var commentStream = firestore.collection('Posts').doc(post.id).snapshots();

    return ListTile(
        tileColor: !isSelected
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.grey[300],
        onLongPress: () {

          print(context.read<SelectionProvider>().selectedComments);
          if (post.authorUserName ==
                  context.read<UserProvider>().user.username ||
              widget.userOwnParent) {
            context.read<SelectionProvider>().addComment(post, widget.parentId);
          }
        },

        onTap: () {
          if (selectionMode) {
            if (post.authorUserName ==
                    context.read<UserProvider>().user.username ||
                widget.userOwnParent) {
              isSelected == false
                  ? context.read<SelectionProvider>().addComment(post, widget.parentId)
                  : context.read<SelectionProvider>().removeComment(post);
            }
          } else {
            showCommentsOfComments = true;
          }
        },
        title: Column(
          children: [
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(post.authorName,
                    style: (const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16))),
                Text(timeStampToDisplay,
                    style: (const TextStyle(color: Colors.grey, fontSize: 16))),
              ],
            ),
            Row(
              children: [
                Text('@${post.authorUserName}',
                    style: (const TextStyle(color: Colors.grey, fontSize: 15))),
              ],
            ),
          ],
        ),
        subtitle: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                  child: Text(post.text,
                      style:
                          (const TextStyle(color: Colors.black, fontSize: 15))))
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            GestureDetector(
              child: const Text('Kommentieren',
                  style: TextStyle(color: Colors.blue)),
              onTap: () {
                selectionMode
                    ? context.read<SelectionProvider>().addComment(post, widget.parentId)
                    : context
                        .read<SelectionProvider>()
                        .activateCommentMode(post.authorUserName, post.id);
              },
            ),
            Expanded(child: Container()),
            StreamBuilder(
                stream: commentStream,
                builder: (ctx, snapshot) {

                  print('stream');
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('0',
                        style: (TextStyle(color: Colors.blue)));
                  }
                  dynamic data = snapshot.data!;

                  List replies = [];
                  int commVal = 0;
                  try{
                    replies = data['comments'];
                    commVal = data['commentsVal'];
                  } catch(e){
                    print(e);
                  }
                  hasReplies = replies.isNotEmpty;

                  return Row(children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.mode_comment_outlined, size: 22),
                      color: Colors.blue,
                      onPressed: () {
                        print(replies);
                        setState(() {
                          replyList = replies;
                        });
                        hasReplies && !selectionMode
                            ? setState(() {
                                showCommentsOfComments =
                                    !showCommentsOfComments;
                              })
                            : null;
                      },
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 10),
                    Text('$commVal',
                        style: (const TextStyle(color: Colors.blue))),
                  ]);
                }),
            const SizedBox(width: 20),
            StreamBuilder(
                stream: commentStream,
                builder: (ctx, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('0',
                        style: (TextStyle(color: Colors.red)));
                  }

                  dynamic data = snapshot.data!;
                  int likeval = 0;
                  try {
                    likeval = data['likeVal'];
                  } catch (e){
                    return Container();
                  }
                  return Row(children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                          likedByUser ? Icons.favorite : Icons.favorite_border),
                      color: Colors.red,
                      onPressed: () {
                        if (likedByUser) {
                          firestore.collection('Posts').doc(post.id).update({
                            'likeVal': FieldValue.increment(-1),
                            'likedBy': FieldValue.arrayRemove([uid])
                          });
                          post.likedBy.remove(uid);
                        } else {
                          firestore.collection('Posts').doc(post.id).update({
                            'likeVal': FieldValue.increment(1),
                            'likedBy': FieldValue.arrayUnion([uid])
                          });
                        }
                      },
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 10),
                    Text('$likeval',
                        style: (const TextStyle(color: Colors.red)))
                  ]);
                })
          ]),
          const SizedBox(height: 5),
          showCommentsOfComments
              ? ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: replyList.length,
                  itemBuilder: (context, index) {
                    return Material(
                        child: ReplyTile(
                            replyId: replyList[index],
                            uid: widget.uid,
                            parentId: post.id,
                            userOwnParent: widget.userOwnParent));
                  })
              : Container()
        ]),
        leading: CircleAvatar(
            radius: 20,
            backgroundImage: post.profilePicture != null
                ? Image.memory(post.profilePicture!).image
                : const AssetImage("assets/images/Default Profile Pic.png")));
  }
}
