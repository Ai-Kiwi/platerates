import 'dart:convert';
import 'dart:io';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/imageUtils.dart';
import 'package:PlateRates/libs/loadScreen.dart';
import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
//import 'package:toggle_switch/toggle_switch.dart';

import '../libs/errorHandler.dart';
import '../main.dart';
import '../login/userLogin.dart';

class CreatePostPage extends StatefulWidget {
  final List<dynamic> imagesData;

  CreatePostPage({
    required this.imagesData,
  });

  @override
  _CreatePostState createState() => _CreatePostState(imagesData: imagesData);
}

class _CreatePostState extends State<CreatePostPage> {
  final List<dynamic> imagesData;
  late Uint8List convertedImageData;
  String _title = '';
  String _description = '';
  int shareModeSelected = 0;
  List<String> postCodeNames = ['public', 'friends'];
  List<String> postNamings = ['public post', 'friend\'s only post'];
  final PageController _pageController = PageController();
  int currentPage = 0;
  bool uploadingPost = false;

  _CreatePostState({required this.imagesData});

  @override
  Widget build(BuildContext context) {
    if (uploadingPost == true) {
      return LoadingScreen(plateRatesLogo: false);
    }
    return Scaffold(
        body: PageBackButton(
      warnDiscardChanges: false,
      active: true,
      child: Center(
          child: ListView(
        children: [
          const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
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
            // image
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(16.0)),
              child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.horizontal,
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Disable user scrolling
                        itemCount: imagesData.length,

                        itemBuilder: (context, index) {
                          return Image.memory(
                            Uint8List.fromList(imagesData[index]),
                            fit: BoxFit.cover,
                          );
                        },
                        onPageChanged: (page) {
                          setState(() {
                            currentPage = page;
                          });
                        },
                      ),
                      Visibility(
                        visible: imagesData.length > 1,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 9.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Color.fromARGB(200, 50, 50, 50),
                              ),
                              width: 50,
                              height: 25,
                              child: Center(
                                child: Text(
                                  '${currentPage + 1}/${imagesData.length}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
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
                decoration: InputDecoration(
                  counterText: "",
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white),
                  contentPadding: EdgeInsets.all(8.0),
                  prefixIcon: Icon(
                    Icons.text_fields,
                    color: Theme.of(context).primaryColor,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
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
                decoration: InputDecoration(
                  counterText: "",
                  labelText: 'description',
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  contentPadding: const EdgeInsets.all(16.0),
                  prefixIcon: Icon(
                    Icons.description,
                    color: Theme.of(context).primaryColor,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
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
                  openAlert(
                      "yes_or_no",
                      "Are you sure you want to post this?",
                      null,
                      context,
                      {
                        "no": () {
                          Navigator.pop(context);
                        },
                        "yes": () async {
                          Navigator.pop(context);
                          try {
                            setState(() {
                              uploadingPost = true;
                            });

                            var imagesUploading = [];
                            for (var i = 0; i < imagesData.length; i++) {
                              // TO DO
                              imagesUploading.add(base64Encode(imagesData[i]));
                            }

                            final response = await http.post(
                              Uri.parse("$serverDomain/post/upload"),
                              headers: <String, String>{
                                'Content-Type':
                                    'application/json; charset=UTF-8',
                                HttpHeaders.authorizationHeader:
                                    userManager.token,
                              },
                              body: jsonEncode({
                                "title": _title,
                                "description": _description,
                                "share_mode": postCodeNames[shareModeSelected],
                                "images": imagesUploading,
                                //"image": base64Encode(
                                //    imageUtils.uintListToBytes(imagesData)),
                              }),
                            );
                            setState(() {
                              uploadingPost = false;
                            });

                            if (response.statusCode == 201) {
                              // ignore: use_build_context_synchronously
                              openAlert("success", "created post", null,
                                  context, null, null);
                            } else {
                              ErrorHandler.httpError(
                                  response.statusCode, response.body, context);
                              openAlert("error", "error uploading post",
                                  response.body, context, null, null);
                            }
                          } on Exception catch (error, stackTrace) {
                            setState(() {
                              uploadingPost = false;
                            });
                            FirebaseCrashlytics.instance
                                .recordError(error, stackTrace);
                            openAlert("error", "unkown error contacting serer",
                                null, context, null, null);
                          }
                        },
                      },
                      null);
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
    ));
  }
}

//remember that you can do the following to close this menu, should also be a exit option if you don't wanna post
//Navigator.pop(context);