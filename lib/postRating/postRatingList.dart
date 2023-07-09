import 'package:Toaster/postRating/userRating.dart';
import 'package:flutter/material.dart';

class PostRatingList extends StatefulWidget {
  final String postId;

  const PostRatingList({super.key, required this.postId});

  @override
  _PostRatingListState createState() => _PostRatingListState();
}

class _PostRatingListState extends State<PostRatingList> {
  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(16, 16, 16, 1),
        ),
        //child: ListView.builder(
        //  controller: _scrollController,
        //  itemCount: posts.length + 1,
        //  itemBuilder: (context, index) {
        //    if (index == 0) {
        //      return widgetAddedToTop;
        //    } else {
        //      return PostItem(
        //        postId: posts[index - 1],
        //      );
        //    }
        //  },
        //),
      ),
    );
  }
}
