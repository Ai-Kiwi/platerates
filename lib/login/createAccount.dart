import 'dart:convert';

import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/errorHandler.dart';
import 'package:Toaster/main.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class createAccountPage extends StatefulWidget {
  const createAccountPage({super.key});

  @override
  State<createAccountPage> createState() => _createAccountPageState();
}

class _createAccountPageState extends State<createAccountPage> {
  String _emailAddress = '';
  String _username = '';

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
        backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
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
                                style: TextStyle(
                                    color: Colors.white, fontSize: 60),
                              ),
                              const SizedBox(height: 48.0),
                              Padding(
                                //password input feild
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
                                        color:
                                            Color.fromARGB(255, 200, 200, 200)),
                                    contentPadding: EdgeInsets.all(8.0),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.green),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                //email input feild
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
                                        color:
                                            Color.fromARGB(255, 200, 200, 200)),
                                    contentPadding: EdgeInsets.all(8.0),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.green),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32.0),
                              Visibility(
                                visible: kIsWeb == false,
                                child: Padding(
                                  //create account button
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 50.0,
                                    child: ElevatedButton(
                                      style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      )),
                                      onPressed: () async {
                                        final response = await http.post(
                                          Uri.parse(
                                              "$serverDomain/createAccount"),
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
                                              "check your email's to activate your account",
                                              context,
                                              null);
                                        } else {
                                          // ignore: use_build_context_synchronously
                                          ErrorHandler.httpError(
                                              response.statusCode,
                                              response.body,
                                              context);
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
                              ),
                              const Visibility(
                                visible: kIsWeb == true,
                                child: Text(
                                    "creating accounts currently limited to phone app\nplease use either your or another persons phone to sign up\nsorry for the inconvenience",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 15)),
                              ),
                            ]))))),
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
          ],
        ));
  }
}
