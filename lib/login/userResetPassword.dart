import 'dart:convert';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:toggle_switch/toggle_switch.dart';
import '../libs/errorHandler.dart';
import '../main.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  String _email = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageBackButton(
      warnDiscardChanges: false,
      active: true,
      child: SizedBox(
          child: Center(
              child: Column(
        children: <Widget>[
          const SizedBox(height: 32.0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "Reset Password",
              style: TextStyle(color: Colors.white, fontSize: 40),
            ),
          ),
          const Divider(
            color: Color.fromARGB(255, 110, 110, 110),
            thickness: 1.0,
          ),
          const SizedBox(height: 8.0),
          Padding(
            //email input feild
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              onChanged: (value) {
                _email = value;
              },
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle:
                    const TextStyle(color: Color.fromARGB(255, 200, 200, 200)),
                contentPadding: const EdgeInsets.all(8.0),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Padding(
            //login button
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                )),
                onPressed: () async {
                  if (_email == "") {
                    openAlert("error", "email can't be nothing", null, context,
                        null, null);
                  } else {
                    final response = await http.post(
                      Uri.parse("$serverDomain/login/reset-password"),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                      },
                      body: jsonEncode(<String, String>{
                        'email': _email,
                      }),
                    );
                    if (response.statusCode == 200) {
                      // ignore: use_build_context_synchronously
                      openAlert(
                          "success",
                          "created reset password link, check emails",
                          null,
                          context,
                          null,
                          null);
                    } else {
                      // ignore: use_build_context_synchronously
                      ErrorHandler.httpError(
                          response.statusCode, response.body, context);
                      // ignore: use_build_context_synchronously
                      openAlert("error", "failed creating reset password link",
                          response.body, context, null, null);
                    }
                  }
                },
                child: const Text(
                  'reset password',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ),
          ),
        ],
      ))),
    ));
  }
}
