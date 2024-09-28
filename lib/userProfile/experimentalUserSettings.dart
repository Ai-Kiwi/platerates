import 'dart:convert';
import 'dart:io';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/errorHandler.dart';
import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import 'package:http/http.dart' as http;

class ExperimentalUserSettings extends StatefulWidget {
  @override
  _ExperimentalUserSettingsState createState() =>
      _ExperimentalUserSettingsState();
}

class _ExperimentalUserSettingsState extends State<ExperimentalUserSettings> {
  bool? alertNewPostsEnabled;

  Future<void> _fetchSettings() async {
    final response = await http.get(
      Uri.parse("$serverDomain/profile/settings/list"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: userManager.token,
      },
    );
    if (response.statusCode == 200) {
      var body = response.body;
      var json_converted = jsonDecode(body);

      setState(() {
        alertNewPostsEnabled = json_converted["notify_on_new_post"];
      });
    } else {
      openAlert("error", "Failed loading settings", null, context, null, null);
    }
  }

  Future<void> _changeSetting(String setting, String value) async {
    final response = await http.post(
      Uri.parse("$serverDomain/profile/settings/change"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: userManager.token,
      },
      body: jsonEncode(<String, String>{
        "setting": setting,
        "value": value,
      }),
    );
    if (response.statusCode == 200) {
      return;
    } else {
      ErrorHandler.httpError(response.statusCode, response.body, context);
      // ignore: use_build_context_synchronously
      openAlert("error", "failed to change setting $setting", response.body,
          context, null, null);
      return;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageBackButton(
      warnDiscardChanges: false,
      active: true,
      child: SafeArea(
          top: false,
          child: ListView(
            children: [
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                      child: Text(
                    "Experimental Settings",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ))),
              const Divider(
                color: Color.fromARGB(255, 110, 110, 110),
                thickness: 1.0,
              ),
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                      child: Text(
                    "Settings here may have unknown or unexpected side effects. Please use at your own risk and report any issues to platerates support.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ))),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: InkWell(
                    //change username
                    onTap: () async {
                      if (alertNewPostsEnabled != null) {
                        bool settingValueTo = !alertNewPostsEnabled!;
                        setState(() {
                          alertNewPostsEnabled = null;
                        });

                        await _changeSetting("notify_on_new_post",
                            settingValueTo ? "true" : "false");
                        await _fetchSettings();
                      }
                    },
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
                                Icons.notification_important,
                                color: Colors.white,
                                size: 30,
                              ))),
                          Expanded(
                              child: Text("Alert all new posts",
                                  style: const TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                  ))),
                          AspectRatio(
                              aspectRatio: 1,
                              child: Center(
                                  child: alertNewPostsEnabled == null
                                      ? CircularProgressIndicator(
                                          strokeWidth: 5,
                                        )
                                      : Icon(
                                          (alertNewPostsEnabled == true)
                                              ? Icons.check_box_outlined
                                              : Icons.check_box_outline_blank,
                                          color: Colors.white60,
                                          size: 35,
                                        ))),
                        ],
                      ),
                    ),
                  ))
            ],
          )),
    ));
  }
}
