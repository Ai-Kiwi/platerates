import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../login/userLogin.dart';
import '../main.dart';

class AdminZonePage extends StatefulWidget {
  //UserSettings({});

  @override
  _AdminZonePageState createState() => _AdminZonePageState();
}

class _AdminZonePageState extends State<AdminZonePage> {
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
                            "   Admin zone",
                            style: TextStyle(color: Colors.white, fontSize: 40),
                          )),
                      const Divider(
                        color: Color.fromARGB(255, 110, 110, 110),
                        thickness: 1.0,
                      ),
                      _AdminItem(
                        settingIcon: Icons.person_outline,
                        settingName: "create user",
                        ontap: () async {
                          String accountUsername = "";
                          String accountEmail = "";

                          Alert(
                              context: context,
                              title: "create user",
                              content: Column(
                                children: <Widget>[
                                  TextField(
                                    maxLengthEnforcement: MaxLengthEnforcement
                                        .truncateAfterCompositionEnds,
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.account_circle),
                                      labelText: 'username',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        accountUsername = value;
                                      });
                                    },
                                  ),
                                  TextField(
                                    maxLengthEnforcement: MaxLengthEnforcement
                                        .truncateAfterCompositionEnds,
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.account_circle),
                                      labelText: 'email',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        accountEmail = value;
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
                                          "$serverDomain/admin/createUser"),
                                      headers: <String, String>{
                                        'Content-Type':
                                            'application/json; charset=UTF-8',
                                      },
                                      body: jsonEncode(<String, String>{
                                        'token': userManager.token,
                                        "username": accountUsername,
                                        "email": accountEmail,
                                      }),
                                    );
                                    if (response.statusCode == 200) {
                                      // ignore: use_build_context_synchronously
                                      Alert(
                                        context: context,
                                        type: AlertType.success,
                                        title: "user created",
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
                                      // ignore: use_build_context_synchronously
                                      Alert(
                                        context: context,
                                        type: AlertType.error,
                                        title: "failed creating user",
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
                                    "create",
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
                      _AdminItem(
                        settingIcon: Icons.remove,
                        settingName: "ban user",
                        ontap: () async {
                          String accountUserId = "";
                          String accountBanReason = "";
                          String accountBanTime = "";

                          Alert(
                              context: context,
                              title: "create user",
                              content: Column(
                                children: <Widget>[
                                  TextField(
                                    maxLengthEnforcement: MaxLengthEnforcement
                                        .truncateAfterCompositionEnds,
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.account_circle),
                                      labelText: 'userId',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        accountUserId = value;
                                      });
                                    },
                                  ),
                                  TextField(
                                    maxLengthEnforcement: MaxLengthEnforcement
                                        .truncateAfterCompositionEnds,
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.account_circle),
                                      labelText: 'reason',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        accountBanReason = value;
                                      });
                                    },
                                  ),
                                  TextField(
                                    maxLengthEnforcement: MaxLengthEnforcement
                                        .truncateAfterCompositionEnds,
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.account_circle),
                                      labelText: 'time (seconds)',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        accountBanTime = value;
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
                                      Uri.parse("$serverDomain/admin/banUser"),
                                      headers: <String, String>{
                                        'Content-Type':
                                            'application/json; charset=UTF-8',
                                      },
                                      body: jsonEncode(<String, String>{
                                        'token': userManager.token,
                                        "userId": accountUserId,
                                        "reason": accountBanReason,
                                        "time": accountBanTime,
                                      }),
                                    );
                                    if (response.statusCode == 200) {
                                      // ignore: use_build_context_synchronously
                                      Alert(
                                        context: context,
                                        type: AlertType.success,
                                        title: "user banned",
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
                                      // ignore: use_build_context_synchronously
                                      Alert(
                                        context: context,
                                        type: AlertType.error,
                                        title: "failed banning user",
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
                                    "ban",
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

class _AdminItem extends StatelessWidget {
  final String settingName;
  final settingIcon;
  final ontap;

  _AdminItem(
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
          onTap: ontap,
        ));
  }
}
