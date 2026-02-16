
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AuthService {
  // --- 1. SIGN UP ---
  Future<bool> signUp(
    String name, 
    String email, 
    String last_name, 
    String phone, 
    String location, 
    String password, 
    String language, 
    String username
  ) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.registerUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'username': username,
          'first_name': name,
          'last_name': last_name,
          'email': email,
          'phone_number': phone,
          'location': location,
          'password': password,
          'language_preferences': language, 
        }),
      );

      if (response.statusCode == 201) {
        return true; 
      }
      
      print("Sign Up Error: ${response.body}");
      return false;
    } catch (e) {
      print("Sign Up Exception: $e");
      return false;
    }
  }

  // --- 2. SIGN IN ---
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveUserSession(
          data['token'], 
          data['farmerName'], 
          data['is_staff'] ?? false
        );
        return {'success': true};
      } 
      
      if (response.statusCode == 403 && data['error'] == 'unverified') {
        return {'success': false, 'error': 'unverified', 'message': data['message']};
      }

      return {'success': false, 'error': 'invalid', 'message': data['error'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'error': 'exception', 'message': e.toString()};
    }
  }

  // --- 3. GET CURRENT USER (NEON DB) ---
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${AppConstants.baseUrl}/auth/profile/"), // Ensure this route exists in Django
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token', // Django Rest Framework usually uses 'Token' prefix
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Map Django fields to our app's UI fields
        return {
          'full_name': "${data['first_name']} ${data['last_name']}",
          'district': data['location'], // Using location as the district
        };
      }
      return null;
    } catch (e) {
      print("Fetch Profile Exception: $e");
      return null;
    }
  }

  // --- CHANGE PASSWORD ---
Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
  try {
    final token = await getToken();
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/auth/password/change/"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': data['error'] ?? 'Failed to update password'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Connection error'};
  }
}

  // --- 4. UPDATE PROFILE (NEON DB) ---
  Future<bool> updateProfile({required String fullName, required String district}) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // Split name back into first and last for Django standard User model
      List<String> parts = fullName.split(" ");
      String firstName = parts.first;
      String lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

      final response = await http.patch( // PATCH is better for partial updates
        Uri.parse("${AppConstants.baseUrl}/auth/profile/update/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'location': district,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Update Profile Exception: $e");
      return false;
    }
  }

  // --- 5. RESEND ACTIVATION ---
  Future<bool> resendActivationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}/resend-activation/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- 6. SESSION HELPERS ---

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_admin') ?? false;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    await prefs.setBool('is_guest', true);
  }

  Future<void> _saveUserSession(String token, String name, bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userDataKey, name);
    await prefs.setBool('is_admin', isAdmin);
    await prefs.setBool('is_guest', false);
  }
}