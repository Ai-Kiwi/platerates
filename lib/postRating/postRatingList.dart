import 'package:Toaster/postRating/userRating.dart';
import 'package:flutter/material.dart';

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
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(16, 16, 16, 1),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  userRating(
                    ratingId: "",
                  ),
                  userRating(
                    ratingId: "",
                  ),
                  userRating(
                    ratingId: "",
                  ),
                  userRating(
                    ratingId: "",
                  ),
                ],
              ),
            ),
            Container(
              //bottom area where exit button is
              width: double.infinity,
              height: 50,
            )
          ],
        ),
      ),
    );
  }
}
