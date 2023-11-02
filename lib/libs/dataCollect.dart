import 'dart:convert';

import 'package:Toaster/libs/alertSystem.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../login/userLogin.dart';
import 'errorHandler.dart';

class DataCollect {
  Future<void> reportError(
      String errorMessage, String dataGetting, context) async {
    openAlert(
        "error", "failed getting $dataGetting", errorMessage, context, null);
  }

  Future<Map> getData(Map headers, String url, String cacheCode, context,
      bool expectError) async {
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
          await jsonCache.refresh(cacheCode, {
            "data": response.body,
            "lastUpdated": DateTime.timestamp().millisecondsSinceEpoch
          });
        } else {
          ErrorHandler.httpError(response.statusCode, response.body, context);
          if (expectError == false) {
            reportError(response.body, "data", context);
          }
          return {};
        }
      }

      //as non of these have returned error it must have found data
      return jsonData;
    } on Exception catch (error, stackTrace) {
      if (expectError == false) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
      jsonCache.remove(cacheCode);
      return {};
    }
  }

  Future<bool> updateData(Map headers, String url, String cacheCode, context,
      bool expectError, Duration cacheLiveTime) async {
    var dataUpdated = false;
    var headersUsing = headers;
    headersUsing['onlyUpdateChangeable'] = true;

    var cachedData = await jsonCache.value(cacheCode);
    if (cachedData != null) {
      if (cachedData["lastUpdated"] >
          DateTime.timestamp().millisecondsSinceEpoch -
              cacheLiveTime.inMilliseconds) {
        return false;
      }
    }

    final response = await http.post(Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(headers));
    if (response.statusCode == 200) {
      var inputData = await dataCollect.getData(
          headers, url, cacheCode, context, expectError);

      var jsonData = jsonDecode(response.body);

      jsonData.forEach((key, value) {
        if (inputData[key] != value) {
          inputData[key] = value;
          dataUpdated = true;
        }
      });

      await jsonCache.refresh(cacheCode, {
        "data": jsonEncode(inputData),
        "lastUpdated": DateTime.timestamp().millisecondsSinceEpoch
      });
    } else {
      ErrorHandler.httpError(response.statusCode, response.body, context);
      if (expectError == false) {
        reportError(response.body, "updated data", context);
      }
      return false;
    }
    if (dataUpdated == true) {
      print("cache updated for $url stored at $cacheCode");
    }
    return dataUpdated;
  }

  Future<Map> getBasicUserData(String userId, context, expectError) async {
    return getData({
      'token': userManager.token,
      "userId": userId,
    }, "$serverDomain/profile/basicData", 'basicUserData-$userId', context,
        expectError);
  }

  Future<bool> updateBasicUserData(String? userId, context, expectError) async {
    return updateData({
      'token': userManager.token,
      'userId': userId,
    }, "$serverDomain/profile/basicData", 'basicUserData-$userId', context,
        expectError, const Duration(minutes: 15));
  }

  Future<Map> getUserData(String? userId, context, expectError) async {
    return getData({
      'token': userManager.token,
      'userId': userId,
    }, "$serverDomain/profile/data", 'userData-$userId', context, expectError);
  }

  Future<bool> updateUserData(String? userId, context, expectError) async {
    return updateData({
      'token': userManager.token,
      'userId': userId,
    }, "$serverDomain/profile/data", 'userData-$userId', context, expectError,
        const Duration(hours: 24));
  }

  Future<Map> getPostData(String? postId, context, expectError) async {
    return getData({
      'token': userManager.token,
      'postId': postId,
    }, "$serverDomain/post/data", 'post-$postId', context, expectError);
  }

  Future<bool> updatePostData(String? postId, context, expectError) async {
    return updateData({
      'token': userManager.token,
      'postId': postId,
    }, "$serverDomain/post/data", 'post-$postId', context, expectError,
        const Duration(minutes: 15));
  }

  Future<Map> getRatingData(String? ratingId, context, expectError) async {
    return getData({
      'token': userManager.token,
      'ratingId': ratingId,
    }, "$serverDomain/post/rating/data", 'rating-$ratingId', context,
        expectError);
  }

  Future<bool> updateRatingData(String? ratingId, context, expectError) async {
    return updateData({
      'token': userManager.token,
      'ratingId': ratingId,
    }, "$serverDomain/post/rating/data", 'rating-$ratingId', context,
        expectError, const Duration(minutes: 15));
  }

  Future<Map> getAvatarData(String? avatarId, context, expectError) async {
    if (avatarId == null) {
      return {};
    }
    print('sending $avatarId');
    return getData({
      'token': userManager.token,
      'avatarId': avatarId,
    }, "$serverDomain/profile/avatar", 'avatar-$avatarId', context,
        expectError);
  }

  Future<Map> getChatRoomData(String? chatRoomId, context, expectError) async {
    return getData({
      'token': userManager.token,
      'chatRoomId': chatRoomId,
    }, "$serverDomain/chat/roomData", 'chatRoomId-$chatRoomId', context,
        expectError);
  }

  Future<bool> updateChatRoomData(
      String? chatRoomId, context, expectError) async {
    return updateData({
      'token': userManager.token,
      'chatRoomId': chatRoomId,
    }, "$serverDomain/chat/roomData", 'chatRoomId-$chatRoomId', context,
        expectError, const Duration(milliseconds: 0));
  }

  //not had a chance todo for anything yet
  //will add for the following
  //chatroom
  //user settings change
  //really any notifcations
  Future<void> clearCacheForItem(String cacheName) async {
    jsonCache.remove(cacheName);
  }
}

DataCollect dataCollect = DataCollect();
