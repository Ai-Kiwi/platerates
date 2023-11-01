import 'dart:convert';

import 'package:Toaster/chat/chatList.dart';
import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/notifications/notificationBarItem.dart';
import 'package:Toaster/posts/postRating/userRating.dart';
import 'package:Toaster/posts/userPost.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../login/userLogin.dart';
import '../userProfile/userProfile.dart';
import 'errorHandler.dart';

class LazyLoadPage extends StatefulWidget {
  final Widget widgetAddedToTop;
  final Widget widgetAddedToEnd;
  final Widget widgetAddedToBlank;
  final String urlToFetch;
  final Map<dynamic, dynamic>? extraUrlData;
  final bool openFullContentTree;

  const LazyLoadPage({
    Key? key,
    required this.widgetAddedToTop,
    required this.urlToFetch,
    required this.widgetAddedToEnd,
    required this.widgetAddedToBlank,
    required this.openFullContentTree,
    this.extraUrlData,
  }) : super(key: key);

  @override
  State<LazyLoadPage> createState() => LazyLoadPageState(
        widgetAddedToTop: widgetAddedToTop,
        urlToFetch: urlToFetch,
        extraUrlData: extraUrlData,
        widgetAddedToEnd: widgetAddedToEnd,
        widgetAddedToBlank: widgetAddedToBlank,
        openFullContentTree: openFullContentTree,
      );
}

class LazyLoadPageState extends State<LazyLoadPage> {
  Widget widgetAddedToTop;
  Widget widgetAddedToEnd;
  Widget widgetAddedToBlank;
  ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool? perentRating = false;
  final double scrollDistence = 0.8;
  final String urlToFetch;
  final Map<dynamic, dynamic>? extraUrlData;
  final bool openFullContentTree;

  LazyLoadPageState({
    required this.widgetAddedToTop,
    required this.urlToFetch,
    required this.widgetAddedToEnd,
    required this.widgetAddedToBlank,
    required this.openFullContentTree,
    this.extraUrlData,
  });

  var lastItem;
  var itemsCollected = [];

  Future<void> _fetchItems() async {
    //test if they have reached the end
    if (itemsCollected.isNotEmpty) {
      if (itemsCollected[itemsCollected.length - 1] == "end" ||
          itemsCollected[itemsCollected.length - 1] == "blank") {
        return;
      }
    }
    _isLoading = true; //say that it is loading more
    //setup data for sending
    Map<dynamic, dynamic> dataSending = {
      'token': userManager.token,
    };
    //add all the extra parm's
    if (extraUrlData != null) {
      dataSending.addAll(extraUrlData!);
    }

    if (lastItem != null) {
      dataSending['startPosPost'] = lastItem!;
    }
    final response = await http.post(
      Uri.parse("$serverDomain$urlToFetch"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(dataSending),
    );
    if (response.statusCode == 200) {
      try {
        if (mounted) {
          setState(() {
            var fetchedData = jsonDecode(response.body);
            var postData = fetchedData["items"];
            if (fetchedData["items"].isEmpty) {
              if (itemsCollected.isEmpty) {
                itemsCollected.add("blank");
              } else {
                itemsCollected.add("end");
              }
              return;
            }
            for (var post in postData) {
              itemsCollected.add(post);
              lastItem = post;
            }
          });
        }
      } on Exception catch (error, stackTrace) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    } else {
      ErrorHandler.httpError(response.statusCode, response.body, context);
      openAlert(
          "error", "failed getting new items", response.body, context, null);
    }
    _isLoading = false;
  }

  void _onScroll() {
    if (_isLoading == false &&
        _scrollController.position.pixels >=
            (_scrollController.position.maxScrollExtent * scrollDistence)) {
      _fetchItems();
    }
  }

  void updateChildWidget() {
    print("set sate for top end item");
    setState(() {
      var oldState = widgetAddedToTop;
      widgetAddedToTop = const Center();
      widgetAddedToTop = oldState;
      itemsCollected = itemsCollected;
      widgetAddedToEnd = widgetAddedToEnd;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final ThemeData theme = Theme.of(context);
    return SizedBox(
      child: Center(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          controller: _scrollController,
          itemCount: itemsCollected.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return widgetAddedToTop;
            } else if (itemsCollected[index - 1] == "end") {
              return widgetAddedToEnd;
            } else if (itemsCollected[index - 1] == "blank") {
              return widgetAddedToBlank;
            } else {
              if (itemsCollected[index - 1]["type"] == "post") {
                return PostItem(
                  postId: itemsCollected[index - 1]["data"],
                  clickable: true,
                  openFullContentTree: openFullContentTree,
                );
              } else if (itemsCollected[index - 1]["type"] == "rating") {
                return userRating(
                  ratingId: itemsCollected[index - 1]["data"],
                  clickable: true,
                  openFullContentTree: openFullContentTree,
                );
              } else if (itemsCollected[index - 1]["type"] == "user") {
                return SimpleUserProfileBar(
                  userId: itemsCollected[index - 1]["data"],
                );
              } else if (itemsCollected[index - 1]["type"] == "notification") {
                return notificationBarItem(
                  notificationData: itemsCollected[index - 1]["data"],
                );
              } else if (itemsCollected[index - 1]["type"] == "chat_room") {
                return chatBarItem(
                  chatItem: itemsCollected[index - 1]["data"],
                );
              }
            }
            return null;
          },
        ),
      ),
    );
  }
}
