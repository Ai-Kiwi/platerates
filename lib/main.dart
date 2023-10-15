import 'dart:convert';

import 'package:Toaster/chat/chatList.dart';
import 'package:Toaster/libs/loadScreen.dart';
import 'package:Toaster/notifications/appNotificationHandler.dart';
import 'package:Toaster/notifications/notificationPageList.dart';
import 'package:Toaster/userProfile/userProfile.dart';
import 'package:Toaster/userFeed/userFeed.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_cache/json_cache.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'createPost/createPostPhoto.dart';
import 'pageNotices.dart';
import 'login/userLogin.dart';
import 'navbar.dart';

String serverDomain = 'https://toaster.aikiwi.dev';
String serverWebsocketDomain = 'wss://toaster.aikiwi.dev';

void main() {
  //make sure something a rather to use app verison

  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode == true) {}

  if (FlavorConfig.instance.variables["release"] == "test") {
    serverDomain = 'http://192.168.0.157:3030';
    serverWebsocketDomain = 'ws://192.168.0.157:3030';
  } else if (FlavorConfig.instance.variables["release"] == "dev") {
    serverDomain = 'https://dev.toaster.aikiwi.dev';
    serverWebsocketDomain = 'wss://dev.toaster.aikiwi.dev';
  }

  runApp(Phoenix(child: const MyApp()));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
}

late JsonCacheMem jsonCache;
//make sure it is running the latest verison
late String appName;
late String packageName;
late String version;
late String buildNumber;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Stream<String> initializeApp() async* {
    //setup verison stuff
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;

    //load in json cache stuff
    await Hive.initFlutter();
    final box =
        await Hive.openBox<String>('appBox'); // it must be a Box<String>.
    jsonCache = JsonCacheMem(JsonCacheHive(box));

    //if I change reset data this also needs to be changed in login script as well as logout script in alerts
    var expireTime = await jsonCache.value("expire-data");
    if (expireTime == null) {
      print("cache expire time is null");
      await jsonCache.clear();
      await jsonCache.refresh("expire-data", {
        "expireTime": DateTime.now().day,
        "clientVersion": '$version+$buildNumber'
      });
    } else {
      if (expireTime["expireTime"] < (DateTime.now().day - 7)) {
        print("cache expire time has expired");
        await jsonCache.clear();
        await jsonCache.refresh("expire-data", {
          "expireTime": DateTime.now().day,
          "clientVersion": '$version+$buildNumber'
        });
      } else {
        if (expireTime["clientVersion"] != '$version+$buildNumber') {
          print("cache version is old");
          await jsonCache.clear();
          await jsonCache.refresh("expire-data", {
            "expireTime": DateTime.now().day,
            "clientVersion": '$version+$buildNumber'
          });
        } else {
          print("cache expire time is still active");
        }
      }
    }

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
          print('server : ${response.body}');
          print('client : $version+$buildNumber');
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

    await initNotificationHandler(); //also handles firebase

    //load notfcation stuff if opened
    var sharedPrefs = await SharedPreferences.getInstance();

    var notData = sharedPrefs.getString('notificationOnBootData');
    print("noti thingy is $notData");
    if (notData != null) {
      if (notData != '') {
        openNotificationOnBootData = notData;
        print("loaded ");
        sharedPrefs.setString('notificationOnBootData', '');
      }
    }

    //respond with if token is valid
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
    return FlavorBanner(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.green,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: MaterialApp(
                title: 'Toaster',
                theme: ThemeData(
                  primaryColor: Colors.green,
                  primarySwatch: Colors.green,
                  dialogBackgroundColor: Color.fromRGBO(16, 16, 16, 1),
                ),
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
                            errorMessage: "client-out-of-date");
                      } else {
                        // User is not logged in, navigate to login page
                        return const LoginPage();
                      }
                    }
                  },
                ))));
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

List<Widget> pages = <Widget>[
  userFeed(),
  FullPageChatList(),
  CameraPage(),
  notificationPageList(),
  UserProfile(openedOntopMenu: false),
];

Future<void> testNotificationOnBootData(context) async {
  if (openNotificationOnBootData != "") {
    openNotification(openNotificationOnBootData, context);

    openNotificationOnBootData = "";
    var sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.setString('notificationOnBootData', '');
  }
}

var updateUnreadNotificationCount;

class _MyHomePageState extends State<MyHomePage> {
  bool userAcceptedMigration = false;
  int _selectedIndex = 0;
  double containerWidth = 200.0;
  double containerHeight = 300.0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    updateUnreadNotificationCount = _updateUnreadNotificationCount;
    updateUnreadNotificationCount();
  }

  int unreadNotificationCount = 0;
  int unreadMessageCount = 0;

  Future<void> _updateUnreadNotificationCount() async {
    var response = await http.post(
      Uri.parse("$serverDomain/notification/unreadCount"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': userManager.token,
      }),
    );

    if (response.statusCode == 200) {
      print(response.body);
      var jsonData = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          unreadNotificationCount = jsonData['unreadCount'];
          //unreadMessageCount = jsonData['unreadMessageCount'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate the aspect ratio
    double aspectRatio = screenHeight / screenWidth;

    if (aspectRatio < 1.5) {
      return DisplayErrorMessagePage(errorMessage: "screen to wide");
    }

    if (userAcceptedMigration == false && kIsWeb == true) {
      return migrateToAppPage(
        ignorePrompt: () {
          setState(() {
            userAcceptedMigration = true;
          });
        },
      );
    }

    //see if notifcation has been clicked and if so display it
    testNotificationOnBootData(context);

    return Scaffold(
        extendBody: true,
        body: Center(
          child: pages.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: UserNavbar(
          notificationCount: unreadNotificationCount,
          selectedIndex: _selectedIndex,
          onClicked: _onItemSelected,
        ));
  }
}

//export PATH="$PATH":"$HOME/.pub-cache/bin"
//flutterfire