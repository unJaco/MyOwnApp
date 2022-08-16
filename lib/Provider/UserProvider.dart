import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Model/AppUser.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  String? _uid;
  Uint8List? _profilePicture;

  int? _follower;
  int? _gefolgt;

  final _firestore = FirebaseFirestore.instance;
  final _firebaseAuth = FirebaseAuth.instance;
  final _firebaseStorage = FirebaseStorage.instance;

  AppUser get user => _user!;

  String? get uid => _uid;

  Uint8List? get profilePicture => _profilePicture;

  int? get follower => _follower;

  int? get gefolgt => _gefolgt;

  setUserInformation(BuildContext context) async {
    _uid = _firebaseAuth.currentUser?.uid;

    await refreshUser();

    notifyListeners();
  }

  Future<AppUser?> refreshUser() async {
    AppUser? appUser;
    await _firestore
        .collection('User')
        .doc(_uid)
        .get()
        .then((value) => appUser = AppUser.fromSnap(value));

    _firestore.collection('Follower').doc(_uid).snapshots().listen((value) {
      var data = value.data();
      try{
        _gefolgt = data!['gefolgtVal'];
        _follower = data['followerVal'];
      } catch(e){
        print(e);
      }

    });



    if (appUser != null) {
      await getProfilePicture(appUser!);
      _user = appUser;
      notifyListeners();
      return _user;
    }
    return null;
  }

  Future uploadProfilePicture(File? image) async {
    _profilePicture = null;
    if (image == null) return;


    try {
      final ref = _firebaseStorage.ref('files/${_user?.username}');
      await ref.putFile(image);
      await getProfilePicture(user);
      notifyListeners();
    } catch (e) {
      print('error occured');
    }
  }

  Future deletePicture() async {
    _profilePicture = null;
    final ref = _firebaseStorage.ref('files/${_user?.username}');
    await ref.delete();

    notifyListeners();
  }

  Future getProfilePicture(AppUser appUser) async {

    final ref = _firebaseStorage.ref('files/${appUser.username}');

    Uint8List? list = await ref.getData().onError((error, stackTrace) => null);

    _profilePicture = list;
  }

  void reset() {
    _user = null;
    _uid = null;
  }
}
