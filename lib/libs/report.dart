import 'dart:convert';
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
        context: context,
        title: "report",
        content: Column(
          children: <Widget>[
            TextField(
              maxLengthEnforcement:
                  MaxLengthEnforcement.truncateAfterCompositionEnds,
              maxLength: 1000,
              decoration: const InputDecoration(
                icon: Icon(Icons.account_circle),
                labelText: 'reason',
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                  'post reported',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                )));
              } else {
                ErrorHandler.httpError(
                    response.statusCode, response.body, context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                  'failed reporting post',
                  style: TextStyle(fontSize: 20, color: Colors.red),
                )));
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
