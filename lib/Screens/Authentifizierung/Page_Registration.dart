import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Service/AuthenticationService.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';

import 'Page_Welcome.dart';

enum ButtonState { init, loading }

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool isAnimating = true;
  ButtonState state = ButtonState.init;

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool nameAvailable = true;

  String name = '';
  String username = '';
  String email = '';
  String password = '';
  String passwordConfirm = '';
  bool isPasswordVisible = true;
  bool isPasswordConfirmVisible = true;

  var firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    emailController.addListener(() {
      setState(() {});
    });
    usernameController.addListener(() {
      setState(() {});
    });
    nameController.addListener(() {
      setState(() {});
    });
  }

  Future<bool> checkIfUserNameIsAvailable(String username) async {

    var b = await firestore
        .collection('UserNames')
        .doc(username.toLowerCase())
        .get();

    return !b.exists;
  }

  @override
  Widget build(BuildContext context) {
    final _isStreched = isAnimating || state == ButtonState.init;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(height: MediaQuery.of(context).size.height * 0.07),
            Container(
              margin: const EdgeInsets.only(left: 25),
              child: Row(
                children: [
                  AppLargeText(text: "Registrieren", color: Colors.deepPurple),
                ],
              ),
            ),
            Container(height: MediaQuery.of(context).size.height * 0.03),
            Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: Column(
                  children: [
                    NameTextField(),
                    const SizedBox(height: 25),
                    usernameTextField(),
                    const SizedBox(height: 5),
                    EmailTextField(),
                    const SizedBox(height: 25),
                    PasswordTextField(),
                    const SizedBox(height: 25),
                    PasswordConfirmTextField(),
                    const SizedBox(height: 25),
                    AcceptConditions(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 0),
              child: AnimatedContainer(
                duration: (const Duration(milliseconds: 300)),
                curve: Curves.easeIn,
                width: state == ButtonState.init ? 320 : 42,
                onEnd: () => setState(() {
                  isAnimating = !isAnimating;
                }),
                margin: const EdgeInsets.symmetric(vertical: 7),
                child: ClipRRect(
                  child:
                      _isStreched ? RegistrationButton() : buildSmallButton(),
                ),
              ),
            ),
            const AlreadyHaveAnAccountCheck(
              login: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget NameTextField() => TextFormField(
        controller: nameController,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: "Name",
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
        validator: (value) {
          if (value!.isEmpty) {
            return "Tippe deinen Namen ein";
          }
        },
        onSaved: (value) => name = value!,
      );

  Widget usernameTextField() {
    return TextFormField(
      controller: usernameController,
      decoration: InputDecoration(
        labelText: "Benutzername",
        hintStyle: const TextStyle(fontSize: 15),
        suffixIcon: usernameController.text.isEmpty
            ? Container(width: 0)
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  usernameController.clear();
                },
              ),
      ),
      //onChanged: (value) => checkIfUserNameIsAvailable(value),
      validator: (value) {
        print('NameAvailable $nameAvailable');
        if (!nameAvailable) {
          setState(() {
            nameAvailable = !nameAvailable;
          });
          return 'Benutzername ist bereits vergeben';
        }

        const pattern =
            r"^(?=.{6,15}$)(?![_.])(?!.*[_.]{2})[a-zA-Z0-9._]+(?<![_.])$";

        final regExp = RegExp(pattern);
        if (value == null) {
          return 'Tippe einen Benutzernamen ein';
        } else if (value.isEmpty) {
          return 'Tippe einen Benutzernamen ein';
        } else if (!regExp.hasMatch(value)) {
          return 'Ungültiger Benutzername - mindestens 6 Zeichen,\nmaximal 15 Zeichen, keine Sonderzeichen';
        }
        return null;
      },
      maxLength: 15,
      onSaved: (value) => username = value!,
    );
  }

  Widget EmailTextField() => TextFormField(
        controller: emailController,
        decoration: InputDecoration(
          labelText: "E-Mail",
          hintStyle: const TextStyle(fontSize: 15),
          suffixIcon: emailController.text.isEmpty
              ? Container(width: 0)
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    emailController.clear();
                  },
                ),
        ),
        validator: (value) {
          const pattern =
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
          final regExp = RegExp(pattern);

          if (value!.isEmpty) {
            return "Tippe deine E-Mail ein";
          } else if (!regExp.hasMatch(value)) {
            return "Ungültige E-Mail";
          } else {
            return null;
          }
        },
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSaved: (value) => email = value!,
      );

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
          const pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{6,}$';
          final regExp = RegExp(pattern);

          if (value!.isEmpty) {
            return "Tippe ein Passwort ein";
          } else if (!regExp.hasMatch(value)) {
            return 'Ungültiges Passwort - Mindestens 6 Zeichen,\neinen Großbuchstaben, einen Kleinbuchstaben und eine Zahl';
          } else {
            return null;
          }
        },
        onSaved: (value) => password = value!,
        onFieldSubmitted: (value) => setState(() => password = value),
        obscureText: isPasswordVisible,
      );

  Widget PasswordConfirmTextField() => TextFormField(
        decoration: InputDecoration(
          labelText: "Passwort wiederholen",
          hintStyle: const TextStyle(fontSize: 15),
          suffixIcon: IconButton(
            icon: isPasswordConfirmVisible
                ? const Icon(Icons.visibility_off)
                : const Icon(Icons.visibility),
            onPressed: () {
              setState(() {
                isPasswordConfirmVisible = !isPasswordConfirmVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return "Wiederhole dein Passwort";
          } else if (value != passwordController.text) {
            return 'Passwort ist nicht identisch';
          } else {
            return null;
          }
        },
        onSaved: (value) => passwordConfirm = value!,
        onFieldSubmitted: (value) => setState(() => passwordConfirm = value),
        obscureText: isPasswordConfirmVisible,
      );

  Widget AcceptConditions() => RichText(
          text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black),
              children: <TextSpan>[
            const TextSpan(text: 'Mit meiner Registrierung stimme ich den '),
            TextSpan(
                text: 'Nutzungsbedingungen ',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    print('Nutzungsbedingungen');
                  }),
            const TextSpan(text: 'und der '),
            TextSpan(
                text: 'Datenschutzerklärung ',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    print('Datenschutzerklärung');
                  }),
            const TextSpan(text: 'zu.')
          ]));

/*Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Expanded(child:Text(
                "Mit meiner Registrierung stimme ich den ",
                style: TextStyle(fontSize: 13, color: Colors.black),
              )),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "Nutzungsbedingungen",
                  style: TextStyle(
                    color: (Colors.blue),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Text(" und der ",
                  style: TextStyle(fontSize: 13, color: Colors.black)),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "Datenschutzerklärung",
                  style: TextStyle(
                    color: (Colors.blue),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Text(" zu.",
                  style: TextStyle(fontSize: 13, color: Colors.black)),
            ],
          ),
        ],
      );*/

  Widget RegistrationButton() => OutlinedButton(
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
          FocusManager.instance.primaryFocus?.unfocus();
          if (formKey.currentState!.validate()) {
            bool b = await checkIfUserNameIsAvailable(usernameController.text);

            print(b);
            if (b == false) {
              setState(() {
                nameAvailable = false;
              });
              formKey.currentState!.validate();
              return;
            }

            setState(() {
              state = ButtonState.loading;
            });

            String? res = await context.read<AuthenticationService>().signUp(
                name: nameController.text,
                email: emailController.text,
                username: usernameController.text,
                password: passwordController.text);



            if (res == 'success') {
              Navigator.of(context).pushReplacementNamed('/verify');
            }
            setState(() {
              state = ButtonState.init;
            });
          }
        },
        child: const FittedBox(
          child: Text(
            "Registrieren",
            style: TextStyle(color: Colors.white),
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
