import 'dart:convert';
import 'package:flutter/services.dart';

class LocalizationService {
  static Map<String, String>? _localizedStrings;

  // Loads the JSON file from the assets/lang folder
  static Future<void> load(String languageCode) async {
    String jsonString = 
        await rootBundle.loadString('assets/lang/$languageCode.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
  }

  // Translates a key (e.g., 'welcome_msg') into the selected language
  static String translate(String key) {
    return _localizedStrings?[key] ?? key;
  }
}