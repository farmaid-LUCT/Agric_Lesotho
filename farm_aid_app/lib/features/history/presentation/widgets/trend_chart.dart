// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';

// class TrendChart extends StatelessWidget {
//   final List<Map<String, dynamic>> data;
//   final bool isDark;

//   const TrendChart({super.key, required this.data, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(builder: (context, constraints) {
//       return Padding(
//         padding: const EdgeInsets.only(right: 20, top: 10),
//         child: InteractiveViewer(
//           // Mimics Plotly's web zoom/pan functionality
//           boundaryMargin: const EdgeInsets.symmetric(horizontal: 20),
//           minScale: 1.0,
//           maxScale: 4.0,
//           child: LineChart(
//             LineChartData(
//               lineTouchData: _buildPlotlyTouchData(),
//               gridData: _buildGridData(),
//               titlesData: _buildTitlesData(), 
//               borderData: FlBorderData(show: false),
//               lineBarsData: [
//                 _buildPlotlyLine(isHealthy: true),  // Green Line (Molemo)
//                 _buildPlotlyLine(isHealthy: false), // Red Line (Kotsi)
//               ],
//               minY: 0,
//               maxY: 1.1, // Slight padding above 100%
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   // 1. TOOLTIPS: Plotly-style "Floating Info Box"
//   LineTouchData _buildPlotlyTouchData() {
//     return LineTouchData(
//       handleBuiltInTouches: true,
//       touchTooltipData: LineTouchTooltipData(
//         getTooltipColor: (touchedSpot) => isDark ? const Color(0xFF252525) : Colors.white,
//         tooltipRoundedRadius: 8,
//         tooltipPadding: const EdgeInsets.all(12),
//         tooltipBorder: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
//         getTooltipItems: (List<LineBarSpot> touchedSpots) {
//           return touchedSpots.map((spot) {
//             final isHealthy = spot.barIndex == 0;
//             final label = isHealthy ? "MOLEMO (HEALTH)" : "KOTSI (RISK)";
            
//             // FIX: Use spot.bar instead of spot.barData for fl_chart 0.70.x
//             final color = spot.bar.color ?? (isHealthy ? const Color(0xFF00E676) : const Color(0xFFFF5252));

//             return LineTooltipItem(
//               "$label\n",
//               TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
//               children: [
//                 TextSpan(
//                   text: "${(spot.y * 100).toInt()}%",
//                   style: TextStyle(
//                     color: isDark ? Colors.white : Colors.black,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//               ],
//             );
//           }).toList();
//         },
//       ),
//     );
//   }

//   // 2. STYLIZED LINES: Deep Gradients & Smooth Curves
//   LineChartBarData _buildPlotlyLine({required bool isHealthy}) {
//     final color = isHealthy ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    
//     return LineChartBarData(
//       spots: data.asMap().entries.map((e) {
//         // Logic: Health is 1.0 - Risk
//         double val = isHealthy ? (1.0 - (e.value['risk'] as double)) : (e.value['risk'] as double);
//         return FlSpot(e.key.toDouble(), val);
//       }).toList(),
//       isCurved: true,
//       curveSmoothness: 8,
//       color: color,
//       barWidth: 10,
//       isStrokeCapRound: true,
//       dotData: const FlDotData(show: false),
//       belowBarData: BarAreaData(
//         show: true,
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [color.withOpacity(0.2), color.withOpacity(0)],
//         ),
//       ),
//     );
//   }

//   // 3. AXIS TITLES: Clean and Minimalistic
//   FlTitlesData _buildTitlesData() {
//     return FlTitlesData(
//       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       bottomTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 30,
//           interval: 1, // Shows every day
//           getTitlesWidget: (value, meta) => Padding(
//             padding: const EdgeInsets.only(top: 8.0),
//             child: Text(
//               "Day ${value.toInt() + 1}",
//               style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10),
//             ),
//           ),
//         ),
//       ),
//       leftTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 40,
//           interval: 0.2, // Shows 20%, 40%, etc.
//           getTitlesWidget: (value, meta) => Text(
//             "${(value * 100).toInt()}%",
//             style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10),
//           ),
//         ),
//       ),
//     );
//   }

//   // 4. GRID: Subtle Background
//   FlGridData _buildGridData() {
//     return FlGridData(
//       show: true,
//       horizontalInterval: 0.2,
//       getDrawingHorizontalLine: (val) => FlLine(
//         color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
//         strokeWidth: 1,
//       ),
//       drawVerticalLine: false,
//     );
//   }
// }

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isDark;

  const TrendChart({super.key, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: const EdgeInsets.only(right: 10, top: 10),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.symmetric(horizontal: 20),
          minScale: 1.0,
          maxScale: 4.0,
          child: LineChart(
            LineChartData(
              lineTouchData: _buildPlotlyTouchData(),
              gridData: _buildGridData(),
              titlesData: _buildTitlesData(), 
              borderData: FlBorderData(show: false),
              lineBarsData: [
                _buildPlotlyLine(isHealthy: true),  // Green Line (Molemo)
                _buildPlotlyLine(isHealthy: false), // Red Line (Kotsi)
              ],
              minY: 0,
              maxY: 1.1, 
            ),
          ),
        ),
      );
    });
  }

  // 1. TOOLTIPS: Clamped to screen for "Plotly" feel
  LineTouchData _buildPlotlyTouchData() {
    return LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => isDark ? const Color(0xFF252525) : Colors.white,
        tooltipRoundedRadius: 12,
        tooltipPadding: const EdgeInsets.all(12),
        tooltipBorder: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        
        // Ensures the tooltip stays visible even when zoomed in
        fitInsideHorizontally: true, 
        fitInsideVertically: true,   
        tooltipMargin: 12,            

        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((spot) {
            final isHealthy = spot.barIndex == 0;
            final label = isHealthy ? "HEALTH" : "RISK)";
            final color = spot.bar.color ?? (isHealthy ? const Color(0xFF00E676) : const Color(0xFFFF5252));

            return LineTooltipItem(
              "$label\n",
              TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
              children: [
                TextSpan(
                  text: "${(spot.y * 100).toInt()}%",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  // 2. STYLIZED LINES: Gradients & Smooth Curves
  LineChartBarData _buildPlotlyLine({required bool isHealthy}) {
    final color = isHealthy ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    return LineChartBarData(
      spots: data.asMap().entries.map((e) {
        double val = isHealthy ? (1.0 - (e.value['risk'] as double)) : (e.value['risk'] as double);
        return FlSpot(e.key.toDouble(), val);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.35, 
      color: color,
      barWidth: 4,           
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true, 
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 2,
          strokeColor: isDark ? const Color(0xFF121212) : Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.15), color.withOpacity(0)],
        ),
      ),
    );
  }

  // 3. AXIS TITLES: Using raw Widgets to avoid SideTitleWidget parameter errors
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: 1,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "D${value.toInt() + 1}",
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38, 
                  fontSize: 10
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          interval: 0.2,
          getTitlesWidget: (value, meta) => Text(
            "${(value * 100).toInt()}%",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38, 
              fontSize: 10
            ),
          ),
        ),
      ),
    );
  }

  // 4. GRID: Clean horizontal lines
  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      horizontalInterval: 0.2,
      getDrawingHorizontalLine: (val) => FlLine(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        strokeWidth: 1,
      ),
      drawVerticalLine: false,
    );
  }
}