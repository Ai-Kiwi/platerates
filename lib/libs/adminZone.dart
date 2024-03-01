import 'dart:convert';

import 'package:PlateRates/libs/errorHandler.dart';
import 'package:PlateRates/libs/usefullWidgets.dart';
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
        body: PageBackButton(
      warnDiscardChanges: false,
      active: true,
      child: SafeArea(
          top: true,
          bottom: true,
          child: ListView(
            children: [
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                      child: Text(
                    "Admin Zone",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ))),
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
                            style: const TextStyle(color: Colors.white),
                            maxLengthEnforcement: MaxLengthEnforcement
                                .truncateAfterCompositionEnds,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.account_circle),
                              labelText: 'username',
                            ),
                            onChanged: (value) {
                              accountUsername = value;
                            },
                          ),
                          TextField(
                            style: const TextStyle(color: Colors.white),
                            maxLengthEnforcement: MaxLengthEnforcement
                                .truncateAfterCompositionEnds,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.account_circle),
                              labelText: 'email',
                            ),
                            onChanged: (value) {
                              accountEmail = value;
                            },
                          ),
                        ],
                      ),
                      buttons: [
                        DialogButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final response = await http.post(
                              Uri.parse("$serverDomain/admin/createUser"),
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
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                'user created',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white),
                              )));
                            } else {
                              ErrorHandler.httpError(
                                  response.statusCode, response.body, context);
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                'failed creating user',
                                style:
                                    TextStyle(fontSize: 20, color: Colors.red),
                              )));
                            }
                          },
                          child: const Text(
                            "create",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        DialogButton(
                          color: Colors.red,
                          child: const Text(
                            "cancel",
                            style: TextStyle(color: Colors.white, fontSize: 20),
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
                            style: const TextStyle(color: Colors.white),
                            maxLengthEnforcement: MaxLengthEnforcement
                                .truncateAfterCompositionEnds,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.account_circle),
                              labelText: 'userId',
                            ),
                            onChanged: (value) {
                              accountUserId = value;
                            },
                          ),
                          TextField(
                            style: const TextStyle(color: Colors.white),
                            maxLengthEnforcement: MaxLengthEnforcement
                                .truncateAfterCompositionEnds,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.account_circle),
                              labelText: 'reason',
                            ),
                            onChanged: (value) {
                              accountBanReason = value;
                            },
                          ),
                          TextField(
                            style: const TextStyle(color: Colors.white),
                            maxLengthEnforcement: MaxLengthEnforcement
                                .truncateAfterCompositionEnds,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.account_circle),
                              labelText: 'time (seconds)',
                            ),
                            onChanged: (value) {
                              accountBanTime = value;
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
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                'user banned',
                                style:
                                    TextStyle(fontSize: 20, color: Colors.red),
                              )));
                            } else {
                              ErrorHandler.httpError(
                                  response.statusCode, response.body, context);
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                'failed banning user',
                                style:
                                    TextStyle(fontSize: 20, color: Colors.red),
                              )));
                            }
                          },
                          child: const Text(
                            "ban",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        DialogButton(
                          color: Colors.red,
                          child: const Text(
                            "cancel",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      ]).show();
                },
              ),
            ],
          )),
    ));
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
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: InkWell(
          //change username
          onTap: ontap,
          child: Container(
            width: double.infinity,
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AspectRatio(
                    aspectRatio: 1,
                    child: Center(
                        child: Icon(
                      settingIcon,
                      color: Colors.white,
                      size: 30,
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
              ],
            ),
          ),
        ));
  }
}
