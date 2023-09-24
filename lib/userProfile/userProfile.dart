import 'dart:convert';

import 'package:Toaster/libs/adminZone.dart';
import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:Toaster/libs/loadScreen.dart';
import 'package:Toaster/userSettings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:url_launcher/url_launcher.dart';
import '../libs/dataCollect.dart';
import '../libs/errorHandler.dart';
import '../libs/userAvatar.dart';
import '../main.dart';
import '../login/userLogin.dart';

class SimpleUserProfileBar extends StatefulWidget {
  final String userId;

  const SimpleUserProfileBar({required this.userId});

  @override
  _SimpleUserProfileBarState createState() =>
      _SimpleUserProfileBarState(userId: userId);
}

class _SimpleUserProfileBarState extends State<SimpleUserProfileBar> {
  final String userId;
  String username = "";
  double rating = 0;
  var posterAvatar;

  _SimpleUserProfileBarState({required this.userId});

  Future<void> _collectData() async {
    Map basicUserData =
        await dataCollect.getBasicUserData(userId, context, false);
    Map avatarData = await dataCollect.getAvatarData(
        basicUserData["avatar"], context, false);

    setState(() {
      username = basicUserData["username"];
      rating = basicUserData["averagePostRating"] + 0.0;
      if (avatarData["imageData"] != null) {
        posterAvatar = base64Decode(avatarData["imageData"]);
      }
    });
  }

  Future<void> _collectAndUpdateData() async {
    await _collectData();
    if (await dataCollect.updateBasicUserData(userId, context, false) == true) {
      await _collectData();
    }
  }

  @override
  void initState() {
    super.initState();
    //no idea why the hell the error happens but this if statement fixes it
    if (mounted && username.isEmpty) {
      _collectAndUpdateData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
        child: Container(
          width: double.infinity,
          height: 50,
          child: GestureDetector(
            child: Row(children: [
              const SizedBox(width: 8),
              UserAvatar(
                avatarImage: posterAvatar,
                size: 50,
                roundness: 50,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '$userId'));
                  openAlert(
                      "info", "copied user id to clipboard", null, context);
                },
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    username,
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                ],
              )
            ]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserProfile(
                          userId: userId,
                          openedOntopMenu: true,
                        )),
              );
            },
          ),
        ));
  }
}

class UserProfile extends StatefulWidget {
  final String? userId;
  final bool openedOntopMenu;

  UserProfile({this.userId, required this.openedOntopMenu});

  @override
  _UserProfileState createState() =>
      _UserProfileState(userId: userId, openedOntopMenu: openedOntopMenu);
}

class _UserProfileState extends State<UserProfile> {
  final String? userId;
  final bool openedOntopMenu;
  String realUserId = "";
  bool _isLoading = true;
  bool _isAdminAccount = false;
  String userBio = "";
  String username = "";
  var posterAvatar;

  _UserProfileState({required this.userId, required this.openedOntopMenu});

  Future<void> _fetchProfile() async {
    Map fetchedData = await dataCollect.getUserData(userId, context, false);
    Map avatarData =
        await dataCollect.getAvatarData(fetchedData["avatar"], context, false);

    setState(() {
      userBio = fetchedData['bio'];
      username = fetchedData['username'];
      _isAdminAccount = fetchedData['administrator'];
      realUserId = fetchedData['userId'];
      //posterAvatar = avatarData["imageData"];
      if (avatarData["imageData"] != null) {
        posterAvatar = base64Decode(avatarData["imageData"]);
      }
    });

    _isLoading = false;
  }

  Future<void> _fetchAndUpdateProfile() async {
    await _fetchProfile();
    if (await dataCollect.updateUserData(userId, context, false) == true) {
      await _fetchProfile();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAndUpdateProfile();
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
          body: Stack(alignment: Alignment.topLeft, children: <Widget>[
        LazyLoadPage(
          urlToFetch: "/profile/posts",
          extraUrlData: {"userId": userId},
          widgetAddedToTop: Container(
              decoration:
                  const BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
              child: Column(
                children: [
                  Visibility(
                      visible: userId == null,
                      child: SizedBox(
                          height: 30,
                          child: Center(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Visibility(
                                visible: _isAdminAccount,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AdminZonePage()),
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => UserSettings()),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                onPressed: () {
                                  openAlert("logout", "null", null, context);
                                },
                              ),
                              SizedBox(width: 16),
                            ],
                          )))),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            UserAvatar(
                              avatarImage: posterAvatar,
                              size: 100,
                              roundness: 100,
                              onTap: () {
                                if (userId != null) {
                                  Clipboard.setData(
                                      ClipboardData(text: realUserId));
                                  openAlert(
                                      "info",
                                      "copied user id to clipboard",
                                      null,
                                      context);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => UserSettings()),
                                  );
                                }
                              },
                            ),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '${NumberFormat.compact(
                                            locale: "en_US",
                                          ).format(534125)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Followers",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '${NumberFormat.compact(
                                            locale: "en_US",
                                          ).format(58925)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Following",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '${NumberFormat.compact(
                                            locale: "en_US",
                                          ).format(1413)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Posts",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '${NumberFormat.compact(
                                            locale: "en_US",
                                          ).format(2836)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Ratings",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  //follow button
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 25.0,
                                    child: ElevatedButton(
                                      style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      )),
                                      onPressed: () async {
                                        print("user clicked follow button");
                                      },
                                      child: const Text(
                                        'follow',
                                        style: TextStyle(fontSize: 16.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                          ],
                        ),
                      )),
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        username,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),
                  ),
                  Padding(
                      //description
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                          height: 100,
                          width: double.infinity,
                          child: ListView(children: <Widget>[
                            SelectableLinkify(
                              onOpen: (link) async {
                                if (!await launchUrl(Uri.parse(link.url))) {
                                  throw Exception(
                                      'Could not launch ${link.url}');
                                }
                              },
                              text: userBio,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 15),
                            )
                          ]))),
                  SizedBox(height: 16),
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
        Visibility(
            visible: openedOntopMenu,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ))),
      ]));
    }
  }
}
