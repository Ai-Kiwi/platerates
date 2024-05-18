import 'dart:convert';
import 'dart:io';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/errorHandler.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:PlateRates/main.dart';
import 'package:app_installer/app_installer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
//import 'package:android_package_installer/android_package_installer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
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
  int _total = 1, _received = 0;
  late http.StreamedResponse _response;
  final List<int> _bytes = [];

  Future<void> downloadAndInstallApp() async {
    setState(() {
      _updatingApp = true;
    });

    try {
      print("downloading app");
      //get info for download
      final appDir = await getTemporaryDirectory();
      final String downloadPath = '${appDir.path}/Platerates.apk';
      //final String url = "$serverDomain/Platerates.apk";
      final String url = "https://platerates.com/Platerates.apk";

      if (await File(downloadPath).exists() == true) {
        File(downloadPath).deleteSync();
      }

      _response = await http.Client().send(http.Request('GET', Uri.parse(url)));
      setState(() {
        _total = _response.contentLength ?? 0;
      });

      _response.stream.listen((value) {
        setState(() {
          _bytes.addAll(value);
          _received += value.length;
        });
      }).onDone(() async {
        await File(downloadPath).writeAsBytes(_bytes);
        var taskId = "";
        print("installing app");

        //will download the file
        //while (await Permission.requestInstallPackages.isGranted == false) {
        //  // The OS restricts access, for example because of parental controls.
        //  await Permission.requestInstallPackages.request();
        //}
        //sleep(Duration(seconds: 5));
        print(await File(downloadPath).exists());
        if (taskId != null && await File(downloadPath).exists() == true) {
          // Open the downloaded APK file using the android_intent package
          //setState(() {
          //  _updatingApp = false;
          //});
          AppInstaller.installApk(downloadPath);
        } else {
          setState(() {
            _updatingApp = false;
          });
          //openAlert("error", "failed downloading update", response.body,
          //    context, null);
        }
      });

      //get info
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        //String? taskId = await FlutterDownloader.enqueue(
        //  url: url,
        //  savedDir: appDir.path,
        //  fileName: 'Platerates.apk',
        //  showNotification: true,
        //  openFileFromNotification: false,
        //);

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
        //openAlert(
        //    "error", "failed downloading update", response.body, context, null);
        print('Error: ${response.statusCode}');
        setState(() {
          _updatingApp = false;
        });
      }
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
                  "you must update your client to keep using Platerates\ncurrently auto updating is not supported please uninstall then reinstall the app",
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 64),
                  child: LinearProgressIndicator(
                    value: (_received / (_total)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (errorMessage == "error contacting server") {
      return Scaffold(
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Platerates has moved",
              style: TextStyle(
                color: Color.fromARGB(210, 255, 255, 255),
                fontWeight: FontWeight.bold,
                fontSize: 35,
              ),
            ),
            const Icon(
              Icons.system_update,
              color: Colors.white,
              size: 100,
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
              child: Text(
                "Platerates has become a mobile app. To unlock its full potential, click 'Install' below, then install the downloaded file.\nTo install the APK file, enable 'Install from unknown sources' in your web browser or file explorer settings (should prompt when attempting open) then open it and follow the on-screen instructions for installation.",
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
                        Uri.parse('$serverDomain/Platerates.apk'))) {
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

class PromptUserToAcceptNewLicenses extends StatefulWidget {
  const PromptUserToAcceptNewLicenses({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PromptUserToAcceptNewLicensesState createState() =>
      _PromptUserToAcceptNewLicensesState();
}

class _PromptUserToAcceptNewLicensesState
    extends State<PromptUserToAcceptNewLicenses> with WidgetsBindingObserver {
  List _lisensesToAccept = [
    //"CommunityGuidelines",
    //"deleteData",
    //"privacyPolicy",
    //"termsofService"
  ];
  Map<String, dynamic> latestLisenseVersions = {};
  bool _loading = true;

  Future<void> _acceptedNewLisenses() async {
    final response = await http.post(
      Uri.parse('$serverDomain/licenses/update'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "token": userManager.token,
        "licenses": latestLisenseVersions,
      }),
    );
    // ignore: use_build_context_synchronously
    if (response.statusCode == 200) {
      acceptedAllLicenses = true;
      // ignore: use_build_context_synchronously
      updateHomePage();
    } else {
      // ignore: use_build_context_synchronously
      await ErrorHandler.httpError(response.statusCode, response.body, context);
      // ignore: use_build_context_synchronously
      openAlert("error", "failed updating licenses", response.body, context,
          null, null);

      //FirebaseCrashlytics.instance.crash();
    }
  }

  Future<void> _fetchData() async {
    final response = await http.post(
      Uri.parse('$serverDomain/licenses/unaccepted'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "token": userManager.token,
      }),
    );
    if (response.statusCode == 200) {
      var dataFetched = response.body;
      latestLisenseVersions = jsonDecode(dataFetched);
      setState(() {
        latestLisenseVersions.forEach((key, value) {
          _lisensesToAccept.add(key);
        });
        _loading = false;
      });
    } else {
      // ignore: use_build_context_synchronously
      await ErrorHandler.httpError(response.statusCode, response.body, context);
      // ignore: use_build_context_synchronously
      openAlert(
          "error", "failed getting new licenses", null, context, null, null);

      //FirebaseCrashlytics.instance.crash();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        const Text(
          "license updates",
          style: TextStyle(color: Colors.white, fontSize: 35),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: _loading == false
              ? ListView.builder(
                  itemCount: _lisensesToAccept.length,
                  itemBuilder: (context, index) {
                    if (_lisensesToAccept[index] == "CommunityGuidelines") {
                      return ListTile(
                          title: const Text("Community Guidelines",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18)),
                          subtitle: const Text(
                              "Our Community Guidelines outline the standards and expectations for respectful and positive interactions within our online community.",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 40),
                          onTap: () {
                            launchUrl(
                                Uri.parse("$serverDomain/CommunityGuidelines"));
                          });
                    } else if (_lisensesToAccept[index] == "deleteData") {
                      return ListTile(
                          title: const Text("Data Deletion Policy",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18)),
                          subtitle: const Text(
                              "Our Data Deletion Policy defines the procedures and timelines for removing user data upon request or in accordance with our data retention practices.",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 40),
                          onTap: () {
                            launchUrl(Uri.parse("$serverDomain/deleteData"));
                          });
                    } else if (_lisensesToAccept[index] == "privacyPolicy") {
                      return ListTile(
                          title: const Text("Privacy Policy",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18)),
                          subtitle: const Text(
                              "Our Data Privacy Policy explains how we handle and protect your personal information, ensuring your data is safe and used responsibly.",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 40),
                          onTap: () {
                            launchUrl(Uri.parse("$serverDomain/privacyPolicy"));
                          });
                    } else if (_lisensesToAccept[index] == "termsofService") {
                      return ListTile(
                          title: const Text("Terms Of Service",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18)),
                          subtitle: const Text(
                              "Our Terms of Service detail the legal agreement between you and our platform, governing your usage and responsibilities as a user.",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 40),
                          onTap: () {
                            launchUrl(
                                Uri.parse("$serverDomain/CommunityGuidelines"));
                          });
                    }
                    throw Exception("unkown lisence");
                  },
                )
              : const Center(child: Center(child: CircularProgressIndicator())),

          //ListView(
          //  children: [
          //    TextButton(
          //      // reset password
          //      onPressed: () {
          //        launchUrl(Uri.parse("$serverDomain/termsOfService"));
          //      },
          //      style: OutlinedButton.styleFrom(
          //        //minimumSize:
          //        //    Size.infinite, // Set this
          //        padding: EdgeInsets.zero, // and this
          //      ),
          //      child: RichText(
          //        text: const TextSpan(
          //          text: 'community guidelines. ',
          //          style: TextStyle(
          //            color: Colors.white,
          //            fontSize: 16,
          //          ),
          //          children: <TextSpan>[
          //            TextSpan(
          //              text: 'View here',
          //              style: TextStyle(
          //                fontWeight: FontWeight.normal,
          //                color: Colors.blue,
          //                fontSize: 16,
          //              ),
          //            ),
          //          ],
          //        ),
          //      ),
          //    ),
          //  ],
          //),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SizedBox(
            width: 350,
            height: 50,
            child: ElevatedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              onPressed: () async {
                if (latestLisenseVersions["termsofService"] == null) {
                  _acceptedNewLisenses();
                } else {
                  openAlert(
                      "yes_or_no",
                      "accept terms of service",
                      "By clicking 'Yes,' you confirm your agreement to follow our legally binding Terms of Service.",
                      context,
                      {
                        "yes": () {
                          Navigator.pop(context);
                          _acceptedNewLisenses();
                        },
                        "no": () {
                          Navigator.pop(context);
                        },
                      },
                      null);
                }
              },
              child: const Text(
                "Accept new licences",
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ),
      ],
    ))));
  }
}

class PromptUserBanned extends StatefulWidget {
  const PromptUserBanned({super.key});

  @override
  _PromptPromptUserBannedState createState() => _PromptPromptUserBannedState();
}

class _PromptPromptUserBannedState extends State<PromptUserBanned> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Center(
            child: Text(
              "Account Banned",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "We regret to inform you that your Platerates account has been suspended due to violations of our community guidelines and terms of service.\n\nIMPORTANT: Please refrain from creating another account to circumvent this suspension, as it is strictly prohibited and will result in further actions being taken against you.\n\nIf you believe this suspension is in error or wish to discuss the matter further, please contact our support team at support@platerates.com.\n\nYour cooperation in adhering to our platform's rules is essential for maintaining a positive and respectful user environment.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
              child: Center(
            child: ElevatedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              onPressed: () async {
                accountBanned = false;
                updateHomePage();
              },
              child: const Text(
                "retry",
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ))
        ],
      ),
    );
  }
}
