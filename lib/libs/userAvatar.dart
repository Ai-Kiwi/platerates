import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/userProfile/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserAvatar extends StatelessWidget {
  final avatarImage;
  final double roundness;
  final double size;
  final String? onTapFunction;
  final VoidCallback? customFunction;
  final context;
  final userId;

  const UserAvatar(
      {super.key,
      required this.avatarImage,
      required this.size,
      required this.roundness,
      required this.onTapFunction,
      this.customFunction,
      this.context,
      this.userId});

  Future<void> _handleUserClick() async {
    if (onTapFunction == "openProfile") {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                UserProfile(userId: userId, openedOntopMenu: true)),
      );
    } else if (onTapFunction == "copyUserId") {
      if (userId != null) {
        Clipboard.setData(ClipboardData(text: userId));
        openAlert(
            "info", "copied user id to clipboard", null, context, null, null);
      }
    } else if (onTapFunction == "customFunction") {
      customFunction!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (avatarImage != null) {
      return SizedBox(
        height: size,
        width: size,
        child: GestureDetector(
          onTap: onTapFunction != null ? _handleUserClick : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(roundness),
            child: Center(
                child: Image.memory(
              avatarImage,
              width: double.infinity,
              fit: BoxFit.fill,
            )),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: size,
        width: size,
        child: GestureDetector(
          onTap: onTapFunction != null ? _handleUserClick : null,
          child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: const Color.fromARGB(255, 45, 45, 45),
                ),
                borderRadius: BorderRadius.all(Radius.circular(roundness)),
                color: const Color.fromARGB(255, 15, 15, 15),
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  size: (size * 0.75), // Adjust the size of the icon
                  color: Colors.grey[500],
                ),
              )),
        ),
      );
    }
  }
}
