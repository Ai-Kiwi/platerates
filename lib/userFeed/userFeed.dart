import 'package:PlateRates/libs/lazyLoadPage.dart';
import 'package:PlateRates/libs/pageNotices.dart';
import 'package:PlateRates/libs/smoothTransitions.dart';
import 'package:PlateRates/main.dart';
import 'package:PlateRates/searchPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

class userFeed extends StatefulWidget {
  @override
  State<userFeed> createState() => _UserFeedState();
}

class _UserFeedState extends State<userFeed> {
  String pageOpen = "popular";
  int pageItemIndex = 0;

  void changePageOpen(index) {
    setState(() {
      pageItemIndex = index;
      if (index == 0) {
        pageOpen = "popular";
      } else {
        pageOpen = "followers";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //final ThemeData theme = Theme.of(context);
    return LazyLoadPage(
      openFullContentTree: true,
      key: UniqueKey(),
      urlToFetch: "/post/feed",
      widgetAddedToTop: Center(
          child: Column(children: [
        const SizedBox(height: 32),
        Stack(
          children: [
            const Align(
              alignment: Alignment.center,
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                  child: Text(
                    "Your feed",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  )),
            ),
            Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                  child: IconButton(
                    icon: Icon(Icons.search, size: 32, color: Colors.white),
                    onPressed: () => {
                      Navigator.of(context)
                          .push(smoothTransitions.slideUp(const SearchPage()))
                    },
                  ),
                ))
          ],
        ),

        const Divider(
          color: Color.fromARGB(255, 110, 110, 110),
          thickness: 1.0,
        ),
        //Padding(
        //  //share mode selection
        //  padding: const EdgeInsets.symmetric(horizontal: 16.0),
        //  child: SizedBox(
        //    width: double.infinity,
        //    child: ToggleSwitch(
        //      minWidth: double.infinity,
        //      cornerRadius: 15.0,
        //      initialLabelIndex: pageItemIndex,
        //      totalSwitches: 2,
        //      activeBgColors: [
        //        [Theme.of(context).primaryColor],
        //        [Theme.of(context).primaryColor]
        //      ],
        //      centerText: true,
        //      activeFgColor: Colors.white,
        //      inactiveBgColor: const Color.fromARGB(255, 40, 40, 40),
        //      inactiveFgColor: Colors.white,
        //      labels: const ['Recent Posts', 'Followers Posts'],
        //      onToggle: changePageOpen,
        //    ),
        //  ),
        //),
        ///const SizedBox(
        ///  height: 16,
        ///),
        Visibility(
            visible: kIsWeb,
            child: Column(children: [
              Padding(
                  //web verison reminded
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                      width: double.infinity,
                      height: 60.0,
                      child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                                smoothTransitions.slideUp(migrateToAppPage()));
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 231, 38, 38),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: const Center(
                                  child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                    "You are using web version.\nIt is recommended to download the app if you can\nClick here to download",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                    )),
                              )))))),
              const SizedBox(height: 16.0),
            ])),
        Visibility(
            visible: updateNeeded == true,
            child: Column(children: [
              Padding(
                  //web verison reminded
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                      width: double.infinity,
                      height: 60.0,
                      child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(smoothTransitions
                                .slideUp(DisplayErrorMessagePage(
                              errorMessage: 'client-out-of-date',
                            )));
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 231, 38, 38),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: const Center(
                                  child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                    "You are using an outdated version.\nIt is recommended to install the latest app update to get the latest features and patches for the best experience.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                    )),
                              )))))),
              const SizedBox(height: 16.0),
            ])),
        //DropdownButton(
        //    focusColor: Colors.green,
        //    hint: new Text("Select a user"),
        //    value: "e",
        //    dropdownColor: Colors.black,
        //    onChanged: (index) {
        //        //selectedUser = newValue;
        //    },
        //    //items: users.map((User user) {
        //    //  return new DropdownMenuItem<User>(
        //    //    value: user,
        //    //    child: new Text(
        //    //      user.name,
        //    //      style: new TextStyle(color: Colors.black),
        //    //    ),
        //    //  );
        //    //}).toList(),
        //    items: [
        //      DropdownMenuItem<String>(
        //        value: "e",
        //        child: new Text(
        //          "hello",
        //          style: new TextStyle(color: Colors.white),
        //        ),
        //      ),
        //    ]),
      ])),
      widgetAddedToEnd: const Center(
          child: Column(
        children: [
          SizedBox(height: 16),
          Text(
            "end of content",
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          SizedBox(height: 128),
        ],
      )),
      widgetAddedToBlank: const Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "nothing posted",
              style: TextStyle(color: Colors.white, fontSize: 25),
            )),
      ),
      itemsPerPage: 5,
      headers: {},
    );
  }
}
