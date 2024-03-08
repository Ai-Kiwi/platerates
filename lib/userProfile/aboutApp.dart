import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:PlateRates/userProfile/userSettings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../libs/smoothTransitions.dart';

class AboutAppPage extends StatelessWidget {
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
                    "About",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ))),
              const Divider(
                color: Color.fromARGB(255, 110, 110, 110),
                thickness: 1.0,
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
                  launchUrl(Uri.parse("mailto:support@platerates.com"));
                },
              ),
              SettingItem(
                settingIcon: Icons.info,
                settingName: "licenses",
                ontap: () {
                  Navigator.of(context)
                      .push(smoothTransitions.slideRight(const LicensePage()));
                },
              ),

              //launch();

              //const Expanded(child: Center()),
            ],
          )),
    ));
  }
}
