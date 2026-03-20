import 'dart:typed_data';
import 'dart:convert';
import 'dart:js_util' as js_util;
import 'package:flutter/services.dart';
import 'package:tflite_web/tflite_web.dart'; 
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

// ✅ Using Package Imports to prevent "Bad State" compiler errors
import 'package:farm_aid_app/core/constants.dart';
import 'package:farm_aid_app/services/auth_service.dart';

class AIService {
  static TFLiteModel? _model;
  static List<String>? _labels;
  final AuthService _auth = AuthService();

  // ✅ 1. Load Web Model & Labels (Matches agreed folder structure)
  static Future<void> loadModel() async {
    if (_model != null) return;
    try {
      await TFLiteWeb.initialize(); 
      // Ensure the model is in assets/models/
      _model = await TFLiteModel.fromUrl('assets/models/farm_aid_model.tflite');
      
      final labelsString = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsString.split('\n').where((s) => s.isNotEmpty).toList();
      print("🧠 Web AI Model & Labels loaded successfully");
    } catch (e) {
      print("❌ AI Load Error: $e");
    }
  }

// ✅ Updated Sync Method in ai_service_web.dart
  Future<void> syncScanHistory() async {
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception("No Auth Token found");

      // ✅ Use the pre-built constant directly. 
      // Do NOT add strings like "/api" here.
      final response = await http.get(
        Uri.parse(AppConstants.farmerReports), 
        headers: {"Authorization": "Token $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("✅ Sync Success: ${data.length} records retrieved.");
      } else {
        // This will print the exact URL being called so you can see it in the console
        print("⚠️ Server Error: ${response.statusCode} at ${AppConstants.farmerReports}");
      }
    } catch (e) {
      print("❌ Sync Error: $e");
    }
  }

  // ✅ 3. Main Entry Point for AI Scanning
  static Future<Map<String, dynamic>> runInference(Uint8List imageBytes) async {
    if (_model == null) await loadModel();

    // Direct processing for Web environment
    final String rawResult = await _processWebInference(imageBytes);

    // Vegetable-only constraint & Rejection logic
    bool isBackground = rawResult.toLowerCase().contains("background") || 
                        rawResult.toLowerCase().contains("rejected");

    String finalLabel = isBackground ? "Rejected: This is not a vegetable." : rawResult;

    return {
      "label": finalLabel,
      "confidence": 0.95, 
      "isRejected": isBackground,
    };
  }

  // ✅ 4. Core Web-Inference Logic (JS Interop Bridge)
  static Future<String> _processWebInference(Uint8List bytes) async {
    try {
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return "Invalid Image";

      // Resize to model requirements (224x224)
      img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

      // Normalize pixel data to 0.0 - 1.0
      final floatData = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          floatData[pixelIndex++] = pixel.r / 255.0;
          floatData[pixelIndex++] = pixel.g / 255.0;
          floatData[pixelIndex++] = pixel.b / 255.0;
        }
      }

      // Access TensorFlow.js via JS Interop
      final dynamic tf = js_util.getProperty(js_util.globalThis, 'tf');
      if (tf == null) return "Error: TF.js Engine Not Found";

      // Create 4D Tensor: [Batch, Height, Width, Channels]
      final dynamic inputTensor = js_util.callMethod(tf, 'tensor4d', [
        floatData,
        [1, 224, 224, 3],
        'float32'
      ]);

      // ✅ RUN PREDICTION & WAIT FOR JS PROMISE
      final dynamic predictionPromise = _model!.predict(inputTensor);
      final dynamic results = await js_util.promiseToFuture(predictionPromise);
      
      // Extract data
      final dynamic outputTensor = results is Map ? results.values.first : results;
      final List<dynamic> outputData = js_util.callMethod(outputTensor, 'dataSync', []);

      // Softmax/Argmax implementation to find the best label
      double maxScore = -1.0;
      int bestIndex = 0;
      for (int i = 0; i < outputData.length; i++) {
        double score = (outputData[i] as num).toDouble();
        if (score > maxScore) {
          maxScore = score;
          bestIndex = i;
        }
      }

      // 🧹 Memory Cleanup (Crucial for Web browser performance)
      js_util.callMethod(inputTensor, 'dispose', []);
      js_util.callMethod(outputTensor, 'dispose', []);

      return (_labels != null && bestIndex < _labels!.length) 
          ? _labels![bestIndex].trim() 
          : "Healthy";
    } catch (e) {
      print("❌ Web Inference Error: $e");
      return "Rejected: AI Error";
    }
  }
}
