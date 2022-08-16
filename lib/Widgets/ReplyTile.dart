import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_own_app/Provider/SelectionProvider.dart';
import 'package:provider/provider.dart';

import '../Model/Post.dart';
import '../Provider/ProfilePictureProvider.dart';
import '../Provider/UserProvider.dart';

class ReplyTile extends StatefulWidget {
  const ReplyTile(
      {Key? key,
      required this.replyId,
      required this.uid,
      required this.parentId,
      required this.userOwnParent})
      : super(key: key);

  final String replyId;
  final String uid;
  final String parentId;
  final bool userOwnParent;

  @override
  _ReplyTileState createState() => _ReplyTileState();
}

class _ReplyTileState extends State<ReplyTile> {
  final firestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;

  Post? post;

  bool isLoading = true;

  static bool selectionMode = false;
  bool isSelected = false;

  late bool likedByUser;

  Map<String, Uint8List?> profilePictures = {};

  final DateFormat format = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();

    setUp(context);
  }

  void setUp(BuildContext context) async {
    profilePictures = context.read<ProfilePictureProvider>().profilePictures;

    await firestore
        .collection('Posts')
        .doc(widget.replyId)
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
        post = p;
      }
    });

    setState(() {
      isLoading = false;
    });
  }

  Widget _buildListTile(Post? post) {

    if(post == null){
      return const SizedBox();
    }
    Timestamp timeStamp = post.timestamp;

    int differenceMin = DateTime.now().difference(timeStamp.toDate()).inMinutes;
    int differenceHours = DateTime.now().difference(timeStamp.toDate()).inHours;
    int differenceDays = DateTime.now().difference(timeStamp.toDate()).inDays;

    String timeStampToDisplay = '';

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

    final Stream<DocumentSnapshot> replyStream =
        firestore.collection('Posts').doc(post.id).snapshots();

    return ListTile(
      tileColor: !isSelected
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[300],
      onLongPress: () {
        if (post.authorUserName == context.read<UserProvider>().user.username ||
            widget.userOwnParent) {
          context.read<SelectionProvider>().addReply(post, widget.parentId);
        }
      },
      onTap: () {
         if (selectionMode) {
          if (post.authorUserName ==
                  context.read<UserProvider>().user.username ||
              widget.userOwnParent) {
            isSelected == false
                ? context.read<SelectionProvider>().addReply(post, widget.parentId)
                : context.read<SelectionProvider>().removeReply(post);
          }
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
      subtitle: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                  child: Text(post.text,
                      style: (const TextStyle(
                          color: Colors.black, fontSize: 15)))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Container()),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon:
                    Icon(likedByUser ? Icons.favorite : Icons.favorite_border),
                color: Colors.red,
                onPressed: () {
                  if (likedByUser) {
                    firestore.collection('Posts').doc(post.id).update({
                      'likeVal': FieldValue.increment(-1),
                      'likedBy': FieldValue.arrayRemove([widget.uid])
                    });
                    setState(() {
                      post.likedBy.remove(widget.uid);
                    });
                  } else {
                    firestore.collection('Posts').doc(post.id).update({
                      'likeVal': FieldValue.increment(1),
                      'likedBy': FieldValue.arrayUnion([widget.uid])
                    });
                    setState(() {
                      post.likedBy.add(widget.uid);
                    });
                  }
                },
                splashRadius: 20,
              ),
              const SizedBox(width: 10),
              StreamBuilder(
                  stream: replyStream,
                  builder: (ctx, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('0',
                          style: (TextStyle(color: Colors.red)));
                    }
                    dynamic data = snapshot.data!;

                    int likeVal = 0;

                    try {
                      likeVal = data['likeVal'];
                    } catch (e){
                      print(e);
                    }

                    return Text('$likeVal',
                        style: (const TextStyle(color: Colors.red)));
                  })
            ],
          ),
        ],
      ),
      leading: CircleAvatar(
          radius: 20,
          backgroundImage: post.profilePicture != null
              ? Image.memory(post.profilePicture!).image
              : const AssetImage("assets/images/Default Profile Pic.png")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading && post != null) {
      isSelected =
          context.watch<SelectionProvider>().selectedReplies[post] != null;

      selectionMode = context.watch<SelectionProvider>().selectedComments.isNotEmpty || context.watch<SelectionProvider>().selectedReplies.isNotEmpty;

      likedByUser = post!.likedBy.contains(widget.uid);
    }
    return isLoading ? Container() : Material(child: _buildListTile(post));
  }
}
