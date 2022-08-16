import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Utils/Textstyle.dart';

import '../Authentifizierung/Page_Login.dart';
import 'Page_ChangeEmail.dart';
import 'Page_ChangePassword.dart';
import 'Page_EditData.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: AppLargeText(text: "Einstellungen"),
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
        body: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: AppLargeText(text: "Account"),
                  trailing: const Icon(Icons.person_outline_outlined,
                      color: Colors.black),
                ),
                ListTile(
                  title: const Text("Profil bearbeiten"),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const EditDataPage()));
                  },
                ),
                ListTile(
                  title: const Text("Email ändern"),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ChangeEmailPage()));
                  },
                ),
                ListTile(
                  title: const Text("Passwort zurücksetzen"),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage()));
                  },
                ),
                Container(
                    margin: const EdgeInsets.only(left: 15, right: 15),
                    child: const Divider(thickness: 1)),
                const SizedBox(
                  height: 10,
                ),
                ListTile(
                  title: AppLargeText(text: "Über uns"),
                  trailing: const Icon(Icons.contact_support_outlined,
                      color: Colors.black),
                ),
                const ListTile(title: Text("Nutzungsbedingungen")),
                const ListTile(title: Text("Datenschutz")),
                const ListTile(title: Text("Impressum")),
                Container(
                    margin: const EdgeInsets.only(left: 15, right: 15),
                    child: const Divider(thickness: 1)),
                const SizedBox(height: 20),
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
                    FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) {
                      return const LoginScreen();
                    }), (route) => false);
                  },
                  child: const Text("Abmelden",
                      style: TextStyle(fontSize: 18, color: Colors.blue)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
