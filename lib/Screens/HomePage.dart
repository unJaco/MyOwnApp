import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Screens/BottomNavigationBar/Page_Entdecken.dart';
import 'package:my_own_app/Screens/BottomNavigationBar/Page_Profile_Own.dart';
import 'package:my_own_app/Screens/BottomNavigationBar/Page_Start.dart';

import 'BottomNavigationBar/Page_Search.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  int currentIndex = 0;
  final screens = [
    const StartPage(),
    const SearchPage(),
    const Entdecken(),
    const OwnProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

  }



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false,
          showSelectedLabels: false,
          unselectedItemColor: Colors.grey.withOpacity(0.6),
          selectedItemColor: Colors.black54,
          iconSize: 25,
          items: const [
            BottomNavigationBarItem(
                tooltip: "", icon: Icon(Icons.home_filled), label: "Start"),
            BottomNavigationBarItem(
                tooltip: "", icon: Icon(Icons.search), label: "Suchen"),
            BottomNavigationBarItem(
                tooltip: "",
                icon: Icon(Icons.assessment_outlined),
                label: "Entdecken"),
            BottomNavigationBarItem(
                tooltip: "", icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }
}
