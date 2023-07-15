import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../login/userLogin.dart';
import '../main.dart';

class ReportSystem {
  Future<void> reportItem(context, String postItemType, String postItem) async {
    final response = await http.post(
      Uri.parse("$serverDomain/report"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "token": userManager.token,
        "reportItem": {
          "type": postItemType,
          "data": postItem,
        }
      }),
    );
    if (response.statusCode == 200) {
      Alert(
        context: context,
        type: AlertType.success,
        title: "post reported",
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            width: 120,
            child: const Text(
              "ok",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ],
      ).show();
    } else {
      Alert(
        context: context,
        type: AlertType.error,
        title: "failed reporting post",
        desc: response.body,
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            width: 120,
            child: const Text(
              "ok",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ],
      ).show();
    }
  }
}

ReportSystem reportSystem = ReportSystem();
