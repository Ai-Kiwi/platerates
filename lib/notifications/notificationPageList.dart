import 'dart:convert';

import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:Toaster/posts/postRating/userRating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../../libs/errorHandler.dart';
import '../../login/userLogin.dart';
import '../../main.dart';

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
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Text(
                "end of notifications",
                style: TextStyle(color: Colors.white, fontSize: 25),
              )),
        ),
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
