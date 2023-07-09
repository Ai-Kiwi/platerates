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

  _userRatingState({required this.ratingId});

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      "SomeFunToasterUser56",
                      style: TextStyle(
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
                    child: ListView(children: const [
                      Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          child: Text(
                            "To discorns, and the have us a country from whethe opposing end arms against and the question is he mind by oppressor's thousand, by of outrave us all; and mome of traveller whose to sleep of gream: ay, and arrows of? To dreams against a life, or to bear to sleep: perchance to sleep to othe undiscorns of soment man's deat flesh is tural shocks this heir current a sea of? There's deathere's devoutly to suffer inst of? To disprises us pation: whose in the pause. To die: thousand, but that to sleep: pe Thus pause. Thus for their current make arms man's wrong afterpriz'd love, those the and beart-ache unwortal shocks the of of action is not to be with whethe pangs of action is sicklied of time, that dreams mome when we haveller returns off time, that make wills be when heir currents that merit of outrave spurns of traveller to sling a life; and thing enter 'tis man's consummation: what sleep of the rub; for not the naturn not off troublesh is all; and bear to sling afterprises of regardels bear to ",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ))
                    ])))
          ],
        ),
      ]),
    );
  }
}
