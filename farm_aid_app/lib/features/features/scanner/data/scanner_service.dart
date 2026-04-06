import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants.dart';

class ScannerService {
  final _supabase = Supabase.instance.client;
  final _auth = AuthService();

  // ── timeouts ────────────────────────────────────────────────────────────────
  // Render free tier cold-starts can take 20–30s.
  // 40s gives one full cold-start + actual processing time.
  // Upload gets its own 30s window.
  static const _backendTimeout  = Duration(seconds: 40);
  static const _uploadTimeout   = Duration(seconds: 30);

  // ── MOBILE UPLOAD ────────────────────────────────────────────────────────────
  Future<String?> uploadCropImage(File imageFile) async {
    try {
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage
          .from('farm-scans')
          .upload(
            fileName,
            imageFile,
            fileOptions: FileOptions(
              contentType: lookupMimeType(imageFile.path) ?? 'image/jpeg',
              upsert: true,
            ),
          )
          .timeout(_uploadTimeout);                         // ← timeout added
      return _supabase.storage.from('farm-scans').getPublicUrl(fileName);
    } on TimeoutException {
      print('Supabase Mobile Upload: timed out after ${_uploadTimeout.inSeconds}s');
      return null;
    } catch (e) {
      print('Supabase Mobile Upload Error: $e');
      return null;
    }
  }

  // ── WEB UPLOAD ───────────────────────────────────────────────────────────────
  Future<String?> uploadCropImageWeb(Uint8List bytes) async {
    try {
      final fileName = 'web_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage
          .from('farm-scans')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          )
          .timeout(_uploadTimeout);                         // ← timeout added
      return _supabase.storage.from('farm-scans').getPublicUrl(fileName);
    } on TimeoutException {
      print('Supabase Web Upload: timed out after ${_uploadTimeout.inSeconds}s');
      return null;
    } catch (e) {
      print('Supabase Web Upload Error: $e');
      return null;
    }
  }

  // ── SAVE TO DJANGO BACKEND ───────────────────────────────────────────────────
  Future<Map<String, dynamic>?> saveScanToBackend({
    required String  imageUrl,
    required String  diseaseName,
    required double  confidence,
    required String? profileId,
    required double? latitude,
    required double? longitude,
    double?  altitude,
    String?  district,
    String   scanMode = 'personalized', // 'general' or 'personalized'
  }) async {
    try {
      final token = await _auth.getToken();

      final response = await http
          .post(
            Uri.parse(AppConstants.saveScanUrl),
            headers: {
              'Content-Type':  'application/json',
              'Authorization': 'Token $token',
            },
            body: jsonEncode({
              'profileId':    profileId,
              'imageUrl':     imageUrl,
              'diseaseName':  diseaseName,
              'confidence':   confidence,
              'latitude':     latitude,
              'longitude':    longitude,
              'altitude':     altitude,
              'gps_district': district,
              'scan_mode':    scanMode,  // tells backend general vs personalized
            }),
          )
          .timeout(                                         // ← timeout added
            _backendTimeout,
            onTimeout: () {
              // Return a fake 408 response so the caller can show a clear message
              return http.Response(
                jsonEncode({'error': 'Request timed out. The server may be waking up — please try again in 30 seconds.'}),
                408,
              );
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Surface the actual Django error message in the console
      print('Backend Error ${response.statusCode}: ${response.body}');

      // 408 = our own timeout sentinel — return null so caller shows the message
      if (response.statusCode == 408) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Rethrow as exception so scanner_section catches and shows snackbar
        throw Exception(body['error']);
      }

      return null;

    } on TimeoutException {
      // Shouldn't normally reach here because we handle it in onTimeout above,
      // but keep as safety net.
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      print('Django Save Error: $e');
      rethrow;   // Let scanner_section.dart catch and show the error message
    }
  }
}