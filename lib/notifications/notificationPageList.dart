import 'package:PlateRates/libs/lazyLoadPage.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:flutter/material.dart';

class notificationPageList extends StatefulWidget {
  const notificationPageList({super.key});

  @override
  _notificationPageListState createState() => _notificationPageListState();
}

class _notificationPageListState extends State<notificationPageList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (userManager.loggedIn == false) {
      return LoginPage();
    }
    return const Scaffold(
      body: LazyLoadPage(
        urlToFetch: "/notification/list",
        openFullContentTree: true,
        widgetAddedToTop: Center(
            child: Column(children: [
          SizedBox(height: 32),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Text(
                "Notifications",
                style: TextStyle(color: Colors.white, fontSize: 40),
              )),
          Divider(
            color: Color.fromARGB(255, 110, 110, 110),
            thickness: 1.0,
          ),
        ])),
        widgetAddedToEnd: Center(
            child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              "End of notifications",
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            SizedBox(height: 128),
          ],
        )),
        widgetAddedToBlank: Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Text(
                "No notifications",
                style: TextStyle(color: Colors.white, fontSize: 25),
              )),
        ),
        itemsPerPage: 25,
        headers: {},
      ),
    );
  }
}
