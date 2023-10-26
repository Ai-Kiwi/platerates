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
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_outlined),
            activeIcon: Icon(Icons.add),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: FittedBox(
              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.notifications_outlined),
                  ),
                  Visibility(
                    visible: notificationCount > 0.9,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.red),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          "$notificationCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: onClicked,
      ),
    );
  }
}
