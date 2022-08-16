import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_own_app/Utils/Textstyle.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SearchState();
}

class SearchState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(15, 35, 15, 15),
              child: CupertinoSearchTextField(
                placeholder: 'Suchen',
                placeholderStyle: const TextStyle(color: Colors.black54),
                itemColor: Colors.black54,
                onChanged: (value) {},
                onSubmitted: (value) {
                  (value);
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
              child: AppLargeText(text: "Bekannte Inhalte"),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
