import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Provider/AppBarMode.dart';
import 'package:my_own_app/Provider/ProfilePictureProvider.dart';
import 'package:my_own_app/Provider/UserProvider.dart';
import 'package:my_own_app/Screens/Profile/Page_Comments.dart';
import 'package:my_own_app/Screens/Profile/Page_Followed.dart';
import 'package:my_own_app/Screens/Profile/Page_Follower.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_own_app/Widgets/AppBar.dart';
import 'package:my_own_app/Widgets/PostTile.dart';
import 'package:provider/provider.dart';
import '../../Model/AppUser.dart';
import '../../Model/Post.dart';

class ProfilePageUser extends StatefulWidget {
  const ProfilePageUser({Key? key, required this.userName, required this.user})
      : super(key: key);

  final String? userName;
  final AppUser? user;

  @override
  State<ProfilePageUser> createState() => _ProfilePageUserState();
}

class _ProfilePageUserState extends State<ProfilePageUser> {
  final firestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;

  late AppUser appUser;

  late String activeUserId;

  Uint8List? profilePicture;

  bool selected = false;

  bool isLoading = true;

  File? image;

  Map<int, String> postMap = {};
  List<Post> postList = [];

  int postCount = 0;

  String uid = '';

  final controller = ScrollController();
  final controller2 = ScrollController();

  @override
  void initState() {
    super.initState();
    activeUserId = context.read<UserProvider>().user.uid;
    setUp(context);
  }

  void setUp(BuildContext context) async {
    var profilePicList = context.read<ProfilePictureProvider>().profilePictures;
    if (widget.user == null) {
      await firestore
          .collection('UserNames')
          .doc(widget.userName)
          .get()
          .then((value) => uid = value.data()!['uid']);

      await firestore
          .collection('User')
          .doc(uid)
          .get()
          .then((value) => appUser = AppUser.fromSnap(value));

      if (profilePicList.keys.contains(appUser.username)) {
        profilePicture = profilePicList[appUser.username];
      } else {
        var list = await firebaseStorage
            .ref('files/${appUser.username}')
            .getData()
            .onError((error, stackTrace) => null);
        context
            .read<ProfilePictureProvider>()
            .addProfilePicture(appUser.username, list);
        profilePicture = list;
      }
    } else {
      appUser = widget.user!;
      uid = appUser.uid;
    }

    await fetchPosts();

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return _buildProfilePage();
  }

  Widget _buildProfilePage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Scaffold(
        appBar: MyAppbar(
            deletePosts: (List<Post> value) {
              setState(() {
                isLoading = true;
                for (Post p in value) {
                  postList.remove(p);
                }
                postCount -= value.length;
                isLoading = false;
              });
            },
            uid: uid,
            displayedText: 'Profil',
            appBarMode: AppBarMode.POSTS),
        body: _buildProfileInfo(),
      ),
    );
  }

  Widget _buildProfileInfo() {
    final Stream<DocumentSnapshot> followerStream =
        firestore.collection('Follower').doc(uid).snapshots();

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
          List helper = data['follower'];
          bool follow = helper.contains(activeUserId);
          return RefreshIndicator(
              onRefresh: _pullData,
              child: Scrollbar(
                  child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: controller2,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 15, right: 15),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                  height: 72,
                                  width: 72,
                                  child: Stack(children: [
                                    Container(
                                      height: 72,
                                      width: 72,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 3,
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              spreadRadius: 2,
                                              blurRadius: 10,
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              offset: const Offset(0, 10)),
                                        ],
                                        image: DecorationImage(
                                          fit: BoxFit.fill,
                                          image: profilePicture != null
                                              ? Image.memory(profilePicture!)
                                                  .image
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
                                                color: Theme.of(context)
                                                    .scaffoldBackgroundColor,
                                                boxShadow: [
                                                  BoxShadow(
                                                      spreadRadius: 2,
                                                      blurRadius: 10,
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      offset:
                                                          const Offset(0, 10)),
                                                ],
                                                border: Border.all(
                                                  width: 3,
                                                  color: Theme.of(context)
                                                      .scaffoldBackgroundColor,
                                                ))))
                                  ])),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(appUser.name,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500)),
                                  Text("@" + appUser.username,
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 19)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(appUser.bio,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black)),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                FollowerPage(id: uid)));
                                  },
                                  child: Row(children: [
                                    Text('${data['followerVal']}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                    const Text(" Follower",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.black)),
                                  ])),
                              const SizedBox(width: 20),
                              GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              FollowedPage(id: uid)),
                                    );
                                  },
                                  child: Row(children: [
                                    Text('${data['gefolgtVal']}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                    const Text(" Gefolgt",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.black)),
                                  ])),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: () {
                                  if (follow) {
                                    firestore
                                        .collection('Follower')
                                        .doc(activeUserId)
                                        .update({
                                      'gefolgt':
                                          FieldValue.arrayRemove([appUser.uid]),
                                      'gefolgtVal': FieldValue.increment(-1)
                                    });
                                    firestore
                                        .collection('Follower')
                                        .doc(appUser.uid)
                                        .update({
                                      'follower': FieldValue.arrayRemove(
                                          [activeUserId]),
                                      'followerVal': FieldValue.increment(-1)
                                    });
                                  } else {
                                    firestore
                                        .collection('Follower')
                                        .doc(appUser.uid)
                                        .update({
                                      'follower':
                                          FieldValue.arrayUnion([activeUserId]),
                                      'followerVal': FieldValue.increment(1)
                                    });
                                    firestore
                                        .collection('Follower')
                                        .doc(activeUserId)
                                        .update({
                                      'gefolgt':
                                          FieldValue.arrayUnion([appUser.uid]),
                                      'gefolgtVal': FieldValue.increment(1)
                                    });
                                  }
                                  follow = !follow;
                                },
                                child: !follow
                                    ? const Text("Folgen")
                                    : const Text("Gefolgt"),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(thickness: 1),
                          _buildListview()
                        ],
                      ),
                    ),
                  ],
                ),
              )));
        });
  }

  Future<void> _pullData() async {
    await fetchPosts();
    setState(() {});
  }

  Widget _buildListview() {
    return SafeArea(
        child: postList.isEmpty
            ? Center(
                child: Text(
                    'Ziemlich leer hier...\n\nDie Posts von ${appUser.username} werden hier gezeigt'))
            : ListView.separated(
                controller: controller,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: postCount,
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
                          uid: context.read<UserProvider>().uid!,
                          clickable: true,
                        );
                      });
                }));
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
                  child: Wrap(children: [Container()]),
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
                    image: image != null
                        ? FileImage(image!)
                        : const AssetImage(
                                "assets/images/Default Profile Pic.png")
                            as ImageProvider,
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
                ),
              ),
            ],
          ),
        ),
      );
}

/*
class ProfilePageUser extends StatefulWidget {
  const ProfilePageUser({Key? key, required this.user, required this.userName}) : super(key: key);

  final AppUser? user;
  final String? userName;

  @override
  State<ProfilePageUser> createState() => _PageProfileUserState();
}

class _PageProfileUserState extends State<ProfilePageUser> {
  final _firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  bool isLoading = true;

  File? image;

  List<Post> postList = [];

  int postCount = 0;

  late final String uid;
  late final AppUser appUser;

  final controller = ScrollController();
  final controller2 = ScrollController();

  @override
  void initState() {
    super.initState();

    //setUpProfile(context);
    setUp(context);
  }

  void setUp(BuildContext context) async {
    if (widget.user == null) {
      await firestore
          .collection('UserNames')
          .doc(widget.userName)
          .get()
          .then((value) => uid = value.data()!['uid']);

      await firestore
          .collection('User')
          .doc(uid)
          .get()
          .then((value) => appUser = AppUser.fromSnap(value));
    } else {
      appUser = widget.user!;
      uid = appUser.uid;
    }

    await fetchPosts();

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      isLoading = false;
    });
  }

  /*void setUpProfile(BuildContext context) async {
    uid = _firebaseAuth.currentUser!.uid;

    await context.read<UserProvider>().setUserInformation(context);
    await fetchPosts();

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      isLoading = false;
    });
  }*/

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
              print('fetchPost $element');
              await firestore
                  .collection('Posts')
                  .doc(element)
                  .get()
                  .then((post) {
                if (post.exists) {
                  Post p = Post.fromSnap(post);
                  p.setId(element);
                  postList.add(p);
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
                isLoading = true;
                for (Post p in value) {
                  postList.remove(p);
                }
                postCount -= value.length;
                isLoading = false;
              });
            },
            uid: uid, showIcons: true),
        body: _buildProfileInfo(),

      ),
    );
  }

  Widget _buildProfileInfo() {
    final Stream<DocumentSnapshot> followerStream = firestore
        .collection('Follower')
        .doc(uid)
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
          return RefreshIndicator(
              onRefresh: _pullData,
              child: Scrollbar(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: controller2,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 15, right: 15),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  buildProfileImage(),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(appUser.name,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          "@" +
                                              appUser
                                                  .username,
                                          style: const TextStyle(
                                              color: Colors.black54, fontSize: 19)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(appUser.bio,
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.black)),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) => FollowerPage(
                                                  id: appUser
                                                      .uid)),
                                        );
                                      },
                                      child: Row(children: [
                                        Text('${data['followerVal']}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                        const Text(" Follower",
                                            style: TextStyle(
                                                fontSize: 16, color: Colors.black)),
                                      ])),
                                  const SizedBox(width: 20),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) => FollowedPage(
                                                id: appUser
                                                    .uid)),
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
                                            style: TextStyle(
                                                fontSize: 16, color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(thickness: 1),
                              _buildListview()
                            ],
                          ),
                        ),
                      ],
                    ),
                  )));
        });
  }

  Future<void> _pullData() async {
    await fetchPosts();
    setState(() {});
  }

  Widget _buildListview() {
    return SafeArea(
        child: postList.isEmpty
            ? const Center(
            child: Text(
                'Ziemlich leer hier...\n\nDeine Posts werden hier angezeigt'))
            : ListView.separated(
            controller: controller,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: postCount,
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
                        post: postList[index], data: data, uid: uid);
                  });
            }));
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
                    onTap: () {
                      pickImage(ImageSource.gallery);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading:
                    const Icon(Icons.photo_camera, color: Colors.blue),
                    title: const Text("Bild aufnehmen"),
                    onTap: () {
                      pickImage(ImageSource.camera);
                      Navigator.pop(context);
                    },
                  ),
                  (image != null)
                      ? ListTile(
                    leading:
                    const Icon(Icons.delete, color: Colors.red),
                    title: const Text("Bild löschen"),
                    onTap: () {
                      setState(() {
                        image = null;
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
                image: image != null
                    ? FileImage(image!)
                    : const AssetImage(
                    "assets/images/Default Profile Pic.png")
                as ImageProvider,
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
}*/
