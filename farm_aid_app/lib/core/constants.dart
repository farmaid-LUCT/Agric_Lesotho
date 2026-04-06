
// typedef AppConstants = Constants;

// class Constants {
//   // --------------------------------------------------------
//   // BASE URLs
//   // --------------------------------------------------------
//   static const String baseUrl        = "https://farmaid-backend.onrender.com/api";
//   static const String apiBaseUrl     = baseUrl;
//   static const String adminPortalUrl = "https://farmaid-backend.onrender.com/admin/";

//   // --------------------------------------------------------
//   // AUTHENTICATION
//   // --------------------------------------------------------
//   static const String registerUrl         = "$baseUrl/register/";
//   static const String loginUrl            = "$baseUrl/login/";
//   static const String resendActivationUrl = "$baseUrl/resend-activation/";
//   static const String changePasswordUrl   = "$baseUrl/auth/change-password/";
//   static const String googleAuthUrl       = "$baseUrl/auth/google/";

//   // --------------------------------------------------------
//   // PROFILE & SETTINGS
//   // --------------------------------------------------------
//   static const String profileUrl       = "$baseUrl/auth/profile/";
//   static const String profileUpdateUrl = "$baseUrl/auth/profile/update/";

//   // --------------------------------------------------------
//   // WEATHER & REGIONAL DATA
//   // --------------------------------------------------------
//   static const String weatherUrl = "$baseUrl/weather/latest/";

//   // --------------------------------------------------------
//   // ALERTS & NOTIFICATIONS
//   // --------------------------------------------------------
//   static const String alertsUrl         = "$baseUrl/alerts/";
//   static const String markAlertsReadUrl = "$baseUrl/alerts/mark-read/";
//   static const String unreadCountUrl    = "$baseUrl/alerts/unread-count/";

//   // --------------------------------------------------------
//   // CROP PROFILES
//   // --------------------------------------------------------
//   static const String cropProfileUrl = "$baseUrl/crop-profiles/";

//   // --------------------------------------------------------
//   // AI SCAN
//   // --------------------------------------------------------
//   static const String saveScanUrl = "$baseUrl/save-scan/";
//   static const String saveScan    = saveScanUrl;

//   // --------------------------------------------------------
//   // DIAGNOSIS FEEDBACK
//   // --------------------------------------------------------
//   static String diagnosisFeedbackUrl(int diagnosisId) =>
//       "$baseUrl/diagnosis/$diagnosisId/feedback/";

//   // --------------------------------------------------------
//   // HISTORY & REPORTS
//   // --------------------------------------------------------
//   static const String farmerHistory = "$baseUrl/farmer-history/";
//   static const String farmerReports = "$baseUrl/farmer-reports/";

//   // --------------------------------------------------------
//   // FARMER INSIGHTS (Analytics) — used by AnalyticsScreen
//   // --------------------------------------------------------
//   static const String farmerInsightUrl = "$baseUrl/farmer-insight/";

//   // --------------------------------------------------------
//   // GROWTH JOURNAL
//   // --------------------------------------------------------
//   static const String journalUrl = "$baseUrl/journal/";
//   static String journalDeleteUrl(int entryId) =>
//       "$baseUrl/journal/$entryId/delete/";

//   // --------------------------------------------------------
//   // MARKET PRICES
//   // --------------------------------------------------------
//   static const String marketPricesUrl = "$baseUrl/market-prices/";

//   // --------------------------------------------------------
//   // LOCAL STORAGE KEYS
//   // --------------------------------------------------------
//   static const String tokenKey      = "auth_token";
//   static const String userDataKey   = "user_data";
//   static const String languageKey   = "selected_language";
//   static const String isAdminKey    = "is_admin";
//   static const String farmerNameKey = "farmer_name";

//   // Cache keys
//   static const String insightCacheKey = "farmer_insight_cache";
//   static const String profileCacheKey = "farmer_profile_cache";
//   static const String weatherCacheKey = "weather_cache";
// }

typedef AppConstants = Constants;

class Constants {
  // --------------------------------------------------------
  // BASE URLs
  // --------------------------------------------------------
  static const String baseUrl        = "https://farmaid-backend.onrender.com/api";
  static const String apiBaseUrl     = baseUrl;
  static const String adminPortalUrl = "https://farmaid-backend.onrender.com/admin/";

  // --------------------------------------------------------
  // AUTHENTICATION
  // --------------------------------------------------------
  static const String registerUrl         = "$baseUrl/register/";
  static const String loginUrl            = "$baseUrl/login/";
  static const String resendActivationUrl = "$baseUrl/resend-activation/";
  static const String changePasswordUrl   = "$baseUrl/auth/change-password/";
  static const String googleAuthUrl       = "$baseUrl/auth/google/";
  
  // --- ADDED THIS LINE TO FIX THE ERROR ---
  static const String passwordResetUrl    = "$baseUrl/auth/password-reset/";

  // --------------------------------------------------------
  // PROFILE & SETTINGS
  // --------------------------------------------------------
  static const String profileUrl       = "$baseUrl/auth/profile/";
  static const String profileUpdateUrl = "$baseUrl/auth/profile/update/";

  // --------------------------------------------------------
  // WEATHER & REGIONAL DATA
  // --------------------------------------------------------
  static const String weatherUrl = "$baseUrl/weather/latest/";

  // --------------------------------------------------------
  // ALERTS & NOTIFICATIONS
  // --------------------------------------------------------
  static const String alertsUrl         = "$baseUrl/alerts/";
  static const String markAlertsReadUrl = "$baseUrl/alerts/mark-read/";
  static const String unreadCountUrl    = "$baseUrl/alerts/unread-count/";

  // --------------------------------------------------------
  // CROP PROFILES
  // --------------------------------------------------------
  static const String cropProfileUrl = "$baseUrl/crop-profiles/";

  // --------------------------------------------------------
  // AI SCAN
  // --------------------------------------------------------
  static const String saveScanUrl = "$baseUrl/save-scan/";
  static const String saveScan    = saveScanUrl;

  // --------------------------------------------------------
  // DIAGNOSIS FEEDBACK
  // --------------------------------------------------------
  static String diagnosisFeedbackUrl(int diagnosisId) =>
      "$baseUrl/diagnosis/$diagnosisId/feedback/";

  // --------------------------------------------------------
  // HISTORY & REPORTS
  // --------------------------------------------------------
  static const String farmerHistory = "$baseUrl/farmer-history/";
  static const String farmerReports = "$baseUrl/farmer-reports/";

  // --------------------------------------------------------
  // FARMER INSIGHTS (Analytics)
  // --------------------------------------------------------
  static const String farmerInsightUrl = "$baseUrl/farmer-insight/";

  // --------------------------------------------------------
  // GROWTH JOURNAL
  // --------------------------------------------------------
  static const String journalUrl = "$baseUrl/journal/";
  static String journalDeleteUrl(int entryId) =>
      "$baseUrl/journal/$entryId/delete/";

  // --------------------------------------------------------
  // MARKET PRICES
  // --------------------------------------------------------
  static const String marketPricesUrl = "$baseUrl/market-prices/";

  // --------------------------------------------------------
  // LOCAL STORAGE KEYS
  // --------------------------------------------------------
  static const String tokenKey      = "auth_token";
  static const String userDataKey   = "user_data";
  static const String languageKey   = "selected_language";
  static const String isAdminKey    = "is_admin";
  static const String farmerNameKey = "farmer_name";

  // Cache keys
  static const String insightCacheKey = "farmer_insight_cache";
  static const String profileCacheKey = "farmer_profile_cache";
  static const String weatherCacheKey = "weather_cache";
}
