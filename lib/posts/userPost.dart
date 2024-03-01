import 'dart:convert';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/dataCollect.dart';
import 'package:PlateRates/libs/smoothTransitions.dart';
import 'package:PlateRates/libs/timeMaths.dart';
import 'package:PlateRates/libs/userAvatar.dart';
import 'package:PlateRates/notifications/appNotificationHandler.dart';
import 'package:PlateRates/posts/fullPagePost.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:PlateRates/userProfile/userProfile.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:url_launcher/url_launcher.dart';
import '../libs/errorHandler.dart';
import '../libs/report.dart';
import '../main.dart';

class PostItem extends StatefulWidget {
  final String postId;
  final bool clickable;
  final bool openFullContentTree;

  const PostItem(
      {super.key,
      required this.postId,
      required this.clickable,
      required this.openFullContentTree});

  @override
  _PostItemState createState() => _PostItemState(
      clickable: clickable,
      postId: postId,
      openFullContentTree: openFullContentTree);
}

class _PostItemState extends State<PostItem> {
  String postId;
  final bool clickable;
  final bool openFullContentTree;
  String title = "";
  String description = "";
  double rating = 0;
  String posterName = "";
  int? postDate;
  int ratingsAmount = 0;
  bool? hasRated = true;
  var posterAvatar;
  String posterUserId = "";
  var imageData;
  bool errorOccurred = false;
  bool? viewerIsCreator;

  _PostItemState(
      {required this.postId,
      required this.clickable,
      required this.openFullContentTree});

  Future<void> _collectData() async {
    //as non of these have returned error it must have found data
    try {
      var jsonData = await dataCollect.getPostData(postId, context, false);
      Map basicUserData = await dataCollect.getBasicUserData(
          jsonData['posterId'], context, false);
      dataCollect.updateBasicUserData(jsonData['posterId'], context, false);
      print(basicUserData);
      Map avatarData = await dataCollect.getAvatarData(
          basicUserData["avatar"], context, false);

      //print(basicUserData);
      setState(() {
        title = jsonData["title"];
        description = jsonData["description"];
        rating = double.parse('${jsonData["rating"]}');
        imageData = base64Decode(jsonData['imageData']);
        posterName = basicUserData["username"];
        posterUserId = jsonData['posterId'];
        postDate = jsonData['postDate'];
        ratingsAmount = int.parse(jsonData['ratingsAmount']);
        viewerIsCreator = jsonData["relativeViewerData"]["viewerIsCreator"];
        // ignore: sdk_version_since
        hasRated = bool.tryParse(jsonData['requesterRated']);
        errorOccurred = false;
        if (avatarData["imageData"] != null) {
          posterAvatar = base64Decode(avatarData["imageData"]);
        }
      });
      return;
    } catch (err, stackTrace) {
      FirebaseCrashlytics.instance.recordError(err, stackTrace);
      print(err);
      return;
    }
  }

  Future<void> _collectDataAndUpdate() async {
    //as non of these have returned error it must have found data
    try {
      await _collectData();
      if (await dataCollect.updatePostData(postId, context, false) == true) {
        await _collectData();
      }
    } catch (err, stackTrace) {
      FirebaseCrashlytics.instance.recordError(err, stackTrace);
      print(err);
    }
  }

  @override
  void initState() {
    super.initState();
    //no idea why the hell the error happens but this if statement fixes it
    if (mounted && title.isEmpty) {
      _collectDataAndUpdate();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (errorOccurred == true) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: Container(
              decoration:
                  const BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
              child: const Center(
                  child: Text(
                "error getting post",
                style: TextStyle(color: Colors.red, fontSize: 20),
              ))));
    } else {
      return GestureDetector(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Container(
              color: Colors.transparent,
              child: Column(children: <Widget>[
                //user logo and name
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                        height: 35,
                        child: Row(children: <Widget>[
                          Flexible(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 8),
                                  UserAvatar(
                                    avatarImage: posterAvatar,
                                    size: 35,
                                    roundness: 35,
                                    onTapFunction: 'openProfile',
                                    context: context,
                                    userId: posterUserId,
                                  ),
                                  const SizedBox(width: 4),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    UserProfile(
                                                        userId: posterUserId,
                                                        openedOntopMenu: true)),
                                          );
                                        },
                                        child: Text(posterName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            )),
                                      ),
                                      Text(
                                          "${timeMaths.SingleLongFormatDuration(postDate == null ? 0 : (DateTime.now().millisecondsSinceEpoch - postDate!))} ago",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          )),
                                    ],
                                  )
                                ]),
                          ),
                          PostManageButton(
                            posterUserId: posterUserId,
                            postId: postId,
                            viewerIsCreator: viewerIsCreator,
                          ),
                          SizedBox(
                            width: 8,
                          )
                        ]))),
                const SizedBox(height: 8.0),
                Padding(
                  // image
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      child: PostImage(
                        imageData: imageData,
                        imageRoundness: 16,
                      )),
                ),

                //rating row
                Row(children: <Widget>[
                  // 2nd row of items
                  const SizedBox(width: 16.0),
                  //rating display
                  SizedBox(
                      height: 25,
                      child: Row(
                        children: [
                          RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 20.0,
                            direction: Axis.horizontal,
                          ),
                          Text(
                            " ($ratingsAmount)",
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      )),
                  //display if you have rated yet
                  Visibility(
                      visible: !hasRated!,
                      child: const Row(
                        children: [
                          SizedBox(width: 8),
                          Text(
                            "not rated yet",
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ],
                      ))
                ]),
                //title and desc
                Padding(
                  //title
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    child: SelectableLinkify(
                      onOpen: (link) async {
                        if (!await launchUrl(Uri.parse(link.url))) {
                          throw Exception('Could not launch ${link.url}');
                        }
                      },
                      text: title,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Padding(
                    //description
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      child: SelectableLinkify(
                        onOpen: (link) async {
                          if (!await launchUrl(Uri.parse(link.url))) {
                            throw Exception('Could not launch ${link.url}');
                          }
                        },
                        text: description,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )),
                const SizedBox(height: 16.0),
              ]),
            ),
          ),
          onTap: () {
            if (clickable == true) {
              if (openFullContentTree == true) {
                openUserItemContent({
                  "type": "post",
                  "data": postId,
                }, context);
              } else {
                Navigator.of(context).push(
                    smoothTransitions.slideUp(fullPagePost(postId: postId)));
              }
            }
          });
    }
  }
}

class PostImage extends StatelessWidget {
  final imageData;
  final double imageRoundness;

  PostImage({required this.imageData, required this.imageRoundness});

  @override
  Widget build(BuildContext context) {
    if (imageData == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(imageRoundness)),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            )),
      );
    } else {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(imageRoundness)),
            ),
            child: Center(
              child: Image.memory(
                imageData,
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            )),
      );
    }
  }
}

class PostManageButton extends StatelessWidget {
  final String posterUserId;
  final String postId;
  final bool? viewerIsCreator;

  const PostManageButton(
      {required this.posterUserId,
      required this.postId,
      required this.viewerIsCreator});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
        child: Center(
            child: IconButton(
      icon: Icon(
        Icons.more_vert,
        size: 35, // Adjust the size of the icon
        color: Colors.grey[500],
      ),
      onPressed: () {
        openAlert("custom_buttons", "select action for message", null, context,
            null, [
          Visibility(
            visible: viewerIsCreator == true,
            child: DialogButton(
              color: Colors.red,
              child: const Text(
                'delete',
                style: TextStyle(fontSize: 16.0, color: Colors.white),
              ),
              onPressed: () async {
                openAlert(
                    "yes_or_no",
                    "are you sure you want to delete this post?",
                    null,
                    context,
                    {
                      "yes": () async {
                        final response = await http.post(
                          Uri.parse("$serverDomain/post/delete"),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode(<String, String>{
                            'token': userManager.token,
                            'postId': postId,
                          }),
                        );
                        if (response.statusCode == 200) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          // ignore: use_build_context_synchronously
                          openAlert("success", "post deleted", null, context,
                              null, null);
                        } else {
                          // ignore: use_build_context_synchronously
                          ErrorHandler.httpError(
                              response.statusCode, response.body, context);
                          // ignore: use_build_context_synchronously
                          openAlert("error", "failed deleting post",
                              response.body, context, null, null);
                        }
                      },
                      "no": () {
                        Navigator.pop(context);
                      },
                    },
                    null);
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
              reportSystem.reportItem(context, "post", postId);
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
    )));
  }
}
