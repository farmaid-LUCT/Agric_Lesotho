// lib/services/translation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  final String _apiUrl = "https://translate.terraprint.co/translate";

  Future<String> getTranslation(String text, String targetLang) async {
    if (targetLang == 'en') return text; // Already in English

    // 1. TODO: Check Neon Database Cache first
    // String? cached = await checkDatabase(text);
    // if (cached != null) return cached;

    // 2. If not cached, call LibreTranslate
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "q": text,
          "source": "en",
          "target": targetLang,
          "format": "text"
        }),
      );

      if (response.statusCode == 200) {
        String result = jsonDecode(response.body)['translatedText'];
        // 3. TODO: Save to Neon Database here for next time
        return result;
      }
    } catch (e) {
      debugPrint("Translation API failed: $e");
    }
    return text; // Fallback to English
  }
}