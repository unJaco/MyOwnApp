import 'package:flutter/material.dart';
import 'package:my_own_app/Utils/Textstyle.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          AppLargeText(text: "Willkommen"),
          Center(
            child: Container(
              height: 325,
              width: 400,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/virtual-business-assistant-isolated-on-white-background-vector-vector-id1153240053.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: const [
              WelcomeButton(
                text: "Login",
                color: Color(0xC30052CB),
                login: true,
              ),
              WelcomeButton(
                text: "Registrieren",
                color: Color(0x75BBF5FD),
                textColor: Colors.black,
                login: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WelcomeButton extends StatelessWidget {
  const WelcomeButton({
    Key? key,
    required this.text,
    required this.color,
    this.textColor = Colors.white,
    this.login = true,
  }) : super(key: key);

  final String text;
  final Color color, textColor;
  final bool login;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: ClipRRect(
        child: OutlinedButton(
          style: ButtonStyle(
              splashFactory: NoSplash.splashFactory,
              backgroundColor: MaterialStateProperty.all(color),
              minimumSize: MaterialStateProperty.all(const Size(320, 42)),
              maximumSize: MaterialStateProperty.all(const Size(320, 42)),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ))),
          onPressed: () {
            login
                ? Navigator.pushNamed(context, '/login')
                : Navigator.pushNamed(context, '/registration');
          },
          child: Text(
            text,
            style: TextStyle(color: textColor),
          ),
        ),
      ),
    );
  }
}

class AlreadyHaveAnAccountCheck extends StatelessWidget {
  final bool login;

  const AlreadyHaveAnAccountCheck({
    Key? key,
    this.login = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 25, right: 25),
          child: Divider(
            color: Colors.blue,
          ),
        ),
        Container(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              login
                  ? "Hast du noch keinen Account? "
                  : "Hast du bereits einen Account? ",
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    login ? '/registration' : '/login', (route) => false);
              },
              child: Text(
                login ? "Registrieren" : "Anmelden",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
