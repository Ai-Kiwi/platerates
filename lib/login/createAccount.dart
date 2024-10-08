import 'dart:convert';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/errorHandler.dart';
import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:PlateRates/main.dart';
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
  String _passowrd = '';
  String _confirmPassword = '';
  bool _agreeToTos = false;
  bool _agreeToCommunityGuidelines = false;

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
        body: PageBackButton(
      warnDiscardChanges: false,
      active: true,
      child: SafeArea(
          bottom: true,
          top: true,
          child: Center(
              //make sure on pc it's not to wide
              child: SizedBox(
                  width: 500,
                  height: double.infinity,
                  child: SingleChildScrollView(
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
                              initialValue: _username,
                              onChanged: (value) {
                                _username = value;
                              },
                              autofillHints: const [AutofillHints.password],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: const TextStyle(
                                    color: Color.fromARGB(255, 200, 200, 200)),
                                contentPadding: const EdgeInsets.all(8.0),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
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
                              initialValue: _emailAddress,
                              onChanged: (value) {
                                _emailAddress = value;
                              },
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: const TextStyle(
                                    color: Color.fromARGB(255, 200, 200, 200)),
                                contentPadding: const EdgeInsets.all(8.0),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
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
                              obscureText: true,
                              initialValue: _passowrd,
                              onChanged: (value) {
                                _passowrd = value;
                              },
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(
                                    color: Color.fromARGB(255, 200, 200, 200)),
                                contentPadding: const EdgeInsets.all(8.0),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
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
                              obscureText: true,
                              initialValue: _confirmPassword,
                              onChanged: (value) {
                                _confirmPassword = value;
                              },
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                              decoration: InputDecoration(
                                labelText: 'Password Confirmation',
                                labelStyle: const TextStyle(
                                    color: Color.fromARGB(255, 200, 200, 200)),
                                contentPadding: const EdgeInsets.all(8.0),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
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
                                    side: BorderSide(
                                        width: 2,
                                        color: Theme.of(context).primaryColor),
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
                                      side: BorderSide(
                                          width: 2,
                                          color:
                                              Theme.of(context).primaryColor)),
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
                                        null,
                                        null);
                                    return;
                                  }
                                  if (_agreeToCommunityGuidelines == false) {
                                    openAlert(
                                        "error",
                                        "you must agree to follow community guidelines",
                                        null,
                                        context,
                                        null,
                                        null);
                                    return;
                                  }
                                  if (_confirmPassword != _passowrd) {
                                    openAlert(
                                        "error",
                                        "Passwords must be the same",
                                        null,
                                        context,
                                        null,
                                        null);
                                    return;
                                  }
                                  if (_passowrd == "") {
                                    openAlert(
                                        "error",
                                        "Passwords can't be nothing",
                                        null,
                                        context,
                                        null,
                                        null);
                                    return;
                                  }
                                  if (_emailAddress == "") {
                                    openAlert("error", "Email can't be nothing",
                                        null, context, null, null);
                                    return;
                                  }
                                  if (_username == "") {
                                    openAlert(
                                        "error",
                                        "Username can't be nothing",
                                        null,
                                        context,
                                        null,
                                        null);
                                    return;
                                  }

                                  final response = await http.post(
                                    Uri.parse("$serverDomain/createAccount"),
                                    headers: <String, String>{
                                      'Content-Type':
                                          'application/json; charset=UTF-8',
                                    },
                                    body: jsonEncode({
                                      "email": _emailAddress,
                                      "username": _username,
                                      "password":
                                          _confirmPassword, //just for craps this uses confirm password feild so technicality everyone who talks about this is wrong
                                    }),
                                  );

                                  if (response.statusCode == 200) {
                                    // ignore: use_build_context_synchronously
                                    openAlert(
                                        "success",
                                        "created account creation code",
                                        "check your email's to activate your account\nNote: Email has not been tested for being valid",
                                        context,
                                        null,
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
                                        null,
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
                        ])),
                  )))),
    ));
  }
}
