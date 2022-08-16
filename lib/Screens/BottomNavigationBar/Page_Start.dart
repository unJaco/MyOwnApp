import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Model/Post.dart';
import 'package:my_own_app/Screens/BottomNavigationBar/Page_Profile_User.dart';
import '../../Widgets/PostTile.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  bool isLoading = true;

  late final String uid;

  Map<int, String> postMap = {};
  List<Post> postList = [];

  int postCount = 0;

  @override
  void initState() {
    super.initState();

    setUp(context);
  }

  void setUp(BuildContext context) async {
    uid = _firebaseAuth.currentUser!.uid;

    await fetchPosts();

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchPosts() async {
    await firestore.collection('Follower').doc(uid).get().then((doc) async {
      var data = doc.data();

      if (data != null) {
        List gefolgt = data['gefolgt'];

        for (String gefolgtId in gefolgt) {
          await firestore
              .collection('PostsByUser')
              .doc(gefolgtId)
              .get()
              .then((postsByUser) async {
            var data = postsByUser.data();
            if (data != null) {
              List postIds = data['postIds'];
              for (String postId in postIds) {
                bool exists = false;
                for (Post p in postList) {
                  if (p.id == postId) {
                    exists = true;
                  }
                }
                if (!exists) {
                  await firestore
                      .collection('Posts')
                      .doc(postId)
                      .get()
                      .then((post) {
                    if (post.exists) {
                      Post? p = Post.fromSnap(post);
                      if (p != null) {
                        p.setId(postId);
                        postList.add(p);
                      }
                    }
                  });
                }
              }
            }
          });
        }
      }
    });
    postList.sort((p1, p2) {
      Timestamp t1 = p1.timestamp as Timestamp;
      Timestamp t2 = p2.timestamp as Timestamp;

      return t2.compareTo(t1);
    });
  }

  Future<void> _pullData() async {
    await fetchPosts();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    leading: Container(height: 0),
                    pinned: true,
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    foregroundColor: Colors.black,
                    toolbarHeight: 70,
                    actions: <Widget>[
                      Expanded(
                        child: GestureDetector(onTap: () {}),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.person_search_outlined, size: 28),
                        tooltip: "Profil Suche",
                        onPressed: () {
                          showSearch(
                            context: context,
                            delegate: ProfileSearchDelegate(),
                          );
                        },
                      )
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: WatchlistButton(),
                    ),
                  ),
                ],
            body: postList.isEmpty
                ? const Center(
                    child: Text(
                        'Ziemlich leer hier...\nDie Posts von anderen werden hier gezeigt'))
                : _buildBody());
  }

  Widget _buildBody() {
    return RefreshIndicator(
        onRefresh: _pullData,
        child: SingleChildScrollView(child: Column(children: [
          const SizedBox(height: 10),
          const Divider(thickness: 1),
          _buildListview()
        ])));
  }

  Widget _buildListview() {
    return postList.isEmpty
        ? const Center(
            child: Text(
                'Ziemlich leer hier...\n\nDeine Posts werden hier angezeigt'))
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

                    if (snapshot.connectionState == ConnectionState.waiting) {
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

  Widget WatchlistButton() => SizedBox(
        height: 60,
        child: OutlinedButton(
          style: ButtonStyle(
            splashFactory: NoSplash.splashFactory,
            backgroundColor: MaterialStateProperty.all(
                Theme.of(context).scaffoldBackgroundColor),
          ),
          onPressed: () {},
          child: Row(
            children: [
              const Text("Füge Informationen hinzu",
                  style: TextStyle(color: Colors.black, fontSize: 18)),
              Expanded(child: Container()),
              const Icon(Icons.add, color: Colors.black, size: 28),
            ],
          ),
        ),
      );
}

class ProfileSearchDelegate extends SearchDelegate {
  final _collection = FirebaseFirestore.instance.collection('UserNames');

  @override
  List<Widget>? buildActions(BuildContext context) => [
        query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                color: Colors.grey,
                onPressed: () {
                  query = '';
                })
            : Container(height: 0)
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        color: Colors.black,
        onPressed: () {
          close(context, null);
        },
      );

  @override
  Widget buildResults(BuildContext context) => Center(
        child: Text(
          query + 'lol',
          style: const TextStyle(fontSize: 64),
        ),
      );

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: query != ''
            ? _collection
                .where(FieldPath.documentId,
                    isGreaterThanOrEqualTo: query.toLowerCase())
                .where(FieldPath.documentId,
                    isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
                .limit(10)
                .orderBy(FieldPath.documentId)
                .snapshots()
            : null,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.connectionState == ConnectionState.active ||
              snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return const Text('Error');
            } else if (!snapshot.hasData) {
              return const Text('Empty data');
            } else {
              return ListView(
                  children: snapshot.data!.docs
                      .map((DocumentSnapshot document) {
                        Map<String, dynamic> data =
                            document.data()! as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['caseSensitive']),
                          subtitle: Text(document.id.toString()),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ProfilePageUser(
                                      userName: document.id,
                                      user: null,
                                    )));
                          },
                        );
                      })
                      .toList()
                      .cast());
            }
          } else if (snapshot.connectionState == ConnectionState.none) {
            return Container();
          } else {
            return Text('State: ${snapshot.connectionState}');
          }
        });
  }

  @override
  String get searchFieldLabel => 'Profil Suche';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      textTheme: const TextTheme(
        headline6: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w500,
            decorationThickness: 0),
      ),
      appBarTheme: const AppBarTheme(
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/*


RefreshIndicator(
                      onRefresh: _pullData,
                      child: ListView.separated(
                          itemCount: postCount,
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(height: 2),
                          itemBuilder: (context, index) {
                            bool likedByuser =
                                postList[index].likedBy.contains(uid);
                            Timestamp timestamp = postList[index].timestamp;

                            final Stream<DocumentSnapshot> postStream =
                                firestore
                                    .collection('Posts')
                                    .doc(postMap[index + 1])
                                    .snapshots();
                            return StreamBuilder(
                                stream: postStream,
                                builder: (ctx, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Text('Something went wrong');
                                  }

                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text("Loading");
                                  }

                                  dynamic data = snapshot.data!;
                                  return Column(
                                    children: [
                                      ListTile(
                                        onTap: () {
                                          /*Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CommentsPage()));*/
                                        },
                                        title: Column(
                                          children: [
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(postList[index].authorName,
                                                    style: (const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16))),
                                                Text(
                                                    '${DateTime.now().difference(timestamp.toDate()).inMinutes}',
                                                    style: (const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 16))),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                    '@${postList[index].authorUserName}',
                                                    style: (const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 15))),
                                              ],
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(postList[index].text,
                                                    style: (const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15))),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(child: Container()),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: const Icon(
                                                      Icons
                                                          .mode_comment_outlined,
                                                      size: 22),
                                                  color: Colors.blue,
                                                  onPressed: () {
                                                    /*Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const CommentsPage()));*/
                                                  },
                                                  splashRadius: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Text('${data['commentsVal']}',
                                                    style: (const TextStyle(
                                                        color: Colors.blue))),
                                                const SizedBox(width: 20),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: Icon(
                                                      likedByuser
                                                          ? Icons.favorite
                                                          : Icons
                                                              .favorite_border,
                                                      size: 22),
                                                  color: Colors.red,
                                                  onPressed: () {
                                                    if (likedByuser) {
                                                      firestore
                                                          .collection('Posts')
                                                          .doc(postMap[
                                                              index + 1])
                                                          .update({
                                                        'likeVal': FieldValue
                                                            .increment(-1),
                                                        'likedBy': FieldValue
                                                            .arrayRemove([uid])
                                                      });
                                                    } else {
                                                      firestore
                                                          .collection('Posts')
                                                          .doc(postMap[
                                                              index + 1])
                                                          .update({
                                                        'likeVal': FieldValue
                                                            .increment(1),
                                                        'likedBy': FieldValue
                                                            .arrayUnion([uid])
                                                      });
                                                    }

                                                    likedByuser = !likedByuser;
                                                  },
                                                  splashRadius: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Text('${data['likeVal']}',
                                                    style: (const TextStyle(
                                                        color: Colors.red))),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                          ],
                                        ),
                                        leading: const CircleAvatar(
                                          radius: 20,
                                          backgroundImage: AssetImage(
                                              "assets/images/Default Profile Pic.png"),
                                        ),
                                      ),
                                      //   const Divider(),
                                    ],
                                  );
                                });
                          }),
                    ),



 */
