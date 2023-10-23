import 'package:Toaster/accountInfoSettings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../libs/smoothTransitions.dart';
import '../login/userResetPassword.dart';

class UserSettings extends StatefulWidget {
  const UserSettings({super.key});

  //UserSettings({});

  @override
  _UserSettingsState createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  //_UserSettingsState({});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromRGBO(16, 16, 16, 1),
        body: Stack(alignment: Alignment.topLeft, children: <Widget>[
          SafeArea(
              top: false,
              child: ListView(
                children: [
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                          child: Text(
                        "Settings",
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      ))),
                  const Divider(
                    color: Color.fromARGB(255, 110, 110, 110),
                    thickness: 1.0,
                  ),
                  SettingItem(
                    settingIcon: Icons.person,
                    settingName: "account info",
                    ontap: () {
                      Navigator.of(context).push(smoothTransitions
                          .slideRight(const AccountInfoSettings()));
                    },
                  ),
                  SettingItem(
                    settingIcon: Icons.lock,
                    settingName: "password",
                    ontap: () {
                      Navigator.of(context).push(
                          smoothTransitions.slideRight(ResetPasswordPage()));
                    },
                  ),
                  SettingItem(
                    settingIcon: Icons.book,
                    settingName: "change log",
                    ontap: () {
                      launchUrl(Uri.parse("$serverDomain/changeLog"));
                    },
                  ),
                  SettingItem(
                    settingIcon: Icons.lock,
                    settingName: "privacy policy",
                    ontap: () {
                      launchUrl(Uri.parse("$serverDomain/privacyPolicy"));
                    },
                  ),
                  SettingItem(
                    settingIcon: Icons.rule,
                    settingName: "Community guidelines",
                    ontap: () {
                      launchUrl(Uri.parse("$serverDomain/CommunityGuidelines"));
                    },
                  ),
                  SettingItem(
                    settingIcon: Icons.hardware,
                    settingName: "terms of service",
                    ontap: () {
                      launchUrl(Uri.parse("$serverDomain/termsOfService"));
                    },
                  ),
                  SettingItem(
                    settingIcon: Icons.help,
                    settingName: "contact support",
                    ontap: () {
                      launchUrl(Uri.parse("mailto:toaster@aikiwi.dev"));
                    },
                  ),
                  SettingItem(
                    settingIcon: Icons.info,
                    settingName: "licenses",
                    ontap: () {
                      Navigator.of(context).push(
                          smoothTransitions.slideRight(const LicensePage()));
                    },
                  ),

                  //launch();

                  //const Expanded(child: Center()),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                    child: Center(
                        child: Text("version $version build $buildNumber",
                            style: const TextStyle(
                              color: Colors.white,
                            ))),
                  ),
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
        ]));
  }
}

class SettingItem extends StatelessWidget {
  final String settingName;
  final settingIcon;
  final ontap;

  const SettingItem(
      {super.key,
      required this.settingIcon,
      required this.settingName,
      required this.ontap});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: InkWell(
          //change username
          onTap: ontap,
          child: Container(
            width: double.infinity,
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AspectRatio(
                    aspectRatio: 1,
                    child: Center(
                        child: Icon(
                      settingIcon,
                      color: Colors.white,
                      size: 30,
                    ))),
                Expanded(
                    child: Text(settingName,
                        style: const TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                        ))),
                const AspectRatio(
                    aspectRatio: 1,
                    child: Center(
                        child: Icon(
                      Icons.arrow_right_rounded,
                      color: Colors.white60,
                      size: 35,
                    ))),
              ],
            ),
          ),
        ));
  }
}
