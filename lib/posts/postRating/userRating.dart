import 'dart:convert';

import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/userAvatar.dart';
import 'package:Toaster/posts/fullPagePost.dart';
import 'package:Toaster/posts/postRating/fullPageRating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
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

  userRating({
    super.key,
    required this.ratingId,
    required this.clickable,
  });

  @override
  _userRatingState createState() =>
      _userRatingState(ratingId: ratingId, clickable: clickable);
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
          rating = jsonData["rating"] + 0.0;
        }
        posterName = basicUserData['username'];
        posterUserId = jsonData['ratingPosterId'];
        rootItem = jsonData['rootItem'];
        childRatingsAmount = jsonData['childRatingsAmount'];
        ratingLikes = jsonData['ratingLikes'];
        if (avatarData["imageData"] != null) {
          posterAvatar = base64Decode(avatarData["imageData"]);
        }
        ratingLiked = jsonData['relativeViewerData']['userLiked'];
      });
      return;
    } catch (err) {
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
        "ratingId": ratingId
      }),
    );
    if (response.statusCode == 200) {
      //setState(() {
      //  userFollowing = newFollowState;
      //});
      await _collectAndUpdateData();
    } else {}
  }

  Future<void> _collectAndUpdateData() async {
    //fixes mounting error having try here, am too lazy to fix myself
    try {
      await _collectData();
      if (await dataCollect.updateRatingData(ratingId, context, false) ==
              true ||
          await dataCollect.updateBasicUserData(posterUserId, context, false) ==
              true) {
        await _collectData();
      }
    } on Error {}
  }

  @override
  void initState() {
    super.initState();
    _collectAndUpdateData();
  }

  _userRatingState({required this.ratingId, required this.clickable});

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
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        posterName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
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
                    child: PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 35, // Adjust the size of the icon
                    color: Colors.grey[500],
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final response = await http.post(
                        Uri.parse("$serverDomain/post/rating/delete"),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: jsonEncode(<String, String>{
                          'token': userManager.token,
                          'ratingId': ratingId,
                        }),
                      );
                      if (response.statusCode == 200) {
                        openAlert(
                            "error", "rating deleted", null, context, null);
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    fullPagePost(postId: rootItem["data"])));
                      } else {
                        ErrorHandler.httpError(
                            response.statusCode, response.body, context);
                        openAlert("error", "failed deleting rating", null,
                            context, null);
                      }
                    } else if (value == 'report') {
                      reportSystem.reportItem(context, "post_rating", ratingId);
                    } else if (value == 'copyId') {
                      Clipboard.setData(ClipboardData(text: posterUserId));
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'copyId',
                        child: Text(
                          'copy id to clipboard',
                          style:
                              TextStyle(color: Color.fromARGB(255, 45, 45, 45)),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Text(
                          'report 🚩',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ];
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
                  Text((ratingLikes ?? "").toString(),
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
                  Text((childRatingsAmount ?? "").toString(),
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
            Navigator.of(context).push(
                smoothTransitions.slideUp(FullPageRating(ratingId: ratingId)));
          }
        },
      ),
    );
  }
}
