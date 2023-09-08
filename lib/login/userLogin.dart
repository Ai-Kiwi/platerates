import 'dart:convert';

import 'package:Toaster/login/userResetPassword.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../libs/smoothTransitions.dart';
import '../main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class LoginResponse {
  bool? success;
  String? error;

  LoginResponse({this.success, this.error});
}

// User class
class User {
  String token = "";

  //User({this.token});
  User();

  Future<void> loadTokenFromStoreage() async {
    String? tokenValue = await storage.read(key: "token");
    if (tokenValue == null) {
      token = "";
    } else {
      token = tokenValue.toString();
    }
  }

  Future<bool> checkLoginState() async {
    if (token == "") {
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse("$serverDomain/testToken"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': token,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (err) {
      return false;
    }
  }

  Future<LoginResponse> loginUser(String emailAddress, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$serverDomain/login"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': emailAddress,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        var returnData = jsonDecode(response.body);
        token = returnData["token"];
        await storage.write(key: "token", value: token);
        return LoginResponse(error: null, success: true);
      } else {
        return LoginResponse(error: response.body, success: false);
      }
    } catch (err) {
      return LoginResponse(error: "error contacting server", success: false);
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _username = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
        body: SafeArea(
            bottom: true,
            top: true,
            child: Stack(
              children: [
                Center(
                    //make sure on pc it's not to wide
                    child: Container(
                        width: 650,
                        height: double.infinity,
                        child: Center(
                            child: AutofillGroup(
                                child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Login",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 40),
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              //email input feild
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: TextFormField(
                                onChanged: (value) {
                                  setState(() {
                                    _username = value;
                                  });
                                },
                                autofillHints: const [AutofillHints.email],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: const TextStyle(
                                      color:
                                          Color.fromARGB(255, 200, 200, 200)),
                                  contentPadding: const EdgeInsets.all(16.0),
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
                            Padding(
                              //password input feild
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: TextFormField(
                                  onChanged: (value) {
                                    setState(() {
                                      _password = value;
                                    });
                                  },
                                  autofillHints: const [AutofillHints.password],
                                  obscureText: true,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 200, 200, 200)),
                                    contentPadding: const EdgeInsets.all(16.0),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.green),
                                    ),
                                  )),
                            ),
                            const SizedBox(height: 8.0),
                            TextButton(
                              // reset password
                              onPressed: () {
                                Navigator.of(context).push(smoothTransitions
                                    .slideUp(const ResetPasswordPage()));
                              },
                              child: const Text('Reset Password'),
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              //login button
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
                                    LoginResponse correctLogin =
                                        await userManager.loginUser(
                                            _username, _password);

                                    if (correctLogin.success == true) {
                                      //save login
                                      TextInput.finishAutofillContext();
                                      // ignore: use_build_context_synchronously
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MyHomePage()),
                                      );
                                    } else {
                                      // ignore: use_build_context_synchronously
                                      Alert(
                                        context: context,
                                        type: AlertType.error,
                                        title: "login failed",
                                        desc: correctLogin.error,
                                        buttons: [
                                          DialogButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            width: 120,
                                            child: const Text(
                                              "ok",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20),
                                            ),
                                          )
                                        ],
                                      ).show();
                                    }
                                  },
                                  child: const Text(
                                    'Log in',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ))))),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Column(children: [
                    SizedBox(
                      height: 8,
                    ),
                    Padding(
                      //closed beta reminder
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 231, 38, 38),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                  "Toaster is currently in a closed beta. Please contact the owner to request access to the closed beta.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                  )),
                            ),
                          ),
                        ),
                      ),
                    ),
                    //warning about running on web
                    Visibility(
                        visible: kIsWeb,
                        child: Column(children: [
                          const SizedBox(height: 16.0),
                          Padding(
                              //closed beta reminder
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: SizedBox(
                                  width: double.infinity,
                                  height: 50.0,
                                  child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 231, 38, 38),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: const Center(
                                          child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Text(
                                            "You are using web version which is poorly optimised and not recommend, please use phone app for best experience",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                            )),
                                      ))))),
                        ])),
                  ]),
                ),
                const Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: Column(children: [
                    Expanded(child: Center()),
                    Text('by signing in you agree to our privacy policy',
                        style: TextStyle(
                          fontStyle: FontStyle.normal,
                          color: Colors.white70,
                        )),
                    SizedBox(height: 2),
                    Text('view at https://toaster.aikiwi.dev/privacyPolicy',
                        style: TextStyle(
                          fontStyle: FontStyle.normal,
                          color: Colors.white70,
                        )),
                    SizedBox(height: 8),
                    Text(
                      'contact support at toaster@aikiwi.dev',
                      style: TextStyle(
                          fontStyle: FontStyle.normal, color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                  ]),
                )
              ],
            )));
  }
}

User userManager = User();
