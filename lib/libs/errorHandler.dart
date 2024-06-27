import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:PlateRates/login/userLogin.dart';
import 'package:PlateRates/main.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class errorHandlerClass {
  Future<void> httpError(errorCode, errorMessage, context) async {
    print("http error : $errorMessage code $errorCode");
    if (errorMessage == "invalid token" || errorMessage == "Not logged in") {
      final response = await http.post(
        Uri.parse("$serverDomain/login/logout"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          HttpHeaders.authorizationHeader: userManager.token
        },
        body: jsonEncode(<String, String>{}),
      );
      Phoenix.rebirth(context);
    } else if (errorMessage == "not accepted licenses") {
      acceptedAllLicenses = false;
      Phoenix.rebirth(context);
    } else if (errorMessage == "account banned") {
      accountBanned = true;
      Phoenix.rebirth(context);
    }
  }
}

errorHandlerClass ErrorHandler = errorHandlerClass();
