import 'package:Toaster/userProfile/userProfile.dart';
import 'package:Toaster/userFeed/userFeed.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'createPost/createPostPhoto.dart';
import 'userLogin.dart';
import 'navbar.dart';

//add better loading system, should have a nice ui as well as handling for when it can't talk to the server

String serverDomain = 'toaster.aikiwi.dev';

void main() {
  if (kDebugMode) {
    serverDomain = '192.168.0.157:3030';
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
                  return const Scaffold(
                      backgroundColor: Color.fromRGBO(16, 16, 16, 1),
                      body: Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 16),
                              child: Text(
                                "Toaster",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 40),
                              ),
                            ),
                            SizedBox(height: 16),
                            CircularProgressIndicator(),
                          ])));
                } else {
                  if (snapshot.hasData && snapshot.data == true) {
                    // User is logged in, navigate to home page
                    return MyHomePage();
                  } else {
                    // User is not logged in, navigate to login page
                    return LoginPage();
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
