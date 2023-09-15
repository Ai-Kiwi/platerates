import 'dart:convert';

import 'package:Toaster/libs/dataCollect.dart';
import 'package:Toaster/libs/timeMaths.dart';
import 'package:Toaster/libs/userAvatar.dart';
import 'package:Toaster/notifications/appNotificationHandler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    try {
      var textColor = Colors.white;
      if (jsonData['read'] == true) {
        textColor = Colors.grey;
      }

      if (jsonData['action'] == "user_rated_post") {
        var ratingData =
            await dataCollect.getRatingData(jsonData['itemId'], context, true);
        rootItem = ratingData['rootItem'];
        var userData = await dataCollect.getBasicUserData(
            ratingData['ratingPosterId'], context, true);
        var username = userData['username'] as String;

        userImage =
            await dataCollect.getAvatarData(userData["avatar"], context, true);
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
                size: 45,
                roundness: 45,
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
            await dataCollect.getRatingData(jsonData['itemId'], context, true);
        rootItem = ratingData['rootItem'];
        var userData = await dataCollect.getBasicUserData(
            ratingData['ratingPosterId'], context, true);
        var username = userData['username'] as String;

        userImage =
            await dataCollect.getAvatarData(userData["avatar"], context, true);
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
                size: 45,
                roundness: 45,
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
    } catch (err) {
      if (jsonData['read'] == false) {
        //invalid noti and not read so should contact server to mark as read
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
      }
      if (mounted) {
        setState(() {
          insideData = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              UserAvatar(
                avatarImage: null,
                size: 45,
                roundness: 45,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text(
                "item deleted",
                style: TextStyle(color: Colors.red, fontSize: 20),
              )),
            ],
          );
        });
      }
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
              jsonData = await openNotification(notificationData, context);
              setState(() {
                jsonData = jsonData;
              });
              fetchNotificationData();
            }),
      ),
    );
  }
}
