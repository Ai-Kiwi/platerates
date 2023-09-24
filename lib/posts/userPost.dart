import 'dart:convert';

import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/dataCollect.dart';
import 'package:Toaster/libs/smoothTransitions.dart';
import 'package:Toaster/libs/userAvatar.dart';
import 'package:Toaster/posts/fullPagePost.dart';
import 'package:Toaster/login/userLogin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../libs/errorHandler.dart';
import '../libs/report.dart';
import '../main.dart';
import '../userProfile/userProfile.dart';

class PostItem extends StatefulWidget {
  final String postId;
  final bool clickable;

  const PostItem({super.key, required this.postId, required this.clickable});

  @override
  _PostItemState createState() =>
      _PostItemState(clickable: clickable, postId: postId);
}

class _PostItemState extends State<PostItem> {
  String postId;
  final bool clickable;
  String title = "";
  String description = "";
  double rating = 0;
  String posterName = "";
  int ratingsAmount = 0;
  bool? hasRated = true;
  var posterAvatar;
  String posterUserId = "";
  var imageData;
  bool errorOccurred = false;

  _PostItemState({required this.postId, required this.clickable});

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
        ratingsAmount = int.parse(jsonData['ratingsAmount']);
        // ignore: sdk_version_since
        hasRated = bool.tryParse(jsonData['requesterRated']);
        errorOccurred = false;
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

  Future<void> _collectDataAndUpdate() async {
    //as non of these have returned error it must have found data
    try {
      await _collectData();
      if (await dataCollect.updatePostData(postId, context, false) == true) {
        await _collectData();
      }
    } catch (err) {
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Container(
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => UserProfile(
                                            userId: posterUserId,
                                            openedOntopMenu: true)),
                                  );
                                }),
                            const SizedBox(width: 4),
                            Text(posterName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                )),
                          ]),
                    ),
                    PostManageButton(
                      posterUserId: posterUserId,
                      postId: postId,
                    ),
                    SizedBox(
                      width: 8,
                    )
                  ]))),
          const SizedBox(height: 8.0),
          Padding(
              // image
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                  child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      child: PostImage(
                        imageData: imageData,
                        imageRoundness: 16,
                      )),
                  onTap: () {
                    if (clickable == true) {
                      Navigator.of(context).push(smoothTransitions
                          .slideUp(fullPagePost(postId: postId)));
                    }
                  })),

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
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
              )),
          const SizedBox(height: 16.0),
        ])),
      );
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

  const PostManageButton({required this.posterUserId, required this.postId});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
        child: Center(
            child: PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 35, // Adjust the size of the icon
        color: Colors.grey[500],
      ),
      onSelected: (value) async {
        // Handle menu item selection
        if (value == 'delete') {
          Alert(
            context: context,
            type: AlertType.warning,
            title: "are you sure you want to delete this post?",
            buttons: [
              DialogButton(
                onPressed: () async {
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
                    openAlert("success", "post deleted", null, context);
                  } else {
                    // ignore: use_build_context_synchronously
                    ErrorHandler.httpError(
                        response.statusCode, response.body, context);
                    // ignore: use_build_context_synchronously
                    openAlert("error", "failed deleting post", null, context);
                  }
                },
                color: Colors.green,
                child: const Text(
                  "Yes",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              DialogButton(
                color: Colors.red,
                child: const Text(
                  "No",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          ).show();
        } else if (value == 'report') {
          reportSystem.reportItem(context, "post", postId);
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
              style: TextStyle(color: Color.fromARGB(255, 45, 45, 45)),
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
    )));
  }
}
