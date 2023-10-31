import 'dart:convert';

import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/imageUtils.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
//import 'package:toggle_switch/toggle_switch.dart';

import '../libs/errorHandler.dart';
import '../main.dart';
import '../login/userLogin.dart';

class CreatePostPage extends StatefulWidget {
  final List<int> imageData;

  CreatePostPage({
    required this.imageData,
  });

  @override
  _CreatePostState createState() => _CreatePostState(imageData: imageData);
}

class _CreatePostState extends State<CreatePostPage> {
  final List<int> imageData;
  late Uint8List convertedImageData;
  String _title = '';
  String _description = '';
  int shareModeSelected = 0;
  List<String> postCodeNames = ['public', 'friends'];
  List<String> postNamings = ['public post', 'friend\'s only post'];

  _CreatePostState({required this.imageData});

  @override
  Widget build(BuildContext context) {
    convertedImageData = Uint8List.fromList(imageData);
    return Scaffold(
        body: Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[
        Center(
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
            const Divider(
              color: Color.fromARGB(255, 110, 110, 110),
              thickness: 1.0,
            ),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                  width: double.infinity,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          convertedImageData,
                          fit: BoxFit.cover,
                        )),
                  )),
            ),
            const SizedBox(height: 16),
            Padding(
              //title input feild
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                child: TextFormField(
                  maxLength: 50,
                  maxLengthEnforcement:
                      MaxLengthEnforcement.truncateAfterCompositionEnds,
                  onChanged: (value) {
                    _title = value;
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    counterText: "",
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white),
                    contentPadding: EdgeInsets.all(8.0),
                    prefixIcon: Icon(
                      Icons.text_fields,
                      color: Colors.green,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              //description input feild
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  maxLength: 250,
                  maxLengthEnforcement:
                      MaxLengthEnforcement.truncateAfterCompositionEnds,
                  maxLines: 5,
                  onChanged: (value) {
                    _description = value;
                  },
                  style: TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    counterText: "",
                    labelText: 'description',
                    labelStyle: TextStyle(
                      color: Colors.white,
                    ),
                    contentPadding: const EdgeInsets.all(16.0),
                    prefixIcon: Icon(
                      Icons.description,
                      color: Colors.green,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                ),
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
                    openAlert("yes_or_no",
                        "Are you sure you want to post this?", null, context, {
                      "yes": () async {
                        Navigator.pop(context);

                        try {
                          final response = await http.post(
                            Uri.parse("$serverDomain/post/upload"),
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                            },
                            body: jsonEncode({
                              "token": userManager.token,
                              "title": _title,
                              "description": _description,
                              "shareMode": postCodeNames[shareModeSelected],
                              "image": base64Encode(
                                  imageUtils.uintListToBytes(imageData)),
                            }),
                          );

                          if (response.statusCode == 201) {
                            Navigator.pop(context);
                            // ignore: use_build_context_synchronously
                            openAlert(
                                "success", "created post", null, context, null);
                          } else {
                            ErrorHandler.httpError(
                                response.statusCode, response.body, context);
                            openAlert("error", "error uploading post", null,
                                context, null);
                          }
                        } on Exception catch (error, stackTrace) {
                          FirebaseCrashlytics.instance
                              .recordError(error, stackTrace);
                          openAlert("error", "unkown error contacting serer",
                              null, context, null);
                        }
                      },
                      "no": () {
                        Navigator.pop(context);
                      },
                    });
                  },
                  child: const Text(
                    'Upload post',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        )),
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

//remember that you can do the following to close this menu, should also be a exit option if you don't wanna post
//Navigator.pop(context);