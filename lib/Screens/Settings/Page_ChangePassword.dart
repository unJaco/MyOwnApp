import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Service/AuthenticationService.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';

enum ButtonState { init, loading, done }

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool isAnimating = true;
  ButtonState state = ButtonState.init;
  final formKey = GlobalKey<FormState>();
  final newpasswordController = TextEditingController();
  String newPassword = '';
  bool isnewPasswordVisible = true;
  final newpasswordConfirmController = TextEditingController();
  String newpasswordConfirm = '';
  bool isnewPasswordConfirmVisible = true;

  final _firebaseAuth = FirebaseAuth.instance;

  @override
  void dispose() {
    newpasswordController.dispose();
    newpasswordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _isDone = state == ButtonState.done;
    final _isStreched = isAnimating || state == ButtonState.init;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: AppLargeText(text: 'Passwort zurücksetzen'),
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
                  padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                  child: Column(
                    children: [
                      NewPasswordTextField(),
                      const SizedBox(height: 30),
                      NewPasswordConfirmTextField(),
                      const SizedBox(height: 30),
                    ],
                  ),
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
            newPassword = newpasswordController.text;
          });

          var credential = EmailAuthProvider.credential(
              email: _firebaseAuth.currentUser!.email!,
              password: newpasswordController.text);

          _firebaseAuth.currentUser!.reauthenticateWithCredential(credential);

          String? res = await context
              .read<AuthenticationService>()
              .changePassword(newPassword);

          if (res == 'success') {
            setState(() {
              state = ButtonState.done;
            });
            Navigator.pop(context);
          } else {
            setState(() {
              state = ButtonState.init;
            });
          }
        },
        child: const FittedBox(
          child: Text(
            'Speichern und neu anmelden',
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

  Widget NewPasswordTextField() => TextFormField(
        controller: newpasswordController,
        decoration: InputDecoration(
          labelText: 'Neues Passwort',
          hintStyle: const TextStyle(fontSize: 15),
          suffixIcon: IconButton(
            icon: isnewPasswordVisible
                ? const Icon(Icons.visibility_off)
                : const Icon(Icons.visibility),
            onPressed: () {
              setState(() {
                isnewPasswordVisible = !isnewPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) {
          const pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{6,}$';
          final regExp = RegExp(pattern);

          if (value!.isEmpty) {
            return 'Tippe ein Passwort ein';
          } else if (!regExp.hasMatch(value)) {
            return 'Ungültiges Passwort - Mindestens 6 Zeichen,\neinen Großbuchstaben, einen Kleinbuchstaben und eine Zahl';
          } else {
            return null;
          }
        },
        onSaved: (value) => newPassword = value!,
        onFieldSubmitted: (value) => setState(() => newPassword = value),
        obscureText: isnewPasswordVisible,
      );

  Widget NewPasswordConfirmTextField() => TextFormField(
        decoration: InputDecoration(
          labelText: 'Neues Passwort wiederholen',
          hintStyle: const TextStyle(fontSize: 15),
          suffixIcon: IconButton(
            icon: isnewPasswordConfirmVisible
                ? const Icon(Icons.visibility_off)
                : const Icon(Icons.visibility),
            onPressed: () {
              setState(() {
                isnewPasswordConfirmVisible = !isnewPasswordConfirmVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Wiederhole dein Passwort';
          } else if (value != newpasswordController.text) {
            return 'Passwort ist nicht identisch';
          } else {
            return null;
          }
        },
        onSaved: (value) => newpasswordConfirm = value!,
        onFieldSubmitted: (value) => setState(() => newpasswordConfirm = value),
        obscureText: isnewPasswordConfirmVisible,
      );
}
