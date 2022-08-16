import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Model/AppUser.dart';
import 'package:my_own_app/Provider/UserProvider.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';

import '../../Model/Post.dart';

class AddMessagePage extends StatefulWidget {
  const AddMessagePage({Key? key}) : super(key: key);

  @override
  State<AddMessagePage> createState() => _AddMessagePageState();
}

class _AddMessagePageState extends State<AddMessagePage> {
  final firestore = FirebaseFirestore.instance;

  final messagesController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    messagesController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
          toolbarHeight: 70,
          title: AppLargeText(text: "Einen Beitrag erstellen..."),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.blue),
            tooltip: "Abbrechen",
            onPressed: () {
              messagesController.text.isNotEmpty
                  ? showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Beitrag löschen?"),
                        content: const Text("Dein Beitrag wird gelöscht."),
                        actions: [
                          TextButton(
                              child: const Text("Abbrechen"),
                              onPressed: () {
                                Navigator.pop(context);
                              }),
                          TextButton(
                              child: const Text("OK"),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              }),
                        ],
                      ),
                    )
                  : Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          actions: [
            Container(
              child: messagesController.text.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.send, color: Colors.grey))
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      tooltip: "Senden",
                      onPressed: () {
                        setState(() {
                          AppUser user = context.read<UserProvider>().user;
                          Post postToInsert = Post(
                              authorName: user.name,
                              authorUserName: user.username,
                              text: messagesController.text,
                              timestamp: FieldValue.serverTimestamp(),
                              likeVal: 0,
                              commentsVal: 0,
                              comments: [],
                              likedBy: []);

                          firestore
                              .collection('Posts')
                              .add(postToInsert.toJSON())
                              .then((post) {
                            firestore
                                .collection('PostsByUser')
                                .doc(user.uid)
                                .set({
                              'postIds': FieldValue.arrayUnion([post.id]),
                              'count': FieldValue.increment(1)
                            }, SetOptions(merge: true)).onError(
                                    (error, stackTrace) {
                              print(error);
                              print(stackTrace);
                            });
                          });
                          messagesController.clear();
                          FocusScope.of(context).unfocus();
                        });
                      },
                    ),
            ),
          ],
        ),
        body: Container(
          margin: const EdgeInsets.only(left: 15, right: 15),
          child: Scrollbar(
            controller: scrollController,
            child: TextFormField(
              minLines: 1,
              maxLines: null,
              controller: messagesController,
              scrollController: scrollController,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Einen Beitrag erstellen...",
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
