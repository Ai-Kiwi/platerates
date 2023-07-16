import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import 'package:toggle_switch/toggle_switch.dart';
import '../main.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  String _NewPassword = "";
  String _confirmNewPassword = "";
  String _email = "";
  String _resetCode = "";
  bool _useResetCode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration:
                const BoxDecoration(color: Color.fromRGBO(16, 16, 16, 1)),
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
                      setState(() {
                        _email = value;
                      });
                    },
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
                          _NewPassword = value;
                        });
                      },
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: InputDecoration(
                        labelText: 'New Password',
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
                const SizedBox(height: 16.0),
                Padding(
                  //confirm password input feild
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _confirmNewPassword = value;
                        });
                      },
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
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
                const SizedBox(height: 12.0),
                Padding(
                  //reset code feild
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _resetCode = value;
                        });
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: InputDecoration(
                        labelText: 'Reset Code',
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
                const SizedBox(height: 12.0),
                Padding(
                  //if to create reset code or use reset code
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    child: ToggleSwitch(
                      minWidth: double.infinity,
                      cornerRadius: 15.0,
                      initialLabelIndex: 0,
                      totalSwitches: 2,
                      centerText: true,
                      activeFgColor: Colors.white,
                      inactiveBgColor: const Color.fromARGB(255, 40, 40, 40),
                      inactiveFgColor: Colors.white,
                      labels: const ["create reset code", "use reset code"],
                      onToggle: (index) {
                        if (index! == 1) {
                          _useResetCode = true;
                        } else {
                          _useResetCode = false;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
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
                        if (_useResetCode == true) {
                          final response = await http.post(
                            Uri.parse("$serverDomain/login/reset-password"),
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                            },
                            body: jsonEncode(<String, String>{
                              'email': _email,
                              'newPassword': _NewPassword,
                              'resetCode': _resetCode,
                            }),
                          );
                          if (_NewPassword != _confirmNewPassword) {
                            Alert(
                              context: context,
                              type: AlertType.error,
                              title: "passwords do not match",
                              buttons: [
                                DialogButton(
                                  onPressed: () => Navigator.pop(context),
                                  width: 120,
                                  child: const Text(
                                    "ok",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                )
                              ],
                            ).show();
                          } else {
                            if (response.statusCode == 200) {
                              Alert(
                                context: context,
                                type: AlertType.success,
                                title: "password changed",
                                buttons: [
                                  DialogButton(
                                    onPressed: () => Navigator.pop(context),
                                    width: 120,
                                    child: const Text(
                                      "ok",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                  )
                                ],
                              ).show();
                            } else {
                              Alert(
                                context: context,
                                type: AlertType.error,
                                title: "error using reseting password code",
                                desc: response.body,
                                buttons: [
                                  DialogButton(
                                    onPressed: () => Navigator.pop(context),
                                    width: 120,
                                    child: const Text(
                                      "ok",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                  )
                                ],
                              ).show();
                            }
                          }
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
                            Alert(
                              context: context,
                              type: AlertType.success,
                              title: "reset password code created",
                              buttons: [
                                DialogButton(
                                  onPressed: () => Navigator.pop(context),
                                  width: 120,
                                  child: const Text(
                                    "ok",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                )
                              ],
                            ).show();
                          } else {
                            Alert(
                              context: context,
                              type: AlertType.error,
                              title: "error creating reseting password code",
                              desc: response.body,
                              buttons: [
                                DialogButton(
                                  onPressed: () => Navigator.pop(context),
                                  width: 120,
                                  child: const Text(
                                    "ok",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                )
                              ],
                            ).show();
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
            ))));
  }
}
