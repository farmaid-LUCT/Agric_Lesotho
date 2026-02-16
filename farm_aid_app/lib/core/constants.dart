// // // lib/core/constants.dart

// // class AppConstants {
// //   // 💻 LOCAL TESTING: Use '127.0.0.1' or 'localhost' for Chrome.
// //   // 📱 MOBILE TESTING: Use your IPv4 address (10.120.110.223) for physical devices.
// //   static const String serverIp = "10.120.110.223"; 
// //   static const String baseUrl = "http://$serverIp:8000/api";

// //   // --- API Endpoints ---
// //   static const String registerUrl = "$baseUrl/register/";
// //   static const String loginUrl = "$baseUrl/login/";
// //   static const String saveScanUrl = "$baseUrl/save-scan/"; // Added for your Neon/Django sync

// //   // --- AI Configuration ---
// //   // Fixed: Must be static const to live inside a class
// //   static const String geminiApiKey = 'AIzaSyCh_Kbhuj27lplco77eq5O-tM0rupM2sAA';

// //   // --- Storage Keys ---
// //   static const String tokenKey = "auth_token";
// //   static const String userDataKey = "user_data";
// // }



// class AppConstants {
//   // 💻 LOCAL TESTING: 
//   // - Chrome: 'localhost'
//   // - Android Emulator: '10.0.2.2' 
//   // - Physical Device: Your IPv4 (10.40.151.141)
//   static const String serverIp = "10.40.151.141"; 
//   static const String baseUrl = "http://$serverIp:8000/api";

//   // --- 🔐 AUTH ENDPOINTS ---
//   static const String registerUrl = "$baseUrl/register/";
//   static const String loginUrl = "$baseUrl/login/";

//   // --- ⚠️ ALERTS MODULE (New) ---
//   static const String alertsUrl = "$baseUrl/alerts/";
//   static const String markAlertsReadUrl = "$baseUrl/alerts/mark-read/";

//   // --- 🌦️ WEATHER MODULE ---
//   static const String weatherUrl = "$baseUrl/weather/";

//   // --- 🧪 SCANNER & DATABASE ---
//   static const String saveScanUrl = "$baseUrl/save-scan/";
  
//   // --- 🧠 AI CONFIGURATION ---
//   // Using 'static const' for compile-time optimization
//   static const String geminiApiKey = 'AIzaSyCh_Kbhuj27lplco77eq5O-tM0rupM2sAA';

//   // --- 💾 STORAGE KEYS ---
//   static const String tokenKey = "auth_token";
//   static const String userDataKey = "user_data";
// }


// lib/core/constants.dart 10.11.1.190

class AppConstants {
  static const String serverIp = "10.65.70.167"; 
  
  // ✅ This fixes the 'baseUrl' member not found error
  static const String baseUrl = "http://$serverIp:8000/api";
  
  // ✅ This fixes the 'apiBaseUrl' member not found error
  static const String apiBaseUrl = baseUrl;

  // --- 🔐 AUTH ENDPOINTS ---
  static const String registerUrl = "$baseUrl/register/";
  static const String loginUrl = "$baseUrl/login/";
  static const String profileUrl = "$baseUrl/auth/profile/";
  static const String profileUpdateUrl = "$baseUrl/auth/profile/update/";
  static const String changePasswordUrl = "$baseUrl/auth/password/change/";
  static const String resendActivationUrl = "$baseUrl/resend-activation/";

  // --- ⚠️ ALERTS MODULE ---
  static const String alertsUrl = "$baseUrl/alerts/";
  static const String markAlertsReadUrl = "$baseUrl/alerts/mark-read/";

  // --- 🌦️ WEATHER MODULE ---
  static const String weatherUrl = "$baseUrl/weather/latest/";

  // --- 🧪 SCANNER & DATABASE ---
  static const String saveScanUrl = "$baseUrl/save-scan/";
  static const String farmerReports = "$baseUrl/farmer-reports/";
  static const String farmerHistory = "$baseUrl/farmer-history/";
  static const String cropProfileUrl = "$baseUrl/crop-profiles/";

  // --- 💾 STORAGE KEYS ---
  static const String tokenKey = "auth_token";
  static const String userDataKey = "user_data";
}