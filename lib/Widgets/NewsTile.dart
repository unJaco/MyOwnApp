

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_own_app/Model/News.dart';

class NewsTile extends StatelessWidget {
  NewsTile({Key? key, required this.news}) : super(key: key);

  final News news;
  late String timeStampToDisplay;


  final DateFormat format = DateFormat('dd-MM-yyyy');


  @override
  Widget build(BuildContext context) {

    Timestamp timeStamp = news.timestamp;

    int differenceMin = DateTime.now().difference(timeStamp.toDate()).inMinutes;
    int differenceHours = DateTime.now().difference(timeStamp.toDate()).inHours;
    int differenceDays = DateTime.now().difference(timeStamp.toDate()).inDays;

    if (differenceMin == 0) {
      timeStampToDisplay = '<1 min';
    } else if (differenceMin < 60) {
      timeStampToDisplay = '$differenceMin min';
    } else if (differenceHours < 24) {
      timeStampToDisplay = '$differenceHours h';
    } else if (differenceDays < 31) {
      timeStampToDisplay = '$differenceDays d';
    } else {
      final DateTime date = timeStamp.toDate();
      final String formatted = format.format(date);

      timeStampToDisplay = formatted;
    }

    return ListTile(
      title: Column(
        children: [
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(news.name,
                  style: (const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))),
              Text(timeStampToDisplay,
                  style: (const TextStyle(color: Colors.grey, fontSize: 16))),
            ],
          ),
          Row(
            children: [
              Text('@' + news.userName,
                  style: (const TextStyle(color: Colors.grey, fontSize: 15))),
            ],
          ),
        ],
      ),
      subtitle: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Text(news.msg,
                  style: (const TextStyle(color: Colors.black, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
      leading: const CircleAvatar(
        radius: 20,
        backgroundImage: AssetImage("assets/images/Default Profile Pic.png"),
      ),
    );
  }


}
