import 'dart:convert';

import 'package:Toaster/libs/userAvatar.dart';
import 'package:Toaster/posts/fullPagePost.dart';
import 'package:Toaster/posts/postRating/fullPageRating.dart';
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
import '../../userProfile/userProfile.dart';

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
  var rootItem;
  var posterAvatar;

  Future<void> _collectData() async {
    //as non of these have returned error it must have found data
    try {
      var jsonData = await dataCollect.getRatingData(ratingId, context);
      Map basicUserData = await dataCollect.getBasicUserData(
          jsonData['ratingPosterId'], context);
      //send an update request could be done bett but is what it is rn
      dataCollect.updateBasicUserData(jsonData['ratingPosterId'], context);

      Map avatarData =
          await dataCollect.getAvatarData(jsonData["avatar"], context);

      setState(() {
        text = jsonData["text"];
        if (jsonData["rating"] != null) {
          rating = jsonData["rating"] + 0.0;
        }
        posterName = basicUserData['username'];
        posterUserId = jsonData['ratingPosterId'];
        rootItem = jsonData['rootItem'];
        childRatingsAmount = jsonData['childRatingsAmount'];
        if (avatarData["imageData"] != null) {
          posterAvatar = base64Decode(avatarData["imageData"]);
        }
      });
      return;
    } catch (err) {
      print(err);
      return;
    }
  }

  Future<void> _collectAndUpdateData() async {
    await _collectData();
    if (await dataCollect.updateRatingData(ratingId, context) == true) {
      await _collectData();
    }
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserProfile(
                                  userId: posterUserId, openedOntopMenu: true)),
                        );
                      },
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
                        Alert(
                          context: context,
                          type: AlertType.success,
                          title: "rating deleted",
                          desc: "refresh page to see",
                          buttons: [
                            DialogButton(
                              onPressed: () {
                                jsonCache.remove('post-${rootItem["data"]}');
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => fullPagePost(
                                            postId: rootItem["data"])));
                              },
                              width: 120,
                              child: const Text(
                                "ok",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            )
                          ],
                        ).show();
                      } else {
                        ErrorHandler.httpError(
                            response.statusCode, response.body, context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                          'failed deleting rating',
                          style: TextStyle(fontSize: 20, color: Colors.red),
                        )));
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
              //const Padding(
              //  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              //  child: Center(
              //      child: Icon(
              //    //plus button
              //    Icons.thumb_up_outlined,
              //    color: Colors.white,
              //  )),
              //),

              const SizedBox(width: 8),
              Column(
                children: [
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
                      decoration: BoxDecoration(
                          color: const Color.fromRGBO(16, 16, 16, 1),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: const Color.fromARGB(215, 45, 45, 45),
                              width: 3)),
                      height: 150,
                      child: ListView(children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                            child: SelectableLinkify(
                              onOpen: (link) async {
                                if (!await launchUrl(Uri.parse(link.url))) {
                                  throw Exception(
                                      'Could not launch ${link.url}');
                                }
                              },
                              text: text,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ))
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
