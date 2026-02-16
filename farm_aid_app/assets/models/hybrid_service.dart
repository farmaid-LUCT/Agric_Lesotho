import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class AIService {
  // Your TFLite logic here...

  Future<String> predictCropStatus(Uint8List imageBytes) async {
    // Step 1: Run Local Model
    var localResult = await runTFLite(imageBytes); 
    
    // Step 2: Automatic Fallback
    if (localResult.confidence < 0.85) {
      print("Low confidence (${localResult.confidence}). Switching to Web Brain...");
      return await _getGeminiAnalysis(imageBytes);
    }

    return "Result: ${localResult.label}";
  }

  Future<String> _getGeminiAnalysis(Uint8List bytes) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: 'AIzaSyCh_Kbhuj27lplco77eq5O-tM0rupM2sAA');
    final content = [
      Content.multi([
        TextPart("Identify this vegetable leaf and its disease. If it's not a vegetable, say 'Rejected: Not a vegetable'."),
        DataPart('image/jpeg', bytes),
      ])
    ];
    
    final response = await model.generateContent(content);
    return response.text ?? "Detection failed. Please try again.";
  }
}