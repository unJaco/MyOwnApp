import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_own_app/Model/AppUser.dart';
import 'package:provider/provider.dart';

import '../Provider/UserProvider.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;

  final _firestore = FirebaseFirestore.instance;

  AuthenticationService(this._firebaseAuth);

  Stream<User?> get idTokenChanges => _firebaseAuth.idTokenChanges();

  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _firebaseAuth.signOut();
    context.read<UserProvider>().reset();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<String?> signUp(
      {required String name,
      required String email,
      required String username,
      required String password}) async {
    AppUser user =
        AppUser(name: name, username: username, email: email, uid: '', bio: '');

    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: user.email, password: password);

      user.uid = _firebaseAuth.currentUser!.uid;

      await _firestore.collection('User').doc(user.uid).set(user.toJson());

      await _firestore.collection('User').doc(user.uid).collection('News').doc('unreadNews').set(
          {'count' : 0});

      await _firestore
          .collection('UserNames')
          .doc(user.username.toLowerCase())
          .set({'caseSensitive': username, 'uid' : user.uid});

      await _firestore.collection('Follower').doc(user.uid).set({'follower' : [], 'followerVal' : 0, 'gefolgt' : [], 'gefolgtVal' : 0});


      return 'success';
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  Future<String?> fillerUserNames({required String username}) async {
    try {
      await _firestore
          .collection('UserNames')
          .doc(username.toLowerCase())
          .set({'assigned': true, 'caseSensitive': username});

      return 'success';
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteAccount() async {
    try {

      String uid = _firebaseAuth.currentUser!.uid;

      var docRef = _firestore.collection('User').doc(uid);

      late AppUser user;
      docRef.get().then((userSnap) => user = AppUser.fromSnap(userSnap));
      docRef.delete();

      _firestore.collection('UserNames').doc(user.username).delete();

      _firestore.collection('PostsByUser').doc(uid).get().then((doc) {
        Map? data = doc.data();
        if(data != null) {
          List postId = data['postIds'];
          for (String id in postId) {
            _firestore.collection('Posts').doc(id).delete();
          }
        }
      });

      _firestore.collection('Follower').doc(uid).get().then((doc) async {
        Map? data = doc.data();
        if(data != null) {
          List gefolgt = data['gefolgt'];
          for (String g in gefolgt) {
            _firestore.collection('Follower').doc(g).update({
              'followerVal': FieldValue.increment(-1),
              'follower': FieldValue.arrayRemove([uid])
            });
          }
          List follower = data['follower'];
          for (String f in follower) {
            _firestore.collection('Follower').doc(f).update({
              'gefolgtVal': FieldValue.increment(-1),
              'gefolgt': FieldValue.arrayRemove([uid])
            });
          }
        }
      });
      _firestore.collection('PostsByUser').doc(uid).delete();
      _firestore.collection('Follower').doc(uid).delete();

      await _firebaseAuth.currentUser?.delete();
      return 'success';
    } on FirebaseException catch (e) {
      print(e);
      return e.message;
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return 'success';
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  Future<String?> changeEmail(String email) async {
    try {
      await _firestore.collection('/User').doc(_firebaseAuth.currentUser!.uid).update({'email' : email});
      await _firebaseAuth.currentUser?.updateEmail(email);
      return 'success';
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  Future<String?> changePassword(String newPassword) async {
    try {
      await _firebaseAuth.currentUser?.updatePassword(newPassword);
      return 'success';
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
}
