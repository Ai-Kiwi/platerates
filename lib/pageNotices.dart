import 'dart:io';

import 'package:Toaster/main.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
//import 'package:android_package_installer/android_package_installer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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

        print("installing app");

        //will download the file
        while (await Permission.requestInstallPackages.isGranted == false) {
          // The OS restricts access, for example because of parental controls.
          await Permission.requestInstallPackages.request();
        }

        //int? statusCode =
        //    await AndroidPackageInstaller.installApk(apkFilePath: downloadPath);
        //print(statusCode);
        //if (code != null) {
        //  PackageInstallerStatus installationStatus =
        //      PackageInstallerStatus.byCode(statusCode);
        //  print(installationStatus.name);
        //}

        //SystemNavigator.pop();
      } else {
        // Handle download error
        print('Error: ${response.statusCode}');
      }
      setState(() {
        _updatingApp = false;
      });
    } on Exception catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                child: Text(
                  "app out of date",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Icon(
                Icons.system_update,
                color: Colors.white,
                size: 100,
              ),
              const SizedBox(
                height: 32,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                child: Text(
                  "you must update your client to keep using toaster\ncurrently auto updating is not supported please redownload the app",
                  style: TextStyle(
                    color: Color.fromARGB(210, 255, 255, 255),
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              //const Text(
              //  "you may need to give some permissions to update",
              //  style: TextStyle(
              //    color: Color.fromARGB(210, 255, 255, 255),
              //    fontWeight: FontWeight.normal,
              //    fontSize: 15,
              //  ),
              //),
              //const Text(
              //  "app will close after done, you must reopen it yourself",
              //  style: TextStyle(
              //    color: Color.fromARGB(210, 255, 255, 255),
              //    fontWeight: FontWeight.normal,
              //    fontSize: 15,
              //  ),
              //),
              //const SizedBox(height: 32),
              //Visibility(
              //  visible: !_updatingApp,
              //  child: ElevatedButton(
              //    style: OutlinedButton.styleFrom(
              //        shape: RoundedRectangleBorder(
              //      borderRadius: BorderRadius.circular(15.0),
              //    )),
              //    onPressed: () async {
              //      downloadAndInstallApp();
              //    },
              //    child: const Text(
              //      'update app',
              //      style: TextStyle(fontSize: 18.0),
              //    ),
              //  ),
              //),
              Visibility(
                visible: _updatingApp,
                child: const CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      );
    } else if (errorMessage == "error contacting server") {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 16, 16, 16),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "error contacting server",
                style: const TextStyle(
                  color: Color.fromARGB(210, 255, 255, 255),
                  fontWeight: FontWeight.normal,
                  fontSize: 25,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                )),
                onPressed: () async {
                  Phoenix.rebirth(context);
                },
                child: const Text(
                  'retry',
                  style: TextStyle(fontSize: 18.0),
                ),
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

class migrateToAppPage extends StatelessWidget {
  VoidCallback ignorePrompt;

  migrateToAppPage({required this.ignorePrompt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 16, 16),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Toaster has moved",
              style: TextStyle(
                color: Color.fromARGB(210, 255, 255, 255),
                fontWeight: FontWeight.bold,
                fontSize: 35,
              ),
            ),
            Icon(
              Icons.system_update,
              color: Colors.white,
              size: 100,
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
              child: Text(
                "Toaster has become a mobile app. To unlock its full potential, click 'Install' below, then install the downloaded file.\nTo install the APK file, enable 'Install from unknown sources' in your web browser or file explorer settings (should prompt when attempting open) then open it and follow the on-screen instructions for installation.",
                style: TextStyle(
                  color: Color.fromARGB(210, 255, 255, 255),
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
              child: Text(
                "note: sadly it is not possible for phones other then android",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  )),
                  onPressed: () async {
                    //downloadAndInstallApp();
                    if (!await launchUrl(
                        Uri.parse('$serverDomain/toaster.apk'))) {
                      throw Exception('Could not launch domain');
                    }
                  },
                  child: const Text(
                    'install',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      backgroundColor: Colors.red),
                  onPressed: () {
                    ignorePrompt();
                  },
                  child: const Text(
                    'ignore',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
