// lib/features/alerts/data/alert_service.dart
//
// Handles all API calls for the alerts feature:
//   GET  /api/alerts/              → full alerts list + unread count
//   GET  /api/alerts/unread-count/ → lightweight badge count only
//   POST /api/alerts/mark-read/    → marks all as read
//
// Follows the same token + base URL pattern used across the rest of
// the app (auth_service.dart, market_service.dart, etc.)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert_model.dart';

class AlertService {
  // ── Base URL — matches the pattern in lib/core/constants.dart ────────────
  static const String _baseUrl =
      'https://farmaid-backend.onrender.com/api';

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static const String _alertsEndpoint      = '$_baseUrl/alerts/';
  static const String _unreadCountEndpoint = '$_baseUrl/alerts/unread-count/';
  static const String _markReadEndpoint    = '$_baseUrl/alerts/mark-read/';

  // ── Token helper — same SharedPreferences key used in auth_service.dart ──
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _headers(String token) => {
    'Content-Type':  'application/json',
    'Authorization': 'Token $token',
  };

  // ── 1. Fetch full alerts list ─────────────────────────────────────────────
  /// Returns [AlertsResponse] with alerts list + unread count.
  /// Pass [alertType] to filter by type (e.g. 'weather', 'disease').
  Future<AlertsResponse> fetchAlerts({String? alertType}) async {
    final token = await _getToken();
    if (token == null) return AlertsResponse.empty();

    try {
      final uri = Uri.parse(
        alertType != null
            ? '$_alertsEndpoint?type=$alertType'
            : _alertsEndpoint,
      );

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AlertsResponse.fromJson(json);
      }

      // 401 — token expired or invalid
      if (response.statusCode == 401) {
        return AlertsResponse.empty();
      }

      return AlertsResponse.empty();
    } catch (_) {
      return AlertsResponse.empty();
    }
  }

  // ── 2. Fetch unread count only (lightweight — for bell badge) ─────────────
  /// Returns just the unread count integer.
  /// Called every 60 s by AlertBellIcon — keeps payload tiny.
  Future<int> fetchUnreadCount() async {
    final token = await _getToken();
    if (token == null) return 0;

    try {
      final response = await http
          .get(
            Uri.parse(_unreadCountEndpoint),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['unread_count'] as int?) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── 3. Mark all alerts as read ─────────────────────────────────────────────
  /// Called when the farmer opens the alerts screen.
  /// Returns true on success.
  Future<bool> markAllRead() async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http
          .post(
            Uri.parse(_markReadEndpoint),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}