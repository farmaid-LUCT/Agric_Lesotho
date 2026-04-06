import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ScannerResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ScannerResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // 1. Extract nested data structures
    final Map<String, dynamic> analysis = result['results'] ?? {};
    final List<dynamic> personalizedRules = result['personalized_rules'] ?? [];
    final Map<String, dynamic> cropInfo = result['crop_info'] ?? {};

    // 2. Safe Confidence Extraction Logic
    // We check root, then nested 'results', then 'crop_info'
    final dynamic rawConf = result['confidence'] ?? 
                            result['ConfidenceLevel'] ?? 
                            analysis['confidence'] ?? 
                            cropInfo['confidence'] ?? 0.0;

    // Convert to double safely, handling potential String or Numeric types
    final double confDouble = (rawConf is String) 
        ? (double.tryParse(rawConf) ?? 0.0) 
        : (rawConf as num).toDouble();
        
    final String confidence = (confDouble * 100).toStringAsFixed(1);
    
    // Debug output to help you verify what the UI is actually seeing
    debugPrint("DEBUG: UI received confidence: $rawConf -> Final UI Value: $confidence%");

    final String label = analysis['disease'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis & Insights'),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[800]!],
                  ),
                ),
                child: Column(
                  children: [
                    const Text('Detected Condition', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      label.replaceAll('_', ' '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Chip(
                      label: Text('AI Confidence: $confidence%'),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 
            if (personalizedRules.isNotEmpty) ...[
              Text("💡 Smart Farmer Insights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900])),
              const SizedBox(height: 10),
              ...personalizedRules.map((rule) => Card(
                color: Colors.amber[50],
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.amber[200]!), borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.orange),
                  title: Text(rule['ExpertAdvice'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  subtitle: cropInfo['age_days'] != null ? Text("Based on your ${cropInfo['age_days']}-day old crop stage") : null,
                ),
              )),
              const SizedBox(height: 20),
            ],
            _buildInfoSection(title: 'Recommended Pesticide', content: analysis['pesticide'] ?? 'N/A', icon: Icons.science, color: Colors.blue[800]!),
            const SizedBox(height: 15),
            _buildInfoSection(title: 'Dosage', content: analysis['dosage'] ?? 'N/A', icon: Icons.scale, color: Colors.purple[800]!),
            const SizedBox(height: 15),
            _buildInfoSection(title: 'Application Steps', content: analysis['steps'] ?? 'Isolate plant and consult an expert.', icon: Icons.format_list_numbered, color: Colors.orange[800]!),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text('SCAN ANOTHER PLANT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]))]),
          const Divider(),
          Text(content, style: TextStyle(fontSize: 15, height: 1.4, color: Colors.grey[700])),
        ],
      ),
    );
  }
}