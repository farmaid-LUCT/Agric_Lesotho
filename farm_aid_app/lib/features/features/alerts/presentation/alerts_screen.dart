import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../core/constants.dart'; 
import '../../../services/auth_service.dart';
import '../../../services/theme_provider.dart';
import '../../../core/app_localizations.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AuthService _auth = AuthService();
  List _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  // Fetches alerts from the Neon database
  Future<void> _fetchAlerts() async {
    try {
      final token = await _auth.getToken();
      
      final response = await http.get(
        Uri.parse("${AppConstants.apiBaseUrl}/alerts/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List fetchedAlerts = jsonDecode(response.body);
        setState(() {
          _alerts = fetchedAlerts;
          _isLoading = false;
        });

        // If there are unread alerts, mark them as read automatically when the screen opens
        if (_alerts.any((alert) => alert['IsRead'] == false)) {
          _markAllAsRead(token);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Alerts Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // Handles the "Swipe to Dismiss" logic on the backend
  Future<void> _dismissAlert(int alertId, int index) async {
    try {
      final token = await _auth.getToken();
      final response = await http.post(
        Uri.parse("${AppConstants.apiBaseUrl}/alerts/dismiss/$alertId/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _alerts.removeAt(index); 
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate("Alert dismissed from dashboard") ?? "Alert dismissed from dashboard"),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error dismissing alert: $e");
    }
  }

  Future<void> _markAllAsRead(String? token) async {
    try {
      await http.post(
        Uri.parse("${AppConstants.apiBaseUrl}/alerts/mark-read/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );
    } catch (e) {
      debugPrint("Error marking alerts as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final appLoc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          appLoc?.translate("Agricultural Alerts") ?? "Agricultural Alerts", 
          style: TextStyle(
            color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), 
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.green),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
        : RefreshIndicator(
            onRefresh: _fetchAlerts,
            color: Colors.green,
            child: _alerts.isEmpty 
              ? _buildPlaceholderAlerts(isDark, appLoc) 
              : _buildAlertList(isDark),
          ),
    );
  }

  Widget _buildAlertList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        bool isUnread = alert['IsRead'] == false;
        final int alertId = alert['AlertID'] ?? 0;

        return Dismissible(
          key: Key(alertId.toString()),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => _dismissAlert(alertId, index),
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
          ),
          child: _alertCard(
            alert['Title'] ?? "Alert", 
            alert['Message'] ?? "", 
            _getSeverityColor(alert['alert_type'], isDark), 
            _getIcon(alert['alert_type']),
            isUnread,
            isDark,
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderAlerts(bool isDark, AppLocalizations? appLoc) {
    return SingleChildScrollView( 
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: isDark ? Colors.white12 : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              appLoc?.translate("No active alerts for your crops.") ?? "No active alerts for your crops.", 
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16)
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String? type, bool isDark) {
    switch (type?.toLowerCase()) {
      case 'disease': return isDark ? Colors.redAccent : Colors.red;
      case 'pest': return isDark ? Colors.orangeAccent : Colors.orange;
      case 'weather': return isDark ? Colors.blueAccent : Colors.blue;
      default: return isDark ? Colors.greenAccent : Colors.green;
    }
  }

  IconData _getIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'weather': return Icons.cloudy_snowing;
      case 'disease': return Icons.coronavirus_outlined;
      case 'pest': return Icons.pest_control;
      default: return Icons.info_outline;
    }
  }

  Widget _alertCard(String title, String desc, Color color, IconData icon, bool isUnread, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 15, 
                  color: isDark ? Colors.white : Colors.black87
                )
              )
            ),
            if (isUnread) 
              Container(
                width: 8, height: 8, 
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)
              ),
          ],
        ),
        subtitle: Text(desc, 
          style: TextStyle(
            fontSize: 13, 
            color: isDark ? Colors.white70 : Colors.black87
          )
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}