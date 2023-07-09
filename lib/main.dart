import 'package:Toaster/libs/loadScreen.dart';
import 'package:Toaster/userProfile/userProfile.dart';
import 'package:Toaster/userFeed/userFeed.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'createPost/createPostPhoto.dart';
import 'userLogin.dart';
import 'navbar.dart';

//add better loading system, should have a nice ui as well as handling for when it can't talk to the server

String serverDomain = 'https://toaster.aikiwi.dev';
bool productionMode = false;

void main() {
  if (productionMode == false) {
    serverDomain = 'http://192.168.0.157:3030';
  }
  runApp(const MyApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            home: StreamBuilder<bool>(
              stream: userManager.checkLoginStateStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show a loading indicator while the authentication state is being fetched
                  return LoadingScreen(
                    toasterLogo: true,
                  );
                } else {
                  if (snapshot.hasData && snapshot.data == true) {
                    // User is logged in, navigate to home page
                    return MyHomePage();
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
  CameraPage(),
  UserProfile(userId: userManager.userId)
];

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

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
