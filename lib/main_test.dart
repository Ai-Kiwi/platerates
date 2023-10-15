import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';

import 'main.dart' as mainFile;

void main() {
  FlavorConfig(
    name: "TESTING",
    color: Colors.orange,
    location: BannerLocation.topStart,
    variables: {
      "release": "test",
    },
  );
  mainFile.main();
}
