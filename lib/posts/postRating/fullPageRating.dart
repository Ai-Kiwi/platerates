import 'dart:convert';
import 'dart:io';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/lazyLoadPage.dart';
import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:PlateRates/posts/postRating/userRating.dart';
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
        body: PageBackButton(
      warnDiscardChanges: false,
      active: true,
      child: SafeArea(
          top: false,
          child: SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: Column(
                children: [
                  Expanded(
                    child: LazyLoadPage(
                      openFullContentTree: false,
                      widgetAddedToTop: Center(
                          child: Column(children: [
                        SizedBox(height: 32),
                        userRating(
                          ratingId: rootItem,
                          clickable: false,
                          openFullContentTree: false,
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
                      //should include that you are fetching rating data and which one
                      urlToFetch: '/post/ratings',
                      itemsPerPage: 5,
                      headers: {
                        "rating_id": rootItem,
                      },
                    ),
                  ),
                  //menu for you to rate the post
                  Visibility(
                    //menu for you to rate the post
                    visible: userManager.loggedIn == true,
                    child: Container(
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
                                uploadingRatingText = value;
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
                                    HttpHeaders.authorizationHeader:
                                        userManager.token,
                                  },
                                  body: jsonEncode({
                                    "token": userManager.token,
                                    "text": uploadingRatingText,
                                    //"shareMode": "public",
                                    "root_type": "rating",
                                    "root_data": rootItem
                                  }),
                                );

                                if (response.statusCode == 201) {
                                  // ignore: use_build_context_synchronously
                                  openAlert("success", "created comment", null,
                                      context, null, null);

                                  await jsonCache.remove('rating-$rootItem');
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => FullPageRating(
                                              ratingId: rootItem)));
                                } else {
                                  // ignore: use_build_context_synchronously
                                  ErrorHandler.httpError(response.statusCode,
                                      response.body, context);
                                  // ignore: use_build_context_synchronously
                                  openAlert("error", "failed creating comments",
                                      response.body, context, null, null);
                                }
                              },
                              child: const Text(
                                'publish comment',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                          )
                        ]),
                      ),
                    ),
                  ),
                ],
              ))),
    ));
  }
}
