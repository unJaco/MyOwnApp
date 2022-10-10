import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_own_app/Provider/ProfilePictureProvider.dart';
import 'package:my_own_app/Provider/UserProvider.dart';
import 'package:provider/provider.dart';
import '../Model/Post.dart';
import '../Provider/SelectionProvider.dart';
import '../Screens/Profile/Page_Comments.dart';

class PostTile extends StatefulWidget {
  const PostTile(
      {Key? key,
      required this.post,
      required this.data,
      required this.uid,
      required this.clickable})
      : super(key: key);

  final Post post;
  final dynamic data;
  final String uid;

  final bool clickable;

  @override
  _PostTileState createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  final firestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;

  late Post post;
  late dynamic data;
  late String uid;

  late String timeStampToDisplay;
  late bool likedByUser;

  Map<String, Uint8List?> profilePictures = {};
  late Uint8List? profilePicture;

  static bool selectionMode = false;
  bool isSelected = false;

  final DateFormat format = DateFormat('dd-MM-yyyy');

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    setUp();
  }


  @override
  void dispose() {
    super.dispose();
  }

  void setUp() async {

    profilePictures = context.read<ProfilePictureProvider>().profilePictures;
    if(profilePictures.keys.contains(widget.post.authorUserName)){
      widget.post.setProfilePicture(profilePictures[widget.post.authorUserName]);
    }else {
      var list = await firebaseStorage.ref(
          'files/${widget.post.authorUserName}').getData().onError((error,
          stackTrace) => null);
      context.read<ProfilePictureProvider>().addProfilePicture(widget.post.authorUserName, list);
      widget.post.setProfilePicture(list);
    }
    setState(() {
      isLoading = false;
    });
  }

  Future navigateToComments() => Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (context) => CommentsPage(
                    uid: uid,
                    data: data,
                    post: post,
                    ownId: post.id,
                  )))
          .then((value) => context.read<SelectionProvider>().deactivateCommentMode());

  @override
  Widget build(BuildContext context) {

    if(isLoading){
      return Container();
    }

    post = widget.post;
    data = widget.data;
    uid = widget.uid;

    profilePicture = post.profilePicture;

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

    likedByUser = post.likedBy.contains(uid);

    isSelected =
        context.watch<SelectionProvider>().selectedPosts.contains(post);
    selectionMode = context.watch<SelectionProvider>().selectedPosts.isNotEmpty;

    int commVal = 0;
    int likeVal = 0;
    try {
      commVal = data['commentsVal'];
      likeVal = data['likeVal'];
    } catch (e) {
      print(e);
    }

    return Column(
      children: [
        ListTile(
          tileColor: !isSelected
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.grey[300],
          onTap: () {
            widget.clickable
                ? selectionMode
                    ? isSelected == false
                        ? context.read<SelectionProvider>().addPost(post)
                        : context.read<SelectionProvider>().removePost(post)
                    : navigateToComments()
                : null;
          },
          onLongPress: () {
            if (post.authorUserName ==
                    context.read<UserProvider>().user.username &&
                widget.clickable) {
              context.read<SelectionProvider>().addPost(post);
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
                      style:
                          (const TextStyle(color: Colors.grey, fontSize: 16))),
                ],
              ),
              Row(
                children: [
                  Text('@${post.authorUserName}',
                      style:
                          (const TextStyle(color: Colors.grey, fontSize: 15))),
                ],
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                      child: Text(post.text,
                          style: (const TextStyle(
                              color: Colors.black, fontSize: 15))))
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  widget.clickable
                      ? GestureDetector(
                          child: const Text('Kommentieren',
                              style: TextStyle(color: Colors.blue)),
                          onTap: () {
                            !selectionMode ? navigateToComments() : null;
                          },
                        )
                      : Container(),
                  Expanded(child: Container()),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.mode_comment_outlined, size: 22),
                    color: Colors.blue,
                    onPressed: () {
                      widget.clickable && !selectionMode ? navigateToComments() : null;
                    },
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 10),
                  Text('$commVal',
                      style: (const TextStyle(color: Colors.blue))),
                  const SizedBox(width: 20),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                        likedByUser ? Icons.favorite : Icons.favorite_border,
                        size: 22),
                    color: Colors.red,
                    onPressed: () {
                      if(!selectionMode) {
                        if (likedByUser) {
                          firestore.collection('Posts').doc(post.id).update({
                            'likeVal': FieldValue.increment(-1),
                            'likedBy': FieldValue.arrayRemove([uid])
                          });
                          setState(() {
                            post.likedBy.remove(uid);
                          });

                        } else {
                          firestore.collection('Posts').doc(post.id).update({
                            'likeVal': FieldValue.increment(1),
                            'likedBy': FieldValue.arrayUnion([uid])
                          });
                          setState(() {
                            post.likedBy.add(uid);
                          });
                        }
                      }
                    },
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 10),
                  Text('$likeVal', style: (const TextStyle(color: Colors.red))),
                ],
              ),
              const SizedBox(height: 5),
            ],
          ),
          leading: CircleAvatar(
            radius: 20,
            backgroundImage:
                profilePicture != null? Image.memory(post.profilePicture!).image :
                const AssetImage("assets/images/Default Profile Pic.png"),
          ),
        ),
        //   const Divider(),
      ],
    );
  }
}
