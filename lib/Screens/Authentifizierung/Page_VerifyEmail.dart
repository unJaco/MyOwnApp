import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Screens/HomePage.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';

import '../../Service/AuthenticationService.dart';

class VerifyEMailPage extends StatefulWidget {
  const VerifyEMailPage({Key? key}) : super(key: key);

  @override
  State<VerifyEMailPage> createState() => _VerifyEMailPageState();
}

class _VerifyEMailPageState extends State<VerifyEMailPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) timer?.cancel();
  }

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() {
        canResendEmail = false;
        Future.delayed(const Duration(seconds: 5));
        setState(() {
          canResendEmail = true;
        });
      });
    } catch (e) {
      //Utils.showSnackBar(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return isEmailVerified
        ? const HomePage()
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.black,
              toolbarHeight: 70,
              title: AppLargeText(text: "E-Mail Verifizierung"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  context.read<AuthenticationService>().signOut(context);
                },
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Eine Verifizierungs-E-Mail wurde verschickt.\nBitte überprüfe dein E-Mail Postfach.",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 7),
                      child: ClipRRect(
                        child: OutlinedButton(
                          style: ButtonStyle(
                              splashFactory: NoSplash.splashFactory,
                              backgroundColor: MaterialStateProperty.all(
                                  const Color(0xC30052CB)),
                              minimumSize: MaterialStateProperty.all(
                                  const Size(320, 42)),
                              maximumSize: MaterialStateProperty.all(
                                  const Size(320, 42)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ))),
                          onPressed:
                              canResendEmail ? sendVerificationEmail : null,
                          child: const Text(
                            "E-Mail erneut senden",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
                    child: GestureDetector(
                      child: const Text(
                        "Abbrechen",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        context.read<AuthenticationService>().signOut(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
