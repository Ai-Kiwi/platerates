import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  //UserSettings({});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  //_UserSettingsState({});
  String textSearching = "";
  String urlSearching = "/search/users";
  int searchItemIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void changeSearchItem(index) {
    setState(() {
      searchItemIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: LazyLoadPage(
      key: UniqueKey(),
      openFullContentTree: true,
      urlToFetch: urlSearching,
      extraUrlData: {"searchText": textSearching},
      widgetAddedToBlank: const Center(),
      widgetAddedToEnd: const Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "end of search",
              style: TextStyle(color: Colors.white, fontSize: 25),
            )),
      ),
      widgetAddedToTop: Center(
          child: Column(children: [
        const SizedBox(height: 32),
        Padding(
          //email input feild
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: TextFormField(
            initialValue: textSearching,
            onChanged: (value) {
              textSearching = value;
            },
            onFieldSubmitted: (value) {
              setState(() {
                textSearching = textSearching;
              });
            },
            autofillHints: const [AutofillHints.email],
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: const InputDecoration(
                labelText: 'Search',
                labelStyle:
                    TextStyle(color: Color.fromARGB(255, 200, 200, 200)),
                contentPadding: EdgeInsets.all(8.0),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                suffixIcon: Icon(
                  Icons.search,
                  color: Colors.white,
                )),
          ),
        ),
        //Padding(
        //  //share mode selection
        //  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        //  child: SizedBox(
        //    width: double.infinity,
        //    child: ToggleSwitch(
        //      minWidth: double.infinity,
        //      cornerRadius: 15.0,
        //      initialLabelIndex: searchItemIndex,
        //      totalSwitches: 3,
        //      activeBgColors: const [
        //        [Colors.green],
        //        [Colors.green]
        //      ],
        //      centerText: true,
        //      activeFgColor: Colors.white,
        //      inactiveBgColor: const Color.fromARGB(255, 40, 40, 40),
        //      inactiveFgColor: Colors.white,
        //      //labels: const ['Users'],
        //      onToggle: changeSearchItem,
        //    ),
        //  ),
        //),
        const Divider(
          color: Color.fromARGB(255, 110, 110, 110),
          thickness: 1.0,
        ),
      ])),
    ));

    //return Center();
  }
}
