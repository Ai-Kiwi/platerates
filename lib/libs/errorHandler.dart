import 'package:Toaster/main.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class errorHandlerClass {
  Future<void> httpError(errorCode, errorMessage, context) async {
    print("http error : $errorMessage code $errorCode");
    if (errorMessage == "invalid token") {
      Phoenix.rebirth(context);
    } else if (errorMessage == "not accepted licenses") {
      acceptedAllLicenses = false;
      Phoenix.rebirth(context);
    }
  }
}

errorHandlerClass ErrorHandler = errorHandlerClass();
