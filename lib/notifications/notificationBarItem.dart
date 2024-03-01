import 'dart:convert';

import 'package:PlateRates/libs/dataCollect.dart';
import 'package:PlateRates/libs/timeMaths.dart';
import 'package:PlateRates/libs/userAvatar.dart';
import 'package:PlateRates/notifications/appNotificationHandler.dart';
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
  var rootItem;
  var jsonData;

  var userImageData;
  var notificationText = "";
  var notificationTextColor = Colors.white;
  var itemDeleted = false;

  String? notificationCreaterId;

  Future<void> fetchNotificationData() async {
    try {
      if (jsonData['action'] == "user_rated_post") {
        var ratingData =
            await dataCollect.getRatingData(jsonData['itemId'], context, true);
        rootItem = ratingData['rootItem'];
        var userData = await dataCollect.getBasicUserData(
            ratingData['ratingPosterId'], context, true);
        notificationCreaterId = ratingData['ratingPosterId'];
        var username = userData['username'] as String;

        var userImage =
            await dataCollect.getAvatarData(userData["avatar"], context, true);

        setState(() {
          if (userImage["imageData"] != null) {
            userImageData = base64Decode(userImage["imageData"]);
          }
          notificationText = "${username} responded to your post";
          if (jsonData['read'] == false) {
            notificationTextColor = Colors.white;
          } else {
            notificationTextColor = Colors.grey;
          }
        });
      } else if (jsonData['action'] == "user_reply_post_rating") {
        var ratingData =
            await dataCollect.getRatingData(jsonData['itemId'], context, true);
        rootItem = ratingData['rootItem'];
        var userData = await dataCollect.getBasicUserData(
            ratingData['ratingPosterId'], context, true);
        notificationCreaterId = ratingData['ratingPosterId'];
        var username = userData['username'] as String;

        var userImage =
            await dataCollect.getAvatarData(userData["avatar"], context, true);

        setState(() {
          if (userImage["imageData"] != null) {
            userImageData = base64Decode(userImage["imageData"]);
          }
          notificationText = "${username} responded to your rating";
          if (jsonData['read'] == false) {
            notificationTextColor = Colors.white;
          } else {
            notificationTextColor = Colors.grey;
          }
        });
      }
    } catch (err) {
      if (jsonData['read'] == false) {
        //invalid noti and not read so should contact server to mark as read
        await http.post(
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
          itemDeleted = true;
          notificationText = "item deleted";
          notificationTextColor = Colors.red;
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      UserAvatar(
                        avatarImage: userImageData,
                        size: 45,
                        roundness: 45,
                        onTapFunction: null,
                        context: context,
                        userId: notificationCreaterId,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                        notificationText,
                        style: TextStyle(
                            color: notificationTextColor, fontSize: 20),
                      )),
                    ],
                  ),
                ),
                Text(
                  timeMaths.shortFormatDuration(
                      DateTime.now().millisecondsSinceEpoch -
                          (jsonData['sentDate'] as int)),
                  style: TextStyle(color: notificationTextColor, fontSize: 32),
                ),
              ],
            ),
            onTap: () async {
              if (itemDeleted == false) {
                jsonData = await openNotification(notificationData, context);
                setState(() {
                  jsonData = jsonData;
                });
                fetchNotificationData();
              }
            }),
      ),
    );
  }
}
