import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../services/theme_provider.dart';
import '../../../../core/app_localizations.dart';

class ScannerResultService {
  static void showResult(
    BuildContext context,
    Map<String, dynamic> backendResponse, {
    int? diagnosisId,
    String? cropType,
    DateTime? followUpDate,
  }) {
    final bool isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final appLoc = AppLocalizations.of(context);

    // Extract data from backend response
    final String disease = backendResponse['disease_name'] ?? 'Healthy';
    final double confidence = (backendResponse['confidence'] ?? 0.0) * 100;
    final String vegetable = cropType ?? backendResponse['vegetable_type'] ?? "Vegetable";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            
            // Status Icon
            Icon(
              disease.toLowerCase() == 'healthy' ? Icons.check_circle : Icons.warning_amber_rounded,
              color: disease.toLowerCase() == 'healthy' ? Colors.green : Colors.orange,
              size: 60,
            ),
            
            const SizedBox(height: 16),
            Text(
              vegetable,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            
            Text(
              disease,
              style: TextStyle(fontSize: 18, color: disease.toLowerCase() == 'healthy' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            
            Text("${confidence.toStringAsFixed(1)}% Confidence", style: const TextStyle(color: Colors.grey)),
            
            const Divider(height: 30),

            if (followUpDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  "Next Checkup: ${DateFormat('dd MMM').format(followUpDate)}",
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),

            // Recommendation text
            Text(
              appLoc?.translate("Recommendation") ?? "Recommendation",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              disease.toLowerCase() == 'healthy' 
                ? "Your plant looks great! Continue with your current watering schedule."
                : "Isolate this plant if possible and check for similar symptoms on nearby crops.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(context),
                child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}