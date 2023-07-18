import 'package:flutter/material.dart';

class DisplayErrorMessagePage extends StatefulWidget {
  final String errorMessage;

  DisplayErrorMessagePage({
    required this.errorMessage,
  });

  @override
  _DisplayErrorMessagePageState createState() =>
      _DisplayErrorMessagePageState(errorMessage: errorMessage);
}

class _DisplayErrorMessagePageState extends State<DisplayErrorMessagePage>
    with WidgetsBindingObserver {
  _DisplayErrorMessagePageState({required this.errorMessage});
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 16, 16),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(
                color: Color.fromARGB(210, 255, 255, 255),
                fontWeight: FontWeight.normal,
                fontSize: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
