import 'package:PlateRates/libs/lazyLoadPage.dart';
import 'package:flutter/material.dart';

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
      //should be added to include data like what you are searching for, filters, text feild search etc
      headers: {
        "text": textSearching,
      },
      urlToFetch: urlSearching,
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
        Row(
          children: [
            Center(
                child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            )),
            Expanded(
              child: Padding(
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
                  decoration: InputDecoration(
                      labelText: 'Search',
                      labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 200, 200, 200)),
                      contentPadding: const EdgeInsets.all(8.0),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      suffixIcon: const Icon(
                        Icons.search,
                        color: Colors.white,
                      )),
                ),
              ),
            ),
          ],
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
      itemsPerPage: 15,
    ));

    //return Center();
  }
}
