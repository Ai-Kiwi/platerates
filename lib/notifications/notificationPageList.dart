import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:flutter/material.dart';

class notificationPageList extends StatefulWidget {
  const notificationPageList({super.key});

  @override
  _notificationPageListState createState() => _notificationPageListState();
}

class _notificationPageListState extends State<notificationPageList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromRGBO(16, 16, 16, 1),
      body: LazyLoadPage(
        urlToFetch: "/notification/list",
        widgetAddedToTop: Center(
            child: Column(children: [
          SizedBox(height: 32),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Text(
                "notifications",
                style: TextStyle(color: Colors.white, fontSize: 40),
              )),
          Divider(
            color: Color.fromARGB(255, 110, 110, 110),
            thickness: 1.0,
          ),
        ])),
        widgetAddedToEnd: Center(
            child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              "end of notifications",
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            SizedBox(height: 128),
          ],
        )),
        widgetAddedToBlank: Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Text(
                "no notifications",
                style: TextStyle(color: Colors.white, fontSize: 25),
              )),
        ),
      ),
    );
  }
}
