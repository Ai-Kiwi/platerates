import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:PlateRates/libs/errorHandler.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:PlateRates/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

const alertStyle = AlertStyle(
  animationType: AnimationType.grow,
  isCloseButton: true,
  //isOverlayTapDismiss: false,
  titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  descStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),

  animationDuration: Duration(milliseconds: 250),
  //alertBorder: RoundedRectangleBorder(
  //  borderRadius: BorderRadius.circular(0.0),
  //  side: BorderSide(
  //    color: Colors.grey,
  //  ),
  //),

  //alertAlignment: Alignment.topCenter,
);

Future<void> openAlert(
    String type,
    String title,
    String? desc,
    context,
    Map<String, VoidCallback>? functionsToRunPerButton,
    List<Widget>? customButtons) async {
  if (type == "info") {
    Alert(
      context: context,
      style: alertStyle,
      type: AlertType.info,
      title: title,
      desc: desc,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "ok",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ],
    ).show();
  } else if (type == "error") {
    Alert(
      context: context,
      style: alertStyle,
      type: AlertType.error,
      title: title,
      desc: desc,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "ok",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ],
    ).show();
  } else if (type == "success") {
    Alert(
      context: context,
      style: alertStyle,
      type: AlertType.success,
      title: title,
      desc: desc,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "ok",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ],
    ).show();
  } else if (type == "warning") {
    Alert(
      context: context,
      style: alertStyle,
      type: AlertType.warning,
      title: title,
      desc: desc,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "ok",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ],
    ).show();
  } else if (type == "logout") {
    Alert(
      context: context,
      type: AlertType.info,
      title: "select devices to logout",
      style: alertStyle,
      buttons: [
        DialogButton(
          color: Theme.of(context).primaryColor,
          child: const Text(
            "all",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () async {
            Navigator.pop(context);
            final response = await http.post(
              Uri.parse("$serverDomain/login/logout"),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
                HttpHeaders.authorizationHeader: userManager.token,
              },
              body: jsonEncode(<String, String>{}),
            );
            if (response.statusCode == 200) {
              await jsonCache.clear();
              await jsonCache.refresh("expire-data", {
                "expireTime": DateTime.now().day,
                "clientVersion": '$version+$buildNumber'
              });
              userManager.loggedIn = false;
              userManager.token = "";
              userManager.userId = "";
              Phoenix.rebirth(context);
            } else {
              ErrorHandler.httpError(
                  response.statusCode, response.body, context);
              openAlert("error", "failed logging out", response.body, context,
                  null, null);
            }
          },
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
        ),
      ],
    ).show();
  } else if (type == "yes_or_no") {
    Alert(
      context: context,
      type: AlertType.warning,
      title: title,
      desc: desc,
      style: alertStyle,
      buttons: [
        DialogButton(
          color: Colors.red,
          child: const Text(
            "No",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: functionsToRunPerButton?["no"],
        ),
        DialogButton(
          onPressed: functionsToRunPerButton?["yes"],
          color: Theme.of(context).primaryColor,
          child: const Text(
            "Yes",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        )
      ],
    ).show();
  } else if (type == "custom_buttons") {
    Alert(
      context: context,
      title: title,
      desc: desc,
      style: alertStyle,
      content: Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          Column(children: customButtons!)
        ],
      ),
      buttons: [],
    ).show();
  }
}

//create yes or no question and apply
//custom for which devices to logout and apply