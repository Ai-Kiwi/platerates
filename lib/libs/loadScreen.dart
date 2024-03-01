import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class LoadingScreen extends StatelessWidget {
  final bool plateRatesLogo;

  LoadingScreen({required this.plateRatesLogo});

  @override
  Widget build(BuildContext context) {
    if (plateRatesLogo) {
      return Scaffold(
          body: SafeArea(
              child: Stack(children: [
        const Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "PlateRates",
              style: TextStyle(color: Colors.white, fontSize: 40),
            ),
          ),
          SizedBox(height: 16),
          CircularProgressIndicator(),
        ])),
        Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Linkify(
                text: "contact support at support@platerates.com",
                onOpen: (link) async {
                  if (!await launchUrl(Uri.parse(link.url))) {
                    throw Exception('Could not launch ${link.url}');
                  }
                },
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            )),
      ])));
    } else {
      return const Scaffold(
          body: Center(
        child: CircularProgressIndicator(),
      ));
    }
  }
}
