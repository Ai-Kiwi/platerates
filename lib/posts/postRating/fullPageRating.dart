import 'dart:convert';

import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:Toaster/posts/postRating/userRating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../libs/errorHandler.dart';
import '../../login/userLogin.dart';
import '../../main.dart';

class FullPageRating extends StatefulWidget {
  final String ratingId;

  const FullPageRating({super.key, required this.ratingId});

  @override
  _fullPageRatingState createState() =>
      _fullPageRatingState(rootItem: ratingId);
}

class _fullPageRatingState extends State<FullPageRating> {
  String uploadingRatingText = "";
  String rootItem;
  bool hasRated = true;

  _fullPageRatingState({required this.rootItem});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(alignment: Alignment.topLeft, children: <Widget>[
      SafeArea(
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
                      widgetAddedToTop: Center(
                          child: Column(children: [
                        userRating(
                          ratingId: rootItem,
                          clickable: false,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 16),
                          child: Divider(
                            color: Color.fromARGB(255, 110, 110, 110),
                            thickness: 1.0,
                          ),
                        ),
                      ])),
                      widgetAddedToEnd: const Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16),
                            child: Text(
                              "end of comments.",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 25),
                            )),
                      ),
                      widgetAddedToBlank: const Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16),
                            child: Text(
                              "no comments to display",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 25),
                            )),
                      ),
                      extraUrlData: {
                        "rootItem": {"type": "rating", "data": rootItem}
                      },
                      urlToFetch: '/post/ratings',
                    ),
                  ),
                  //menu for you to rate the post
                  Container(
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      )),
                      height: 185,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(children: [
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
                                labelText: 'comment text',
                                labelStyle: const TextStyle(
                                  color: Color.fromARGB(255, 200, 200, 200),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                  borderSide: const BorderSide(
                                      width: 2,
                                      color: Color.fromARGB(255, 45, 45, 45)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                  borderSide: const BorderSide(
                                      width: 2,
                                      color: Color.fromARGB(255, 45, 45, 45)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                  borderSide: BorderSide(
                                      width: 2,
                                      color: Theme.of(context).primaryColor),
                                ),
                                contentPadding: const EdgeInsets.all(12.0),
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
                                //post comment
                                final response = await http.post(
                                  Uri.parse("$serverDomain/post/rating/upload"),
                                  headers: <String, String>{
                                    'Content-Type':
                                        'application/json; charset=UTF-8',
                                  },
                                  body: jsonEncode({
                                    "token": userManager.token,
                                    "text": uploadingRatingText,
                                    "shareMode": "public",
                                    "rootItem": {
                                      "type": "rating",
                                      "data": rootItem
                                    },
                                  }),
                                );

                                if (response.statusCode == 201) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                    'created comment',
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.white),
                                  )));

                                  await jsonCache.remove('rating-$rootItem');
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => FullPageRating(
                                              ratingId: rootItem)));
                                } else {
                                  ErrorHandler.httpError(response.statusCode,
                                      response.body, context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                    'failed creating comment',
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.red),
                                  )));
                                }
                              },
                              child: const Text(
                                'publish comment',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                          )
                        ]),
                      )),
                ],
              ))),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ))
    ]));
  }
}
