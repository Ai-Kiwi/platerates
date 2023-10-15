import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';

import 'main.dart' as mainFile;

void main() {
  FlavorConfig(
    name: "DEV",
    color: Colors.red,
    location: BannerLocation.topStart,
    variables: {
      "release": "dev",
    },
  );
  mainFile.main();
}
