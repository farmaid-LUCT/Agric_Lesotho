import 'package:flutter/material.dart';

class PlantingCalendarScreen extends StatelessWidget {
  const PlantingCalendarScreen({super.key});

  // Data categorized by season
  final List<Map<String, dynamic>> _crops = const [
    {"name": "Cabbage", "months": [4, 5, 6, 7, 8], "type": "Winter"},
    {"name": "Spinach", "months": [3, 4, 5, 6, 7, 8, 9], "type": "Both"},
    {"name": "Tomato", "months": [9, 10, 11, 12, 1], "type": "Summer"},
    {"name": "Onion", "months": [2, 3, 4, 5], "type": "Winter/Spring"},
    {"name": "Carrot", "months": [8, 9, 10, 1, 2], "type": "Both"},
  ];

  @override
  Widget build(BuildContext context) {
    // Get the current month (1 = Jan, 3 = March, etc.)
    int currentMonth = DateTime.now().month;
    
    // Filter crops that should be planted THIS month
    final recommendedNow = _crops.where((c) => c['months'].contains(currentMonth)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("PLANTING CALENDAR"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recommended for ${ _getMonthName(currentMonth)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text("Based on Lesotho's seasonal cycle"),
            const SizedBox(height: 20),
            
            Expanded(
              child: ListView.builder(
                itemCount: recommendedNow.length,
                itemBuilder: (context, index) {
                  final crop = recommendedNow[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.grass, color: Colors.white),
                      ),
                      title: Text(crop['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Season: ${crop['type']}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}