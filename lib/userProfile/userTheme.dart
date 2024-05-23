import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/usefullWidgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';

class UserThemeSettings extends StatefulWidget {
  @override
  _UserThemeSettingsState createState() => _UserThemeSettingsState();
}

class _UserThemeSettingsState extends State<UserThemeSettings> {
  //_UserSettingsState({});
  var colorCodesAsList = primaryColorCodes.keys.map((String colorName) {
    return colorName;
  }).toList();

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
                    "Theme",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ))),
              const Divider(
                color: Color.fromARGB(255, 110, 110, 110),
                thickness: 1.0,
              ),
              const SizedBox(height: 16),
              const Center(
                  child: Text("Primary color",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                      ))),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 500,
                  child: GridView.builder(
                    itemCount: primaryColorCodes.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                          onTap: () {
                            print(
                                "Are you sure you would like to change your color?");
                            openAlert(
                                "yes_or_no",
                                "are you sure you want to change you primary color?",
                                null,
                                context,
                                {
                                  "yes": () async {
                                    var sharedPrefs =
                                        await SharedPreferences.getInstance();
                                    await sharedPrefs.setString('primaryColor',
                                        colorCodesAsList[index]);
                                    primaryColor = primaryColorCodes[
                                        colorCodesAsList[index]]!;
                                    Phoenix.rebirth(context);
                                  },
                                  "no": () {
                                    Navigator.pop(context);
                                  },
                                },
                                null);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.transparent, width: 2),
                              shape: BoxShape.circle,
                              color: primaryColorCodes[colorCodesAsList[index]],
                            ),
                            width: 15,
                            height: 15,
                            margin: EdgeInsets.all(4.0),
                          ));
                    },
                  ),
                ),
              ),

              //launch();

              //const Expanded(child: Center()),
            ],
          )),
    ));
  }
}
