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
        backgroundColor: Color.fromRGBO(16, 16, 16, 1),
        body: LazyLoadPage(
          urlToFetch: "/search/users",
          widgetAddedToBlank: Center(),
          widgetAddedToEnd: Center(),
          widgetAddedToTop: Center(),
        ));
    //return Center();
  }
}
