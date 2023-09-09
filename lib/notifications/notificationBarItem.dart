import 'dart:convert';

import 'package:Toaster/libs/dataCollect.dart';
import 'package:Toaster/libs/timeMaths.dart';
import 'package:Toaster/libs/userAvatar.dart';
import 'package:Toaster/posts/fullPagePost.dart';
import 'package:Toaster/posts/postRating/fullPageRating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
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
  var jsonData;
  var userImage;

  Future<void> fetchNotificationData() async {
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

      userImage = await dataCollect.getAvatarData(userData["avatar"], context);
      var image;
      if (userImage["imageData"] != null) {
        image = base64Decode(userImage["imageData"]);
      }

      setState(() {
        insideData = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            UserAvatar(
              avatarImage: image,
              size: 35,
              roundness: 35,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
              "${username} responded to your post",
              style: TextStyle(color: textColor, fontSize: 20),
            )),
          ],
        );
      });
    } else if (jsonData['action'] == "user_reply_post_rating") {
      var ratingData =
          await dataCollect.getRatingData(jsonData['itemId'], context);
      rootItem = ratingData['rootItem'];
      var userData = await dataCollect.getBasicUserData(
          ratingData['ratingPosterId'], context);
      var username = userData['username'] as String;

      userImage = await dataCollect.getAvatarData(userData["avatar"], context);
      var image;
      if (userImage["imageData"] != null) {
        image = base64Decode(userImage["imageData"]);
      }

      setState(() {
        insideData = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            UserAvatar(
              avatarImage: image,
              size: 35,
              roundness: 35,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
              "${username} responded to your rating",
              style: TextStyle(color: textColor, fontSize: 20),
            )),
          ],
        );
      });
    }
  }

  @override
  void initState() {
    jsonData = jsonDecode(notificationData);
    super.initState();
    fetchNotificationData();
  }

  _notificationBarItemState({required this.notificationData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
      child: Container(
        width: double.infinity,
        child: GestureDetector(
            child: Row(
              children: [
                Expanded(
                  child: insideData,
                ),
                Text(
                  timeMaths.shortFormatDuration(
                      DateTime.now().millisecondsSinceEpoch -
                          (jsonData['sentDate'] as int)),
                  style: TextStyle(color: Colors.white, fontSize: 32),
                ),
              ],
            ),
            onTap: () async {
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

                var response = await http.post(
                  Uri.parse("$serverDomain/notification/read"),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, String>{
                    'token': userManager.token,
                    'notificationId': jsonData['notificationId'],
                  }),
                );

                if (response.statusCode == 200) {
                  jsonData['read'] = true;
                  fetchNotificationData();
                } else {
                  Alert(
                    context: context,
                    type: AlertType.error,
                    title: "error marking notification read",
                    desc: response.body,
                    buttons: [
                      DialogButton(
                        child: Text(
                          "ok",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                        width: 120,
                      )
                    ],
                  ).show();
                }
              }
            }),
      ),
    );
  }
}
