import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import '../../Model/AppUser.dart';
import '../BottomNavigationBar/Page_Profile_User.dart';

class FollowedPage extends StatefulWidget {
  const FollowedPage({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  State<FollowedPage> createState() => _FollowedPageState();
}

class _FollowedPageState extends State<FollowedPage> {
  final firestore = FirebaseFirestore.instance;

  bool isLoading = true;

  List<dynamic> gefolgtIds = [];

  List<AppUser> gefolgt = [];

  late int gefolgtVal;

  late String id;

  @override
  void initState() {
    super.initState();

    id = widget.id;

    setUp(context);
  }

  void setUp(BuildContext context) async {
    await firestore.collection('Follower').doc(id).get().then((doc) {
      var data = doc.data()!;

      gefolgtIds = data['gefolgt'];

      gefolgtVal = data['gefolgtVal'];
    });

    for (var gefolgtId in gefolgtIds) {
      await firestore.collection('User').doc(gefolgtId).get().then((user) {
        gefolgt.add(AppUser.fromSnap(user));
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: Scaffold(
              appBar: AppBar(
                title: AppLargeText(text: "Gefolgt"),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.black,
                toolbarHeight: 70,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              body: Scrollbar(
                child: ListView.builder(
                    itemCount: gefolgt.length,
                    itemBuilder: (context, index) {

                        Stream<DocumentSnapshot> followStream = firestore
                            .collection('Follower')
                            .doc(id)
                            .snapshots();

                        return StreamBuilder(
                            stream: followStream,
                            builder: (ctx, snapshot) {
                              if (snapshot.hasError) {
                                return const Text('Something went wrong');
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }

                              dynamic data = snapshot.data!;

                              List<dynamic> helper = data['gefolgt'];
                              bool follow = helper.contains(gefolgt[index].uid);

                              return SizedBox(
                                height: 70,
                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ProfilePageUser(
                                                    userName: null,
                                                    user: gefolgt[index])));
                                  },
                                  title: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 5),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text(gefolgt[index].name,
                                            style: (const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16))),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                            '@${gefolgt[index].username}',
                                            style: (const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 15))),
                                      ),
                                    ],
                                  ),
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: AssetImage(
                                            "assets/images/Default Profile Pic.png"),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          if (follow) {
                                            firestore
                                                .collection('Follower')
                                                .doc(id)
                                                .update({
                                              'gefolgt': FieldValue.arrayRemove(
                                                  [gefolgt[index].uid]),
                                              'gefolgtVal':
                                                  FieldValue.increment(-1)
                                            });
                                            firestore
                                                .collection('Follower')
                                                .doc(gefolgt[index].uid)
                                                .update({
                                              'follower': FieldValue.arrayRemove(
                                                  [id]),
                                              'followerVal':
                                              FieldValue.increment(-1)
                                            });
                                          } else {
                                            firestore
                                                .collection('Follower')
                                                .doc(id)
                                                .update({
                                              'gefolgt': FieldValue.arrayUnion(
                                                  [gefolgt[index].uid]),
                                              'gefolgtVal':
                                                  FieldValue.increment(1)
                                            });
                                            firestore
                                                .collection('Follower')
                                                .doc(gefolgt[index].uid)
                                                .update({
                                              'follower': FieldValue.arrayUnion(
                                                  [id]),
                                              'followerVal':
                                              FieldValue.increment(1)
                                            });

                                          }

                                          follow = !follow;
                                        },
                                        child: !follow
                                            ? const Text("Folgen")
                                            : const Text("Gefolgt")
                                      )
                                    ]
                                  )
                                )
                              );
                            });
                    }),
              ),
            ),
          );
  }
}
