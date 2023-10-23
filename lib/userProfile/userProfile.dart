import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:Toaster/chat/openChat.dart';
import 'package:Toaster/libs/adminZone.dart';
import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:Toaster/libs/loadScreen.dart';
import 'package:Toaster/login/userLogin.dart';
import 'package:Toaster/main.dart';
import 'package:Toaster/userProfile/userSettings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
//import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../libs/dataCollect.dart';
import '../libs/userAvatar.dart';

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
    // ignore: use_build_context_synchronously
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
    // ignore: use_build_context_synchronously
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
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: GestureDetector(
            child: Row(children: [
              const SizedBox(width: 8),
              UserAvatar(
                avatarImage: posterAvatar,
                size: 50,
                roundness: 50,
                onTapFunction: 'copyUserId',
                context: context,
                userId: userId,
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    username,
                    style: const TextStyle(color: Colors.white, fontSize: 25),
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
  bool followingUser = false;
  var posterAvatar;
  //display data for profile
  int followersCount = 0;
  int followingCount = 0;
  int postCount = 0;
  int ratingCount = 0;
  String updateValue = "";
  //follow info
  bool userFollowing = false;

  _UserProfileState({required this.userId, required this.openedOntopMenu});

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    Map fetchedData = await dataCollect.getUserData(userId, context, false);
    Map avatarData =
        // ignore: use_build_context_synchronously
        await dataCollect.getAvatarData(fetchedData["avatar"], context, false);

    setState(() {
      userBio = fetchedData['bio'];
      username = fetchedData['username'];
      _isAdminAccount = fetchedData['administrator'];
      realUserId = fetchedData['userId'];
      followersCount = fetchedData['followersCount'];
      followingCount = fetchedData['followingCount'];
      postCount = fetchedData['postCount'];
      ratingCount = fetchedData['ratingCount'];
      userFollowing = fetchedData["relativeViewerData"]['following'];
      if (avatarData["imageData"] != null) {
        posterAvatar = base64Decode(avatarData["imageData"]);
      }
      updateValue = randomString();
      _isLoading = false;
    });
  }

  Future<void> _fetchAndUpdateProfile() async {
    await _fetchProfile();
    // ignore: use_build_context_synchronously
    if (await dataCollect.updateUserData(userId, context, false) == true) {
      await _fetchProfile();
    }
  }

  Future<void> _followToggle() async {
    var newFollowState = !userFollowing;
    final response = await http.post(
      Uri.parse('$serverDomain/profile/follow'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "token": userManager.token,
        "following": newFollowState,
        "userId": userId
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        userFollowing = newFollowState;
        if (newFollowState == true) {
          followersCount = followersCount + 1;
        } else {
          followersCount = followersCount - 1;
        }
      });
    } else {
      openAlert("error", "failed to change follow state", null, context, null);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAndUpdateProfile();
    //Timer.periodic(Duration(seconds: 1), (Timer t) => _fetchAndUpdateProfile());
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
    }
    return Scaffold(
        backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
        body: Stack(alignment: Alignment.topLeft, children: <Widget>[
          LazyLoadPage(
            key: UniqueKey(),
            urlToFetch: "/profile/posts",
            extraUrlData: {"userId": realUserId},
            widgetAddedToTop: Column(
              children: [
                const SizedBox(height: 32),
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
                                        builder: (context) => AdminZonePage()),
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
                                      builder: (context) =>
                                          const UserSettings()),
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
                                openAlert(
                                    "logout", "null", null, context, null);
                              },
                            ),
                            const SizedBox(width: 16),
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
                            onTapFunction: 'copyUserId',
                            context: context,
                            userId: userId,
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
                                        NumberFormat.compact(
                                          locale: "en_US",
                                        ).format(followersCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
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
                                        NumberFormat.compact(
                                          locale: "en_US",
                                        ).format(followingCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
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
                                        NumberFormat.compact(
                                          locale: "en_US",
                                        ).format(postCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
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
                                        NumberFormat.compact(
                                          locale: "en_US",
                                        ).format(ratingCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
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
                              Visibility(
                                visible: userId != null,
                                child: Padding(
                                  //follow button
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                            style: OutlinedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                            )),
                                            onPressed: _followToggle,
                                            child: userFollowing
                                                ? const Text(
                                                    "unfollow",
                                                    style: TextStyle(
                                                        fontSize: 16.0),
                                                  )
                                                : const Text(
                                                    "follow",
                                                    style: TextStyle(
                                                        fontSize: 16.0),
                                                  )),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                            ),
                                            backgroundColor: Colors.grey[800],
                                          ),
                                          onPressed: () async {
                                            final response = await http.post(
                                              Uri.parse(
                                                  "$serverDomain/chat/openChat"),
                                              headers: <String, String>{
                                                'Content-Type':
                                                    'application/json; charset=UTF-8',
                                              },
                                              body: jsonEncode({
                                                "token": userManager.token,
                                                "chatUserId": realUserId,
                                              }),
                                            );

                                            if (response.statusCode == 200) {
                                              final Map responseJsonData =
                                                  jsonDecode(response.body);

                                              // ignore: use_build_context_synchronously
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          FullPageChat(
                                                            chatRoomId:
                                                                responseJsonData[
                                                                    "chatRoomId"],
                                                          )));
                                            } else {
                                              // ignore: use_build_context_synchronously
                                              openAlert(
                                                  "error",
                                                  "failed opening message chat",
                                                  response.body,
                                                  context,
                                                  null);
                                            }
                                          },
                                          child: const Text(
                                            "open chat",
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                        ),
                                      ),
                                    ],
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
                      style: const TextStyle(color: Colors.white, fontSize: 25),
                    ),
                  ),
                ),
                Padding(
                    //description
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: ListView(
                            padding: EdgeInsets.zero,
                            children: <Widget>[
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
                const SizedBox(height: 16),
              ],
            ),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
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
