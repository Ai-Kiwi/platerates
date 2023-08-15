import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../main.dart';
import 'libs/errorHandler.dart';
import 'libs/smoothTransitions.dart';
import 'login/userLogin.dart';
import 'login/userResetPassword.dart';

class UserSettings extends StatefulWidget {
  const UserSettings({super.key});

  //UserSettings({});

  @override
  _UserSettingsState createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  //_UserSettingsState({});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromRGBO(16, 16, 16, 1),
        body: Stack(alignment: Alignment.topLeft, children: <Widget>[
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView(
                    children: [
                      const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 8),
                          child: Text(
                            "   Settings",
                            style: TextStyle(color: Colors.white, fontSize: 40),
                          )),
                      const Divider(
                        color: Color.fromARGB(255, 110, 110, 110),
                        thickness: 1.0,
                      ),
                      SettingItem(
                        settingIcon: Icons.person_outline,
                        settingName: "username",
                        ontap: () {
                          String newUsername = "";
                          Alert(
                              context: context,
                              title: "Change username",
                              desc:
                                  "please note you can only change it once per week",
                              content: Column(
                                children: <Widget>[
                                  TextField(
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.account_circle),
                                      labelText: 'Username',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        newUsername = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              buttons: [
                                DialogButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final response = await http.post(
                                      Uri.parse(
                                          "$serverDomain/profile/settings/change"),
                                      headers: <String, String>{
                                        'Content-Type':
                                            'application/json; charset=UTF-8',
                                      },
                                      body: jsonEncode(<String, String>{
                                        'token': userManager.token,
                                        "setting": "username",
                                        "value": newUsername,
                                      }),
                                    );
                                    if (response.statusCode == 200) {
                                      // ignore: use_build_context_synchronously
                                      Alert(
                                        context: context,
                                        type: AlertType.success,
                                        title: "username changed",
                                        buttons: [
                                          DialogButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            width: 120,
                                            child: const Text(
                                              "ok",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20),
                                            ),
                                          )
                                        ],
                                      ).show();
                                    } else {
                                      ErrorHandler.httpError(
                                          response.statusCode,
                                          response.body,
                                          context);
                                      Alert(
                                        context: context,
                                        type: AlertType.error,
                                        title: "username change failed",
                                        desc: response.body,
                                        buttons: [
                                          DialogButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            width: 120,
                                            child: const Text(
                                              "ok",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20),
                                            ),
                                          )
                                        ],
                                      ).show();
                                    }
                                  },
                                  child: const Text(
                                    "Change",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                ),
                                DialogButton(
                                  color: Colors.red,
                                  child: const Text(
                                    "cancel",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              ]).show();
                        },
                      ),
                      SettingItem(
                        settingIcon: Icons.lock,
                        settingName: "password",
                        ontap: () {
                          Navigator.of(context).push(smoothTransitions
                              .slideRight(ResetPasswordPage()));
                        },
                      ),
                      SettingItem(
                        settingIcon: Icons.chat,
                        settingName: "bio",
                        ontap: () {
                          String newBio = "";
                          Alert(
                              context: context,
                              title: "Change bio",
                              content: Column(
                                children: <Widget>[
                                  TextField(
                                    maxLines: 5,
                                    minLines: 3,
                                    maxLength: 500,
                                    maxLengthEnforcement: MaxLengthEnforcement
                                        .truncateAfterCompositionEnds,
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.account_circle),
                                      labelText: 'bio',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        newBio = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              buttons: [
                                DialogButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final response = await http.post(
                                      Uri.parse(
                                          "$serverDomain/profile/settings/change"),
                                      headers: <String, String>{
                                        'Content-Type':
                                            'application/json; charset=UTF-8',
                                      },
                                      body: jsonEncode(<String, String>{
                                        'token': userManager.token,
                                        "setting": "bio",
                                        "value": newBio,
                                      }),
                                    );
                                    if (response.statusCode == 200) {
                                      // ignore: use_build_context_synchronously
                                      Alert(
                                        context: context,
                                        type: AlertType.success,
                                        title: "bio changed",
                                        desc: "refresh profile page to see",
                                        buttons: [
                                          DialogButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            width: 120,
                                            child: const Text(
                                              "ok",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20),
                                            ),
                                          )
                                        ],
                                      ).show();
                                    } else {
                                      ErrorHandler.httpError(
                                          response.statusCode,
                                          response.body,
                                          context);
                                      // ignore: use_build_context_synchronously
                                      Alert(
                                        context: context,
                                        type: AlertType.error,
                                        title: "bio change failed",
                                        desc: response.body,
                                        buttons: [
                                          DialogButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            width: 120,
                                            child: const Text(
                                              "ok",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20),
                                            ),
                                          )
                                        ],
                                      ).show();
                                    }
                                  },
                                  child: const Text(
                                    "Change",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                ),
                                DialogButton(
                                  color: Colors.red,
                                  child: const Text(
                                    "cancel",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              ]).show();
                        },
                      ),
                      SettingItem(
                        settingIcon: Icons.info,
                        settingName: "licenses",
                        ontap: () {
                          Navigator.of(context).push(smoothTransitions
                              .slideRight(const LicensePage()));
                        },
                      ),
                      SettingItem(
                        settingIcon: Icons.lock,
                        settingName: "privacy policy",
                        ontap: () {
                          launchUrl(Uri.parse(
                              "https://toaster.aikiwi.dev/privacyPolicy"));
                        },
                      ),
                      SettingItem(
                        settingIcon: Icons.help,
                        settingName: "contact support",
                        ontap: () {
                          launchUrl(Uri.parse("mailto:toaster@aikiwi.dev"));
                        },
                      ),
                      //launch();

                      //const Expanded(child: Center()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 4),
                        child: Center(
                            child: Text("version $version build $buildNumber",
                                style: const TextStyle(
                                  color: Colors.white,
                                ))),
                      ),
                    ],
                  ))),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ))
        ]));
  }
}

class SettingItem extends StatelessWidget {
  final String settingName;
  final settingIcon;
  final ontap;

  const SettingItem(
      {super.key,
      required this.settingIcon,
      required this.settingName,
      required this.ontap});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          //change username
          onTap: ontap,
          child: Container(
            decoration: BoxDecoration(
                color: const Color.fromARGB(215, 40, 40, 40),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                    color: const Color.fromARGB(215, 45, 45, 45), width: 3)),
            width: double.infinity,
            height: 50,
            child: Row(children: [
              AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                      child: Icon(
                    settingIcon,
                    color: Colors.white,
                    size: 25,
                  ))),
              Expanded(
                  child: Text(settingName,
                      style: const TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                      ))),
              const AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                      child: Icon(
                    Icons.arrow_right_rounded,
                    color: Colors.white60,
                    size: 35,
                  ))),
            ]),
          ),
        ));
  }
}
