// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
// import 'package:google_generative_ai/google_generative_ai.dart';
// import '../../../core/constants.dart';

// class AIService {
//   static Interpreter? _interpreter;
//   static List<String>? _labels;
//   // ✅ 1. Load Local Model & Labels (FarmAid structure)
//   static Future<void> loadModel() async {
//     if (_interpreter != null) return;
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/farm_aid_model.tflite');
//       final labelsString = await rootBundle.loadString('assets/models/labels.txt');
//       _labels = labelsString.split('\n').where((s) => s.isNotEmpty).toList();
//       print("🧠 Local AI Model loaded successfully");
//     } catch (e) {
//       print("❌ AI Load Error: $e");
//     }
//   }
//   // ✅ 2. Main Entry Point
//   static Future<Map<String, dynamic>> runInference(Uint8List imageBytes) async {
//     if (_interpreter == null) await loadModel();
//     // STEP A: LOCAL PREDICTION
//     final localGuess = await compute(_processLocalInference, {
//       'bytes': imageBytes,
//       'labels': _labels,
//       'interpreterAddress': _interpreter!.address,
//     });
//     print("🧠 Local thinks: $localGuess. Validating with Gemini...");
//     // STEP B: VALIDATION WITH GEMINI 2.5
//     return await getGeminiAnalysis(imageBytes, localGuess);
//   }
//   // ✅ 3. Gemini Validator (Updated for 2026 Stable Models)
//   static Future<Map<String, dynamic>> getGeminiAnalysis(Uint8List bytes, String suggestedLabel) async {

//     // FIX: Using gemini-2.5-flash which is the stable production model in 2026
//     // gemini-1.5-flash is now deprecated/retired.
//     final model = GenerativeModel(
//       model: 'gemini-2.5-flash',
//       apiKey: AppConstants.geminiApiKey,
//       // API version v1 is now the stable standard
//       requestOptions: const RequestOptions(apiVersion: 'v1'),
//     );
//     final prompt = [
//       Content.multi([
//         TextPart(
//           "You are a specialized FarmAid agronomist. I have an image predicted as '$suggestedLabel'. "
//           "STRICT RULES: "
//           "1. If the image is a VEGETABLE: Identify the disease name OR say 'Healthy'. "
//           "2. If the image is NOT a vegetable (human, animal, object): Respond ONLY with 'Rejected: Not a vegetable'."

//         ),
//         DataPart('image/jpeg', bytes),
//       ])
//     ];
//     try {
//       final response = await model.generateContent(prompt);
//       String text = response.text?.trim() ?? "Unknown";
//       // Determine if rejected based on your rule
//       bool isRejected = text.toLowerCase().contains("rejected") ||

//                         text.toLowerCase().contains("not a vegetable");

//       print("📡 Gemini response: $text");

//       return {
//         "label": text,
//         "confidence": 1.0,
//         "isRejected": isRejected,
//       };
//     } catch (e) {
//       print("❌ Gemini Critical Error: $e");
//       // Safety Fallback: Reject if we can't confirm it's a vegetable via cloud
//       return {
//         "label": "Offline - Check Connection",
//         "confidence": 0.0,
//         "isRejected": true,
//       };
//     }
//   }







//   // Background function for image processing



//   static String _processLocalInference(Map<String, dynamic> params) {



//     final Uint8List bytes = params['bytes'];



//     final List<String> labels = params['labels'];



//     final int address = params['interpreterAddress'];



   



//     final interpreter = Interpreter.fromAddress(address);



   



//     img.Image? originalImage = img.decodeImage(bytes);



//     if (originalImage == null) return "Invalid Image";



   



//     img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);



   



//     var input = List.generate(1, (index) => List.generate(224, (y) => List.generate(224, (x) {



//       final pixel = resizedImage.getPixel(x, y);



//       return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];



//     })));



//     var output = List.filled(1 * labels.length, 0.0).reshape([1, labels.length]);
//     interpreter.run(input, output);
//     double maxScore = -1.0;
//     int bestIndex = 0;
//     for (int i = 0; i < output[0].length; i++) {
//       if (output[0][i] > maxScore) {
//         maxScore = output[0][i];
//         bestIndex = i;
//       }
//     }
//     return labels[bestIndex].trim();
//   }
// }




// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;

// class AIService {
//   static Interpreter? _interpreter;
//   static List<String>? _labels;

//   // ✅ 1. Load Local Model & Labels (FarmAid structure)
//   static Future<void> loadModel() async {
//     if (_interpreter != null) return;
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/farm_aid_model.tflite');
//       final labelsString = await rootBundle.loadString('assets/models/labels.txt');
//       _labels = labelsString.split('\n').where((s) => s.isNotEmpty).toList();
//       print("🧠 Local AI Model loaded successfully");
//     } catch (e) {
//       print("❌ AI Load Error: $e");
//     }
//   }

//   // ✅ 2. Main Entry Point (Now purely local)
//   static Future<Map<String, dynamic>> runInference(Uint8List imageBytes) async {
//     if (_interpreter == null) await loadModel();

//     // Perform Local Prediction on a background thread
//     final String localResult = await compute(_processLocalInference, {
//       'bytes': imageBytes,
//       'labels': _labels,
//       'interpreterAddress': _interpreter!.address,
//     });

//     print("🧠 Local AI Result: $localResult");

//     // ✅ 3. Rejection Logic based on labels.txt content
//     // If your model labels include "Background_car", etc., we check for them here.
//     bool isRejected = localResult.toLowerCase().contains("background") || 
//                       localResult.toLowerCase().contains("rejected");

//     return {
//       "label": localResult,
//       "confidence": 0.95, // Estimated for local model
//       "isRejected": isRejected,
//     };
//   }

//   // ✅ 4. Background function for image processing (No changes needed here)
//   static String _processLocalInference(Map<String, dynamic> params) {
//     final Uint8List bytes = params['bytes'];
//     final List<String> labels = params['labels'];
//     final int address = params['interpreterAddress'];

//     final interpreter = Interpreter.fromAddress(address);

//     img.Image? originalImage = img.decodeImage(bytes);
//     if (originalImage == null) return "Invalid Image";

//     img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

//     var input = List.generate(1, (index) => List.generate(224, (y) => List.generate(224, (x) {
//       final pixel = resizedImage.getPixel(x, y);
//       return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
//     })));

//     var output = List.filled(1 * labels.length, 0.0).reshape([1, labels.length]);
//     interpreter.run(input, output);

//     double maxScore = -1.0;
//     int bestIndex = 0;
//     for (int i = 0; i < output[0].length; i++) {
//       if (output[0][i] > maxScore) {
//         maxScore = output[0][i];
//         bestIndex = i;
//       }
//     }

//     return labels[bestIndex].trim();
//   }
// }



// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;

// class AIService {
//   static Interpreter? _interpreter;
//   static List<String>? _labels;

//   // ✅ 1. Load Local Model & Labels (FarmAid structure)
//   static Future<void> loadModel() async {
//     if (_interpreter != null) return;
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/farm_aid_model.tflite');
//       final labelsString = await rootBundle.loadString('assets/models/labels.txt');
//       _labels = labelsString.split('\n').where((s) => s.isNotEmpty).toList();
//       print("🧠 Local AI Model loaded successfully");
//     } catch (e) {
//       print("❌ AI Load Error: $e");
//     }
//   }

//   // ✅ 2. Main Entry Point
//   static Future<Map<String, dynamic>> runInference(Uint8List imageBytes) async {
//     if (_interpreter == null) await loadModel();

//     // Perform Local Prediction on a background thread
//     final String rawLocalResult = await compute(_processLocalInference, {
//       'bytes': imageBytes,
//       'labels': _labels,
//       'interpreterAddress': _interpreter!.address,
//     });

//     print("🧠 Raw Model Prediction: $rawLocalResult");

//     // ✅ 3. Updated Rejection Logic
//     // If the model identifies the image as background or non-crop
//     bool isBackground = rawLocalResult.toLowerCase().contains("background") || 
//                         rawLocalResult.toLowerCase().contains("rejected");

//     String finalLabel = rawLocalResult;
    
//     // If it's not a vegetable, we force the specific rejection message
//     if (isBackground) {
//       finalLabel = "Rejected: This is not a vegetable.";
//     }

//     return {
//       "label": finalLabel,
//       "confidence": 0.95, 
//       "isRejected": isBackground,
//     };
//   }

//   // ✅ 4. Background function for image processing
//   static String _processLocalInference(Map<String, dynamic> params) {
//     final Uint8List bytes = params['bytes'];
//     final List<String> labels = params['labels'];
//     final int address = params['interpreterAddress'];

//     final interpreter = Interpreter.fromAddress(address);

//     img.Image? originalImage = img.decodeImage(bytes);
//     if (originalImage == null) return "Invalid Image";

//     img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

//     var input = List.generate(1, (index) => List.generate(224, (y) => List.generate(224, (x) {
//       final pixel = resizedImage.getPixel(x, y);
//       // Normalized RGB values
//       return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
//     })));

//     var output = List.filled(1 * labels.length, 0.0).reshape([1, labels.length]);
//     interpreter.run(input, output);

//     double maxScore = -1.0;
//     int bestIndex = 0;
//     for (int i = 0; i < output[0].length; i++) {
//       if (output[0][i] > maxScore) {
//         maxScore = output[0][i];
//         bestIndex = i;
//       }
//     }

//     return labels[bestIndex].trim();
//   }
// }



// import 'dart:typed_data';
// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
// import 'package:http/http.dart' as http; // Added for Neon/Django sync
// import '../../../services/auth_service.dart'; // Added to get token

// class AIService {
//   static Interpreter? _interpreter;
//   static List<String>? _labels;
//   final AuthService _auth = AuthService();

//   // ✅ 1. Load Local Model & Labels
//   static Future<void> loadModel() async {
//     if (_interpreter != null) return;
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/farm_aid_model.tflite');
//       final labelsString = await rootBundle.loadString('assets/models/labels.txt');
//       _labels = labelsString.split('\n').where((s) => s.isNotEmpty).toList();
//       print("🧠 Local AI Model loaded successfully");
//     } catch (e) {
//       print("❌ AI Load Error: $e");
//     }
//   }

//   // ✅ NEW: Sync Method for Settings Screen
//   // This satisfies the call: await _aiService.syncScanHistory();
//   Future<void> syncScanHistory() async {
//     try {
//       final token = await _auth.getToken();
//       if (token == null) throw Exception("No Auth Token found");

//       // Fetching from your Django API linked to Neon DB
//       final response = await http.get(
//         Uri.parse("http://10.58.154.10:8000/api/farmer-reports/"), 
//         headers: {"Authorization": "Token $token"},
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         print("✅ Sync Success: ${data.length} records retrieved from Neon.");
        
//         // In a production app, you could save 'data' to a local database here
//         // so that the History screen works even without internet.
//       } else {
//         throw Exception("Server returned ${response.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Sync Error: $e");
//       rethrow; // Send error back to Settings screen to show SnackBar
//     }
//   }

//   // ✅ 2. Main Entry Point for AI Scanning
//   static Future<Map<String, dynamic>> runInference(Uint8List imageBytes) async {
//     if (_interpreter == null) await loadModel();

//     final String rawLocalResult = await compute(_processLocalInference, {
//       'bytes': imageBytes,
//       'labels': _labels,
//       'interpreterAddress': _interpreter!.address,
//     });

//     bool isBackground = rawLocalResult.toLowerCase().contains("background") || 
//                         rawLocalResult.toLowerCase().contains("rejected");

//     String finalLabel = rawLocalResult;
    
//     if (isBackground) {
//       finalLabel = "Rejected: This is not a vegetable.";
//     }

//     return {
//       "label": finalLabel,
//       "confidence": 0.95, 
//       "isRejected": isBackground,
//     };
//   }

//   // ✅ 3. Background function for image processing
//   static String _processLocalInference(Map<String, dynamic> params) {
//     final Uint8List bytes = params['bytes'];
//     final List<String> labels = params['labels'];
//     final int address = params['interpreterAddress'];

//     final interpreter = Interpreter.fromAddress(address);

//     img.Image? originalImage = img.decodeImage(bytes);
//     if (originalImage == null) return "Invalid Image";

//     img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

//     var input = List.generate(1, (index) => List.generate(224, (y) => List.generate(224, (x) {
//       final pixel = resizedImage.getPixel(x, y);
//       return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
//     })));

//     var output = List.filled(1 * labels.length, 0.0).reshape([1, labels.length]);
//     interpreter.run(input, output);

//     double maxScore = -1.0;
//     int bestIndex = 0;
//     for (int i = 0; i < output[0].length; i++) {
//       if (output[0][i] > maxScore) {
//         maxScore = output[0][i];
//         bestIndex = i;
//       }
//     }

//     return labels[bestIndex].trim();
//   }
// }




export 'ai_service_stub.dart'
    if (dart.library.io) 'ai_service_mobile.dart'
    if (dart.library.html) 'ai_service_web.dart'
    if (dart.library.js_interop) 'ai_service_web.dart';