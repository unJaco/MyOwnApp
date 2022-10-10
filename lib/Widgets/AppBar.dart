import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Provider/AppBarMode.dart';
import 'package:provider/provider.dart';
import '../Model/Post.dart';
import '../Provider/SelectionProvider.dart';
import '../Screens/Profile/Page_News.dart';
import '../Screens/Settings/Page_Settings.dart';
import '../Utils/Textstyle.dart';

class MyAppbar extends StatefulWidget with PreferredSizeWidget {
  const MyAppbar(
      {Key? key,
      required this.deletePosts,
      required this.uid,
      required this.displayedText,
      required this.appBarMode})
      : super(key: key);

  final ValueChanged<List<Post>>? deletePosts;

  final String uid;

  final String displayedText;

  final AppBarMode appBarMode;

  @override
  _MyAppbarState createState() => _MyAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MyAppbarState extends State<MyAppbar> {
  final firestore = FirebaseFirestore.instance;

  late String text;
  late bool showIcons;

  List<Post> selectedPosts = [];
  List<Post> selectedComments = [];
  Map<Post, String> selectedReplies = {};
  bool selectionMode = false;

  @override
  Widget build(BuildContext context) {
    selectedPosts = context.watch<SelectionProvider>().selectedPosts;
    selectedComments = context.watch<SelectionProvider>().selectedComments;
    selectedReplies = context.watch<SelectionProvider>().selectedReplies;

    selectionMode = selectedPosts.isNotEmpty || selectedComments.isNotEmpty || selectedReplies.isNotEmpty;

    text = widget.displayedText;


    var unreadNewsStream = firestore
        .collection('User')
        .doc(widget.uid)
        .collection('News')
        .doc('unreadNews')
        .snapshots();

    switch (widget.appBarMode) {
      case AppBarMode.POSTS:
        showIcons = true;
        break;
      case AppBarMode.COMMENTS:
        showIcons = false;
        break;
      case AppBarMode.COMMENTSOFCOMMENTS:
        showIcons = false;
        break;
    }
    return AppBar(
      leading: !selectionMode
          ? null
          : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                context.read<SelectionProvider>().clear();
              }),
      title: !selectionMode
          ? AppLargeText(text: text)
          : AppLargeTextWhite(text: "Ausgewählt"),
      backgroundColor: !selectionMode ? Colors.transparent : Colors.blue,
      elevation: 0,
      foregroundColor: !selectionMode ? Colors.black : Colors.white,
      toolbarHeight: 70,
      actions: <Widget>[
        !selectionMode && showIcons
            ? Badge(
                badgeContent: StreamBuilder(
                    stream: unreadNewsStream,
                    builder: (ctx, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Something went wrong');
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("0",
                            style: TextStyle(color: Colors.white));
                      }
                      dynamic data = snapshot.data!;
                      int val = data['count'];
                      String count = '0';
                      if(val > 99){
                        count = '99+';
                      } else {
                        count = val.toString();
                      }
                      return Text(count,
                          style: const TextStyle(color: Colors.white));
                    }),
                badgeColor: Colors.red,
                toAnimate: false,
                position: BadgePosition.topEnd(top: 10, end: 0),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none),
                  tooltip: "Neuigkeiten",
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const NewsPage()));
                  },
                ),
              )
            : Container(width: 0),
        if (selectionMode)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Löschen",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Beitrag löschen?"),
                  content: const Text(
                      "Möchtest du diesen Beitrag wirklich unwiderruflich löschen?"),
                  actions: [
                    TextButton(
                        child: const Text("Abbrechen"),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    TextButton(
                        child: const Text("OK"),
                        onPressed: () async {
                          List<Post> postsToDelete =
                              context.read<SelectionProvider>().selectedPosts;

                          List<Post> commentsToDelete = context
                              .read<SelectionProvider>()
                              .selectedComments;

                          Map<Post, String> repliesToDelete =
                              context.read<SelectionProvider>().selectedReplies;

                          List<String> postIdList = [];

                          String? parentId = context
                              .read<SelectionProvider>()
                              .parentOfCommentId;

                          context.read<SelectionProvider>().clear();

                          print('Posts: $postsToDelete');
                          if (postsToDelete.isNotEmpty) {
                            widget.deletePosts!(postsToDelete);
                            for (Post p in postsToDelete) {
                              postIdList.add(p.id);
                            }
                            for (var postToDelete in postsToDelete) {
                              await firestore
                                  .collection('Posts')
                                  .doc(postToDelete.id)
                                  .delete();

                            }
                            await firestore
                                .collection('PostsByUser')
                                .doc(widget.uid)
                                .update({
                              'postIds': FieldValue.arrayRemove(postIdList),
                              'count':
                              FieldValue.increment(-postIdList.length)
                            });
                          }
                          List commentIdList = [];

                          if (commentsToDelete.isNotEmpty) {
                            for (Post p in commentsToDelete) {
                              print(p.id);
                              commentIdList.add(p.id);
                            }
                            for (var commentId in commentIdList) {
                              await firestore
                                  .collection('Posts')
                                  .doc(commentId)
                                  .delete();
                            }
                            if (parentId != null) {
                              await firestore
                                  .collection('Posts')
                                  .doc(parentId)
                                  .update({
                                'comments':
                                    FieldValue.arrayRemove(commentIdList),
                                'commentsVal':
                                    FieldValue.increment(-commentIdList.length)
                              });
                            }
                          }
                          if (repliesToDelete.isNotEmpty) {
                            for (Post replyToDelete in repliesToDelete.keys) {
                              await firestore
                                  .collection('Posts')
                                  .doc(replyToDelete.id)
                                  .delete();
                              if (!commentIdList
                                  .contains(repliesToDelete[replyToDelete])) {
                                await firestore
                                    .collection('Posts')
                                    .doc(repliesToDelete[replyToDelete])
                                    .update({
                                  'comments': FieldValue.arrayRemove(
                                      [replyToDelete.id]),
                                  'commentsVal': FieldValue.increment(-1)
                                });
                              }
                            }
                          }
                          widget.deletePosts!(commentsToDelete + repliesToDelete.keys.toList());
                          Navigator.pop(context);
                        }),
                  ],
                ),
              );
            },
          )
        else
          showIcons
              ? IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: "Einstellungen",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                )
              : Container()
      ],
    );
  }
}
