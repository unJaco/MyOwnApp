import 'package:flutter/material.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';

import '../../Service/AuthenticationService.dart';

enum ButtonState { init, loading, done }

class DeleteProfilePage extends StatefulWidget {
  const DeleteProfilePage({Key? key}) : super(key: key);

  @override
  State<DeleteProfilePage> createState() => _DeleteProfilePageState();
}

bool isAnimating = true;
ButtonState state = ButtonState.init;
final formKey = GlobalKey<FormState>();
final passwordController = TextEditingController();
String password = '';
bool isPasswordVisible = true;

@override
void dispose() {
  passwordController.dispose();
}

class _DeleteProfilePageState extends State<DeleteProfilePage> {
  final _isStreched = isAnimating || state == ButtonState.init;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: AppLargeText(text: "Profil löschen"),
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
          child: Column(children: [
            const SizedBox(height: 10),
            const Text(
              "Bitte gebe dein Passwort ein,\n um dein Profil zu löschen.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 50),
            Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: PasswordTextField(),
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
              child: AnimatedContainer(
                duration: (const Duration(milliseconds: 300)),
                curve: Curves.easeIn,
                width: state == ButtonState.init ? 320 : 42,
                onEnd: () => setState(() {
                  isAnimating = !isAnimating;
                }),
                margin: const EdgeInsets.symmetric(vertical: 7),
                child: ClipRRect(
                  child: _isStreched ? buildButton() : buildSmallButton(),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget PasswordTextField() => TextFormField(
        controller: passwordController,
        decoration: InputDecoration(
          labelText: "Passwort",
          hintStyle: const TextStyle(fontSize: 15),
          suffixIcon: IconButton(
            icon: isPasswordVisible
                ? const Icon(Icons.visibility_off)
                : const Icon(Icons.visibility),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "Tippe dein Passwort ein";
          } else {
            return null;
          }
        },
        onSaved: (value) => password = value!,
        onFieldSubmitted: (value) => setState(() => password = value),
        obscureText: isPasswordVisible,
      );

  Widget buildButton() => OutlinedButton(
        style: ButtonStyle(
            splashFactory: NoSplash.splashFactory,
            minimumSize: MaterialStateProperty.all(const Size(320, 42)),
            maximumSize: MaterialStateProperty.all(const Size(320, 42)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.red),
            ))),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Profil löschen?"),
              content: const Text(
                  "Dein Profil und deine gesamten Beiträge werden unwiderruflich gelöscht. Diese Entscheidung kann nicht mehr rückgängig gemacht werden."),
              actions: [
                TextButton(
                    child: const Text("Abbrechen"),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                TextButton(
                    child: const Text("OK"),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          state = ButtonState.loading;
                        });
                        String? res = await context
                            .read<AuthenticationService>()
                            .deleteAccount();
                        if (res == "success") {
                          setState(() {
                            state = ButtonState.done;
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Profil wurde gelöscht."),
                                  backgroundColor: Colors.green));
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        } else {
                          setState(() {
                            state = ButtonState.init;
                          });
                        }
                      }
                    }),
              ],
            ),
          );
        },
        child: const FittedBox(
          child: Text(
            "Profil löschen",
            style: TextStyle(color: Colors.red, fontSize: 15),
          ),
        ),
      );

  Widget buildSmallButton() {
    return Container(
      height: 42,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Color(0xC30052CB)),
      child: const Center(
        child: SizedBox(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          height: 25,
          width: 25,
        ),
      ),
    );
  }
}
