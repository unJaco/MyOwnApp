import 'package:flutter/material.dart';
import 'package:my_own_app/Service/AuthenticationService.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:provider/provider.dart';

enum ButtonState { init, loading, done }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool isAnimating = true;
  ButtonState state = ButtonState.init;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
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
    final _isDone = state == ButtonState.done;
    final _isStreched = isAnimating || state == ButtonState.init;

    return Scaffold(
      appBar: AppBar(
        title: AppLargeText(text: "Passwort vergessen"),
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
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              const Text(
                "Bitte gebe deine E-Mail ein und wir schicken dir\neinen Link, um dein Passwort zurückzusetzen.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: TextFormField(
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
                      return "Bitte gebe deine E-Mail ein";
                    } else {
                      return null;
                    }
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 40, 25, 0),
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
                        _isStreched ? buildButton() : buildSmallButton(_isDone),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButton() => OutlinedButton(
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
            String? res = await context
                .read<AuthenticationService>()
                .resetPassword(emailController.text);
            if (res == "success") {
              setState(() {
                state = ButtonState.done;
              });
              await Future.delayed(const Duration(seconds: 1));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Bitte überprüfe dein E-Mail Postfach."),
                  backgroundColor: Colors.green));
            } else {
              setState(() {
                state = ButtonState.init;
              });
            }
          }
        },
        child: const FittedBox(
          child: Text(
            "Passwort zurücksetzen",
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
}
