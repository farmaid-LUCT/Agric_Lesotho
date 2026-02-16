import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _appLocale = const Locale('en');

  Locale get appLocale => _appLocale;

  // Called in main.dart to set the initial language from disk
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String langCode = prefs.getString('language_code') ?? 'en';
    _appLocale = Locale(langCode);
    notifyListeners();
  }

  // Called from SettingsScreen when a farmer toggles the language
  Future<void> changeLanguage(Locale type) async {
    if (_appLocale == type) return;

    final prefs = await SharedPreferences.getInstance();
    _appLocale = type;
    
    // Persist choice locally
    await prefs.setString('language_code', type.languageCode);
    
    notifyListeners(); // This triggers the MaterialApp rebuild in main.dart
  }
}