import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:PlateRates/userProfile/aboutApp.dart';
import 'package:PlateRates/userProfile/accountInfoSettings.dart';
import 'package:PlateRates/userProfile/experimentalUserSettings.dart';
import 'package:PlateRates/userProfile/userTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../libs/smoothTransitions.dart';
import '../login/userResetPassword.dart';

class UserSettings extends StatelessWidget {
  //_UserSettingsState({});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageBackButton(
      warnDiscardChanges: false,
      active: true,
      child: SafeArea(
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
                      smoothTransitions.slideRight(const ResetPasswordPage()));
                },
              ),
              SettingItem(
                settingIcon: Icons.palette,
                settingName: "theme",
                ontap: () {
                  Navigator.of(context)
                      .push(smoothTransitions.slideRight(UserThemeSettings()));
                },
              ),
              SettingItem(
                settingIcon: Icons.biotech,
                settingName: "experimental",
                ontap: () {
                  Navigator.of(context).push(
                      smoothTransitions.slideRight(ExperimentalUserSettings()));
                },
              ),
              SettingItem(
                settingIcon: Icons.question_mark,
                settingName: "about app",
                ontap: () {
                  Navigator.of(context)
                      .push(smoothTransitions.slideRight(AboutAppPage()));
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
    ));
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
