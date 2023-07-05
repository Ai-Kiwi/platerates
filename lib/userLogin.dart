import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class LoginResponse {
  bool? success;
  String? error;

  LoginResponse({this.success, this.error});
}

// User class
class User {
  String token = "";
  String userId = "";

  //User({this.token});
  User();

  Future<void> loadTokenFromStoreage() async {
    String? tokenValue = await storage.read(key: "token");
    if (tokenValue == null) {
      token = "";
    } else {
      token = tokenValue.toString();
    }

    String? userIdValue = await storage.read(key: "userId");
    if (userIdValue == null) {
      userId = "";
    } else {
      userId = userIdValue.toString();
    }
  }

  Future<bool> checkLoginState() async {
    if (token == "") {
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse("http://$serverDomain/testToken"),
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
        Uri.parse("http://$serverDomain/login"),
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
        userId = returnData["userId"];
        await storage.write(key: "token", value: token);
        await storage.write(key: "userId", value: userId);
        return LoginResponse(error: null, success: true);
      } else {
        return LoginResponse(error: response.body, success: false);
      }
    } catch (err) {
      return LoginResponse(error: "error contacting server", success: false);
    }
  }

  Stream<bool> checkLoginStateStream() async* {
    if (token == "") {
      await loadTokenFromStoreage();
    }
    yield await checkLoginState();
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _username = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Center(
                child: Text(
          'Log in',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 30,
          ),
        ))),
        body: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration:
                const BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
            child: Center(
                child: Column(
              children: <Widget>[
                const SizedBox(height: 16.0),
                Padding(
                  //closed beta reminder
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    height: 50.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 231, 38, 38),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                const SizedBox(height: 8.0),
                Divider(
                  color: Color.fromARGB(255, 110, 110, 110),
                  thickness: 1.0,
                ),
                const SizedBox(height: 8.0),
                Padding(
                  //email input feild
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    child: TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _username = value;
                        });
                      },
                      style: TextStyle(color: Colors.white, fontSize: 20),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(
                            color: const Color.fromARGB(255, 200, 200, 200)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                              width: 2,
                              color: const Color.fromARGB(255, 45, 45, 45)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                              width: 2,
                              color: const Color.fromARGB(255, 45, 45, 45)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                              width: 2, color: Theme.of(context).primaryColor),
                        ),
                        contentPadding: EdgeInsets.all(16.0),
                        fillColor: const Color.fromARGB(255, 40, 40, 40),
                        filled: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Padding(
                  //password input feild
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            _password = value;
                          });
                        },
                        obscureText: true,
                        style: TextStyle(color: Colors.white, fontSize: 20),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                              color: const Color.fromARGB(255, 200, 200, 200)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                                width: 2,
                                color: const Color.fromARGB(255, 45, 45, 45)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                                width: 2,
                                color: const Color.fromARGB(255, 45, 45, 45)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context).primaryColor),
                          ),
                          contentPadding: EdgeInsets.all(16.0),
                          fillColor: const Color.fromARGB(255, 40, 40, 40),
                          filled: true,
                        )),
                  ),
                ),
                const SizedBox(height: 24.0),
                Padding(
                  //login button
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    height: 50.0,
                    child: ElevatedButton(
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      )),
                      onPressed: () async {
                        LoginResponse CorrectLogin =
                            await userManager.loginUser(_username, _password);

                        if (CorrectLogin.success == true) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyHomePage()),
                          );
                        } else {
                          Alert(
                            context: context,
                            type: AlertType.error,
                            title: "login failed",
                            desc: CorrectLogin.error,
                            buttons: [
                              DialogButton(
                                child: Text(
                                  "ok",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                                onPressed: () => Navigator.pop(context),
                                width: 120,
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
                    Alert(
                      context: context,
                      type: AlertType.info,
                      title: "reset password not added yet",
                      desc:
                          "just idk, don't use bad passwords and remember them??? I mean i'm just saying it would fix alota problems in this day and age.",
                      buttons: [
                        DialogButton(
                          child: Text(
                            "ok",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          onPressed: () => Navigator.pop(context),
                          width: 120,
                        )
                      ],
                    ).show();
                  },
                  child: const Text('Reset Password'),
                ),
              ],
            ))));
  }
}

User userManager = User();
