import 'dart:convert';

import 'package:Toaster/libs/alertSystem.dart';
import 'package:Toaster/libs/userAvatar.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../libs/dataCollect.dart';
import '../libs/errorHandler.dart';
import '../libs/imageUtils.dart';
import '../login/userLogin.dart';
import '../main.dart';

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
  bool _savingData = false;
  List<int>? _userImage;
  List<int>? _startUserImage;
  String _realUserId = '';

  //late String _realUserId;

  Future<void> _fetchAccountData() async {
    await dataCollect.updateUserData(null, context, false);
    var fetchedData = await dataCollect.getUserData(null, context, false);

    Map avatarData =
        await dataCollect.getAvatarData(fetchedData["avatar"], context, false);

    setState(() {
      _bio = fetchedData['bio'];
      _startBio = fetchedData['bio'];

      _username = fetchedData['username'];
      _startUsername = fetchedData['username'];

      _realUserId = fetchedData['userId'];

      _loading = false;

      if (avatarData["imageData"] != null) {
        _userImage = base64Decode(avatarData["imageData"]);
        _startUserImage = _userImage;
      }
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
      openAlert("error", "failed to change setting $setting", response.body,
          context, null);
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
          body: Center(
        child: CircularProgressIndicator(),
      ));
    }
    return Scaffold(
        body: SafeArea(
            child: Stack(alignment: Alignment.topLeft, children: <Widget>[
      Center(
          //make sure on pc it's not to wide
          child: SizedBox(
              width: 650,
              child: Center(
                  child: AutofillGroup(
                      child: ListView(
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Center(
                        child: SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              children: [
                                UserAvatar(
                                  avatarImage: _userImage,
                                  size: 200,
                                  roundness: 200,
                                  customFunction: () async {
                                    const XTypeGroup typeGroup = XTypeGroup(
                                      label: 'images',
                                      extensions: <String>['jpg', 'png'],
                                    );

                                    XFile? file = await openFile(
                                        acceptedTypeGroups: <XTypeGroup>[
                                          typeGroup
                                        ]);
                                    if (file != null) {
                                      final List<int>? tempNewUserImage =
                                          await imageUtils.resizePhoto(
                                              await file?.readAsBytes());

                                      setState(() {
                                        if (tempNewUserImage != null) {
                                          _userImage = tempNewUserImage;
                                        }
                                      });
                                    }
                                  },
                                  onTapFunction: 'customFunction',
                                  context: context,
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 16.0),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.grey[800],
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 20, // Adjust the size of the icon
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )),
                      )),
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
                        _username = value;
                      },
                      initialValue: _username,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: const InputDecoration(
                        labelText: 'username',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(255, 200, 200, 200)),
                        contentPadding: const EdgeInsets.all(8.0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextFormField(
                      onChanged: (value) {
                        _bio = value;
                      },
                      initialValue: _bio,
                      autofillHints: const [AutofillHints.password],
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: const InputDecoration(
                        labelText: 'bio',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(255, 200, 200, 200)),
                        contentPadding: const EdgeInsets.all(8.0),
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
                    //login button
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: _savingData
                            ? ElevatedButton(
                                style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                )),
                                onPressed: () async {},
                                child: const Center(
                                    child: CircularProgressIndicator(
                                  color: Colors.white,
                                )))
                            : ElevatedButton(
                                style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                )),
                                onPressed: () async {
                                  setState(() {
                                    _savingData = true;
                                  });

                                  if (_userImage != _startUserImage) {
                                    print("changing user image");
                                    await _changeSetting(
                                        "avatar",
                                        base64Encode(imageUtils.uintListToBytes(
                                            Uint8List.fromList(_userImage!))));
                                  }
                                  if (_username != _startUsername) {
                                    print("changing username");
                                    await _changeSetting("username", _username);
                                  }
                                  if (_bio != _startBio) {
                                    print("changing user bio");
                                    await _changeSetting("bio", _bio);
                                  }
                                  await dataCollect
                                      .clearCacheForItem('basicUserData-null');
                                  await dataCollect
                                      .clearCacheForItem('userData-null');
                                  await dataCollect.clearCacheForItem(
                                      'basicUserData-$_realUserId');
                                  await dataCollect.clearCacheForItem(
                                      'userData-$_realUserId');

                                  // ignore: use_build_context_synchronously
                                  openAlert("success", "changed settings", null,
                                      context, null);
                                  setState(() {
                                    _savingData = false;
                                  });
                                },
                                child: const Text(
                                  'change info',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              )),
                  ),
                ],
              ))))),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              openAlert(
                  "yes_or_no",
                  "Discard changes",
                  "Any unsaved changes will be discarded.\nAre you sure you want to continue?",
                  context, {
                "no": () {
                  Navigator.pop(context);
                },
                "yes": () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              });
            },
          ))
    ])));
  }
}
