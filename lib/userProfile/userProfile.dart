import 'dart:convert';

import 'package:Toaster/libs/adminZone.dart';
import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:Toaster/libs/loadScreen.dart';
import 'package:Toaster/userSettings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../libs/smoothTransitions.dart';
import '../libs/userAvatar.dart';
import '../main.dart';
import '../login/userLogin.dart';

class UserProfile extends StatefulWidget {
  final String? userId;

  UserProfile({
    this.userId,
  });

  @override
  _UserProfileState createState() => _UserProfileState(userId: userId);
}

class _UserProfileState extends State<UserProfile> {
  final String? userId;
  bool _isLoading = true;
  bool _isAdminAccount = false;
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
        _isAdminAccount = fetchedData['administrator'];
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
        body: LazyLoadPage(
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
                              //Container(
                              //  width: 100,
                              //  height: 100,
                              //  decoration: BoxDecoration(
                              //      color: const Color.fromRGBO(16, 16, 16, 1),
                              //      borderRadius: BorderRadius.circular(10.0),
                              //      border: Border.all(
                              //          color: const Color.fromARGB(
                              //              215, 45, 45, 45),
                              //          width: 3)),
                              //  child: const Center(
                              //    child: CircularProgressIndicator(),
                              //  ),
                              //),
                              UserAvatar(
                                avatarImage: null,
                                size: 100,
                                roundness: 30,
                              ),
                              Center(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0, horizontal: 16),
                                      child: Text(
                                        username,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 25),
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
                          child: ListView(children: <Widget>[
                            Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  userBio,
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      fontSize: 15),
                                ))
                          ]))),
                  Visibility(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    //user settings box
                    child: Row(
                      children: [
                        SizedBox(
                          height: 33,
                          width: 75,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 15),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0, vertical: 1.0),
                              backgroundColor:
                                  const Color.fromARGB(255, 45, 45, 45),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                  smoothTransitions.slideUp(UserSettings()));
                            },
                            child: const Text("settings",
                                style: TextStyle(
                                    color: Color.fromARGB(210, 255, 255, 255),
                                    fontWeight: FontWeight.normal)),
                          ),
                        ),
                        Visibility(
                            visible: _isAdminAccount,
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 33,
                                  width: 95,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontSize: 15),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0, vertical: 1.0),
                                      backgroundColor:
                                          const Color.fromARGB(255, 45, 45, 45),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                          smoothTransitions
                                              .slideUp(AdminZonePage()));
                                    },
                                    child: const Text("admin zone",
                                        style: TextStyle(
                                            color: Color.fromARGB(
                                                210, 255, 255, 255),
                                            fontWeight: FontWeight.normal)),
                                  ),
                                ),
                              ],
                            )),
                        Expanded(child: Center()),
                        SizedBox(
                          height: 33,
                          width: 75,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 15),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0, vertical: 1.0),
                              backgroundColor:
                                  const Color.fromARGB(255, 45, 45, 45),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Alert(
                                context: context,
                                type: AlertType.info,
                                title: "who would you like to logout?",
                                desc:
                                    "select which devices you wish to logout.",
                                buttons: [
                                  //DialogButton(
                                  //  onPressed: () async {},
                                  //  color: Colors.green,
                                  //  child: const Text(
                                  //    "this",
                                  //    style: TextStyle(
                                  //        color: Colors.white, fontSize: 20),
                                  //  ),
                                  //),
                                  DialogButton(
                                    color: Colors.green,
                                    child: const Text(
                                      "everyone",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final response = await http.post(
                                        Uri.parse("$serverDomain/login/logout"),
                                        headers: <String, String>{
                                          'Content-Type':
                                              'application/json; charset=UTF-8',
                                        },
                                        body: jsonEncode(<String, String>{
                                          'token': userManager.token,
                                        }),
                                      );
                                      if (response.statusCode == 200) {
                                        //if true do nothing and then it will display
                                        //Navigator.pop(context);
                                        //Navigator.push(
                                        //    context,
                                        //    MaterialPageRoute(
                                        //        builder: (context) =>
                                        //            LoginPage()));
                                        Phoenix.rebirth(context);
                                      } else {
                                        Alert(
                                          context: context,
                                          type: AlertType.error,
                                          title: "failed logging out",
                                          desc: response.body,
                                          buttons: [
                                            DialogButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              width: 120,
                                              child: const Text(
                                                "ok",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20),
                                              ),
                                            )
                                          ],
                                        ).show();
                                      }
                                    },
                                  ),
                                  DialogButton(
                                    color: Colors.red,
                                    child: const Text(
                                      "cancel",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  )
                                ],
                              ).show();
                            },
                            child: const Text("logout",
                                style: TextStyle(
                                    color: Color.fromARGB(210, 255, 255, 255),
                                    fontWeight: FontWeight.normal)),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              )),
          widgetAddedToEnd: const Center(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                child: Text(
                  "end of posts.",
                  style: TextStyle(color: Colors.white, fontSize: 25),
                )),
          ),
          widgetAddedToBlank: const Center(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                child: Text(
                  "no posts to display",
                  style: TextStyle(color: Colors.white, fontSize: 25),
                )),
          ),
        ),
      );
    }
  }
}
