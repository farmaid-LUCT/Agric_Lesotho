// lib/features/scanner/data/ai_service_web.dart
//
// On web (Chrome), TFLite WASM cannot run reliably due to:
//   - SharedArrayBuffer CORS restrictions
//   - _malloc errors from incomplete WASM initialisation
//   - Browser security policies blocking WASM memory
//
// Solution: Send the image to the Django backend for server-side
// inference. The backend already runs the model natively (Python/TFLite).


// lib/features/scanner/data/ai_service_web.dart
//
// On web (Chrome), TFLite WASM cannot run reliably due to:
//   - SharedArrayBuffer CORS restrictions
//   - _malloc errors from incomplete WASM initialisation
//   - Browser security policies blocking WASM memory
//
// Solution: Send the image to the Django backend for server-side
// inference. The backend already runs the model natively (Python/TFLite).

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:farm_aid_app/core/constants.dart';
import 'package:farm_aid_app/services/auth_service.dart';

class AIService {
  final AuthService _auth = AuthService();

  // ── No-op on web — model runs server-side ─────────────────────
  static Future<void> loadModel() async {
    print('🌐 Web mode: server-side inference active');
  }

  // ── Sync scan history ─────────────────────────────────────────
  Future<void> syncScanHistory() async {
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('No auth token');

      final response = await http.get(
        Uri.parse(AppConstants.farmerReports),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Sync: ${data.length} records');
      } else {
        print('⚠️ Sync error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Sync Error: $e');
    }
  }

  // ── Main inference — sends image to Django backend ────────────
  static Future<Map<String, dynamic>> runInference(Uint8List imageBytes) async {
    try {
      final auth  = AuthService();
      final token = await auth.getToken();

      // POST multipart image to /api/scan-image/
      // Your Django view receives 'image' file field and returns JSON:
      // { "label": "Tomato_Leaf_Blight", "confidence": 0.93, "is_rejected": false }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/scan-image/'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'scan.jpg',
      ));

      final streamed = await request.send()
          .timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final String label = (data['label'] ??
                              data['diagnosis'] ??
                              data['result'] ?? 'Unknown').toString();
        final double confidence =
            double.tryParse(data['confidence']?.toString() ?? '0.9') ?? 0.9;
        final bool isRejected =
            data['is_rejected'] == true ||
            label.toLowerCase().contains('not a vegetable') ||
            label.toLowerCase().contains('background') ||
            label.toLowerCase().contains('rejected');

        print('🌐 Server: $label @ ${(confidence * 100).toStringAsFixed(1)}%');

        return {
          'label':      isRejected
              ? 'Rejected: This is not a vegetable.'
              : label,
          'confidence': confidence,
          'isRejected': isRejected,
        };
      } else {
        print('❌ Server ${response.statusCode}: ${response.body}');
        return _fail('Server error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Web Inference Error: $e');
      final isTimeout = e.toString().contains('TimeoutException') ||
                        e.toString().contains('Future not completed');
      return {
        'label': isTimeout
            ? 'Server is waking up — please wait a moment and try again.'
            : 'Scan failed — check your connection and try again.',
        'confidence': 0.0,
        'isRejected': true,
        'error': e.toString(),
      };
    }
  }

  static Map<String, dynamic> _fail(String reason) => {
    'label':      'Scan failed — check your connection and try again.',
    'confidence': 0.0,
    'isRejected': true,
    'error':      reason,
  };
}