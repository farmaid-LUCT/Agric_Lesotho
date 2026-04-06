import 'package:flutter/material.dart';

class FarmAidTheme {
  static const Color primaryGreen = Color(0xFF2E7D32);

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    // Define text themes here to avoid manual 'textColor' logic
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
  );
}
