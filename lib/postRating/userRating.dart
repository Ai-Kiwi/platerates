import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class userRating extends StatefulWidget {
  final String ratingId;

  userRating({super.key, required this.ratingId});

  @override
  _userRatingState createState() => _userRatingState(ratingId: ratingId);
}

class _userRatingState extends State<userRating> {
  final String ratingId;
  String ratingText = "";
  String posterName = "";
  double ratingValue = 0;
  bool loading = true;

  _userRatingState({required this.ratingId});

  @override
  Widget build(BuildContext context) {
    if (loading == true) {
      return SizedBox(
          width: double.infinity,
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ));
    } else {
      return Padding(
        //post item
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
        child: Column(children: [
          Row(
            //top feild
            children: [
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                  child: Center(
                    child: CircleAvatar(),
                  )),
              Expanded(
                //name and rating
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        posterName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      RatingBarIndicator(
                        rating: 1.33,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 25.0,
                        direction: Axis.horizontal,
                      ),
                    ]),
              ),
              FittedBox(
                //3 dots on post
                child: Center(
                    child: PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 35, // Adjust the size of the icon
                    color: Colors.grey[500],
                  ),
                  onSelected: (value) {},
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ];
                  },
                )),
              ),
            ],
          ),
          Row(
            //bottom feild
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //const Padding(
              //  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              //  child: Center(
              //      child: Icon(
              //    //plus button
              //    Icons.thumb_up_outlined,
              //    color: Colors.white,
              //  )),
              //),
              const SizedBox(width: 48),
              Flexible(
                  //text for rating
                  child: Container(
                      decoration: BoxDecoration(
                          color: const Color.fromRGBO(16, 16, 16, 1),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: const Color.fromARGB(215, 45, 45, 45),
                              width: 3)),
                      height: 150,
                      child: ListView(children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                            child: Text(
                              ratingText,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ))
                      ])))
            ],
          ),
        ]),
      );
    }
  }
}
