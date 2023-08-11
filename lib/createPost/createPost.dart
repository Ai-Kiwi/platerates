import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
//import 'package:toggle_switch/toggle_switch.dart';

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

  Uint8List uintListToBytes(List<int> uintList) {
    final buffer = Uint8List.fromList(uintList);
    final byteData = ByteData.view(buffer.buffer);
    return byteData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    convertedImageData = Uint8List.fromList(imageData);
    return Scaffold(
        backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
        body: Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            Center(
                child: ListView(
              children: [
                const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16),
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
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          border: Border.all(
                              color: Color.fromARGB(215, 45, 45, 45),
                              width: 3)),
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
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
                                width: 2,
                                color: Color.fromARGB(255, 45, 45, 45)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: const BorderSide(
                                width: 2,
                                color: Color.fromARGB(255, 45, 45, 45)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context).primaryColor),
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
                          title: "Are you sure you want to post this?",
                          buttons: [
                            DialogButton(
                              onPressed: () async {
                                Navigator.pop(context);

                                try {
                                  final response = await http.post(
                                    Uri.parse("$serverDomain/post/upload"),
                                    headers: <String, String>{
                                      'Content-Type':
                                          'application/json; charset=UTF-8',
                                    },
                                    body: jsonEncode({
                                      "token": userManager.token,
                                      "title": _title,
                                      "description": _description,
                                      "shareMode":
                                          postCodeNames[shareModeSelected],
                                      "image": base64Encode(
                                          uintListToBytes(imageData)),
                                    }),
                                  );

                                  if (response.statusCode == 201) {
                                    // ignore: use_build_context_synchronously
                                    Alert(
                                      context: context,
                                      type: AlertType.success,
                                      title: "post uploaded",
                                      buttons: [
                                        DialogButton(
                                          width: 120,
                                          child: const Text(
                                            "ok",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
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
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          width: 120,
                                        )
                                      ],
                                    ).show();
                                  }
                                } catch (err) {
                                  Alert(
                                    context: context,
                                    type: AlertType.error,
                                    title: "unkown error contacting server",
                                    buttons: [
                                      DialogButton(
                                        width: 120,
                                        child: const Text(
                                          "ok",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20),
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
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            ),
                            DialogButton(
                              color: Colors.red,
                              child: const Text(
                                "No",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
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
                const SizedBox(height: 16.0),
              ],
            )),
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

//remember that you can do the following to close this menu, should also be a exit option if you don't wanna post
//Navigator.pop(context);