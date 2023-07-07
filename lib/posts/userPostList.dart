import 'dart:convert';

import 'package:Toaster/posts/userPost.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../userLogin.dart';

class UserPostList extends StatefulWidget {
  final Widget widgetAddedToTop;
  final String urlToFetch;
  final extraUrlData;

  UserPostList(
      {super.key,
      required this.widgetAddedToTop,
      required this.urlToFetch,
      this.extraUrlData});

  @override
  State<UserPostList> createState() => _userPostListState(
      widgetAddedToTop: widgetAddedToTop,
      urlToFetch: urlToFetch,
      extraUrlData: extraUrlData);
}

class _userPostListState extends State<UserPostList> {
  Widget widgetAddedToTop;
  ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final double scrollDistence = 0.8;
  String? lastPost;
  final String urlToFetch;
  final Map<String, String>? extraUrlData;

  _userPostListState(
      {required this.widgetAddedToTop,
      required this.urlToFetch,
      this.extraUrlData});

  var posts = [];

  Future<void> _fetchPosts() async {
    _isLoading = true;
    var dataSending = <String, String>{
      'token': userManager.token,
    };
    //add all the extra parm's
    if (extraUrlData != null) {
      //extraUrlData!.forEach((key, value) => dataSending[key] = value);
      dataSending.addAll(extraUrlData!);
    }

    if (lastPost != null) {
      dataSending['startPosPost'] = lastPost!;
    }

    final response = await http.post(
      Uri.parse("$serverDomain$urlToFetch"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(dataSending),
    );
    if (response.statusCode == 200) {
      setState(() {
        var fetchedData = jsonDecode(response.body);
        var postData = fetchedData["posts"];
        if (fetchedData["posts"].isEmpty) {
          _isLoading = true;
          return;
        }
        for (var post in postData) {
          posts.add(post);
          lastPost = post;
        }
      });
    } else {
      setState(() {
        Alert(
          context: context,
          type: AlertType.error,
          title: "an error occurred while getting new posts",
          desc: "a fairly big problem",
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
      });
    }
    _isLoading = false;
  }

  void _onScroll() {
    if (!_isLoading &&
        _scrollController.position.pixels >=
            (_scrollController.position.maxScrollExtent * scrollDistence)) {
      _fetchPosts();
    }
  }

  void updateChildWidget(String newState) {
    setState(() {
      widgetAddedToTop = widgetAddedToTop;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final ThemeData theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
      child: Center(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: posts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return widgetAddedToTop;
            } else {
              return PostItem(
                postId: posts[index - 1],
              );
            }
          },
        ),
      ),
    );
  }
}
