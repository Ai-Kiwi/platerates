import 'package:Toaster/postRating/userRating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class PostRatingList extends StatefulWidget {
  final String postId;

  const PostRatingList({super.key, required this.postId});

  @override
  _PostRatingListState createState() => _PostRatingListState();
}

class _PostRatingListState extends State<PostRatingList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(16, 16, 16, 1),
        ),
        child: ListView(children: [
          userRating(ratingId: "E"),
        ]),
      ),
    );
  }
}
