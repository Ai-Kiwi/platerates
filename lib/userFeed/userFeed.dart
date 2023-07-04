import 'dart:convert';

import 'package:Toaster/userFeed/userPost.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../userLogin.dart';

class userFeed extends StatefulWidget {
  @override
  State<userFeed> createState() => _userFeedState();
}

class _userFeedState extends State<userFeed> {
  ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final double scrollDistence = 0.8;
  String? lastPost;

  var posts = [];

  Future<void> _fetchPosts() async {
    _isLoading = true;
    var dataSending = <String, String>{
      'token': userManager.token,
    };
    if (lastPost != null) {
      dataSending['startPosPost'] = lastPost!;
    }

    final response = await http.post(
      Uri.parse("http://$serverDomain/post/feed"),
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
              child: Text(
                "ok",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(context),
              width: 120,
            )
          ],
        ).show();
      });
      print(response.statusCode);
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
              return const Center(
                  child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                      child: Text(
                        "Your feed",
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      )));
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
