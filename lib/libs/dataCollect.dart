import 'dart:convert';
import 'dart:ffi';
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
      bool expectError,
      num expireTime) async {
    try {
      var jsonData;
      var extractedData = await jsonCache.value(cacheCode);
      if (extractedData != null) {
        jsonData = jsonDecode(extractedData["data"]);
        //test if it is expired
        if (extractedData["expire"] <
            DateTime.timestamp().millisecondsSinceEpoch) {
          print("cache is old ignoring it");
          jsonData = null;
        }
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
            HttpHeaders.authorizationHeader: userManager.token,
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          // body: jsonEncode(headers),
        );
        if (response.statusCode == 200) {
          //if true do nothing and then it will display
          jsonData = jsonDecode(response.body);
          await jsonCache.refresh(cacheCode, {
            "data": response.body,
            "lastUpdated": DateTime.timestamp().millisecondsSinceEpoch,
            "expire": DateTime.timestamp().millisecondsSinceEpoch + expireTime
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

  Future<void> removeCacheData(String cacheName) async {
    jsonCache.remove(cacheName);
  }

  Future<Map> getBasicUserData(String userId, context, expectError) async {
    return getData(
      {
        "user_id": userId,
      },
      "/profile/basicData",
      'basicUserData-$userId',
      context,
      expectError,
      1000 * 60 * 60 * 24, //lasts a day before expire
    );
  }

  Future<void> clearBasicUserData(String userId) async {
    return removeCacheData('basicUserData-$userId');
  }

  Future<Map> getUserData(String userId, context, expectError) async {
    return getData(
      {
        'user_id': userId,
      },
      "/profile/data",
      'userData-$userId',
      context,
      expectError,
      1000 * 60 * 60 * 24 //lasts a day before expire
      ,
    );
  }

  Future<void> clearUserData(String userId) async {
    return removeCacheData('userData-$userId');
  }

  Future<Map> getPostData(String postId, context, expectError) async {
    return getData(
      {
        'post_id': postId,
      },
      "/post/data",
      'post-$postId',
      context,
      expectError,
      1000 * 60 * 5, //lasts 5m before expire
    );
  }

  Future<void> clearPostData(String postId) async {
    return removeCacheData('post-$postId');
  }

  Future<Map> getRatingData(String ratingId, context, expectError) async {
    return getData(
      {
        'rating_id': ratingId,
      },
      "/post/rating/data",
      'rating-$ratingId',
      context,
      expectError,
      1000 * 60 * 5, //lasts 5m before expire
    );
  }

  Future<void> clearRatingData(String ratingId) async {
    return removeCacheData('rating-$ratingId');
  }

  Future<Map> getAvatarData(String? avatarId, context, expectError) async {
    if (avatarId == null) {
      return {};
    }
    print('sending $avatarId');
    return getData(
      {
        'avatar_id': avatarId,
      },
      "/profile/avatar",
      'avatar-$avatarId',
      context,
      expectError,
      1000 *
          60 *
          60 *
          24 *
          7, //lasts a week before expire, doesn't change really much so can be ages
    );
  }

  Future<Map> getChatRoomData(String chatRoomId, context, expectError) async {
    return getData(
      {
        'chat_room_id': chatRoomId,
      },
      "/chat/roomData",
      'chatRoomId-$chatRoomId',
      context,
      expectError,
      1, //non for the moment as it is gonna cause issues no matter how I do it lol
    );
  }

  Future<Map> getPostImageData(
      String postId, String imageNumber, context, expectError) async {
    return getData(
      {
        "post_id": postId,
        "image_number": imageNumber,
      },
      "/post/image",
      'imageData-$postId-$imageNumber',
      context,
      expectError,
      1000 *
          60 *
          60 *
          24 *
          7, //lasts a week before expire, doesn't change really much so can be ages
    );
  }

  //not had a chance todo for anything yet
  //will add for the following
  //chatroom
  //user settings change
  //really any notifcations
}

DataCollect dataCollect = DataCollect();
