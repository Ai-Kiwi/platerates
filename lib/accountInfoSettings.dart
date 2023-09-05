import 'dart:convert';
import 'dart:typed_data';

import 'package:Toaster/libs/userAvatar.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import 'libs/dataCollect.dart';
import 'libs/errorHandler.dart';
import 'libs/imageUtils.dart';
import 'login/userLogin.dart';
import 'main.dart';
import 'package:image/image.dart' as img;

class AccountInfoSettings extends StatefulWidget {
  const AccountInfoSettings({super.key});

  @override
  State<AccountInfoSettings> createState() => _AccountInfoSettingsState();
}

class _AccountInfoSettingsState extends State<AccountInfoSettings> {
  String _username = '';
  String _startUsername = '';
  String _bio = '';
  String _startBio = '';
  bool _loading = true;
  Uint8List? newUserImage;

  late String _realUserId;

  Future<void> _fetchAccountData() async {
    await dataCollect.updateUserData(null, context);
    var fetchedData = await dataCollect.getUserData(null, context);
    setState(() {
      _bio = fetchedData['bio'];
      _startBio = fetchedData['bio'];

      _username = fetchedData['username'];
      _startUsername = fetchedData['username'];

      _realUserId = fetchedData['userId'];

      _loading = false;
    });
    return;
  }

  Future<void> _changeSetting(String setting, String value) async {
    final response = await http.post(
      Uri.parse("$serverDomain/profile/settings/change"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': userManager.token,
        "setting": setting,
        "value": value,
      }),
    );
    if (response.statusCode == 200) {
      return;
    } else {
      ErrorHandler.httpError(response.statusCode, response.body, context);
      // ignore: use_build_context_synchronously
      Alert(
        context: context,
        type: AlertType.error,
        title: "bio change failed",
        desc: response.body,
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            width: 120,
            child: const Text(
              "ok",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ],
      ).show();
      return;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchAccountData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading == true) {
      return const Scaffold(
          backgroundColor: Color.fromRGBO(16, 16, 16, 1),
          body: Center(
            child: CircularProgressIndicator(),
          ));
    }
    return Scaffold(
        backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
        body: SafeArea(
            child: Stack(alignment: Alignment.topLeft, children: <Widget>[
          Center(
              //make sure on pc it's not to wide
              child: Container(
                  width: 650,
                  child: Center(
                      child: AutofillGroup(
                          child: ListView(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.symmetric(vertical: 48.0),
                          child: Center(
                              child: UserAvatar(
                            avatarImage: newUserImage,
                            size: 200,
                            roundness: 200,
                            userId: _realUserId,
                            onTap: () async {
                              const XTypeGroup typeGroup = XTypeGroup(
                                label: 'images',
                                extensions: <String>['jpg', 'png'],
                              );

                              XFile? file = await openFile(
                                  acceptedTypeGroups: <XTypeGroup>[typeGroup]);

                              final List<int>? tempNewUserImage =
                                  await imageUtils
                                      .resizePhoto(await file?.readAsBytes());

                              setState(() {
                                if (tempNewUserImage != null) {
                                  newUserImage =
                                      Uint8List.fromList(tempNewUserImage!);
                                }
                              });
                            },
                          ))),
                      //const Divider(
                      //  color: Color.fromARGB(255, 110, 110, 110),
                      //  thickness: 1.0,
                      //),
                      const SizedBox(height: 8.0),
                      Padding(
                        //email input feild
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          onChanged: (value) {
                            setState(() {
                              _username = value;
                            });
                          },
                          initialValue: _username,
                          autofillHints: const [AutofillHints.email],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          decoration: InputDecoration(
                            labelText: 'username',
                            labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 200, 200, 200)),
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
                                _bio = value;
                              });
                            },
                            initialValue: _bio,
                            autofillHints: const [AutofillHints.password],
                            maxLines: 5,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                            decoration: InputDecoration(
                              labelText: 'bio',
                              labelStyle: const TextStyle(
                                  color: Color.fromARGB(255, 200, 200, 200)),
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
                      const SizedBox(height: 16.0),
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
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                  'saving info...',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ));

                              if (newUserImage != null) {
                                Alert(
                                  context: context,
                                  type: AlertType.error,
                                  title: "user profile changing not added yet",
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
                              if (_username != _startUsername) {
                                await _changeSetting("username", _username);
                              }
                              if (_bio != _startBio) {
                                await _changeSetting("bio", _bio);
                              }
                              // ignore: use_build_context_synchronously
                              Alert(
                                context: context,
                                type: AlertType.success,
                                title: "account info changed",
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
                            },
                            child: const Text(
                              'change info',
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ))))),
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
        ])));
  }
}
