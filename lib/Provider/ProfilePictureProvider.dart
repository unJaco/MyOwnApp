import 'dart:typed_data';

class ProfilePictureProvider {


  final Map<String, Uint8List?> _profilePictures = {};

  Map<String, Uint8List?> get profilePictures => _profilePictures;

  void addProfilePicture(String authorUserName, Uint8List? picture){
    _profilePictures[authorUserName] = picture;
  }

  Uint8List? getPicture(String authorUserName){
    return _profilePictures[authorUserName];
  }

  bool containsPicture(String authorUserName){
    return _profilePictures.keys.contains(authorUserName);
  }
}