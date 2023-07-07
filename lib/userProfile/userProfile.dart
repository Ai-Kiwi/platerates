import 'dart:convert';

import 'package:Toaster/libs/loadScreen.dart';
import 'package:Toaster/posts/userPostList.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../main.dart';
import '../userLogin.dart';

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
  bool _isLoading = true;
  String userBio = "";
  String username = "";

  _UserProfileState({required this.userId});

  Future<void> _fetchProfile() async {
    final response = await http.post(
      Uri.parse("$serverDomain/profile/data"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'token': userManager.token,
        'userId': userId,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        var fetchedData = jsonDecode(response.body);
        userBio = fetchedData['bio'];
        username = fetchedData['username'];
        print(userBio);
        print(username);
      });
    } else {
      setState(() {
        Alert(
          context: context,
          type: AlertType.error,
          title: "failed fetching account data",
          desc: response.body,
          buttons: [
            DialogButton(
              onPressed: () => Navigator.pop(context),
              width: 120,
              child: const Text(
                "ok",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          ],
        ).show();
      });
    }
    _isLoading = false;
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading == true) {
      return LoadingScreen(
        toasterLogo: false,
      );
    } else {
      return Scaffold(
          body: UserPostList(
              urlToFetch: "/profile/posts",
              extraUrlData: {"userId": userId},
              widgetAddedToTop: Container(
                  decoration:
                      const BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
                  child: Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 100,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                        color:
                                            const Color.fromRGBO(16, 16, 16, 1),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        border: Border.all(
                                            color: const Color.fromARGB(
                                                215, 45, 45, 45),
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
                                    color:
                                        const Color.fromARGB(255, 45, 45, 45)),
                              ),
                              child: ListView(children: <Widget>[
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      userBio,
                                      style: const TextStyle(
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 15),
                                    ))
                              ]))),
                    ],
                  ))));
    }
  }
}
