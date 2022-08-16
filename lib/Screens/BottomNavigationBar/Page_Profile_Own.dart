import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_own_app/Provider/AppBarMode.dart';
import 'package:my_own_app/Screens/Profile/Page_AddMessage.dart';
import 'package:my_own_app/Screens/Profile/Page_Followed.dart';
import 'package:my_own_app/Screens/Profile/Page_Follower.dart';
import 'package:my_own_app/Provider/UserProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../Model/Post.dart';
import '../../Widgets/AppBar.dart';
import '../../Widgets/PostTile.dart';

class OwnProfilePage extends StatefulWidget {
  const OwnProfilePage({Key? key}) : super(key: key);

  @override
  State<OwnProfilePage> createState() => _OwnProfilePageState();
}

class _OwnProfilePageState extends State<OwnProfilePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;
  final _fcm = FirebaseMessaging.instance;


  bool isLoading = true;

  File? image;

  List<Post> postList = [];

  int postCount = 0;

  late final String uid;


  Uint8List? profilePicture;


  @override
  void initState() {
    super.initState();

    setUpProfile(context);

  }

  void setUpProfile(BuildContext context) async {
    uid = _firebaseAuth.currentUser!.uid;


    await context.read<UserProvider>().setUserInformation(context);

    await fetchPosts();

    _saveDeviceToken();

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      isLoading = false;
    });
  }

  _saveDeviceToken() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print(fcmToken);
    if(fcmToken != null) {
      var tokenRef = firestore.collection('User').doc(uid)
          .collection("Token")
          .doc(fcmToken);

      await tokenRef.set(
          {'token': fcmToken, 'platform': Platform.operatingSystem});
    } else {
      print('null');
    }
  }

  Future<void> fetchPosts() async {
    await firestore.collection('PostsByUser').doc(uid).get().then((doc) async {
      var data = doc.data();
      if (data != null) {
        List postIds = data['postIds'];
        postCount = data['count'];

        if (postList.length != postCount) {
          for (var element in postIds) {
            bool exists = false;
            for (Post p in postList) {
              if (p.id == element) {
                exists = true;
              }
            }
            if (!exists) {
              await firestore
                  .collection('Posts')
                  .doc(element)
                  .get()
                  .then((post) {
                if (post.exists) {
                  Post? p = Post.fromSnap(post);
                  if (p != null) {
                    p.setId(element);
                    postList.add(p);
                  }
                }
              });
            }
          }
        }
      }

      postList.sort((p1, p2) {
        Timestamp t1 = p1.timestamp as Timestamp;
        Timestamp t2 = p2.timestamp as Timestamp;

        return t2.compareTo(t1);
      });
    });
  }


  Future pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() {
        this.image = imageTemporary;
      });

    } on PlatformException catch (e) {
      print("Ein Fehler ist aufgetreten: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    profilePicture = context.watch<UserProvider>().profilePicture;
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildProfilePage();
  }

  Widget _buildProfilePage() {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppbar(
            deletePosts: (List<Post> value) {
              setState(() {
                for (Post p in value) {
                  postList.remove(p);
                }
                postCount -= value.length;
              });
            },
            uid: uid,
            displayedText: 'Profil',
            appBarMode: AppBarMode.POSTS),
        body: _buildProfilePageBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const AddMessagePage()));
          },
          child: const Icon(Icons.add_comment),
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildProfilePageBody() {
    final Stream<DocumentSnapshot> followerStream = firestore
        .collection('Follower')
        .doc(context.read<UserProvider>().uid)
        .snapshots();

    return StreamBuilder(
        stream: followerStream,
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          dynamic data = snapshot.data!;
          try{
            var random = data['followerVal'];
          } catch(e){
            return const SizedBox();
          }
          return RefreshIndicator(
              onRefresh: _pullData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(children: [
                        _buildProfileInfo(data),
                        const SizedBox(height: 10),
                        const Divider(thickness: 1),
                        _buildListview()
                      ])));
        });
  }

  Widget _buildProfileInfo(dynamic data) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Row(children: [
              buildProfileImage(),
              const SizedBox(width: 20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.watch<UserProvider>().user.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500)),
                Text('@' + context.watch<UserProvider>().user.username,
                    style: const TextStyle(color: Colors.black54, fontSize: 19))
              ])
            ]),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(context.watch<UserProvider>().user.bio,
                  style: const TextStyle(fontSize: 15, color: Colors.black)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => FollowerPage(
                                id: context.read<UserProvider>().user.uid)),
                      );
                    },
                    child: Row(children: [
                      Text('${data['followerVal']}',
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      const Text(" Follower",
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    ])),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => FollowedPage(
                              id: context.read<UserProvider>().user.uid)),
                    );
                  },
                  child: Row(
                    children: [
                      Text('${data['gefolgtVal']}',
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      const Text(" Gefolgt",
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  Future<void> _pullData() async {
    await fetchPosts();
    setState(() {});
  }

  Widget _buildListview() {

    return postList.isEmpty
            ? Center(
                child: Container(
                    margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 5),
                    child: const Text(
                    'Ziemlich leer hier...\n\nDeine Posts werden hier angezeigt')))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: postList.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(height: 2),
                itemBuilder: (context, index) {

                  final Stream<DocumentSnapshot> postStream = firestore
                      .collection('Posts')
                      .doc(postList[index].id)
                      .snapshots();

                  return StreamBuilder(
                      stream: postStream,
                      builder: (ctx, snapshot) {

                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container();
                        }

                        dynamic data = snapshot.data!;
                        return PostTile(
                          post: postList[index],
                          data: data,
                          uid: uid,
                          clickable: true,
                        );
                      });
                });
  }

  Widget buildProfileImage() => SizedBox(
        height: 72,
        width: 72,
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              )),
              context: context,
              builder: (context) {
                return SafeArea(
                  child: Wrap(
                    children: <Widget>[
                      const ListTile(
                        title: Text("Profilbild",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.image, color: Colors.blue),
                        title: const Text("Bild auswählen"),
                        onTap: () async {
                          await pickImage(ImageSource.gallery);
                          context.read<UserProvider>().uploadProfilePicture(image);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.photo_camera, color: Colors.blue),
                        title: const Text("Bild aufnehmen"),
                        onTap: () async {
                          await pickImage(ImageSource.camera);
                          Navigator.pop(context);
                        },
                      ),
                      profilePicture != null
                          ? ListTile(
                              leading:
                                  const Icon(Icons.delete, color: Colors.red),
                              title: const Text("Bild löschen"),
                              onTap: () {
                                setState(() {
                                  context.read<UserProvider>().deletePicture();
                                  Navigator.pop(context);
                                });
                              },
                            )
                          : Container(height: 0),
                    ],
                  ),
                );
              },
            );
          },
          child: Stack(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  border: Border.all(
                      width: 3,
                      color: Theme.of(context).scaffoldBackgroundColor),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        spreadRadius: 2,
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 10)),
                  ],
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: profilePicture != null
                        ? Image.memory(profilePicture!).image
                        : const AssetImage(
                                "assets/images/Default Profile Pic.png"),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                          spreadRadius: 2,
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 10)),
                    ],
                    border: Border.all(
                      width: 3,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  child: const Icon(Icons.add_a_photo,
                      color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ),
      );
}
