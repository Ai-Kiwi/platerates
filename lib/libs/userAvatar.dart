import 'dart:convert';

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final avatarImage;
  final double roundness;
  final double size;

  const UserAvatar(
      {super.key,
      required this.avatarImage,
      required this.size,
      required this.roundness});

  @override
  Widget build(BuildContext context) {
    if (avatarImage != null) {
      return SizedBox(
          height: size,
          width: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(roundness),
            child: Center(
                child: Image.memory(
              avatarImage,
              width: double.infinity,
              fit: BoxFit.fill,
            )),
          ));
    } else {
      return SizedBox(
        height: size,
        width: size,
        child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: const Color.fromARGB(255, 45, 45, 45),
              ),
              borderRadius: BorderRadius.all(Radius.circular(roundness)),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: (size * 0.75), // Adjust the size of the icon
                color: Colors.grey[500],
              ),
            )),
      );
    }
  }
}
