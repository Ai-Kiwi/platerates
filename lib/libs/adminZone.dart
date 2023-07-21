import 'package:flutter/material.dart';

class AdminZonePage extends StatefulWidget {
  //UserSettings({});

  @override
  _AdminZonePageState createState() => _AdminZonePageState();
}

class _AdminZonePageState extends State<AdminZonePage> {
  //_UserSettingsState({});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(16, 16, 16, 1),
      body: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: const [
                  Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                      child: Text(
                        "Settings",
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      )),
                  Divider(
                    color: Color.fromARGB(255, 110, 110, 110),
                    thickness: 1.0,
                  ),
                ],
              ))),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String settingName;
  final settingIcon;
  final ontap;

  _SettingItem(
      {super.key,
      required this.settingIcon,
      required this.settingName,
      required this.ontap});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          //change username
          child: Container(
            decoration: BoxDecoration(
                color: const Color.fromARGB(215, 40, 40, 40),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                    color: const Color.fromARGB(215, 45, 45, 45), width: 3)),
            width: double.infinity,
            height: 50,
            child: Row(children: [
              AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                      child: Icon(
                    settingIcon,
                    color: Colors.white,
                    size: 25,
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
            ]),
          ),
          onTap: ontap,
        ));
  }
}
