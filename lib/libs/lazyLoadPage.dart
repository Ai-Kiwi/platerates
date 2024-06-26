import 'dart:convert';
import 'dart:io';

import 'package:PlateRates/chat/chatList.dart';
import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:PlateRates/notifications/notificationBarItem.dart';
import 'package:PlateRates/posts/postRating/userRating.dart';
import 'package:PlateRates/posts/userPost.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../userProfile/userProfile.dart';
import 'errorHandler.dart';

class LazyLoadPage extends StatefulWidget {
  final Widget widgetAddedToTop;
  final Widget widgetAddedToEnd;
  final Widget widgetAddedToBlank;
  final String urlToFetch;
  final bool openFullContentTree;
  final int itemsPerPage;
  final Map<String, String> headers;

  const LazyLoadPage({
    Key? key,
    required this.widgetAddedToTop,
    required this.urlToFetch,
    required this.widgetAddedToEnd,
    required this.widgetAddedToBlank,
    required this.openFullContentTree,
    required this.itemsPerPage,
    required this.headers,
  }) : super(key: key);

  @override
  State<LazyLoadPage> createState() => LazyLoadPageState(
        widgetAddedToTop: widgetAddedToTop,
        urlToFetch: urlToFetch,
        widgetAddedToEnd: widgetAddedToEnd,
        widgetAddedToBlank: widgetAddedToBlank,
        openFullContentTree: openFullContentTree,
        itemsPerPage: itemsPerPage,
        headers: headers,
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
  final bool openFullContentTree;
  final int itemsPerPage;
  final Map<String, String> headers;

  LazyLoadPageState({
    required this.widgetAddedToTop,
    required this.urlToFetch,
    required this.widgetAddedToEnd,
    required this.widgetAddedToBlank,
    required this.openFullContentTree,
    required this.itemsPerPage,
    required this.headers,
  });

  int pageUpto = 0;
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

    Map<String, String> sending_headers = Map();

    headers.forEach((k, v) => sending_headers[k] = v);

    sending_headers["page"] = pageUpto.toString();
    sending_headers["page_size"] = itemsPerPage.toString();

    if (userManager.loggedIn == true) {
      sending_headers["authorization"] = userManager.token;
    }

    var subbedServerDomain = serverDomain.substring(0, 5);
    var justDomainUrl;
    if (subbedServerDomain == "https") {
      justDomainUrl =
          Uri.https(serverDomain.substring(8), "$urlToFetch", sending_headers);
    } else {
      justDomainUrl =
          Uri.http(serverDomain.substring(7), "$urlToFetch", sending_headers);
    }

    final response = await http.get(
      justDomainUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: userManager.token
      },
    );
    if (response.statusCode == 200) {
      try {
        if (mounted) {
          setState(() {
            var fetchedData = jsonDecode(response.body);
            var postData = fetchedData;
            if (fetchedData.isEmpty) {
              if (itemsCollected.isEmpty) {
                itemsCollected.add("blank");
              } else {
                itemsCollected.add("end");
              }
              return;
            }
            for (var post in postData) {
              if (itemsCollected.contains(post) == false) {
                itemsCollected.add(post);
              }
            }
            pageUpto++;
          });
        }
      } on Exception catch (error, stackTrace) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    } else {
      ErrorHandler.httpError(response.statusCode, response.body, context);
      openAlert("error", "failed getting new items", response.body, context,
          null, null);
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
