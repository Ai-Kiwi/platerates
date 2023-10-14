import 'package:Toaster/libs/lazyLoadPage.dart';
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
      key: UniqueKey(),
      urlToFetch: "/post/feed",
      extraUrlData: {"pageFetching": pageOpen},
      widgetAddedToTop: Center(
          child: Column(children: [
        const SizedBox(height: 32),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "Your feed",
              style: TextStyle(color: Colors.white, fontSize: 40),
            )),
        const Divider(
          color: Color.fromARGB(255, 110, 110, 110),
          thickness: 1.0,
        ),
        Padding(
          //share mode selection
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ToggleSwitch(
              minWidth: double.infinity,
              cornerRadius: 15.0,
              initialLabelIndex: pageItemIndex,
              totalSwitches: 2,
              activeBgColors: const [
                [Colors.green],
                [Colors.green]
              ],
              centerText: true,
              activeFgColor: Colors.white,
              inactiveBgColor: const Color.fromARGB(255, 40, 40, 40),
              inactiveFgColor: Colors.white,
              labels: const ['popular posts', 'followers posts'],
              onToggle: changePageOpen,
            ),
          ),
        ),
        const SizedBox(
          height: 16,
        )
      ])),
      widgetAddedToEnd: const Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "end of feed",
              style: TextStyle(color: Colors.white, fontSize: 25),
            )),
      ),
      widgetAddedToBlank: const Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "nothing in your feed",
              style: TextStyle(color: Colors.white, fontSize: 25),
            )),
      ),
    );
  }
}
