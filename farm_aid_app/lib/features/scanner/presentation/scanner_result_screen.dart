import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ScannerResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ScannerResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Formatting the confidence to a percentage (e.g., 0.95 -> 95%)
    final String confidence = (result['confidence'] * 100).toStringAsFixed(1);
    final String label = result['label'].replaceAll('_', ' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis Result'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Prediction Header Card
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
                    const Text(
                      'Detected Condition',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Chip(
                      label: Text('Confidence: $confidence%'),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // 2. Symptoms Section
            _buildInfoSection(
              title: 'Symptoms',
              content: result['symptoms'] ?? 'No symptom data available.',
              icon: Icons.search,
              color: Colors.orange[800]!,
            ),

            const SizedBox(height: 15),

            // 3. Treatment Section
            _buildInfoSection(
              title: 'Recommended Treatment',
              content: result['treatment'] ?? 'Consult an expert for advice.',
              icon: Icons.medication_liquid,
              color: Colors.blue[800]!,
            ),

            const SizedBox(height: 30),

            // 4. Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ],
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            content,
            style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}