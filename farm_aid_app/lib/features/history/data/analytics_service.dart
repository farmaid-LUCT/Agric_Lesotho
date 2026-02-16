class AnalyticsService {
  /// Generates data points for the 7-day health trend chart.
  /// 'date': The day of the record
  /// 'risk': A double between 0.0 and 1.0 representing disease probability
  static List<Map<String, dynamic>> getMockTrendData() {
    final now = DateTime.now();
    return [
      {"date": now.subtract(const Duration(days: 6)), "risk": 0.15},
      {"date": now.subtract(const Duration(days: 5)), "risk": 0.22},
      {"date": now.subtract(const Duration(days: 4)), "risk": 0.35},
      {"date": now.subtract(const Duration(days: 3)), "risk": 0.78}, // Simulation of a spike
      {"date": now.subtract(const Duration(days: 2)), "risk": 0.55},
      {"date": now.subtract(const Duration(days: 1)), "risk": 0.62},
      {"date": now, "risk": 0.82}, // Current high risk
    ];
  }

  /// Use this later to calculate risk based on real scan counts
  static double calculateRiskFromData(int diseasedCount, int total) {
    if (total == 0) return 0.0;
    return (diseasedCount / total).clamp(0.0, 1.0);
  }
}