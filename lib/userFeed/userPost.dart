import 'dart:convert';

import 'package:Toaster/userLogin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class PostItem extends StatefulWidget {
  final String postId;
  const PostItem({super.key, required this.postId});

  @override
  _PostItemState createState() => _PostItemState(postId);
}

class _PostItemState extends State<PostItem> {
  String postId;
  String title = "";
  String description = "";
  double rating = 0;
  String posterName = "";
  String posterAvatar = "";
  var imageData;
  bool errorOccurred = false;

  _PostItemState(this.postId);

  Future<void> _collectData() async {
    final response = await http.post(
      Uri.parse("http://$serverDomain/post/data"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': userManager.token,
        'postId': postId,
      }),
    );
    if (response.statusCode == 200) {
      try {
        setState(() {
          var jsonData = jsonDecode(response.body);
          title = jsonData["title"];
          description = jsonData["description"];
          rating = double.parse('${jsonData["rating"]}');
          imageData = base64Decode(jsonData['imageData']);
          posterName = jsonData["posterData"]['username'];
          errorOccurred = false;
        });
      } catch (err) {}
      return;
    } else {
      print(response.body);
      setState(() {
        errorOccurred = true;
      });
      print(response.statusCode);
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    //no idea why the hell the error happens but this if statement fixes it
    if (mounted) {
      _collectData();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (errorOccurred == true) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: Container(
              decoration: BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
              child: Center(
                  child: Text(
                "error getting post",
                style: TextStyle(color: Colors.red, fontSize: 20),
              ))));
    } else {
      if (title.isEmpty && description.isEmpty) {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Container(
                decoration: BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
                child: Center(
                  child: CircularProgressIndicator(),
                )));
      } else {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Container(
                decoration: BoxDecoration(
                    color: Color.fromARGB(215, 40, 40, 40),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Color.fromARGB(215, 45, 45, 45), width: 3)),
                width: double.infinity,
                child: Column(children: <Widget>[
                  const SizedBox(height: 16.0),
                  //user logo and name
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              width: 2,
                              color: const Color.fromARGB(255, 45, 45, 45)),
                        ),
                        width: double.infinity,
                        height: 35,
                        child: Row(children: [
                          const SizedBox(width: 4),
                          //SizedBox(
                          //    height: 25,
                          //    child: CircleAvatar(
                          //      backgroundImage: NetworkImage(posterAvatar),
                          //      radius: 15,
                          //    )),
                          Text(posterName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              )),
                        ]),
                      )),
                  const SizedBox(height: 8.0),
                  Padding(
                      // image
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          child: Image.memory(
                            imageData,
                            width: double.infinity,
                            fit: BoxFit.fill,
                          ))),
                  const SizedBox(height: 8.0),
                  //input buttons
                  Row(children: <Widget>[
                    // 2nd row of items
                    const SizedBox(width: 16.0),
                    //rate it button
                    SizedBox(
                      height: 25,
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 1.0), // Adjust the padding values
                          ),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Color.fromARGB(255, 75, 75, 75)),
                        ),
                        onPressed: () {
                          Alert(
                            context: context,
                            type: AlertType.info,
                            title: "rating has not been added yet",
                            desc:
                                "It's not like it's the main part of the app or anything.",
                            buttons: [
                              DialogButton(
                                child: Text(
                                  "ok",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                                onPressed: () => Navigator.pop(context),
                                width: 120,
                              )
                            ],
                          ).show();
                        },
                        child: RatingBarIndicator(
                          rating: rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 15.0,
                          direction: Axis.horizontal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    //report it button
                    SizedBox(
                      height: 25,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 15),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5.0, vertical: 1.0),
                          backgroundColor: Colors.red,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Alert(
                            context: context,
                            type: AlertType.info,
                            title: "reporting has not been added yet",
                            desc:
                                "idk, just close your eyes, it's really not that hard",
                            buttons: [
                              DialogButton(
                                child: Text(
                                  "ok",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                                onPressed: () => Navigator.pop(context),
                                width: 120,
                              )
                            ],
                          ).show();
                        },
                        child: const Text("report 🚩",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8.0),
                  //title and desc
                  Padding(
                    //title
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            width: 2,
                            color: const Color.fromARGB(255, 45, 45, 45)),
                      ),
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            title,
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          )),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Padding(
                      //description
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                                width: 2,
                                color: const Color.fromARGB(255, 45, 45, 45)),
                          ),
                          child: ListView(
                            children: [
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ))
                            ],
                          ))),
                  const SizedBox(height: 16.0),
                ])));
      }
    }
  }
}
