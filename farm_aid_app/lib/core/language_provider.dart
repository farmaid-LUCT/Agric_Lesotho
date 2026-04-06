// lib/core/language_provider.dart
import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;
  bool get isSesotho => _currentLocale.languageCode == 'st';

  void toggleLanguage() {
    _currentLocale = isSesotho ? const Locale('en') : const Locale('st');
    notifyListeners(); // This refreshes EVERY screen in the app
  }
}
