// import 'dart:io';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:mime/mime.dart';
// import '../../../services/auth_service.dart';
// import '../../../core/constants.dart';

// class ScannerService {
//   final _supabase = Supabase.instance.client;
//   final _auth = AuthService();

//   final int _maxFileSize = 5 * 1024 * 1024; // 5 MB
//   final List<String> _allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];

//   /// STEP 1: Upload the image to Supabase Bucket
//   Future<String?> uploadCropImage(File imageFile) async {
//     try {
//       final int fileSize = await imageFile.length();
//       if (fileSize > _maxFileSize) {
//         throw Exception("File too large. Max size is 5MB.");
//       }

//       final String? mimeType = lookupMimeType(imageFile.path);
//       if (mimeType == null || !_allowedMimeTypes.contains(mimeType)) {
//         throw Exception("Invalid file type. Please upload a JPG, PNG, or WebP image.");
//       }

//       final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       final path = 'public/$fileName';

//       await _supabase.storage.from('farm-scans').upload(
//             path,
//             imageFile,
//             fileOptions: FileOptions(contentType: mimeType, upsert: false),
//           );

//       return _supabase.storage.from('farm-scans').getPublicUrl(path);
//     } catch (e) {
//       print('Supabase Upload Error: $e');
//       rethrow;
//     }
//   }

//   /// STEP 2: Save the scan to Django and get Personalized Vegetable Advice
//   Future<Map<String, dynamic>> saveScanToBackend({
//     required String imageUrl,
//     required String diseaseName,
//     required double confidence,
//     required int? profileId,
//     required String vegetableType,
//   }) async {
//     try {
//       final token = await _auth.getToken();
      
//       final response = await http.post(
//         Uri.parse("${AppConstants.apiBaseUrl}/save-scan/"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Token $token",
//         },
//         body: jsonEncode({
//           "ProfileID": profileId,
//           "CropType": vegetableType,
//           "ImageFile": imageUrl,
//           "DiseaseName": diseaseName,
//           "ConfidenceLevel": confidence,
//           "RequestPersonalized": profileId != null, // Request rules if profile exists
//         }),
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception("Backend failed to save scan: ${response.body}");
//       }
//     } catch (e) {
//       print('Django Save Error: $e');
//       rethrow;
//     }
//   }
// }




import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants.dart';

class ScannerService {
  final _supabase = Supabase.instance.client;
  final _auth = AuthService();

  /// STEP 1: Upload the image to Supabase Bucket
  Future<String?> uploadCropImage(File imageFile) async {
    try {
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // The path in the bucket
      final path = fileName; 

      await _supabase.storage.from('farm-scans').upload(
            path,
            imageFile,
            fileOptions: FileOptions(
              contentType: lookupMimeType(imageFile.path) ?? 'image/jpeg', 
              upsert: true
            ),
          );

      // This returns the full https://... URL from Supabase
      return _supabase.storage.from('farm-scans').getPublicUrl(path);
    } catch (e) {
      print('Supabase Upload Error: $e');
      return null;
    }
  }

  /// STEP 2: Save to Neon via Django
  Future<Map<String, dynamic>?> saveScanToBackend({
    required String imageUrl,
    required String diseaseName,
    required double confidence,
    required String? profileId, 
  }) async {
    try {
      final token = await _auth.getToken();
      
      // ✅ FIX: Keys are updated to match exactly what Django SaveScanView expects
      final response = await http.post(
        Uri.parse(AppConstants.saveScanUrl), 
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token $token",
        },
        body: jsonEncode({
          "profileId": profileId,            // Django looks for 'profileId'
          "imageUrl": imageUrl,              // Sending the full Supabase URL
          "diseaseName": diseaseName,        
          "confidence": confidence,          // The confidence score
          "RequestPersonalized": profileId != null, 
        }),
      );

      // Debugging: See what the server says about the save
      print('Backend Response Status: ${response.statusCode}');
      print('Backend Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Server rejection: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Django Save Error: $e');
      return null;
    }
  }
}