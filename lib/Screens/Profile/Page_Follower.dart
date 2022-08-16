import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Model/AppUser.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import '../BottomNavigationBar/Page_Profile_User.dart';

class FollowerPage extends StatefulWidget {
  const FollowerPage({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  State<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends State<FollowerPage> {
  final firestore = FirebaseFirestore.instance;

  bool isLoading = true;

  List<dynamic> followerIds = [];
  List<dynamic> gefolgtIds = [];

  List<AppUser> follower = [];

  late int followCount;

  late String uid;

  @override
  void initState() {
    super.initState();

    uid = widget.id;

    setUp(context);
  }

  void setUp(BuildContext context) async {
    await firestore.collection('Follower').doc(uid).get().then((doc) {
      var data = doc.data()!;

      followerIds = data['follower'];
      gefolgtIds = data['gefolgt'];

      followCount = data['followerVal'];
    });

    for (var followerId in followerIds) {
      await firestore.collection('User').doc(followerId).get().then((user) {
        follower.add(AppUser.fromSnap(user));
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
                title: AppLargeText(text: "Follower"),
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
                    itemCount: followCount == follower.length
                        ? follower.length
                        : follower.length + 1,
                    itemBuilder: (context, index) {
                      if (index < follower.length) {
                        Stream<DocumentSnapshot> followStream = firestore
                            .collection('Follower')
                            .doc(uid)
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

                              List<dynamic> gefolgt = data['gefolgt'];
                              bool follow =
                                  gefolgt.contains(follower[index].uid);

                              return SizedBox(
                                height: 70,
                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ProfilePageUser(
                                                    userName: null,
                                                    user: follower[index])));
                                  },
                                  title: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 5),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text(follower[index].name,
                                            style: (const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16))),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                            '@${follower[index].username}',
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
                                                .doc(uid)
                                                .update({
                                              'gefolgt': FieldValue.arrayRemove(
                                                  [follower[index].uid]),
                                              'gefolgtVal':
                                                  FieldValue.increment(-1)
                                            });
                                            firestore
                                                .collection('Follower')
                                                .doc(gefolgt[index].uid)
                                                .update({
                                              'follower': FieldValue.arrayRemove(
                                                  [uid]),
                                              'followerVal':
                                              FieldValue.increment(-1)
                                            });
                                          } else {
                                            firestore
                                                .collection('Follower')
                                                .doc(uid)
                                                .update({
                                              'gefolgt': FieldValue.arrayUnion(
                                                  [follower[index].uid]),
                                              'gefolgtVal':
                                                  FieldValue.increment(1)
                                            });
                                            firestore
                                                .collection('Follower')
                                                .doc(gefolgt[index].uid)
                                                .update({
                                              'follower': FieldValue.arrayUnion(
                                                  [uid]),
                                              'followerVal':
                                              FieldValue.increment(1)
                                            });
                                          }

                                          follow = !follow;
                                        },
                                        child: !follow
                                            ? const Text("Folgen")
                                            : const Text("Gefolgt"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                      } else {
                        return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                                child: Column(children: [
                              const CircularProgressIndicator(),
                              Text(followerIds.length.toString())
                            ])));
                      }
                    }),
              ),
            ),
          );
  }
}
