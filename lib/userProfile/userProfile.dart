import 'package:flutter/material.dart';

class UserProfile extends StatefulWidget {
  @override
  State<UserProfile> createState() => _UserProfiletate();
}

class _UserProfiletate extends State<UserProfile> {
  @override
  Widget build(BuildContext context) {
    //final ThemeData theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
      child: Column(
        children: [
          SizedBox(height: 8),
          SizedBox(
            width: 15,
            height: 15,
            child: CircleAvatar(
              backgroundColor: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
