import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants.dart';
import '../../../services/theme_provider.dart';
import '../../../core/app_localizations.dart';

// Modules for the Trend Analysis
import 'widgets/trend_chart.dart';
import '../data/analytics_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final AuthService _auth = AuthService();
  bool _isLoading = true;
  
  // Data for the Pie Chart
  int totalScans = 0;
  double healthyPct = 0;
  double diseasedPct = 0;
  double atRiskPct = 0; 
  double otherPct = 0;

  // Data for the Time-Series Chart
  List<Map<String, dynamic>> dailyTrend = [];

  @override
  void initState() {
    super.initState();
    _loadInsightData();
  }

  Future<void> _loadInsightData() async {
    try {
      final token = await _auth.getToken();
      final response = await http.get(
        Uri.parse(AppConstants.farmerReports),
        headers: {"Authorization": "Token $token"},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _processRealData(data);
      }
    } catch (e) {
      debugPrint("Insights Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processRealData(List data) {
    if (data.isEmpty) return;

    totalScans = data.length;
    int healthyCount = 0;
    int diseasedCount = 0;
    int atRiskCount = 0;

    Map<String, List<bool>> groupedByDate = {};

    for (var item in data) {
      // 1. Diagnosis Analysis (Vegetable specific keywords)
      String diagnosis = item['DiagnosisSummary']?.toString().toLowerCase() ?? '';
      double confidence = double.tryParse(item['Confidence']?.toString() ?? '1.0') ?? 1.0;
      
      // Healthy check
      bool isDiseased = !diagnosis.contains('healthy');

      if (!isDiseased) {
        healthyCount++;
      } else if (confidence < 0.6) {
        atRiskCount++;
      } else {
        diseasedCount++;
      }

      // 2. Date Parsing - Using ReportDate as per our Plant table sync
      String dateKey = item['ReportDate']?.toString().substring(0, 10) ?? 
                       DateTime.now().toString().substring(0, 10);
      
      groupedByDate.putIfAbsent(dateKey, () => []);
      groupedByDate[dateKey]!.add(isDiseased);
    }

    // 3. Constructing the Trend Points
    List<String> sortedDates = groupedByDate.keys.toList()..sort();
    dailyTrend = sortedDates.map((date) {
      List<bool> dayScans = groupedByDate[date]!;
      int sickOnDay = dayScans.where((s) => s == true).length;
      return {
        "date": DateTime.parse(date),
        "risk": (sickOnDay / dayScans.length).clamp(0.0, 1.0),
      };
    }).toList();

    setState(() {
      healthyPct = (healthyCount / totalScans) * 100;
      diseasedPct = (diseasedCount / totalScans) * 100;
      atRiskPct = (atRiskCount / totalScans) * 100;
      
      double currentSum = healthyPct + diseasedPct + atRiskPct;
      otherPct = currentSum >= 100 ? 0 : 100 - currentSum;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final appLoc = AppLocalizations.of(context);
    
    final trendData = dailyTrend.isNotEmpty 
        ? dailyTrend 
        : AnalyticsService.getMockTrendData();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(appLoc?.translate("Vegetable Insights") ?? "Vegetable Insights", 
          style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.green),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
        : totalScans == 0 
          ? _buildNoDataState(isDark, appLoc)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryCard(isDark, appLoc),
                  const SizedBox(height: 16),
                  
                  if (trendData.isNotEmpty)
                    _buildPredictiveBanner(trendData.last['risk'], isDark, appLoc),
                  
                  const SizedBox(height: 16),
                  _buildChartCard(isDark, appLoc), 
                  const SizedBox(height: 16),
                  _buildTrendCard(trendData, isDark, appLoc), 
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(bool isDark, AppLocalizations? appLoc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Text(
            "${appLoc?.translate("Total Vegetable Scans") ?? "Total Vegetable Scans"}: $totalScans",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            "${appLoc?.translate("Overall Health") ?? "Overall Health"}: ${healthyPct.toStringAsFixed(1)}%",
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveBanner(double risk, bool isDark, AppLocalizations? appLoc) {
    bool isHigh = risk > 0.6;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHigh ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isHigh ? Colors.red : Colors.green),
      ),
      child: Row(
        children: [
          Icon(isHigh ? Icons.warning : Icons.health_and_safety, color: isHigh ? Colors.red : Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isHigh 
                ? (appLoc?.translate("predictive_high") ?? "Alert: Recent patterns suggest a localized disease spike. Monitor humidity levels.") 
                : (appLoc?.translate("predictive_low") ?? "Stability: Your vegetable health patterns are within the normal range."),
              style: TextStyle(fontSize: 13, color: isHigh ? Colors.red : Colors.green, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(List<Map<String, dynamic>> data, bool isDark, AppLocalizations? appLoc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appLoc?.translate("Health Risk Trend") ?? "Health Risk Trend", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
          const SizedBox(height: 25),
          SizedBox(height: 180, child: TrendChart(data: data, isDark: isDark)),
          const SizedBox(height: 10),
          Text(appLoc?.translate("Moving average showing disease detection rate.") ?? "Moving average showing disease detection rate.", 
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChartCard(bool isDark, AppLocalizations? appLoc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appLoc?.translate("Current Distribution") ?? "Current Distribution", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(value: healthyPct, color: Colors.green.shade400, radius: 30, showTitle: false),
                  PieChartSectionData(value: atRiskPct, color: Colors.orange.shade400, radius: 30, showTitle: false),
                  PieChartSectionData(value: diseasedPct, color: Colors.red.shade400, radius: 30, showTitle: false),
                  PieChartSectionData(value: otherPct > 0 ? otherPct : 0.1, color: Colors.grey.shade400, radius: 30, showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          _buildLegendRow(
            appLoc?.translate("Healthy") ?? "Healthy", healthyPct, Colors.green.shade400, 
            appLoc?.translate("Diseased") ?? "Diseased", diseasedPct, Colors.red.shade400, 
            isDark
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label1, double val1, Color col1, String label2, double val2, Color col2, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem(label1, val1, col1, isDark),
        _legendItem(label2, val2, col2, isDark),
      ],
    );
  }

  Widget _legendItem(String label, double val, Color color, bool isDark) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text("$label: ${val.toStringAsFixed(0)}%", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
      ],
    );
  }

  Widget _buildNoDataState(bool isDark, AppLocalizations? appLoc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: isDark ? Colors.white12 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(appLoc?.translate("No scan history found for vegetables.") ?? "No scan history found for vegetables.", 
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
        ],
      ),
    );
  }
}
