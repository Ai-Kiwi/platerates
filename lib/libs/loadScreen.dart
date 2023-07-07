import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final bool toasterLogo;

  LoadingScreen({required this.toasterLogo});

  @override
  Widget build(BuildContext context) {
    if (toasterLogo) {
      return const Scaffold(
          backgroundColor: Color.fromRGBO(16, 16, 16, 1),
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                  child: Text(
                    "Toaster",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ])));
    } else {
      return const Scaffold(
          backgroundColor: Color.fromRGBO(16, 16, 16, 1),
          body: Center(
            child: CircularProgressIndicator(),
          ));
    }
  }
}
