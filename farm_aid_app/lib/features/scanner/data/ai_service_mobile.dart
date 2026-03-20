import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http; 

import 'package:farm_aid_app/core/constants.dart';
import 'package:farm_aid_app/services/auth_service.dart';

class AIService {
  static Interpreter? _interpreter;
  static List<String>? _labels;
  final AuthService _auth = AuthService();

  static Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/farm_aid_model.tflite');
      final labelsString = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsString.split('\n').where((s) => s.isNotEmpty).toList();
      print("🧠 Mobile AI: TFLite Hardware Acceleration Ready");
    } catch (e) {
      print("❌ Mobile AI Load Error: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchTreatmentAndSave({
    required String rawLabel,
    required String imageUrl,
    required double confidence,
    required String languageCode,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}/save-scan/"), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'diseaseName': rawLabel,
          'imageUrl': imageUrl,
          'confidence': confidence,
          'language': languageCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results']; 
      } else {
        print("⚠️ Server Error in SaveScan: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception fetching treatment: $e");
      return null;
    }
  }

  Future<void> syncScanHistory() async {
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception("No Auth Token found");

      final response = await http.get(
        Uri.parse(AppConstants.farmerReports), 
        headers: {"Authorization": "Token $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("✅ Mobile Sync Success: ${data.length} records fetched.");
      } else {
        print("⚠️ Server Error: ${response.statusCode} at ${AppConstants.farmerReports}");
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Sync Error: $e");
      rethrow;
    }
  }

  // ✅ 4. Updated Main Entry Point (Local Inference)
  static Future<Map<String, dynamic>> runInference(Uint8List imageBytes) async {
    if (_interpreter == null) await loadModel();

    final String jsonResult = await compute(_processLocalInference, {
      'bytes': imageBytes,
      'labels': _labels,
      'interpreterAddress': _interpreter!.address,
    });

    final Map<String, dynamic> decoded = jsonDecode(jsonResult);
    final String label = decoded['label'];
    final double confidence = decoded['score'];

    bool isRejected = label.toLowerCase().contains("background") || 
                      label.toLowerCase().contains("rejected") ||
                      label.toLowerCase().contains("unknown");

    return {
      "label": isRejected ? "Rejected: This is not a vegetable." : label,
      "confidence": confidence, 
      "isRejected": isRejected,
    };
  }

  // ✅ 5. Updated Background Processing (Isolate)
  static String _processLocalInference(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final List<String> labels = params['labels'];
    final int address = params['interpreterAddress'];

    final interpreter = Interpreter.fromAddress(address);

    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return jsonEncode({"label": "Invalid", "score": 0.0});

    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

    var input = List.generate(1, (index) => List.generate(224, (y) => List.generate(224, (x) {
      final pixel = resizedImage.getPixel(x, y);
      return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
    })));

    var output = List.filled(1 * labels.length, 0.0).reshape([1, labels.length]);
    interpreter.run(input, output);

    double maxScore = -1.0;
    int bestIndex = 0;
    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > maxScore) {
        maxScore = output[0][i];
        bestIndex = i;
      }
    }

    return jsonEncode({
      "label": labels[bestIndex].trim(),
      "score": maxScore
    });
  }
}
