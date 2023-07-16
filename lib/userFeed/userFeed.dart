import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:flutter/material.dart';

class userFeed extends StatefulWidget {
  @override
  State<userFeed> createState() => _UserFeedState();
}

class _UserFeedState extends State<userFeed> {
  @override
  Widget build(BuildContext context) {
    //final ThemeData theme = Theme.of(context);
    return LazyLoadPage(
      urlToFetch: "/post/feed",
      widgetAddedToTop: const Center(
          child: Column(children: [
        Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "Your feed",
              style: TextStyle(color: Colors.white, fontSize: 40),
            )),
        Divider(
          color: Color.fromARGB(255, 110, 110, 110),
          thickness: 1.0,
        ),
      ])),
      widgetAddedToEnd: const Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "end of feed",
              style: TextStyle(color: Colors.white, fontSize: 25),
            )),
      ),
    );
  }
}
