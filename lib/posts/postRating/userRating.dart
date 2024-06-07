import 'dart:convert';
import 'dart:io';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/timeMaths.dart';
import 'package:PlateRates/libs/userAvatar.dart';
import 'package:PlateRates/notifications/appNotificationHandler.dart';
import 'package:PlateRates/posts/fullPagePost.dart';
import 'package:PlateRates/posts/postRating/fullPageRating.dart';
import 'package:PlateRates/userProfile/userProfile.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../libs/dataCollect.dart';
import '../../libs/errorHandler.dart';
import '../../libs/report.dart';
import '../../libs/smoothTransitions.dart';
import '../../main.dart';
import '../../login/userLogin.dart';

class userRating extends StatefulWidget {
  final String ratingId;
  final bool clickable;
  final bool openFullContentTree;

  userRating({
    super.key,
    required this.ratingId,
    required this.clickable,
    required this.openFullContentTree,
  });

  @override
  _userRatingState createState() => _userRatingState(
      ratingId: ratingId,
      clickable: clickable,
      openFullContentTree: openFullContentTree);
}

class _userRatingState extends State<userRating> {
  final String ratingId;
  final bool clickable;
  String text = "";
  String posterName = "";
  String posterUserId = "";
  double? rating;
  int? childRatingsAmount;
  int? ratingLikes;
  bool? ratingLiked;
  var rootItem;
  var posterAvatar;
  final bool openFullContentTree;
  int? creationDate;

  Future<void> _collectData() async {
    //as non of these have returned error it must have found data
    try {
      var jsonData = await dataCollect.getRatingData(ratingId, context, false);
      // ignore: use_build_context_synchronously
      Map basicUserData = await dataCollect.getBasicUserData(
          jsonData['ratingPosterId'], context, false);
      Map avatarData = await dataCollect.getAvatarData(
          basicUserData["avatar"], context, false);

      setState(() {
        text = jsonData["text"];
        if (jsonData["rating"] != null) {
          rating = double.parse(jsonData["rating"]) + 0.0;
        }
        posterName = basicUserData['username'];
        posterUserId = jsonData['ratingPosterId'];
        rootItem = {
          "data": jsonData['rootItemData'],
          "type": jsonData['rootItemType'],
        };
        childRatingsAmount = jsonData['childRatingsAmount'];
        ratingLikes = jsonData['ratingLikes'];
        creationDate = jsonData["creationDate"];
        if (avatarData["imageData"] != null) {
          posterAvatar = base64Decode(avatarData["imageData"]);
        }
        ratingLiked = jsonData['requesterLiked'];
      });
      return;
    } catch (err, stackTrace) {
      FirebaseCrashlytics.instance.recordError(err, stackTrace);
      print(err);
      return;
    }
  }

  Future<void> _toggleLike() async {
    var newLikeState = !(ratingLiked ?? false);
    final response = await http.post(
      Uri.parse('$serverDomain/post/rating/like'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "token": userManager.token,
        "liking": newLikeState,
        "rating_id": ratingId
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        ratingLiked = newLikeState;
      });
      //await dataCollect.clear
      //await _collectData();
    } else {
      openAlert(
          "error", "failed liking comment", response.body, context, null, null);
    }
  }

  @override
  void initState() {
    super.initState();
    _collectData();
  }

  _userRatingState(
      {required this.ratingId,
      required this.clickable,
      required this.openFullContentTree});

  @override
  Widget build(BuildContext context) {
    return Padding(
      //post item
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: GestureDetector(
        child: Column(children: [
          Row(
            //top feild
            children: [
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                  child: Center(
                    //child: CircleAvatar(),
                    child: UserAvatar(
                      avatarImage: posterAvatar,
                      size: 45,
                      roundness: 25,
                      onTapFunction: 'openProfile',
                      context: context,
                      userId: posterUserId,
                    ),
                  )),
              Expanded(
                //name and rating
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        maintainState: false,
                        visible: rating != null,
                        child: const SizedBox(height: 8),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserProfile(
                                    userId: posterUserId,
                                    openedOntopMenu: true)),
                          );
                        },
                        child: Text(
                          posterName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                          "${timeMaths.SingleLongFormatDuration(creationDate == null ? 0 : (DateTime.now().millisecondsSinceEpoch - creationDate!))} ago",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          )),
                      Visibility(
                          maintainState: false,
                          visible: rating != null,
                          child: RatingBarIndicator(
                            rating: rating ?? 0,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 25.0,
                            direction: Axis.horizontal,
                          )),
                    ]),
              ),
              FittedBox(
                //3 dots on post
                child: Center(
                    child: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 35, // Adjust the size of the icon
                    color: Colors.grey[500],
                  ),
                  onPressed: () {
                    openAlert("custom_buttons", "select action for message",
                        null, context, null, [
                      Visibility(
                        visible: posterUserId == userManager.userId,
                        child: DialogButton(
                          color: Colors.red,
                          child: const Text(
                            'delete',
                            style:
                                TextStyle(fontSize: 16.0, color: Colors.white),
                          ),
                          onPressed: () async {
                            final response = await http.post(
                              Uri.parse(
                                  "$serverDomain/post/rating/delete?rating_id=$ratingId"),
                              headers: <String, String>{
                                'Content-Type':
                                    'application/json; charset=UTF-8',
                                HttpHeaders.authorizationHeader:
                                    userManager.token
                              },
                              body: jsonEncode(<String, String>{}),
                            );
                            if (response.statusCode == 200) {
                              openAlert("error", "rating deleted", null,
                                  context, null, null);
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => fullPagePost(
                                          postId: rootItem["data"])));
                            } else {
                              ErrorHandler.httpError(
                                  response.statusCode, response.body, context);
                              openAlert("error", "failed deleting rating",
                                  response.body, context, null, null);
                            }
                          },
                        ),
                      ),
                      DialogButton(
                        color: Colors.red,
                        child: const Text(
                          'report 🚩',
                          style: TextStyle(fontSize: 16.0, color: Colors.white),
                        ),
                        onPressed: () async {
                          reportSystem.reportItem(
                              context, "post_rating", ratingId);
                        },
                      ),
                      DialogButton(
                        child: const Text(
                          'copyId',
                          style: TextStyle(fontSize: 16.0, color: Colors.white),
                        ),
                        onPressed: () async {
                          Clipboard.setData(ClipboardData(text: posterUserId));
                        },
                      ),
                    ]);
                  },
                )),
              ),
            ],
          ),
          Row(
            //bottom feild
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 8),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      child: Center(
                        child: ratingLiked == true
                            ? const Icon(
                                //plus button
                                Icons.thumb_up,
                                color: Colors.white,
                              )
                            : const Icon(
                                //plus button
                                Icons.thumb_up_outlined,
                                color: Colors.white,
                              ),
                      ),
                      onTap: () {
                        setState(() {
                          _toggleLike();
                        });
                      },
                    ),
                  ),
                  //Padding(
                  //  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  //  child: Center(
                  //    child: IconButton(
                  //      icon: ratingLiked == true
                  //          ? const Icon(
                  //              //plus button
                  //              Icons.thumb_up,
                  //              color: Colors.white,
                  //            )
                  //          : const Icon(
                  //              //plus button
                  //              Icons.thumb_up_outlined,
                  //              color: Colors.white,
                  //            ),
                  //      tooltip: 'like comment',
                  //      onPressed: () {
                  //        setState(() {
                  //          _toggleLike();
                  //        });
                  //      },
                  //    ),
                  //  ),
                  //),
                  Text(numberFormatter.format(ratingLikes ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      )),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                        child: Icon(
                      //plus button
                      Icons.reply,
                      color: Colors.white,
                    )),
                  ),
                  Text(numberFormatter.format(childRatingsAmount ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      )),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                  //text for rating
                  child: Container(
                      height: 150,
                      child: ListView(padding: EdgeInsets.zero, children: [
                        SelectableLinkify(
                          onOpen: (link) async {
                            if (!await launchUrl(Uri.parse(link.url))) {
                              throw Exception('Could not launch ${link.url}');
                            }
                          },
                          text: text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                        )
                      ])))
            ],
          ),
        ]),
        onTap: () {
          if (clickable == true) {
            if (openFullContentTree == true) {
              openUserItemContent({
                "type": "rating",
                "data": ratingId,
              }, context);
            } else {
              Navigator.of(context).push(smoothTransitions
                  .slideUp(FullPageRating(ratingId: ratingId)));
            }
          }
        },
      ),
    );
  }
}
