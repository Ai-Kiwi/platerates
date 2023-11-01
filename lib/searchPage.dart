import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  //UserSettings({});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  //_UserSettingsState({});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: LazyLoadPage(
      openFullContentTree: true,
      urlToFetch: "/search/users",
      widgetAddedToBlank: Center(),
      widgetAddedToEnd: Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "end of search",
              style: TextStyle(color: Colors.white, fontSize: 25),
            )),
      ),
      widgetAddedToTop: Center(
          child: Column(children: [
        SizedBox(height: 32),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "Users",
              style: TextStyle(color: Colors.white, fontSize: 40),
            )),
        Divider(
          color: Color.fromARGB(255, 110, 110, 110),
          thickness: 1.0,
        ),
      ])),
    ));

    //return Center();
  }
}
