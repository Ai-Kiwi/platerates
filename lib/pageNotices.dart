import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
  bool _updatingApp = false;

  Future<void> downloadAndInstallApp() async {
    setState(() {
      _updatingApp = true;
    });

    try {
      print("downloading app");
      //get info for download
      final appDir = await getTemporaryDirectory();
      final downloadPath = '${appDir.path}/app.apk';

      //get info
      final response =
          await http.get(Uri.parse("https://toaster.aikiwi.dev/toaster.apk"));
      if (response.statusCode == 200) {
        final file = File(downloadPath);
        await file.writeAsBytes(response.bodyBytes);

        //will download the file
        print("installing app");
        await InstallPlugin.installApk(downloadPath);

        SystemNavigator.pop();
      } else {
        // Handle download error
        print('Error: ${response.statusCode}');
      }
      setState(() {
        _updatingApp = false;
      });
    } on Exception catch (error) {
      print(error);
      setState(() {
        _updatingApp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage == "client-out-of-date") {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 16, 16, 16),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "app out of date",
                style: TextStyle(
                  color: Color.fromARGB(210, 255, 255, 255),
                  fontWeight: FontWeight.normal,
                  fontSize: 25,
                ),
              ),
              const Text(
                "you must update your client to keep using toaster",
                style: TextStyle(
                  color: Color.fromARGB(210, 255, 255, 255),
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                ),
              ),
              const Text(
                "you may need to give some permissions to update",
                style: TextStyle(
                  color: Color.fromARGB(210, 255, 255, 255),
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                ),
              ),
              const Text(
                "app will close after done, you must reopen it yourself",
                style: TextStyle(
                  color: Color.fromARGB(210, 255, 255, 255),
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              Visibility(
                visible: !_updatingApp,
                child: ElevatedButton(
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  )),
                  onPressed: () async {
                    downloadAndInstallApp();
                  },
                  child: const Text(
                    'update app',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              Visibility(
                visible: _updatingApp,
                child: const CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      );
    } else {
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
}
