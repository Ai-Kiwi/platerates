import 'dart:convert';

import 'package:Toaster/libs/loadScreen.dart';
import 'package:Toaster/searchPage.dart';
import 'package:Toaster/userProfile/userProfile.dart';
import 'package:Toaster/userFeed/userFeed.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:json_cache/json_cache.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'createPost/createPostPhoto.dart';
import 'errorPages.dart';
import 'login/userLogin.dart';
import 'navbar.dart';

//add better loading system, should have a nice ui as well as handling for when it can't talk to the server

String serverDomain = 'https://toaster.aikiwi.dev';
late JsonCacheMem jsonCache;

//make sure it is running the latest verison
late String appName;
late String packageName;
late String version;
late String buildNumber;

void main() {
  //make sure something a rather to use app verison
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode == true) {
    serverDomain = 'http://192.168.0.157:3030';
  }

  runApp(Phoenix(child: const MyApp()));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Stream<String> initializeApp() async* {
    //load in json cache stuff
    final sharedPrefs = await SharedPreferences.getInstance();
    jsonCache = JsonCacheMem(JsonCacheSharedPreferences(sharedPrefs));
    jsonCache.clear();

    //setup verison stuff
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;

    //contact server and get verison
    try {
      final response = await http.post(
        Uri.parse("$serverDomain/latestVersion"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) {
        if (response.body != '$version+$buildNumber') {
          yield "client-out-of-date";
          return;
        }
      } else {
        //really should be error for this
      }
    } catch (err) {
      yield "server-contact-error";
      return;
    }

    //load in token
    if (userManager.token == "") {
      await userManager.loadTokenFromStoreage();
    }

    var loginStateData = await userManager.checkLoginState();
    if (loginStateData == true) {
      yield "valid-token";
      return;
    } else {
      yield "invalid-token";
      return;
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.green,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: MaterialApp(
            title: 'Toaster',
            theme: ThemeData(
                primaryColor: Colors.green, primarySwatch: Colors.green),
            home: StreamBuilder<String>(
              stream: initializeApp(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show a loading indicator while the authentication state is being fetched
                  return LoadingScreen(
                    toasterLogo: true,
                  );
                } else {
                  print(snapshot.data);
                  //if (snapshot.hasData && snapshot.data == true) {
                  if (snapshot.data == "valid-token") {
                    // User is logged in, navigate to home page
                    return MyHomePage();
                  } else if (snapshot.data == "server-contact-error") {
                    //error contacting server
                    return DisplayErrorMessagePage(
                        errorMessage: "error contacting server");
                  } else if (snapshot.data == "client-out-of-date") {
                    //  //client is out of date
                    return DisplayErrorMessagePage(
                        errorMessage: "client out of date");
                  } else {
                    // User is not logged in, navigate to login page
                    return const LoginPage();
                  }
                }
              },
            )));
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

List<Widget> pages = <Widget>[
  userFeed(),
  SearchPage(),
  CameraPage(),
  UserProfile(openedOntopMenu: false),
];

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  double containerWidth = 200.0;
  double containerHeight = 300.0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        body: Center(
          child: pages.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: UserNavbar(
          selectedIndex: _selectedIndex,
          onClicked: _onItemSelected,
        ));
  }
}
