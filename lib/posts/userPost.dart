import 'dart:convert';

import 'package:Toaster/libs/dataCollect.dart';
import 'package:Toaster/libs/smoothTransitions.dart';
import 'package:Toaster/postRating/postRatingList.dart';
import 'package:Toaster/login/userLogin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class PostItem extends StatefulWidget {
  final String postId;
  const PostItem({super.key, required this.postId});

  @override
  _PostItemState createState() => _PostItemState(postId);
}

class _PostItemState extends State<PostItem> {
  String postId;
  String title = "";
  String description = "";
  double rating = 0;
  String posterName = "";
  String posterAvatar = "";
  String posterUserId = "";
  var imageData;
  bool errorOccurred = false;

  _PostItemState(this.postId);

  Future<void> _collectData() async {
    var jsonData;
    var extractedData = await jsonCache.value('post-$postId');
    if (extractedData != null) {
      jsonData = jsonDecode(extractedData["data"]);
    }

    if (jsonData == null) {
      final response = await http.post(
        Uri.parse("$serverDomain/post/data"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': userManager.token,
          'postId': postId,
        }),
      );
      if (response.statusCode == 200) {
        //if true do nothing and then it will display
        jsonData = jsonDecode(response.body);
        await jsonCache.refresh('post-$postId', {"data": response.body});
      } else {
        Alert(
          context: context,
          type: AlertType.error,
          title: "failed fetching post data",
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
      Map basicUserData =
          await dataCollect.getBasicUserData(jsonData['posterId'], context);
      //print(basicUserData);
      setState(() {
        title = jsonData["title"];
        description = jsonData["description"];
        rating = double.parse('${jsonData["rating"]}');
        imageData = base64Decode(jsonData['imageData']);
        posterName = basicUserData["username"];
        posterUserId = jsonData['posterId'];
        errorOccurred = false;
      });
    } catch (err) {
      print(err);
    }
  }

  @override
  void initState() {
    super.initState();
    //no idea why the hell the error happens but this if statement fixes it
    if (mounted && title.isEmpty) {
      _collectData();
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: Container(
              decoration: BoxDecoration(
                  color: const Color.fromARGB(215, 40, 40, 40),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                      color: const Color.fromARGB(215, 45, 45, 45), width: 3)),
              width: double.infinity,
              child: Column(children: <Widget>[
                const SizedBox(height: 16.0),
                //user logo and name
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              width: 2,
                              color: const Color.fromARGB(255, 45, 45, 45)),
                        ),
                        width: double.infinity,
                        height: 35,
                        child: Row(children: <Widget>[
                          Flexible(
                            child: Row(children: [
                              const SizedBox(width: 4),
                              const SizedBox(
                                  height: 25,
                                  child: CircleAvatar(
                                    backgroundImage: null,
                                    radius: 15,
                                  )),
                              Text(posterName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  )),
                            ]),
                          ),
                          PostManageButton(
                            userId: userManager.userId,
                            posterUserId: posterUserId,
                            postId: postId,
                          ),
                        ]))),
                const SizedBox(height: 8.0),
                Padding(
                    // image
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        child: PostImage(
                          imageData: imageData,
                        ))),
                const SizedBox(height: 8.0),
                //input buttons
                Row(children: <Widget>[
                  // 2nd row of items
                  const SizedBox(width: 16.0),
                  //rate it button
                  SizedBox(
                    height: 25,
                    child: TextButton(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 1.0), // Adjust the padding values
                        ),
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(255, 75, 75, 75)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(smoothTransitions
                            .slideUp(PostRatingList(postId: postId)));
                        //Navigator.push(
                        //    context,
                        //    MaterialPageRoute(
                        //        builder: (context) =>
                        //            PostRatingList(postId: postId)));
                      },
                      child: RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 15.0,
                        direction: Axis.horizontal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  //report it button
                  SizedBox(
                    height: 25,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5.0, vertical: 1.0),
                        backgroundColor: Colors.red,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Alert(
                          context: context,
                          type: AlertType.info,
                          title: "reporting has not been added yet",
                          desc:
                              "idk, just close your eyes, it's really not that hard",
                          buttons: [
                            DialogButton(
                              onPressed: () => Navigator.pop(context),
                              width: 120,
                              child: const Text(
                                "ok",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            )
                          ],
                        ).show();
                      },
                      child: const Text("report 🚩",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
                const SizedBox(height: 8.0),
                //title and desc
                Padding(
                  //title
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                          width: 2,
                          color: const Color.fromARGB(255, 45, 45, 45)),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          title,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                        )),
                  ),
                ),
                const SizedBox(height: 8.0),
                Padding(
                    //description
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              width: 2,
                              color: const Color.fromARGB(255, 45, 45, 45)),
                        ),
                        child: ListView(
                          children: [
                            Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  description,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ))
                          ],
                        ))),
                const SizedBox(height: 16.0),
              ])));
    }
  }
}

class PostImage extends StatelessWidget {
  final imageData;

  PostImage({required this.imageData});

  @override
  Widget build(BuildContext context) {
    if (imageData == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                  width: 2, color: const Color.fromARGB(255, 45, 45, 45)),
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
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
              border: Border.all(
                  width: 2, color: const Color.fromARGB(255, 45, 45, 45)),
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
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
  final String userId;
  final String posterUserId;
  final String postId;

  PostManageButton(
      {required this.userId, required this.posterUserId, required this.postId});

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
      onSelected: (value) {
        // Handle menu item selection
        if (value == 'delete') {
          Alert(
            context: context,
            type: AlertType.warning,
            title: "are you sure you want to delete this post?",
            desc: "what the title said",
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
                    Navigator.pop(context);
                    Alert(
                      context: context,
                      type: AlertType.success,
                      title: "post deleted",
                      desc: "refresh page to see",
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
                  } else {
                    Alert(
                      context: context,
                      type: AlertType.error,
                      title: "error deleteing post",
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
          //} else if (value == 'option2') {
          //  // Handle option 2 selection
        }
      },
      itemBuilder: (BuildContext context) {
        return [
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
