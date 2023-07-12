import 'dart:convert';

import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../main.dart';
import '../userLogin.dart';

class PostRatingList extends StatefulWidget {
  final String postId;

  const PostRatingList({super.key, required this.postId});

  @override
  _PostRatingListState createState() => _PostRatingListState(rootItem: postId);
}

class _PostRatingListState extends State<PostRatingList> {
  String uploadingRatingText = "";
  double uploadingRating = 5;
  String rootItem;
  bool hasRated = true;

  Future<void> _testRated() async {
    //attempt to upload post to see if you have posted yet
    final response = await http.post(
      Uri.parse("$serverDomain/post/rating/upload"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "token": userManager.token,
        "rootItem": {"type": "post", "data": rootItem},
      }),
    );

    setState(() {
      print(response.body);
      if (response.body == "you have already rated") {
        hasRated = true;
      } else {
        hasRated = false;
      }
    });
  }

  _PostRatingListState({required this.rootItem});

  @override
  void initState() {
    super.initState();
    _testRated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            top: false,
            child: Container(
                height: double.infinity,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(16, 16, 16, 1),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: LazyLoadPage(
                        widgetAddedToTop: const Center(
                            child: Column(children: [
                          Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 16),
                              child: Text(
                                "post ratings",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 40),
                              )),
                          Divider(
                            color: Color.fromARGB(255, 110, 110, 110),
                            thickness: 1.0,
                          ),
                        ])),
                        widgetAddedToEnd: const Center(
                          child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 16),
                              child: Text(
                                "ratings end, reached you have.",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 25),
                              )),
                        ),
                        extraUrlData: {
                          "rootItem": {"type": "post", "data": rootItem}
                        },
                        urlToFetch: '/post/ratings',
                      ),
                    ),
                    Visibility(
                        visible: !hasRated,
                        child: Container(
                            decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30.0),
                              topRight: Radius.circular(30.0),
                            )),
                            height: 233,
                            width: double.infinity,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(children: [
                                RatingBar.builder(
                                  initialRating: 5,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemPadding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {
                                    setState(() {
                                      uploadingRating = rating;
                                    });
                                  },
                                ),
                                SizedBox(height: 8),
                                TextField(
                                    keyboardType: TextInputType.multiline,
                                    maxLength: 500,
                                    maxLengthEnforcement: MaxLengthEnforcement
                                        .truncateAfterCompositionEnds,
                                    maxLines: 5,
                                    onChanged: (value) {
                                      setState(() {
                                        uploadingRatingText = value;
                                      });
                                    },
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      labelText: 'rating text',
                                      labelStyle: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 200, 200, 200),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        borderSide: const BorderSide(
                                            width: 2,
                                            color: Color.fromARGB(
                                                255, 45, 45, 45)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        borderSide: const BorderSide(
                                            width: 2,
                                            color: Color.fromARGB(
                                                255, 45, 45, 45)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        borderSide: BorderSide(
                                            width: 2,
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.all(12.0),
                                      fillColor:
                                          const Color.fromARGB(255, 40, 40, 40),
                                      filled: true,
                                    )),
                                SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  height: 50.0,
                                  child: ElevatedButton(
                                    style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    )),
                                    onPressed: () async {
                                      //post rating
                                      final response = await http.post(
                                        Uri.parse(
                                            "$serverDomain/post/rating/upload"),
                                        headers: <String, String>{
                                          'Content-Type':
                                              'application/json; charset=UTF-8',
                                        },
                                        body: jsonEncode({
                                          "token": userManager.token,
                                          "text": uploadingRatingText,
                                          "shareMode": "public",
                                          "rating": uploadingRating,
                                          "rootItem": {
                                            "type": "post",
                                            "data": rootItem
                                          },
                                        }),
                                      );

                                      if (response.statusCode == 200) {
                                        Alert(
                                          context: context,
                                          type: AlertType.success,
                                          title: "uploaded rating",
                                          buttons: [
                                            DialogButton(
                                              child: Text(
                                                "ok",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20),
                                              ),
                                              onPressed: () async {
                                                await jsonCache
                                                    .remove('post-$rootItem');
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            PostRatingList(
                                                                postId:
                                                                    rootItem)));
                                              },
                                              width: 120,
                                            )
                                          ],
                                        ).show();
                                      } else {
                                        Alert(
                                          context: context,
                                          type: AlertType.error,
                                          title: "error uploading rating",
                                          desc: response.body,
                                          buttons: [
                                            DialogButton(
                                              child: Text(
                                                "ok",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20),
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              width: 120,
                                            )
                                          ],
                                        ).show();
                                      }
                                    },
                                    child: const Text(
                                      'publish rating',
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                  ),
                                )
                              ]),
                            ))),
                  ],
                ))));
  }
}
