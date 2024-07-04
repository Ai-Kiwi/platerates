import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:PlateRates/chat/openChat.dart';
import 'package:PlateRates/libs/adminZone.dart';
import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/lazyLoadPage.dart';
import 'package:PlateRates/libs/loadScreen.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:PlateRates/main.dart';
import 'package:PlateRates/userProfile/userSettings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:toggle_switch/toggle_switch.dart';
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
      //rating = basicUserData["averagePostRating"] + 0.0;
      if (avatarData["imageData"] != null) {
        posterAvatar = base64Decode(avatarData["imageData"]);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    //no idea why the hell the error happens but this if statement fixes it
    if (mounted && username.isEmpty) {
      _collectData();
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
  final String userId;
  final bool openedOntopMenu;

  UserProfile({required this.userId, required this.openedOntopMenu});

  @override
  _UserProfileState createState() =>
      _UserProfileState(userId: userId, openedOntopMenu: openedOntopMenu);
}

class _UserProfileState extends State<UserProfile> {
  final String userId;
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
  int ProfileItemIndex = 0;
  String urlToSearch = "/profile/posts";
  final verifiedAccounts = {
    "github": {},
  };

  _UserProfileState({required this.userId, required this.openedOntopMenu});

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    //print(userId);
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
      userFollowing = fetchedData["requesterFollowing"];
      if (avatarData["imageData"] != null) {
        posterAvatar = base64Decode(avatarData["imageData"]);
      }
      updateValue = randomString();
      _isLoading = false;
    });
  }

  Future<void> _followToggle() async {
    var newFollowState = !userFollowing;
    final response = await http.post(
      Uri.parse('$serverDomain/profile/follow'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: userManager.token
      },
      body: jsonEncode({
        "following": newFollowState,
        "user_id": userId,
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
      dataCollect.clearBasicUserData(userId);
      dataCollect.clearUserData(userId);
    } else {
      openAlert(
          "error", "failed to change follow state", null, context, null, null);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    //Timer.periodic(Duration(seconds: 1), (Timer t) => _fetchAndUpdateProfile());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void changeUserContentOpen(index) {
    setState(() {
      ProfileItemIndex = index;
      if (index == 0) {
        urlToSearch = "/profile/posts";
      } else {
        urlToSearch = "/profile/ratings";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //user is not logged in so show login screen
    if (_isLoading == true) {
      return LoadingScreen(
        plateRatesLogo: false,
      );
    }
    return Scaffold(
        body: PageBackButton(
            warnDiscardChanges: false,
            active: openedOntopMenu,
            child: Stack(
              children: [
                SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: posterAvatar != null
                        ? ImageFiltered(
                            imageFilter:
                                ImageFilter.blur(sigmaX: 7.5, sigmaY: 7.5),
                            child: Image.memory(
                              posterAvatar,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          )
                        : Center()),
                Container(
                  color:
                      Colors.black.withOpacity(posterAvatar != null ? 0.75 : 0),
                  width: double.infinity,
                  height: double.infinity,
                ),
                LazyLoadPage(
                  openFullContentTree: true,
                  key: UniqueKey(),
                  urlToFetch: urlToSearch,
                  //should include you are fetching user id data and which one
                  widgetAddedToTop: Column(
                    children: [
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 30,
                        child: userId == userManager.userId
                            ? Center(
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
                                            builder: (context) =>
                                                UserSettings()),
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
                                      openAlert("logout", "null", null, context,
                                          null, null);
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ))
                            : Center(),
                      ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              numberFormatter
                                                  .format(followersCount),
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
                                              numberFormatter
                                                  .format(followingCount),
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
                                              numberFormatter.format(postCount),
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
                                              numberFormatter
                                                  .format(ratingCount),
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
                                      visible: userId != userManager.userId,
                                      child: Padding(
                                        //follow button
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16.0),
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
                                                        BorderRadius.circular(
                                                            16.0),
                                                  ),
                                                  backgroundColor:
                                                      Colors.grey[800],
                                                ),
                                                onPressed: () async {
                                                  final response =
                                                      await http.post(
                                                    Uri.parse(
                                                        "$serverDomain/chat/openChat"),
                                                    headers: <String, String>{
                                                      'Content-Type':
                                                          'application/json; charset=UTF-8',
                                                    },
                                                    body: jsonEncode({
                                                      "token":
                                                          userManager.token,
                                                      "chat_user_id":
                                                          realUserId,
                                                    }),
                                                  );

                                                  if (response.statusCode ==
                                                      200) {
                                                    final Map responseJsonData =
                                                        jsonDecode(
                                                            response.body);

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
                                                        null,
                                                        null);
                                                  }
                                                },
                                                child: const Text(
                                                  "open chat",
                                                  style:
                                                      TextStyle(fontSize: 16.0),
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
                            style: const TextStyle(
                                color: Colors.white, fontSize: 25),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: (userBio != ""),
                        child: Padding(
                            //description
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                                height: 100,
                                width: double.infinity,
                                child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: <Widget>[
                                      SelectableLinkify(
                                        onOpen: (link) async {
                                          if (!await launchUrl(
                                              Uri.parse(link.url))) {
                                            throw Exception(
                                                'Could not launch ${link.url}');
                                          }
                                        },
                                        text: userBio,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 15),
                                      )
                                    ]))),
                      ),
                      //VerifiedAccounts(verifiedAccountsData: verifiedAccounts),
                      const SizedBox(height: 16),
                      Padding(
                        //share mode selection
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ToggleSwitch(
                            minWidth: double.infinity,
                            cornerRadius: 15.0,
                            initialLabelIndex: ProfileItemIndex,
                            totalSwitches: 2,
                            activeBgColors: [
                              [Theme.of(context).primaryColor],
                              [Theme.of(context).primaryColor]
                            ],
                            centerText: true,
                            activeFgColor: Colors.white,
                            inactiveBgColor:
                                const Color.fromARGB(255, 40, 40, 40),
                            inactiveFgColor: Colors.white,
                            labels: const ['Posts', 'Ratings'],
                            onToggle: changeUserContentOpen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                  widgetAddedToEnd: const Center(
                      child: Column(
                    children: [
                      SizedBox(height: 16),
                      Text(
                        "end of posts",
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                      SizedBox(height: 128),
                    ],
                  )),
                  widgetAddedToBlank: const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16),
                        child: Text(
                          "no posts to display",
                          style: TextStyle(color: Colors.white, fontSize: 25),
                        )),
                  ),
                  itemsPerPage: 5, headers: {"user_id": userId},
                ),
              ],
            )));
  }
}

class VerifiedAccounts extends StatelessWidget {
  final verifiedAccountsData;

  const VerifiedAccounts({super.key, required this.verifiedAccountsData});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Visibility(
        visible: verifiedAccountsData.isNotEmpty,
        child: Column(
          children: [
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  //
                  Visibility(
                    visible: verifiedAccountsData.containsKey('github'),
                    child: SingleVerifiedAccountItem(
                      accountIcon: FontAwesomeIcons.github,
                      accountUsername: verifiedAccountsData['github']
                          ['username'],
                    ),
                  ),
                  //
                  Visibility(
                    visible: verifiedAccountsData.containsKey('twitter'),
                    child: SingleVerifiedAccountItem(
                      accountIcon: FontAwesomeIcons.twitter,
                      accountUsername: verifiedAccountsData['twitter']
                          ['username'],
                    ),
                  ),
                  //
                  Visibility(
                    visible: verifiedAccountsData.containsKey('snapchat'),
                    child: SingleVerifiedAccountItem(
                      accountIcon: FontAwesomeIcons.snapchat,
                      accountUsername: verifiedAccountsData['snapchat']
                          ['username'],
                    ),
                  ),
                  //
                  Visibility(
                    visible: verifiedAccountsData.containsKey('instagram'),
                    child: SingleVerifiedAccountItem(
                      accountIcon: FontAwesomeIcons.instagram,
                      accountUsername: verifiedAccountsData['instagram']
                          ['username'],
                    ),
                  ),

                  //
                  Visibility(
                    visible: verifiedAccountsData.containsKey('whatsapp'),
                    child: SingleVerifiedAccountItem(
                      accountIcon: FontAwesomeIcons.whatsapp,
                      accountUsername: verifiedAccountsData['whatsapp']
                          ['username'],
                    ),
                  ),
                  //
                  Visibility(
                    visible: verifiedAccountsData.containsKey('telegram'),
                    child: SingleVerifiedAccountItem(
                      accountIcon: FontAwesomeIcons.telegram,
                      accountUsername: verifiedAccountsData['telegram']
                          ['username'],
                    ),
                  ),
                  //
                  Visibility(
                    visible: verifiedAccountsData.containsKey('reddit'),
                    child: SingleVerifiedAccountItem(
                      accountIcon: FontAwesomeIcons.reddit,
                      accountUsername: verifiedAccountsData['reddit']
                          ['username'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}

//verifiedAccountsData.containsKey('github')
class SingleVerifiedAccountItem extends StatelessWidget {
  final accountIcon;
  final String accountUsername;

  const SingleVerifiedAccountItem(
      {super.key, required this.accountIcon, required this.accountUsername});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
            style: BorderStyle.solid,
            width: 1,
          )),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            FaIcon(
              accountIcon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 2),
            Center(
              child: Text(
                accountUsername,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

class LoggedInUserTab extends StatelessWidget {
  const LoggedInUserTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (userManager.userId == "" || userManager.loggedIn == false) {
      return const LoginPage();
    }
    return UserProfile(userId: userManager.userId, openedOntopMenu: false);
  }
}
