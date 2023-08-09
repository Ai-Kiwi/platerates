import 'dart:convert';

import 'package:Toaster/libs/userAvatar.dart';
import 'package:Toaster/posts/fullPagePost.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';

import '../libs/dataCollect.dart';
import '../libs/report.dart';
import '../main.dart';
import '../login/userLogin.dart';

class userRating extends StatefulWidget {
  final String ratingId;

  userRating({super.key, required this.ratingId});

  @override
  _userRatingState createState() => _userRatingState(ratingId: ratingId);
}

class _userRatingState extends State<userRating> {
  final String ratingId;
  String text = "";
  String posterName = "";
  String posterUserId = "";
  double rating = 0;
  var rootItem;

  Future<void> _collectData() async {
    var jsonData;
    var extractedData = await jsonCache.value('rating-$ratingId');
    if (extractedData != null) {
      jsonData = jsonDecode(extractedData["data"]);
    }

    if (jsonData == null) {
      final response = await http.post(
        Uri.parse("$serverDomain/post/rating/data"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': userManager.token,
          'ratingId': ratingId,
        }),
      );
      if (response.statusCode == 200) {
        //if true do nothing and then it will display
        jsonData = jsonDecode(response.body);
        await jsonCache.refresh('rating-$ratingId', {"data": response.body});
      } else {
        Alert(
          context: context,
          type: AlertType.error,
          title: "failed fetching rating data",
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
        return;
      }
    }

    //as non of these have returned error it must have found data
    try {
      Map basicUserData = await dataCollect.getBasicUserData(
          jsonData['ratingPosterId'], context);
      setState(() {
        text = jsonData["text"];
        rating = double.parse('${jsonData["rating"]}');
        posterName = basicUserData['username'];
        posterUserId = jsonData['ratingPosterId'];
        rootItem = jsonData['rootItem'];
      });
    } catch (err) {
      print(err);
    }
  }

  @override
  void initState() {
    super.initState();
    _collectData();
  }

  _userRatingState({required this.ratingId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      //post item
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
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
                    userId: posterUserId,
                    avatarImage: null,
                    size: 45,
                    roundness: 25,
                    clickable: true,
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
                    RatingBarIndicator(
                      rating: rating,
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 25.0,
                      direction: Axis.horizontal,
                    ),
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
                                      builder: (context) => PostRatingList(
                                          postId: rootItem["data"])));
                            },
                            width: 120,
                            child: const Text(
                              "ok",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          )
                        ],
                      ).show();
                    } else {
                      Alert(
                        context: context,
                        type: AlertType.error,
                        title: "error deleteing rating",
                        desc: response.body,
                        buttons: [
                          DialogButton(
                            onPressed: () => Navigator.pop(context),
                            width: 120,
                            child: const Text(
                              "ok",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          )
                        ],
                      ).show();
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
            const SizedBox(width: 48),
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
                          child: Text(
                            text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                          ))
                    ])))
          ],
        ),
      ]),
    );
  }
}
