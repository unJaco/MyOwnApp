import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Provider/UserProvider.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';

import 'Page_DeleteProfile.dart';

class EditDataPage extends StatefulWidget {
  const EditDataPage({Key? key}) : super(key: key);

  @override
  State<EditDataPage> createState() => _EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage> {
  final _firestore = FirebaseFirestore.instance;

  final bioController = TextEditingController();
  final nameController = TextEditingController();

  bool allowed = true;

  @override
  void initState() {
    super.initState();
    bioController.addListener(checkState);
    nameController.addListener(() {
      setState(() {});
    });
  }

  void checkState(){
    setState(() {
      allowed = bioController.text.split('\n').length <= 2;
      print(allowed);
    });

  }
  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: AppLargeText(text: "Profil bearbeiten"),
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: BioTextField(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
                child: NameTextField(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 40, 25, 0),
                child: OutlinedButton(
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
                    var bio = bioController.text;
                    var name = nameController.text;

                    Map<String, dynamic> data = {};

                    bio != '' ? data['bio'] = bio : null;
                    name != '' ? data['name'] = name : null;

                    if (data.isNotEmpty) {
                      _firestore
                          .collection('User')
                          .doc(context.read<UserProvider>().uid)
                          .set(data, SetOptions(merge: true));
                    }

                    context.read<UserProvider>().refreshUser();

                    Navigator.pop(context);
                  },
                  child: const Text("Speichern",
                      style: TextStyle(fontSize: 18, color: Colors.blue)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
                child: GestureDetector(
                  child: const Text("Profil löschen",
                      style: TextStyle(color: Colors.red, fontSize: 14)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const DeleteProfilePage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  StatefulWidget BioTextField() => TextFormField(
        minLines: 1,
        maxLines: 3,
        textInputAction: TextInputAction.newline,
        keyboardType: allowed ? TextInputType.multiline : TextInputType.phone,
        controller: bioController,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: "Biografie hinzufügen",
          hintStyle: const TextStyle(fontSize: 15),
          suffixIcon: bioController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    bioController.clear();
                  },
                ),
        ),
      );

  Widget NameTextField() => TextFormField(
        controller: nameController,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: "Name bearbeiten",
          hintStyle: const TextStyle(fontSize: 15),
          suffixIcon: nameController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    nameController.clear();
                  },
                ),
        ),
      );
}
