

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Provider/UserProvider.dart';
import 'package:provider/provider.dart';

import 'Model/AppUser.dart';

/*class AuthMethods {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<AppUser> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot snap =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return AppUser.fromSnap(snap);
  }

  Future<String> signUpUser(
      {required String email,
      required String password,
      required String username,
      required String name}) async {
    String res = "Ein Fehler ist aufgetreten";

    try {
      if (email.isNotEmpty ||
          password.isNotEmpty ||
          username.isNotEmpty ||
          name.isNotEmpty) {

        UserCredential cred = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        res = "success";

        AppUser user = AppUser(
          name: name,
          username: username,
          email: email,
          uid: cred.user!.uid,
          bio : ''
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());
      }
    } catch (error) {
      res = error.toString();
      //Utils.showSnackBar(res);
    }
    return res;
  }

  Future<String> loginUser({
    required String email,
    required String password
  }) async {
    String res = "Ein Fehler ist aufgetreten";

    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        res = "success";

      }
    } catch (error) {
      print(error);

      if (error == "invalid-email") {
        res = "Ungültige E-Mail";
      }
      if (error == "user-disabled") {
        res = "Benutzer ist nicht aktiviert";
      }
      if (error == "user-not-found") {
        res = "E-Mail oder Passwort ist falsch";
      }
      if (error == "[firebase_auth/wrong-password]") {
        res = "E-Mail oder Passwort ist falsch";
      }

      res = error.toString();
     // Utils.showSnackBar(res);
    }
    return res;
  }

  Future<String> forgotPassword({
    required String email,
  }) async {
    String res = "Ein Fehler ist aufgetreten";

    try {
      if (email.isNotEmpty) {
        await _auth.sendPasswordResetEmail(email: email);
        res = "success";
      }
    } catch (error) {
      res = error.toString();
      //Utils.showSnackBar(res);
    }
    return res;
  }

  Future<String> changePassword({
    required String newpassword,
  }) async {
    String res = "Ein Fehler ist aufgetreten";

    try {
      if (newpassword.isNotEmpty) {
        await currentUser?.updatePassword(newpassword);
        res = "success";
      }
    } catch (error) {
      res = error.toString();
      //Utils.showSnackBar(res);
    }
    return res;
  }

  Future<String> deleteProfile({
    required String password,
  }) async {
    String res = "Ein Fehler ist aufgetreten";

    try {
      if (password.isNotEmpty) {
        await FirebaseAuth.instance.currentUser!.delete();
        runApp(const MaterialApp(home: WelcomeScreen()));
        res = "success";
      }
    } catch (error) {
      res = error.toString();
      //Utils.showSnackBar(res);
    }
    return res;
  }
}
*/
/*class Utils {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();*/

  /*static showSnackBar(String? text) {
    print(text);

    if (text == null) return;

    final snackBar = SnackBar(content: Text(text), backgroundColor: Colors.red);

    messengerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }*/
//}
