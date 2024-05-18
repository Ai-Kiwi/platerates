import 'dart:convert';
import 'dart:io';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../login/userLogin.dart';
import 'errorHandler.dart';

class DataCollect {
  Future<void> reportError(
      String errorMessage, String dataGetting, context) async {
    openAlert("error", "failed getting $dataGetting", errorMessage, context,
        null, null);
  }

  Future<Map> getData(
      //can also support Iterable
      Map<String, String> headers,
      String url,
      String cacheCode,
      context,
      bool expectError) async {
    try {
      var jsonData;
      var extractedData = await jsonCache.value(cacheCode);
      if (extractedData != null) {
        jsonData = jsonDecode(extractedData["data"]);
      }

      if (jsonData == null) {
        var subbedServerDomain = serverDomain.substring(0, 5);
        var justDomainUrl;
        if (subbedServerDomain == "https") {
          justDomainUrl = Uri.https(serverDomain.substring(8), url, headers);
        } else {
          justDomainUrl = Uri.http(serverDomain.substring(7), url, headers);
        }

        //var fullUrl = Uri.https(subbedServerDomain, url, headers);
        final response = await http.get(
          justDomainUrl,
          headers: <String, String>{
            HttpHeaders.authorizationHeader: 'Token ${userManager.token}',
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          // body: jsonEncode(headers),
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

  Future<bool> updateData(
      //can also support Iterable
      Map<String, String> headers,
      String url,
      String cacheCode,
      context,
      bool expectError,
      Duration cacheLiveTime) async {
    var dataUpdated = false;
    var headersUsing = headers;
    //this also needs to be changed to a string from a bool when added back
    //headersUsing['onlyUpdateChangeable'] = true;

    var cachedData = await jsonCache.value(cacheCode);
    if (cachedData != null) {
      if (cachedData["lastUpdated"] >
          DateTime.timestamp().millisecondsSinceEpoch -
              cacheLiveTime.inMilliseconds) {
        return false;
      }
    }

    var subbedServerDomain = serverDomain.substring(0, 5);
    var justDomainUrl;
    if (subbedServerDomain == "https") {
      justDomainUrl = Uri.https(serverDomain.substring(8), url, headers);
    } else {
      justDomainUrl = Uri.http(serverDomain.substring(7), url, headers);
    }

    final response = await http.get(
      justDomainUrl,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Token ${userManager.token}',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );
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
    return true;
  }

  Future<Map> getBasicUserData(String userId, context, expectError) async {
    return getData({
      "userId": userId,
    }, "/profile/basicData", 'basicUserData-$userId', context, expectError);
  }

  Future<bool> updateBasicUserData(String userId, context, expectError) async {
    return updateData({
      'userId': userId,
    }, "/profile/basicData", 'basicUserData-$userId', context, expectError,
        const Duration(minutes: 15));
  }

  Future<Map> getUserData(String userId, context, expectError) async {
    return getData({
      'userId': userId,
    }, "/profile/data", 'userData-$userId', context, expectError);
  }

  Future<bool> updateUserData(String userId, context, expectError) async {
    return updateData({
      'userId': userId,
    }, "/profile/data", 'userData-$userId', context, expectError,
        const Duration(hours: 24));
  }

  Future<Map> getPostData(String postId, context, expectError) async {
    return getData({
      'postId': postId,
    }, "/post/data", 'post-$postId', context, expectError);
  }

  Future<bool> updatePostData(String postId, context, expectError) async {
    return updateData({
      'postId': postId,
    }, "/post/data", 'post-$postId', context, expectError,
        const Duration(minutes: 15));
  }

  Future<Map> getRatingData(String ratingId, context, expectError) async {
    return getData({
      'ratingId': ratingId,
    }, "/post/rating/data", 'rating-$ratingId', context, expectError);
  }

  Future<bool> updateRatingData(String ratingId, context, expectError) async {
    return updateData({
      'ratingId': ratingId,
    }, "/post/rating/data", 'rating-$ratingId', context, expectError,
        const Duration(minutes: 15));
  }

  Future<Map> getAvatarData(String? avatarId, context, expectError) async {
    if (avatarId == null) {
      return {};
    }
    print('sending $avatarId');
    return getData({
      'avatar_id': avatarId,
    }, "/profile/avatar", 'avatar-$avatarId', context, expectError);
  }

  Future<Map> getChatRoomData(String chatRoomId, context, expectError) async {
    return getData({
      'chatRoomId': chatRoomId,
    }, "/chat/roomData", 'chatRoomId-$chatRoomId', context, expectError);
  }

  Future<bool> updateChatRoomData(
      String chatRoomId, context, expectError) async {
    return updateData({
      'chatRoomId': chatRoomId,
    }, "/chat/roomData", 'chatRoomId-$chatRoomId', context, expectError,
        const Duration(milliseconds: 0));
  }

  Future<Map> getPostImageData(
      String postId, String imageNumber, context, expectError) async {
    return getData({
      "postId": postId,
      "imageNumber": imageNumber,
    }, "/post/image", 'imageData-$postId-$imageNumber', context, expectError);
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
