import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../login/userLogin.dart';
import 'errorHandler.dart';

class DataCollect {
  Future<void> reportError(
      String errorMessage, String dataGetting, context) async {
    Alert(
      context: context,
      type: AlertType.error,
      title: "failed getting $dataGetting",
      desc: errorMessage,
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
  }

  Future<Map> getData(
      Map headers, String url, String cacheCode, context) async {
    try {
      var jsonData;
      var extractedData = await jsonCache.value(cacheCode);
      if (extractedData != null) {
        jsonData = jsonDecode(extractedData["data"]);
      }

      if (jsonData == null) {
        final response = await http.post(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(headers),
        );
        if (response.statusCode == 200) {
          //if true do nothing and then it will display
          jsonData = jsonDecode(response.body);
          await jsonCache.refresh(cacheCode, {"data": response.body});
        } else {
          ErrorHandler.httpError(response.statusCode, response.body, context);
          reportError(response.body, "data", context);
          return {};
        }
      }

      //as non of these have returned error it must have found data
      return jsonData;
    } catch (err) {
      jsonCache.remove(cacheCode);
      return {};
    }
  }

  Future<bool> updateData(
      Map headers, String url, String cacheCode, context) async {
    var dataUpdated = false;
    var headersUsing = headers;
    headersUsing['onlyUpdateChangeable'] = true;

    final response = await http.post(Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(headers));
    if (response.statusCode == 200) {
      var inputData =
          await dataCollect.getData(headers, url, cacheCode, context);

      var jsonData = jsonDecode(response.body);

      jsonData.forEach((key, value) {
        if (inputData[key] != value) {
          inputData[key] = value;
          dataUpdated = true;
        }
      });

      await jsonCache.refresh(cacheCode, {"data": jsonEncode(inputData)});
    } else {
      ErrorHandler.httpError(response.statusCode, response.body, context);
      reportError(response.body, "updated data", context);
      return false;
    }
    if (dataUpdated == true) {
      print("cache updated for $url stored at $cacheCode");
    }
    return dataUpdated;
  }

  Future<Map> getBasicUserData(String userId, context) async {
    return getData({
      'token': userManager.token,
      "userId": userId,
    }, "$serverDomain/profile/basicData", 'basicUserData-$userId', context);
  }

  Future<bool> updateBasicUserData(String? userId, context) async {
    return updateData({
      'token': userManager.token,
      'userId': userId,
    }, "$serverDomain/profile/basicData", 'basicUserData-$userId', context);
  }

  Future<Map> getUserData(String? userId, context) async {
    return getData({
      'token': userManager.token,
      'userId': userId,
    }, "$serverDomain/profile/data", 'userData-$userId', context);
  }

  Future<bool> updateUserData(String? userId, context) async {
    return updateData({
      'token': userManager.token,
      'userId': userId,
    }, "$serverDomain/profile/data", 'userData-$userId', context);
  }

  Future<Map> getPostData(String? postId, context) async {
    return getData({
      'token': userManager.token,
      'postId': postId,
    }, "$serverDomain/post/data", 'post-$postId', context);
  }

  Future<bool> updatePostData(String? postId, context) async {
    return updateData({
      'token': userManager.token,
      'postId': postId,
    }, "$serverDomain/post/data", 'post-$postId', context);
  }

  Future<Map> getRatingData(String? ratingId, context) async {
    return getData({
      'token': userManager.token,
      'ratingId': ratingId,
    }, "$serverDomain/post/rating/data", 'rating-$ratingId', context);
  }

  Future<bool> updateRatingData(String? ratingId, context) async {
    return updateData({
      'token': userManager.token,
      'ratingId': ratingId,
    }, "$serverDomain/post/rating/data", 'rating-$ratingId', context);
  }

  Future<Map> getAvatarData(String? avatarId, context) async {
    print('sending $avatarId');
    return getData({
      'token': userManager.token,
      'avatarId': avatarId,
    }, "$serverDomain/profile/avatar", 'avatar-$avatarId', context);
  }
}

DataCollect dataCollect = DataCollect();
