import 'dart:convert';
import 'package:Toaster/libs/alertSystem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../login/userLogin.dart';
import '../main.dart';
import 'errorHandler.dart';

class ReportSystem {
  Future<void> reportItem(context, String postItemType, String postItem) async {
    String reportReason = "";
    Alert(
        style: alertStyle,
        context: context,
        title: "report",
        desc:
            "note: depending on what you are reporting support may need to look further into your account.\neg past chat messages or posts",
        content: Column(
          children: <Widget>[
            TextField(
              maxLengthEnforcement:
                  MaxLengthEnforcement.truncateAfterCompositionEnds,
              maxLength: 1000,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                icon: Icon(Icons.account_circle, color: Colors.white),
                labelText: 'reason',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              onChanged: (value) {
                reportReason = value;
              },
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () async {
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
                  },
                  "reason": reportReason,
                }),
              );
              if (response.statusCode == 201) {
                openAlert(
                    "success", "post reported", null, context, null, null);
              } else {
                ErrorHandler.httpError(
                    response.statusCode, response.body, context);
                openAlert("error", "failed reporting post", response.body,
                    context, null, null);
              }
            },
            child: const Text(
              "report",
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
  }
}

ReportSystem reportSystem = ReportSystem();
