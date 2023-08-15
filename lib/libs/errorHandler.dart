import 'dart:js';

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class errorHandlerClass {
  Future<void> httpError(errorCode, errorMessage, context) async {
    print(errorMessage);
    if (errorMessage == "invaild token") {
      Phoenix.rebirth(context);
    }
  }
}

errorHandlerClass ErrorHandler = errorHandlerClass();
