import 'package:flutter/material.dart';

class AppLargeText extends StatelessWidget {
  double size;
  final String text;
  final Color color;
   AppLargeText({Key? key,
     this.size = 20,
     required this.text,
     this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w500,
       ),
    );
  }
}

class AppLargeTextWhite extends StatelessWidget {
  double size;
  final String text;
  final Color color;
  AppLargeTextWhite({Key? key,
    this.size = 20,
    required this.text,
    this.color = Colors.white}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}


class AppLargestText extends StatelessWidget {
  double size;
  final String text;
  final Color color;
  AppLargestText({Key? key,
    this.size = 30,
    required this.text,
    this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class AppLargestTextWhite extends StatelessWidget {
  double size;
  final String text;
  final Color color;
  AppLargestTextWhite({Key? key,
    this.size = 30,
    required this.text,
    this.color = Colors.white}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
