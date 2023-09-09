import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserAvatar extends StatelessWidget {
  final avatarImage;
  final double roundness;
  final double size;
  final VoidCallback onTap;

  const UserAvatar(
      {super.key,
      required this.avatarImage,
      required this.size,
      required this.roundness,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (avatarImage != null) {
      return SizedBox(
          height: size,
          width: size,
          child: GestureDetector(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(roundness),
              child: Center(
                  child: Image.memory(
                avatarImage,
                width: double.infinity,
                fit: BoxFit.fill,
              )),
            ),
            onTap: () {
              onTap();
            },
          ));
    } else {
      return SizedBox(
        height: size,
        width: size,
        child: GestureDetector(
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
          onTap: () {
            onTap();
          },
        ),
      );
    }
  }
}
