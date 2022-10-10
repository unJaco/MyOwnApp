import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Service/AuthenticationService.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';

enum ButtonState { init, loading, done }

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({Key? key}) : super(key: key);

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  bool isAnimating = true;
  ButtonState state = ButtonState.init;
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final oldController = TextEditingController();

  final passwordController = TextEditingController();
  bool isPasswordVisible = true;

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    oldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _isDone = state == ButtonState.done;
    final _isStreched = isAnimating || state == ButtonState.init;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: AppLargeText(text: "Email ändern"),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
                  child:
                      NewEmailTextField()
                ),
              ),
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
                    child: _isStreched
                        ? buildButton(context)
                        : buildSmallButton(_isDone),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context) => OutlinedButton(
        style: ButtonStyle(
            splashFactory: NoSplash.splashFactory,
            backgroundColor: MaterialStateProperty.all(const Color(0xC30052CB)),
            minimumSize: MaterialStateProperty.all(const Size(320, 42)),
            maximumSize: MaterialStateProperty.all(const Size(320, 42)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ))),
        onPressed: () async {
          if (!formKey.currentState!.validate()) {
            return;
          }

          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            state = ButtonState.loading;
          });

          String? res = await context
              .read<AuthenticationService>()
              .changeEmail(emailController.text);

          if (res == 'success') {
            setState(() {
              state = ButtonState.done;
            });

            await Future.delayed(const Duration(seconds: 1));
            FirebaseAuth.instance.signOut();
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          } else {
            state = ButtonState.init;

            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Falsches Passwort'),
                    backgroundColor: Colors.red));
          }
        },
        child: const FittedBox(
          child: Text(
            "Speichern und neu anmelden",
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );

  Widget buildSmallButton(bool _isDone) {
    final color = _isDone ? Colors.green : const Color(0xC30052CB);

    return Container(
      height: 42,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(
        child: _isDone
            ? const Icon(Icons.done, color: Colors.white, size: 30)
            : const SizedBox(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3),
                height: 25,
                width: 25,
              ),
      ),
    );
  }

  Widget OldEmailTextField() => TextFormField(
        controller: oldController,
        decoration: const InputDecoration(
          labelText: "Alte Email",
          hintStyle: TextStyle(fontSize: 15),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Du musst eine E-Mail angeben';
          } else {
            return null;
          }
        },
      );

  Widget NewEmailTextField() => TextFormField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: "Neue Email",
          hintStyle: TextStyle(fontSize: 15),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Du musst eine E-Mail angeben';
          } else {
            return null;
          }
        },
      );

  Widget PasswordConfirmTextField() => TextFormField(
        decoration: InputDecoration(
          labelText: "Passwort eingeben",
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
            return 'Bitte gib dein Passwort an';
          } else {
            return null;
          }
        },
        controller: passwordController,
        obscureText: isPasswordVisible,
      );
}
