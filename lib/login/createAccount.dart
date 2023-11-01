import 'dart:convert';

import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/errorHandler.dart';
import 'package:Toaster/main.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class createAccountPage extends StatefulWidget {
  const createAccountPage({super.key});

  @override
  State<createAccountPage> createState() => _createAccountPageState();
}

class _createAccountPageState extends State<createAccountPage> {
  String _emailAddress = '';
  String _username = '';
  bool _agreeToTos = false;
  bool _agreeToCommunityGuidelines = false;

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
        body: Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[
        SafeArea(
            bottom: true,
            top: true,
            child: Center(
                //make sure on pc it's not to wide
                child: SizedBox(
                    width: 500,
                    height: double.infinity,
                    child: Form(
                        key: _formKey,
                        child: Column(children: <Widget>[
                          const SizedBox(height: 48.0),
                          const Text(
                            "Sign Up",
                            style: TextStyle(color: Colors.white, fontSize: 60),
                          ),
                          const SizedBox(height: 48.0),
                          Padding(
                            //password input feild
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextFormField(
                              onChanged: (value) {
                                _username = value;
                              },
                              autofillHints: const [AutofillHints.password],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(
                                    color: Color.fromARGB(255, 200, 200, 200)),
                                contentPadding: EdgeInsets.all(8.0),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            //email input feild
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextFormField(
                              onChanged: (value) {
                                _emailAddress = value;
                              },
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(
                                    color: Color.fromARGB(255, 200, 200, 200)),
                                contentPadding: EdgeInsets.all(8.0),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          SizedBox(
                            height: 24,
                            child: Center(
                              child: Row(
                                children: [
                                  const SizedBox(width: 8.0),
                                  Checkbox(
                                    value: _agreeToTos,
                                    onChanged: (value) => {
                                      setState(() {
                                        _agreeToTos = !_agreeToTos;
                                      })
                                    },
                                    side: const BorderSide(
                                        width: 2, color: Colors.green),
                                  ),
                                  TextButton(
                                    // reset password
                                    onPressed: () {
                                      launchUrl(Uri.parse(
                                          "$serverDomain/termsOfService"));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      //minimumSize:
                                      //    Size.infinite, // Set this
                                      padding: EdgeInsets.zero, // and this
                                    ),
                                    child: RichText(
                                      text: const TextSpan(
                                        text: 'I agree to terms of service. ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: 'View here',
                                            style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              color: Colors.blue,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          SizedBox(
                            height: 24,
                            child: Center(
                              child: Row(
                                children: [
                                  const SizedBox(width: 8.0),
                                  Checkbox(
                                    value: _agreeToCommunityGuidelines,
                                    onChanged: (value) => {
                                      setState(() {
                                        _agreeToCommunityGuidelines =
                                            !_agreeToCommunityGuidelines;
                                      })
                                    },
                                    side: const BorderSide(
                                        width: 2, color: Colors.green),
                                  ),
                                  TextButton(
                                    // reset password
                                    onPressed: () {
                                      launchUrl(Uri.parse(
                                          "$serverDomain/CommunityGuidelines"));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      //minimumSize:
                                      //    Size.infinite, // Set this
                                      padding: EdgeInsets.zero, // and this
                                    ),
                                    child: RichText(
                                      text: const TextSpan(
                                        text:
                                            'I agree to follow community guidelines. ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: 'View here',
                                            style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              color: Colors.blue,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32.0),
                          Padding(
                            //create account button
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50.0,
                              child: ElevatedButton(
                                style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                )),
                                onPressed: () async {
                                  if (_agreeToTos == false) {
                                    openAlert(
                                        "error",
                                        "you must agree to follow terms of service",
                                        null,
                                        context,
                                        null);
                                    return;
                                  }
                                  if (_agreeToCommunityGuidelines == false) {
                                    openAlert(
                                        "error",
                                        "you must agree to follow community guidelines",
                                        null,
                                        context,
                                        null);
                                    return;
                                  }

                                  final response = await http.post(
                                    Uri.parse("$serverDomain/createAccount"),
                                    headers: <String, String>{
                                      'Content-Type':
                                          'application/json; charset=UTF-8',
                                      'X-Firebase-AppCheck':
                                          "${await FirebaseAppCheck.instance.getToken()}",
                                    },
                                    body: jsonEncode({
                                      "email": _emailAddress,
                                      "username": _username,
                                    }),
                                  );

                                  if (response.statusCode == 200) {
                                    // ignore: use_build_context_synchronously
                                    openAlert(
                                        "success",
                                        "created account creation code",
                                        "check your email's to activate your account\nNote: Email has not been tested for being valid",
                                        context,
                                        null);
                                  } else {
                                    // ignore: use_build_context_synchronously
                                    ErrorHandler.httpError(response.statusCode,
                                        response.body, context);
                                    // ignore: use_build_context_synchronously
                                    openAlert(
                                        "error",
                                        "failed creating account creation code",
                                        response.body,
                                        context,
                                        null);
                                  }
                                },
                                child: const Text(
                                  'create account',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                          ),
                        ]))))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
      ],
    ));
  }
}
