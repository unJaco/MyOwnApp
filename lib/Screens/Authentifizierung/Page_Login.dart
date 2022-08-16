import 'package:flutter/material.dart';
import 'package:my_own_app/Screens/HomePage.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';
import '../../Service/AuthenticationService.dart';
import 'Page_Welcome.dart';

enum ButtonState { init, loading }

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isAnimating = true;
  ButtonState state = ButtonState.init;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String email = '';
  String password = '';
  bool isPasswordVisible = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final _isStreched = isAnimating || state == ButtonState.init;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(height: MediaQuery.of(context).size.height * 0.07),
            Container(
              margin: const EdgeInsets.only(left: 25),
              child: Row(
                children: [
                  AppLargeText(text: "Login", color: Colors.deepPurple),
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
                    EmailTextField(),
                    const SizedBox(height: 30),
                    PasswordTextField(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 0, 0),
              child: Row(
                children: [
                  GestureDetector(
                    child: const Text(
                      "Passwort vergessen?",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed('/forgot password');
                    },
                  ),
                ],
              ),
            ),
            Container(height: MediaQuery.of(context).size.height * 0.03),
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
                  child: _isStreched ? LoginButton() : buildSmallButton(),
                ),
              ),
            ),
            Container(height: MediaQuery.of(context).size.height * 0.02),
            const AlreadyHaveAnAccountCheck(
              login: true,
            ),
          ],
        ),
      ),
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
          if (value!.isEmpty) {
            return "Tippe deine E-Mail ein";
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

  Widget LoginButton() => OutlinedButton(
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
          if (formKey.currentState!.validate()) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() {
              state = ButtonState.loading;
            });

            String? res = await context.read<AuthenticationService>().signIn(
                email: emailController.text, password: passwordController.text);

            if (res == "success") {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false);
            }
            setState(() {
              state = ButtonState.init;
            });
          }
        },
        child: const FittedBox(
          child: Text(
            "Login",
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
