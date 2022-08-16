import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Model/News.dart';
import 'package:my_own_app/Provider/UserProvider.dart';
import 'package:my_own_app/Utils/Textstyle.dart';
import 'package:my_own_app/Widgets/NewsTile.dart';
import 'package:provider/provider.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {

  final firestore = FirebaseFirestore.instance;
  late String uid;

  List<News> newsList = [];

  @override
  Widget build(BuildContext context) {

    uid = context.read<UserProvider>().uid!;
    firestore.collection('User').doc(uid).collection('News').doc('unreadNews').update({'count' : 0});

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: AppLargeText(text: 'Neuigkeiten'),
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
        body: _buildBody(context)
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();

  }

  Widget _buildBody(BuildContext context) {
    final Stream<QuerySnapshot> newsStream = firestore.collection('User').doc(
        uid).collection('News').snapshots();

    return StreamBuilder(
        stream: newsStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot){
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if(snapshot.data!.docs.isEmpty){
            return const Center(child: Text('Keine Neuigkeiten'));
          }

          List<News?> list = snapshot.data!.docs.map((doc) {
            if(doc.id != 'unreadNews'){
              return News.fromSnap(doc);
            }
            return null;
          }).toList();
          list.removeWhere((element) => element == null);
          list.sort((n1, n2) {
            Timestamp t1 = n1!.timestamp;
            Timestamp t2 = n2!.timestamp;

            return t2.compareTo(t1);
          });
          Set set = list.toSet();
          set.removeWhere((element) => element == null);
          return ListView(
            children: set.map((element) {
              return NewsTile(news: element!);
            }).toList()
          );
    });
  }
}
