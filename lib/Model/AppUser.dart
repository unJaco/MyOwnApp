import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String name;
  final String username;
  final String email;
  late String uid;
  final String bio;

  AppUser(
      {required this.name,
      required this.username,
      required this.email,
      required this.uid,
      required this.bio});

  Map<String, dynamic> toJson() => {
        "name": name,
        "username": username,
        "email": email,
        "uid": uid,
        "bio": bio
      };

  static AppUser fromSnap(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;

    return AppUser(
        name: data['name'],
        username: data['username'],
        email: data['email'],
        uid: data['uid'],
        bio: data['bio']);
  }

  @override
  String toString() {
    return 'AppUser{name: $name, username: $username, email: $email, uid: $uid, bio: $bio}';
  }
}
