import 'dart:convert';

import 'package:Toaster/libs/dataCollect.dart';
import 'package:Toaster/posts/fullPagePost.dart';
import 'package:Toaster/posts/postRating/fullPageRating.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../libs/smoothTransitions.dart';
import '../login/userLogin.dart';
import '../main.dart';

class notificationBarItem extends StatefulWidget {
  final notificationData;

  const notificationBarItem({required this.notificationData});

  @override
  State<notificationBarItem> createState() =>
      _notificationBarItemState(notificationData: notificationData);
}

class _notificationBarItemState extends State<notificationBarItem> {
  final notificationData;
  Widget insideData = const Center(
    child: CircularProgressIndicator(),
  );
  var rootItem;

  Future<void> fetchNotificationData() async {
    var jsonData = jsonDecode(notificationData);
    var textColor = Colors.white;
    if (jsonData['read'] == true) {
      textColor = Colors.grey;
    }

    if (jsonData['action'] == "user_rated_post") {
      var ratingData =
          await dataCollect.getRatingData(jsonData['itemId'], context);
      rootItem = ratingData['rootItem'];
      var userData = await dataCollect.getBasicUserData(
          ratingData['ratingPosterId'], context);
      var username = userData['username'] as String;
      setState(() {
        insideData = Text(
          "${username} responded to your post",
          style: TextStyle(color: textColor, fontSize: 25),
        );
      });
    } else if (jsonData['action'] == "user_reply_post_rating") {
      var ratingData =
          await dataCollect.getRatingData(jsonData['itemId'], context);
      rootItem = ratingData['rootItem'];
      var userData = await dataCollect.getBasicUserData(
          ratingData['ratingPosterId'], context);
      var username = userData['username'] as String;

      setState(() {
        insideData = Text(
          "${username} responded to your rating",
          style: TextStyle(color: textColor, fontSize: 25),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNotificationData();
  }

  _notificationBarItemState({required this.notificationData});

  @override
  Widget build(BuildContext context) {
    var jsonData = jsonDecode(notificationData);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
              width: 2, color: const Color.fromARGB(255, 45, 45, 45)),
        ),
        width: double.infinity,
        child: GestureDetector(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: insideData),
            onTap: () {
              if (rootItem != null) {
                if (jsonData['action'] == "user_rated_post") {
                  Navigator.of(context).push(smoothTransitions
                      .slideUp(fullPagePost(postId: rootItem['data'])));
                  Navigator.of(context).push(smoothTransitions
                      .slideUp(FullPageRating(ratingId: jsonData['itemId'])));
                } else if (jsonData['action'] == "user_reply_post_rating") {
                  Navigator.of(context).push(smoothTransitions
                      .slideUp(FullPageRating(ratingId: rootItem['data'])));
                  Navigator.of(context).push(smoothTransitions
                      .slideUp(FullPageRating(ratingId: jsonData['itemId'])));
                }

                http.post(
                  Uri.parse("$serverDomain/post/rating/delete"),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, String>{
                    'token': userManager.token,
                    'notificationId': jsonData['notificationId'],
                  }),
                );
              }
            }),
      ),
    );
  }
}
