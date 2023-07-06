import 'package:Toaster/posts/userPostList.dart';
import 'package:flutter/material.dart';

class userFeed extends StatefulWidget {
  @override
  State<userFeed> createState() => _userFeedState();
}

class _userFeedState extends State<userFeed> {
  @override
  Widget build(BuildContext context) {
    //final ThemeData theme = Theme.of(context);
    return userPostList(
      urlToFetch: "/post/feed",
      widgetAddedToTop: const Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Text(
                "Your feed",
                style: TextStyle(color: Colors.white, fontSize: 40),
              ))),
    );
  }
}
