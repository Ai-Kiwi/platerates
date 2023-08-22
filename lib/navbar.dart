import 'package:flutter/material.dart';

class UserNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onClicked;
  final int notificationCount;

  const UserNavbar(
      {super.key,
      required this.selectedIndex,
      required this.onClicked,
      required this.notificationCount});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black, blurRadius: 10, spreadRadius: 0),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.primaryColor,
        unselectedFontSize: 0,
        selectedFontSize: 15,
        unselectedItemColor: Colors.white60,
        showUnselectedLabels: false,
        selectedItemColor: Colors.white,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            activeIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_outlined),
            activeIcon: Icon(Icons.add),
            label: 'create',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications),
                Visibility(
                  visible: notificationCount > 0,
                  child: Text(
                    "$notificationCount",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            activeIcon: Icon(Icons.notifications),
            label: 'notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'profile',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: onClicked,
      ),
    );
  }
}
