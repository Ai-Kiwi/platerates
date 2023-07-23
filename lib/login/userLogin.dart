import 'dart:convert';

import 'package:Toaster/login/userResetPassword.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
            child: Center(
                child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Login",
                style: TextStyle(color: Colors.white, fontSize: 40),
              ),
            ),
            const Divider(
              color: Color.fromARGB(255, 110, 110, 110),
              thickness: 1.0,
            ),
            const SizedBox(height: 8.0),
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
                                    "You are using web version which is poorly optimised and not recommend, please use phone app for best experience",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                    )),
                              ))))),
                ])),
            const SizedBox(height: 16.0),
            Padding(
              //email input feild
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                onChanged: (value) {
                  setState(() {
                    _username = value;
                  });
                },
                autofillHints: const [AutofillHints.email],
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 200, 200, 200)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: const BorderSide(
                        width: 2, color: Color.fromARGB(255, 45, 45, 45)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: const BorderSide(
                        width: 2, color: Color.fromARGB(255, 45, 45, 45)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide(
                        width: 2, color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: const EdgeInsets.all(16.0),
                  fillColor: const Color.fromARGB(255, 40, 40, 40),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              //password input feild
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _password = value;
                    });
                  },
                  autofillHints: const [AutofillHints.password],
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 200, 200, 200)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(
                          width: 2, color: Color.fromARGB(255, 45, 45, 45)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(
                          width: 2, color: Color.fromARGB(255, 45, 45, 45)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide(
                          width: 2, color: Theme.of(context).primaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16.0),
                    fillColor: const Color.fromARGB(255, 40, 40, 40),
                    filled: true,
                  )),
            ),
            const SizedBox(height: 24.0),
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
                    LoginResponse correctLogin =
                        await userManager.loginUser(_username, _password);

                    if (correctLogin.success == true) {
                      //save login
                      //TextInput.finishAutofillContext();
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MyHomePage()),
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
                            onPressed: () => Navigator.pop(context),
                            width: 120,
                            child: const Text(
                              "ok",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
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
            //const SizedBox(height: 16),
            TextButton(
              // reset password
              onPressed: () {
                Navigator.of(context)
                    .push(smoothTransitions.slideUp(const ResetPasswordPage()));
              },
              child: const Text('Reset Password'),
            ),
            const Padding(
                //login button
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text('by signing in you agree to our privacy policy',
                    style: TextStyle(
                      fontStyle: FontStyle.normal,
                      color: Colors.white70,
                    ))),
            const Padding(
                //login button
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                child: Text('view at https://toaster.aikiwi.dev/privacyPolicy',
                    style: TextStyle(
                      fontStyle: FontStyle.normal,
                      color: Colors.white70,
                    ))),

            const Expanded(child: Center()),
            const Padding(
              //login button
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              child: Text(
                'contact support at toaster@aikiwi.dev',
                style: TextStyle(
                    fontStyle: FontStyle.normal, color: Colors.white70),
              ),
            ),
          ],
        ))));
  }
}

User userManager = User();
