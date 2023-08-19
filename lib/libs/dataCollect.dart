import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../login/userLogin.dart';
import 'errorHandler.dart';

class DataCollect {
  Future<Map> getBasicUserData(String userId, context) async {
    var jsonData;
    var extractedData = await jsonCache.value('basicUserData-$userId');
    if (extractedData != null) {
      jsonData = jsonDecode(extractedData["data"]);
      if (jsonData["expireTime"] == null) {
        jsonData["expireTime"] = 0;
      }
      if (jsonData["expireTime"] as num <
          (DateTime.now().second - (60 * 60 * 24))) {
        //expires after 1 day
        jsonData = null;
      }
    }

    if (jsonData == null) {
      final response = await http.post(
        Uri.parse("$serverDomain/profile/basicData"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': userManager.token,
          "userId": userId,
        }),
      );
      if (response.statusCode == 200) {
        //if true do nothing and then it will display
        jsonData = jsonDecode(response.body);
        await jsonCache.refresh('basicUserData-$userId',
            {"data": response.body, "expireTime": DateTime.now().second});
      } else {
        ErrorHandler.httpError(response.statusCode, response.body, context);
        Alert(
          context: context,
          type: AlertType.error,
          title: "failed getting basic user data",
          desc: response.body,
          buttons: [
            DialogButton(
              onPressed: () => Navigator.pop(context),
              width: 120,
              child: const Text(
                "ok",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          ],
        ).show();
        return {
          "username": "",
          "averagePostRating": "",
        };
      }
    }

    //as non of these have returned error it must have found data
    return {
      "username": jsonData["username"],
      "averagePostRating": jsonData["averagePostRating"],
    };
  }

  Future<Map> getUserData(String? userId, context) async {
    var jsonData;
    var extractedData = await jsonCache.value('userData-$userId');
    if (extractedData != null) {
      jsonData = jsonDecode(extractedData["data"]);
      if (jsonData["expireTime"] == null) {
        jsonData["expireTime"] = 0;
      }
      if (jsonData["expireTime"] as num <
          (DateTime.now().second - (60 * 60 * 24))) {
        //expires after 1 day
        jsonData = null;
      }
    }

    if (jsonData == null) {
      final response = await http.post(
        Uri.parse("$serverDomain/profile/data"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'token': userManager.token,
          'userId': userId,
        }),
      );
      if (response.statusCode == 200) {
        //if true do nothing and then it will display
        jsonData = jsonDecode(response.body);
        await jsonCache.refresh('userData-$userId',
            {"data": response.body, "expireTime": DateTime.now().second});
      } else {
        ErrorHandler.httpError(response.statusCode, response.body, context);
        Alert(
          context: context,
          type: AlertType.error,
          title: "failed getting user data",
          desc: response.body,
          buttons: [
            DialogButton(
              onPressed: () => Navigator.pop(context),
              width: 120,
              child: const Text(
                "ok",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          ],
        ).show();
        return {
          "bio": "",
          "username": "",
          "administrator": "",
          "userId": "userId",
        };
      }
    }

    //as non of these have returned error it must have found data
    return {
      "bio": jsonData["bio"],
      "username": jsonData["username"],
      "administrator": jsonData["administrator"],
      "userId": jsonData["userId"],
    };
  }
}

DataCollect dataCollect = DataCollect();
