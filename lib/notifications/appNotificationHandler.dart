import 'dart:convert';
import 'dart:math';

import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/dataCollect.dart';
import 'package:Toaster/libs/smoothTransitions.dart';
import 'package:Toaster/login/userLogin.dart';
import 'package:Toaster/main.dart';
import 'package:Toaster/posts/fullPagePost.dart';
import 'package:Toaster/posts/postRating/fullPageRating.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

String openNotificationOnBootData = '';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  var sharedPrefs = await SharedPreferences.getInstance();
  sharedPrefs.setString('notificationOnBootData', '$payload');
}

void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  openNotificationOnBootData = '$payload';

  //await Navigator.push(
  //  context,
  //  MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
  //);
}

//this should have support added for things like group chats
Future<void> sendNotification(
    String title, String description, String openData, String channelId) async {
  AndroidNotificationDetails? androidNotificationDetails;

  if (channelId == "userFollow") {
    androidNotificationDetails =
        AndroidNotificationDetails(channelId, "new follow",
            //following stuff makes sure it plays sound and what not
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
  } else if (channelId == "userRating") {
    androidNotificationDetails =
        AndroidNotificationDetails(channelId, "user rating",
            //following stuff makes sure it plays sound and what not
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
  } else if (channelId == "userComment") {
    androidNotificationDetails =
        AndroidNotificationDetails(channelId, "user commented",
            //following stuff makes sure it plays sound and what not
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
  } else if (channelId == "newMessage") {
    androidNotificationDetails =
        AndroidNotificationDetails(channelId, "new message",
            //following stuff makes sure it plays sound and what not
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
  } else if (channelId == "admin") {
    androidNotificationDetails =
        AndroidNotificationDetails(channelId, "admin notifications",
            //following stuff makes sure it plays sound and what not
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
  }

  if (androidNotificationDetails != null) {
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        Random().nextInt(1000000), title, description, notificationDetails,
        payload: openData);
  } else {
    print("error failed to find channelId $channelId");
  }

  updateUnreadNotificationCount();
}

Future<void> informServerNotificationToken(String? token) async {
  if (userManager.token == '') {
    return; //does nothing as program still being init
  }

  if (token != null) {
    try {
      await http.post(
        Uri.parse("$serverDomain/notification/updateDeviceToken"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': userManager.token,
          'newToken': token,
        }),
      );
    } on Exception catch (error) {
      print(error);
    }

    //  /notification/updateDeviceToken
  }
}

Future<void> initNotificationHandler() async {
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('logo');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    //onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    //onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();

  //await FirebaseMessaging.requestPermission()

  final fcmToken = await FirebaseMessaging.instance.getToken();
  informServerNotificationToken(fcmToken);
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
    informServerNotificationToken(fcmToken);
    // TODO: If necessary send token to application server.

    // Note: This callback is fired at each app startup and whenever a new
    // token is generated.
  }).onError((err) {
    // Error getting token.
  });

  // Handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground Notification: ${message}');
    try {
      Map dataValue = message.data;
      String title = '${dataValue['title']}';
      String desc = '${dataValue['body']}';
      String openData = '${dataValue['notificationId']}';
      String channelId = '${dataValue['channelId']}';

      sendNotification(title, desc, openData, channelId);
    } on Exception catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      print("error with handling Notification data");
    }
  });

  // Handle notifications that are tapped when the app is in the background or terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Background/terminated Notification: ${message}');
    // Handle the notification here (e.g., navigate to a specific screen)
    try {
      Map dataValue = message.data;
      String title = '${dataValue['title']}';
      String desc = '${dataValue['body']}';
      String openData = '${dataValue['notificationId']}';
      String channelId = '${dataValue['channelId']}';

      sendNotification(title, desc, openData, channelId);
    } on Exception catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      print("error with handling Notification data");
    }
  });
}

Future<void> openUserItemContent(perentData, context) async {
  if (perentData["type"] == "rating") {
    Map ratingData =
        await dataCollect.getRatingData(perentData["data"], context, true);
    var rootItem = ratingData['rootItem'];
    if (rootItem != null) {
      await openUserItemContent(rootItem, context);
    }
    Navigator.of(context).push(smoothTransitions
        .slideUp(FullPageRating(ratingId: perentData["data"])));
    return;
  } else if (perentData["type"] == "post") {
    Map postData =
        await dataCollect.getPostData(perentData["data"], context, true);
    var rootItem = postData['rootItem'];
    if (rootItem != null) {
      await openUserItemContent(rootItem, context);
    }
    Navigator.of(context).push(
        smoothTransitions.slideUp(fullPagePost(postId: perentData["data"])));
    return;
  }

  return;
}

Future<Map> openNotification(notificationData, context) async {
  final jsonData = jsonDecode(notificationData);

  if (jsonData['action'] == "user_rated_post") {
    await openUserItemContent({
      "type": "rating",
      "data": jsonData['itemId'],
    }, context);
  } else if (jsonData['action'] == "user_reply_post_rating") {
    await openUserItemContent({
      "type": "rating",
      "data": jsonData['itemId'],
    }, context);
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
  } else {
    openAlert("error", "failed marking notification read", response.body,
        context, null);
  }

  updateUnreadNotificationCount();

  return jsonData;
}
