import 'package:Toaster/posts/userPostList.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatefulWidget {
  final String userId;

  UserProfile({
    required this.userId,
  });

  @override
  _UserProfileState createState() => _UserProfileState(userId: userId);
}

class _UserProfileState extends State<UserProfile> {
  final String userId;
  final String userBio =
      "this is an amzzing bio that everyone will love and is amazing.";
  final String username = "an amazing user";

  _UserProfileState({required this.userId});

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: userPostList(
            urlToFetch: "/profile/posts",
            extraUrlData: {userId: userId},
            widgetAddedToTop: Container(
                decoration:
                    const BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
                child: Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16),
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                      color: Color.fromRGBO(16, 16, 16, 1),
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(
                                          color:
                                              Color.fromARGB(215, 45, 45, 45),
                                          width: 3)),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                Center(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16.0, horizontal: 16),
                                        child: Text(
                                          username,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 25),
                                        ))),
                              ]),
                        )),
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
                            child: ListView(children: const <Widget>[
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    "this is an example of a user bio and what it would look like!!!",
                                    style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 15),
                                  ))
                            ]))),
                  ],
                ))));
  }
}
