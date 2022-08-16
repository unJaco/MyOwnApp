import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Service/AuthenticationService.dart';
import 'package:provider/provider.dart';
import 'package:username_gen/username_gen.dart';

class Entdecken extends StatefulWidget {
  const Entdecken({
    Key? key,
  }) : super(key: key);

  @override
  _EntdeckenState createState() => _EntdeckenState();
}

class _EntdeckenState extends State<Entdecken> {
  var firestore = FirebaseFirestore.instance;

  Future<bool> checkIfUserNameIsAvailable(String username) async {
    var b = await firestore
        .collection('UserNames')
        .doc(username.toLowerCase())
        .get();

    return !b.exists;
  }

  void insertRandomUser(int x) async {
    for (int i = 0; i < x; i++) {
      var uname = UsernameGen().generate();
      bool b = await checkIfUserNameIsAvailable(uname);

      if (b) {
        await context
            .read<AuthenticationService>()
            .fillerUserNames(username: uname);
      }
    }

    print('Inserted Succefully');
  }

  void deleteUserIfAttributeNotExists(
      {required String attribute, required String collection}) async {
    var snap = await firestore.collection(collection).get();
    var ids = List<String>.empty(growable: true);

    snap.docs.forEach((element) {
      var data = element.data();
      if (!data.keys.contains(attribute)) {
        ids.add(element.id);
      }
    });

    var batch = firestore.batch();

    await firestore.collection(collection).get().then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (!doc.data().containsKey(attribute)) {
          batch.delete(doc.reference);
        }
      });
      return batch.commit();
    });

    print('Deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      OutlinedButton(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 40),
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        onPressed: () {
          context.read<AuthenticationService>().signOut(context);
        },
        child: const Text("Ausloggen",
            style: TextStyle(fontSize: 24, color: Colors.blue)),
      ),
      OutlinedButton(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 40),
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        onPressed: () {
          insertRandomUser(50);
        },
        child: const Text("INSERT 50 Random User",
            style: TextStyle(fontSize: 24, color: Colors.blue)),
      ),
      TextButton(
          onPressed: () {
            deleteUserIfAttributeNotExists(
                attribute: 'caseSensitive', collection: 'UserNames');
          },
          child: const Text('Delete User If Attribute not there')),
      TextButton(
          onPressed: () async {
            firestore.collection('Follower').doc('test').get().then((value) {
              var data = value.data();
              print(data!['name']);
              var lol = data['name'].get().then((val) {
                var l = val.data();
              });

            });
          },
          child: const Text('TESTING'))
    ]);
  }
}
