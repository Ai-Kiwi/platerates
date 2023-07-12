import 'dart:convert';

import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:Toaster/libs/loadScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../main.dart';
import 'libs/smoothTransitions.dart';
import 'login/userLogin.dart';
import 'login/userResetPassword.dart';

class UserSettings extends StatefulWidget {
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
      body: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                      child: Text(
                        "Settings",
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      )),
                  Divider(
                    color: Color.fromARGB(255, 110, 110, 110),
                    thickness: 1.0,
                  ),
                  settingItem(
                    settingIcon: Icons.person_outline,
                    settingName: "username",
                    ontap: () {
                      String newUsername = "";
                      Alert(
                          context: context,
                          title: "Change username",
                          content: Column(
                            children: <Widget>[
                              TextField(
                                decoration: InputDecoration(
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
                                  Alert(
                                    context: context,
                                    type: AlertType.success,
                                    title: "username changed",
                                    buttons: [
                                      DialogButton(
                                        onPressed: () => Navigator.pop(context),
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
                                  Alert(
                                    context: context,
                                    type: AlertType.error,
                                    title: "username change failed",
                                    desc: response.body,
                                    buttons: [
                                      DialogButton(
                                        onPressed: () => Navigator.pop(context),
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
                              child: Text(
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
                  settingItem(
                    settingIcon: Icons.lock,
                    settingName: "change password",
                    ontap: () {
                      Navigator.of(context).push(
                          smoothTransitions.slideRight(ResetPasswordPage()));
                    },
                  ),
                ],
              ))),
    );
  }
}

class settingItem extends StatelessWidget {
  String settingName;
  var settingIcon;
  var ontap;

  settingItem(
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
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                      ))),
              AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                      child: Icon(
                    Icons.arrow_right_rounded,
                    color: Colors.white60,
                    size: 35,
                  ))),
            ]),
          ),
          onTap: ontap,
        ));
  }
}
