import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import 'package:toggle_switch/toggle_switch.dart';

import '../main.dart';
import '../userLogin.dart';

class CreatePostPage extends StatefulWidget {
  final String imagePath;

  CreatePostPage({
    required this.imagePath,
  });

  @override
  _CreatePostState createState() => _CreatePostState(imagePath: imagePath);
}

class _CreatePostState extends State<CreatePostPage> {
  final String imagePath;
  String _title = '';
  String _description = '';
  int shareModeSelected = 0;
  List<String> postCodeNames = ['public', 'friends'];
  List<String> postNamings = ['public post', 'friend\'s only post'];

  _CreatePostState({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
        body: Center(
            child: ListView(
          children: [
            const Center(
                child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                    child: Text(
                      "Title post",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(
                        color: Color.fromARGB(215, 45, 45, 45), width: 3)),
                width: double.infinity,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(imagePath))),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              //email input feild
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                child: TextFormField(
                  maxLength: 50,
                  maxLengthEnforcement:
                      MaxLengthEnforcement.truncateAfterCompositionEnds,
                  onChanged: (value) {
                    setState(() {
                      _title = value;
                    });
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    labelText: 'Title',
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
                child: TextField(
                    keyboardType: TextInputType.multiline,
                    maxLength: 250,
                    maxLengthEnforcement:
                        MaxLengthEnforcement.truncateAfterCompositionEnds,
                    maxLines: 5,
                    onChanged: (value) {
                      setState(() {
                        _description = value;
                      });
                    },
                    style: TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      counterText: "",
                      labelText: 'description',
                      labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 200, 200, 200),
                      ),
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
            ),
            //const SizedBox(height: 16.0),
            //Padding(
            //  //share mode selection
            //  padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //  child: Container(
            //    width: double.infinity,
            //    child: ToggleSwitch(
            //      minWidth: double.infinity,
            //      cornerRadius: 15.0,
            //      initialLabelIndex: 0,
            //      totalSwitches: 2,
            //      activeBgColors: const [
            //        [Colors.green],
            //        [Colors.redAccent]
            //      ],
            //      centerText: true,
            //      activeFgColor: Colors.white,
            //      inactiveBgColor: const Color.fromARGB(255, 40, 40, 40),
            //      inactiveFgColor: Colors.white,
            //      labels: postNamings,
            //      onToggle: (index) {
            //        shareModeSelected = index!;
            //      },
            //    ),
            //  ),
            //),
            const SizedBox(height: 16.0),
            Padding(
              //take photo button
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
                    Alert(
                      context: context,
                      type: AlertType.warning,
                      title: "Are you sure you want to post?",
                      desc: "once done this is done",
                      buttons: [
                        DialogButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            File postImageFile = File(imagePath);

                            try {
                              print(_title);
                              final response = await http.post(
                                Uri.parse("http://$serverDomain/post/upload"),
                                headers: <String, String>{
                                  'Content-Type':
                                      'application/json; charset=UTF-8',
                                },
                                body: jsonEncode({
                                  "token": userManager.token,
                                  "title": _title,
                                  "description": _description,
                                  "shareMode": postCodeNames[shareModeSelected],
                                  "image": base64Encode(
                                      postImageFile.readAsBytesSync()),
                                }),
                              );

                              if (response.statusCode == 200) {
                                // ignore: use_build_context_synchronously
                                Alert(
                                  context: context,
                                  type: AlertType.success,
                                  title: "post uploaded",
                                  desc: "",
                                  buttons: [
                                    DialogButton(
                                      width: 120,
                                      child: const Text(
                                        "ok",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      onPressed: () => {
                                        Navigator.pop(context),
                                        Navigator.pop(context)
                                      },
                                    )
                                  ],
                                ).show();
                              } else {
                                Alert(
                                  context: context,
                                  type: AlertType.error,
                                  title: "error uploading post",
                                  desc: response.body,
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
                            } catch (err) {
                              print(err);
                              Alert(
                                context: context,
                                type: AlertType.error,
                                title: "unkown error contacting server",
                                desc: null,
                                buttons: [
                                  DialogButton(
                                    width: 120,
                                    child: const Text(
                                      "ok",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  )
                                ],
                              ).show();
                            }
                          },
                          color: Colors.green,
                          child: const Text(
                            "Yes",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        DialogButton(
                          color: Colors.red,
                          child: const Text(
                            "No",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ).show();
                  },
                  child: const Text(
                    'Upload post',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ),
          ],
        )));
  }
}

//remember that you can do the following to close this menu, should also be a exit option if you don't wanna post
//Navigator.pop(context);