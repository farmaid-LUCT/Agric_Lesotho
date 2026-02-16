
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'dart:ui';
// import 'package:provider/provider.dart';
// import 'package:farm_aid_app/services/theme_provider.dart'; // Ensure this path is correct

// class WeatherServicePage extends StatefulWidget {
//   const WeatherServicePage({super.key});

//   @override
//   _WeatherServicePageState createState() => _WeatherServicePageState();
// }

// class _WeatherServicePageState extends State<WeatherServicePage> {
//   String temp = "0";
//   String location = "Locating...";
//   String condition = "Loading...";
//   String humidity = "0%";
//   String pressure = "0";
//   String visibility = "0 km";
//   String rainfall = "0mm";
//   String windSpeed = "0 km/h";
//   String uvIndex = "Low";
  
//   String sunsetTime = "18:00";
//   String sunriseTime = "06:00";
//   double dayProgress = 0.5;
//   String moonPhaseName = "Crescent";
  
//   List hourlyForecast = [];
//   List dailyForecast = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchRealWeather();
//   }

//   // Logic to determine icon color based on weather - slightly adjusted for visibility in dark mode
//   Color _getWeatherThemeColor(String cond, bool isDark) {
//     String c = cond.toLowerCase();
//     if (c.contains("clear") || c.contains("sun")) return Colors.orange.shade400;
//     if (c.contains("cloud")) return isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade400;
//     if (c.contains("rain") || c.contains("storm")) return Colors.blue.shade400;
//     return const Color(0xFF4CAF50); // Lighter Green for dark mode visibility
//   }

//   Future<void> _fetchRealWeather() async {
//     setState(() => isLoading = true);
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       const apiKey = "9ccb07032dd4d3480d8e3d0dbadbe8a5"; 
//       final url = "https://api.openweathermap.org/data/2.5/forecast?lat=${pos.latitude}&lon=${pos.longitude}&units=metric&appid=$apiKey";
      
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final city = data['city'];
//         final current = data['list'][0];

//         int sunriseUnix = city['sunrise'];
//         int sunsetUnix = city['sunset'];
//         int nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//         double progress = (nowUnix - sunriseUnix) / (sunsetUnix - sunriseUnix);

//         setState(() {
//           location = city['name'];
//           temp = "${current['main']['temp'].round()}";
//           condition = current['weather'][0]['main'];
//           humidity = "${current['main']['humidity']}%";
//           pressure = "${current['main']['pressure']} hPa";
//           visibility = "${(current['visibility'] / 1000).toStringAsFixed(1)} km";
//           windSpeed = "${current['wind']['speed']} km/h";
//           var rainVal = current['rain'] != null ? current['rain']['3h'] ?? 0 : 0;
//           rainfall = "${rainVal}mm"; 

//           int clouds = current['clouds']['all'];
//           if (clouds < 20) uvIndex = "High";
//           else if (clouds < 60) uvIndex = "Moderate";
//           else uvIndex = "Low";

//           sunriseTime = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sunriseUnix * 1000));
//           sunsetTime = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sunsetUnix * 1000));
//           dayProgress = progress.clamp(0.0, 1.0);
//           moonPhaseName = _calculateMoonPhase();
//           hourlyForecast = data['list'].take(8).toList(); 
//           dailyForecast = [];
//           for (int i = 0; i < data['list'].length; i += 8) {
//             dailyForecast.add(data['list'][i]);
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint("Weather Error: $e");
//       setState(() => location = "Maseru");
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   String _calculateMoonPhase() {
//     DateTime now = DateTime.now();
//     double lp = 2551443; 
//     DateTime newMoon = DateTime(1970, 1, 7, 20, 35);
//     double phase = ((now.difference(newMoon).inSeconds) % lp) / lp;
//     if (phase < 0.06 || phase > 0.94) return "New Moon";
//     if (phase < 0.5) return "Waxing";
//     return "Waning";
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProv = Provider.of<ThemeProvider>(context);
//     final isDark = themeProv.isDarkMode;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: isLoading 
//         ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
//         : ListView(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             children: [
//               const SizedBox(height: 60),
//               _buildHeader(isDark),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Hourly Forecast"),
//               _buildHourlySection(isDark),
//               const SizedBox(height: 20),
//               _buildSectionTitle("5-Day Forecast"),
//               _build7DayForecast(isDark),
//               const SizedBox(height: 20),
//               _buildDetailGrid(),
//               const SizedBox(height: 20),
//               _buildSectionTitle("Daylight Path"),
//               _buildSunPathCard(isDark),
//               const SizedBox(height: 20),
//               _buildMoonSection(isDark),
//               const SizedBox(height: 40),
//             ],
//           ),
//     );
//   }

//   Widget _buildHeader(bool isDark) {
//     return Column(
//       children: [
//         Text(location, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1B5E20), fontSize: 26, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 5),
//         Text("$temp°", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF212121), fontSize: 80, fontWeight: FontWeight.w200)),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           decoration: BoxDecoration(
//             color: _getWeatherThemeColor(condition, isDark).withOpacity(0.15),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             condition.toUpperCase(),
//             style: TextStyle(color: _getWeatherThemeColor(condition, isDark), fontWeight: FontWeight.bold, letterSpacing: 1.2),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHourlySection(bool isDark) {
//     return _cleanCard(
//       child: SizedBox(
//         height: 100,
//         child: ListView.builder(
//           scrollDirection: Axis.horizontal,
//           itemCount: hourlyForecast.length,
//           itemBuilder: (context, i) {
//             final item = hourlyForecast[i];
//             String hourCond = item['weather'][0]['main'];
//             return SizedBox(
//               width: 70,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(DateFormat('HH:mm').format(DateTime.parse(item['dt_txt'])), 
//                     style: TextStyle(color: isDark ? Colors.white70 : Colors.black45, fontSize: 11)),
//                   Image.network(
//                     "https://openweathermap.org/img/wn/${item['weather'][0]['icon']}.png", 
//                     width: 35,
//                     color: _getWeatherThemeColor(hourCond, isDark),
//                     colorBlendMode: BlendMode.srcIn,
//                   ),
//                   Text("${item['main']['temp'].round()}°", 
//                     style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _build7DayForecast(bool isDark) {
//     return _cleanCard(
//       child: Column(
//         children: dailyForecast.map((day) {
//           String dayCond = day['weather'][0]['main'];
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10.0),
//             child: Row(
//               children: [
//                 Expanded(child: Text(DateFormat('EEEE').format(DateTime.parse(day['dt_txt'])), 
//                   style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500))),
//                 Image.network(
//                   "https://openweathermap.org/img/wn/${day['weather'][0]['icon']}.png", 
//                   width: 30,
//                   color: _getWeatherThemeColor(dayCond, isDark),
//                   colorBlendMode: BlendMode.srcIn,
//                 ),
//                 const SizedBox(width: 20),
//                 Text("${day['main']['temp'].round()}°C", 
//                   style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildDetailGrid() {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 1.7,
//       mainAxisSpacing: 12, crossAxisSpacing: 12,
//       children: [
//         _detailTile("UV Index", uvIndex, Icons.wb_sunny_outlined),
//         _detailTile("Humidity", humidity, Icons.water_drop_outlined),
//         _detailTile("Wind", windSpeed, Icons.air),
//         _detailTile("Pressure", pressure, Icons.speed),
//         _detailTile("Visibility", visibility, Icons.visibility_outlined),
//         _detailTile("Rainfall", rainfall, Icons.umbrella_outlined),
//       ],
//     );
//   }

//   Widget _detailTile(String label, String val, IconData icon) {
//     bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
//     return _cleanCard(
//       padding: 12,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38), 
//             const SizedBox(width: 5), 
//             Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11))
//           ]),
//           const Spacer(),
//           Text(val, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _buildSunPathCard(bool isDark) {
//     return _cleanCard(
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text("Sunrise: $sunriseTime", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
//               Text("Sunset: $sunsetTime", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
//             ],
//           ),
//           const SizedBox(height: 15),
//           SizedBox(height: 40, width: double.infinity, 
//             child: CustomPaint(painter: SunPathPainter(progress: dayProgress, isDark: isDark))),
//         ],
//       ),
//     );
//   }

//   Widget _buildMoonSection(bool isDark) {
//     return _cleanCard(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.nightlight_round, color: isDark ? Colors.blue.shade200 : Colors.blueGrey.shade700, size: 20),
//           const SizedBox(width: 10),
//           Text("Moon Phase: $moonPhaseName", 
//             style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }

//   Widget _cleanCard({required Widget child, double padding = 15}) {
//     return Container(
//       padding: EdgeInsets.all(padding),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor, 
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
//     return Padding(
//       padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
//       child: Text(title, style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), fontSize: 15, fontWeight: FontWeight.bold)),
//     );
//   }
// }

// class SunPathPainter extends CustomPainter {
//   final double progress;
//   final bool isDark;
//   SunPathPainter({required this.progress, required this.isDark});
//   @override
//   void paint(Canvas canvas, Size size) {
//     var paint = Paint()
//       ..color = isDark ? Colors.white12 : Colors.black12
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;
//     var path = Path();
//     path.moveTo(0, size.height);
//     path.quadraticBezierTo(size.width / 2, -size.height, size.width, size.height);
//     canvas.drawPath(path, paint);
//     double x = size.width * progress;
//     double y = size.height - (4 * size.height * progress * (1 - progress));
//     canvas.drawCircle(Offset(x, y), 6, Paint()..color = isDark ? Colors.yellow.shade400 : Colors.orange.shade600);
//   }
//   @override bool shouldRepaint(CustomPainter oldDelegate) => true;
// }

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'dart:ui';
// import 'package:provider/provider.dart';
// import 'package:farm_aid_app/services/theme_provider.dart';

// class WeatherServicePage extends StatefulWidget {
//   const WeatherServicePage({super.key});

//   @override
//   _WeatherServicePageState createState() => _WeatherServicePageState();
// }

// class _WeatherServicePageState extends State<WeatherServicePage> {
//   String temp = "0";
//   String location = "Locating...";
//   String condition = "Loading...";
//   String humidity = "0%";
//   String pressure = "0";
//   String visibility = "0 km";
//   String rainfall = "0mm";
//   String windSpeed = "0 km/h";
//   String uvIndex = "Low";

//   String sunsetTime = "18:00";
//   String sunriseTime = "06:00";
//   double dayProgress = 0.5;
//   String moonPhaseName = "Crescent";

//   List hourlyForecast = [];
//   List dailyForecast = [];
//   bool isLoading = true;

//   double globalMin = 0;
//   double globalMax = 100;

//   @override
//   void initState() {
//     super.initState();
//     _fetchRealWeather();
//   }

//   // --- AMAZING FEATURE LOGIC ---
//   Map<String, dynamic> get sprayLogic {
//     double wind = double.tryParse(windSpeed.split(' ')[0]) ?? 0;
//     bool isRaining = rainfall != "0mm";
//     if (isRaining) return {"status": "NO SPRAY", "color": Colors.red, "msg": "Rain will wash away medicine."};
//     if (wind > 15) return {"status": "WINDY", "color": Colors.orange, "msg": "Too windy; spray will drift."};
//     return {"status": "SAFE", "color": Colors.green, "msg": "Perfect conditions for spraying."};
//   }

//   Map<String, dynamic> get plantComfort {
//     double t = double.tryParse(temp) ?? 0;
//     int h = int.tryParse(humidity.replaceAll('%', '')) ?? 0;
//     if (t > 30) return {"score": "STRESS", "color": Colors.red, "icon": Icons.sentiment_very_dissatisfied};
//     if (t < 5) return {"score": "COLD", "color": Colors.blue, "icon": Icons.ac_unit};
//     if (h > 80 && t > 25) return {"score": "HUMID", "color": Colors.orange, "icon": Icons.wb_cloudy};
//     return {"score": "IDEAL", "color": Colors.green, "icon": Icons.auto_awesome};
//   }

//   double get waterLossProgress {
//     double t = double.tryParse(temp) ?? 0;
//     double w = double.tryParse(windSpeed.split(' ')[0]) ?? 0;
//     double loss = ((t * 1.5) + (w * 2)) / 100;
//     return loss.clamp(0.1, 1.0);
//   }

//   Color _getWeatherThemeColor(String cond, bool isDark) {
//     String c = cond.toLowerCase();
//     if (c.contains("clear") || c.contains("sun")) return Colors.orange.shade400;
//     if (c.contains("cloud")) return isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade400;
//     if (c.contains("rain") || c.contains("storm")) return Colors.blue.shade400;
//     return const Color(0xFF4CAF50);
//   }

//   Future<void> _fetchRealWeather() async {
//     setState(() => isLoading = true);
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       const apiKey = "9ccb07032dd4d3480d8e3d0dbadbe8a5";
//       final url = "https://api.openweathermap.org/data/2.5/forecast?lat=${pos.latitude}&lon=${pos.longitude}&units=metric&appid=$apiKey";

//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final city = data['city'];
//         final current = data['list'][0];

//         int sunriseUnix = city['sunrise'];
//         int sunsetUnix = city['sunset'];
//         int nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//         double progress = (nowUnix - sunriseUnix) / (sunsetUnix - sunriseUnix);

//         List tempDaily = [];
//         double minFound = 100;
//         double maxFound = -100;

//         for (int i = 0; i < data['list'].length; i += 8) {
//           var dayData = data['list'][i];
//           tempDaily.add(dayData);
//           double dayLow = dayData['main']['temp_min'].toDouble();
//           double dayHigh = dayData['main']['temp_max'].toDouble();
//           if (dayLow < minFound) minFound = dayLow;
//           if (dayHigh > maxFound) maxFound = dayHigh;
//         }

//         setState(() {
//           location = city['name'];
//           temp = "${current['main']['temp'].round()}";
//           condition = current['weather'][0]['main'];
//           humidity = "${current['main']['humidity']}%";
//           pressure = "${current['main']['pressure']} hPa";
//           visibility = "${(current['visibility'] / 1000).toStringAsFixed(1)} km";
//           windSpeed = "${current['wind']['speed']} km/h";
//           var rainVal = current['rain'] != null ? current['rain']['3h'] ?? 0 : 0;
//           rainfall = "${rainVal}mm";

//           int clouds = current['clouds']['all'];
//           if (clouds < 20) uvIndex = "High";
//           else if (clouds < 60) uvIndex = "Moderate";
//           else uvIndex = "Low";

//           sunriseTime = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sunriseUnix * 1000));
//           sunsetTime = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sunsetUnix * 1000));
//           dayProgress = progress.clamp(0.0, 1.0);
//           moonPhaseName = _calculateMoonPhase();
//           hourlyForecast = data['list'].take(8).toList();
//           dailyForecast = tempDaily;
//           globalMin = minFound;
//           globalMax = maxFound;
//         });
//       }
//     } catch (e) {
//       debugPrint("Weather Error: $e");
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   String _calculateMoonPhase() {
//     DateTime now = DateTime.now();
//     double lp = 2551443;
//     DateTime newMoon = DateTime(1970, 1, 7, 20, 35);
//     double phase = ((now.difference(newMoon).inSeconds) % lp) / lp;
//     if (phase < 0.06 || phase > 0.94) return "New Moon";
//     if (phase < 0.5) return "Waxing";
//     return "Waning";
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProv = Provider.of<ThemeProvider>(context);
//     final isDark = themeProv.isDarkMode;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: isLoading
//           ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
//           : ListView(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               children: [
//                 const SizedBox(height: 60),
//                 _buildHeader(isDark),
//                 const SizedBox(height: 30),
//                 _buildAmazingFeaturesRow(isDark),
//                 const SizedBox(height: 20),
//                 _buildSectionTitle("Hourly Forecast"),
//                 _buildHourlySection(isDark),
//                 const SizedBox(height: 20),
//                 _buildSectionTitle("5-Day Forecast"),
//                 _buildModern5DayForecast(isDark),
//                 const SizedBox(height: 20),
//                 _buildDetailGrid(),
//                 const SizedBox(height: 20),
//                 _buildSectionTitle("Daylight Path"),
//                 _buildSunPathCard(isDark),
//                 const SizedBox(height: 20),
//                 _buildMoonSection(isDark),
//                 const SizedBox(height: 40),
//               ],
//             ),
//     );
//   }

//   Widget _buildModern5DayForecast(bool isDark) {
//     return _cleanCard(
//       padding: 0,
//       child: Column(
//         children: dailyForecast.asMap().entries.map((entry) {
//           int index = entry.key;
//           var day = entry.value;
//           DateTime date = DateTime.parse(day['dt_txt']);
//           String dayLabel = index == 0 ? "Today" : DateFormat('EEE').format(date);
//           double low = day['main']['temp_min'].toDouble();
//           double high = day['main']['temp_max'].toDouble();
//           double current = index == 0 ? double.tryParse(temp) ?? low : -100;

//           return Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               border: index == dailyForecast.length - 1 ? null : Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
//             ),
//             child: Row(
//               children: [
//                 SizedBox(
//                   width: 50,
//                   child: Text(dayLabel, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
//                 ),
//                 Image.network(
//                   "https://openweathermap.org/img/wn/${day['weather'][0]['icon']}.png",
//                   width: 30,
//                 ),
//                 const SizedBox(width: 10),
//                 Text("${low.round()}°", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 16)),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: _buildTempBar(low, high, current, isDark),
//                   ),
//                 ),
//                 Text("${high.round()}°", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildTempBar(double dayLow, double dayHigh, double current, bool isDark) {
//     double totalRange = globalMax - globalMin;
//     if (totalRange <= 0) totalRange = 1;
//     double leftPaddingFactor = (dayLow - globalMin) / totalRange;
//     double barWidthFactor = (dayHigh - dayLow) / totalRange;

//     return Container(
//       height: 4,
//       decoration: BoxDecoration(
//         color: isDark ? Colors.white10 : Colors.black12,
//         borderRadius: BorderRadius.circular(2),
//       ),
//       child: Stack(
//         children: [
//           Align(
//             alignment: Alignment(leftPaddingFactor * 2 - 1 + barWidthFactor, 0),
//             child: FractionallySizedBox(
//               widthFactor: barWidthFactor.clamp(0.05, 1.0),
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(2),
//                   gradient: const LinearGradient(
//                     colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           if (current != -100)
//             Align(
//               alignment: Alignment(((current - globalMin) / totalRange) * 2 - 1, 0),
//               child: Container(
//                 width: 7,
//                 height: 7,
//                 decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 2)]),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAmazingFeaturesRow(bool isDark) {
//     final spray = sprayLogic;
//     final comfort = plantComfort;

//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: _cleanCard(
//                 padding: 12,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.opacity, size: 16, color: spray['color']),
//                         const SizedBox(width: 5),
//                         Text("Spray Window", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Text(spray['status'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: spray['color'])),
//                     Text(spray['msg'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _cleanCard(
//                 padding: 12,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(comfort['icon'], size: 16, color: comfort['color']),
//                         const SizedBox(width: 5),
//                         Text("Plant Comfort", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Text(comfort['score'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: comfort['color'])),
//                     const Text("Vegetable Stress Level", style: TextStyle(fontSize: 10, color: Colors.grey)),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         _cleanCard(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text("Soil Water Loss (Evaporation)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
//                   Text("${(waterLossProgress * 100).round()}%", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               LinearProgressIndicator(
//                 value: waterLossProgress,
//                 backgroundColor: isDark ? Colors.white10 : Colors.black12,
//                 color: Colors.blueAccent,
//                 minHeight: 8,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               const SizedBox(height: 5),
//               const Text("High wind and heat increase thirst.", style: TextStyle(fontSize: 10, color: Colors.grey)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader(bool isDark) {
//     return Column(
//       children: [
//         Text(location, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1B5E20), fontSize: 26, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 5),
//         Text("$temp°", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF212121), fontSize: 80, fontWeight: FontWeight.w200)),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           decoration: BoxDecoration(
//             color: _getWeatherThemeColor(condition, isDark).withOpacity(0.15),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             condition.toUpperCase(),
//             style: TextStyle(color: _getWeatherThemeColor(condition, isDark), fontWeight: FontWeight.bold, letterSpacing: 1.2),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHourlySection(bool isDark) {
//     return _cleanCard(
//       child: SizedBox(
//         height: 100,
//         child: ListView.builder(
//           scrollDirection: Axis.horizontal,
//           itemCount: hourlyForecast.length,
//           itemBuilder: (context, i) {
//             final item = hourlyForecast[i];
//             String hourCond = item['weather'][0]['main'];
//             return SizedBox(
//               width: 70,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(DateFormat('HH:mm').format(DateTime.parse(item['dt_txt'])), 
//                     style: TextStyle(color: isDark ? Colors.white70 : Colors.black45, fontSize: 11)),
//                   Image.network(
//                     "https://openweathermap.org/img/wn/${item['weather'][0]['icon']}.png", 
//                     width: 35,
//                     color: _getWeatherThemeColor(hourCond, isDark),
//                     colorBlendMode: BlendMode.srcIn,
//                   ),
//                   Text("${item['main']['temp'].round()}°", 
//                     style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailGrid() {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 1.7,
//       mainAxisSpacing: 12, crossAxisSpacing: 12,
//       children: [
//         _detailTile("UV Index", uvIndex, Icons.wb_sunny_outlined),
//         _detailTile("Humidity", humidity, Icons.water_drop_outlined),
//         _detailTile("Wind", windSpeed, Icons.air),
//         _detailTile("Pressure", pressure, Icons.speed),
//         _detailTile("Visibility", visibility, Icons.visibility_outlined),
//         _detailTile("Rainfall", rainfall, Icons.umbrella_outlined),
//       ],
//     );
//   }

//   Widget _detailTile(String label, String val, IconData icon) {
//     bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
//     return _cleanCard(
//       padding: 12,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38), 
//             const SizedBox(width: 5), 
//             Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11))
//           ]),
//           const Spacer(),
//           Text(val, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _buildSunPathCard(bool isDark) {
//     return _cleanCard(
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text("Sunrise: $sunriseTime", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
//               Text("Sunset: $sunsetTime", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
//             ],
//           ),
//           const SizedBox(height: 15),
//           SizedBox(height: 40, width: double.infinity, 
//             child: CustomPaint(painter: SunPathPainter(progress: dayProgress, isDark: isDark))),
//         ],
//       ),
//     );
//   }

//   Widget _buildMoonSection(bool isDark) {
//     return _cleanCard(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.nightlight_round, color: isDark ? Colors.blue.shade200 : Colors.blueGrey.shade700, size: 20),
//           const SizedBox(width: 10),
//           Text("Moon Phase: $moonPhaseName", 
//             style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }

//   Widget _cleanCard({required Widget child, double padding = 15}) {
//     return Container(
//       padding: EdgeInsets.all(padding),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor, 
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
//     return Padding(
//       padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
//       child: Text(title, style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), fontSize: 15, fontWeight: FontWeight.bold)),
//     );
//   }
// }

// // --- CRITICAL: THE PAINTER CLASS (Fixed missing code) ---
// class SunPathPainter extends CustomPainter {
//   final double progress;
//   final bool isDark;
//   SunPathPainter({required this.progress, required this.isDark});

//   @override
//   void paint(Canvas canvas, Size size) {
//     var paint = Paint()
//       ..color = isDark ? Colors.white12 : Colors.black12
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;

//     var path = Path();
//     path.moveTo(0, size.height);
//     path.quadraticBezierTo(size.width / 2, -size.height, size.width, size.height);
//     canvas.drawPath(path, paint);

//     // Calculate sun position on the curve
//     double x = size.width * progress;
//     double y = size.height - (4 * size.height * progress * (1 - progress));

//     canvas.drawCircle(
//       Offset(x, y), 
//       6, 
//       Paint()..color = isDark ? Colors.yellow.shade400 : Colors.orange.shade600
//     );
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:farm_aid_app/services/theme_provider.dart';
import '../../../core/app_localizations.dart'; // ✅ Added for localization

class WeatherServicePage extends StatefulWidget {
  const WeatherServicePage({super.key});

  @override
  _WeatherServicePageState createState() => _WeatherServicePageState();
}

class _WeatherServicePageState extends State<WeatherServicePage> {
  String temp = "0";
  String location = "Locating...";
  String condition = "Loading...";
  String humidity = "0%";
  String pressure = "0";
  String visibility = "0 km";
  String rainfall = "0mm";
  String windSpeed = "0 km/h";
  String uvIndex = "Low";

  String sunsetTime = "18:00";
  String sunriseTime = "06:00";
  double dayProgress = 0.5;
  String moonPhaseName = "Crescent";

  List hourlyForecast = [];
  List dailyForecast = [];
  bool isLoading = true;

  double globalMin = 0;
  double globalMax = 100;

  @override
  void initState() {
    super.initState();
    _fetchRealWeather();
  }

  // --- AMAZING FEATURE LOGIC ---
  Map<String, dynamic> get sprayLogic {
    final appLoc = AppLocalizations.of(context);
    double wind = double.tryParse(windSpeed.split(' ')[0]) ?? 0;
    bool isRaining = rainfall != "0mm";

    if (isRaining) {
      return {
        "status": appLoc?.translate("NO SPRAY") ?? "NO SPRAY",
        "color": Colors.red,
        "msg": appLoc?.translate("Rain will wash away medicine.") ?? "Rain will wash away medicine."
      };
    }
    if (wind > 15) {
      return {
        "status": appLoc?.translate("WINDY") ?? "WINDY",
        "color": Colors.orange,
        "msg": appLoc?.translate("Too windy; spray will drift.") ?? "Too windy; spray will drift."
      };
    }
    return {
      "status": appLoc?.translate("SAFE") ?? "SAFE",
      "color": Colors.green,
      "msg": appLoc?.translate("Perfect conditions for spraying.") ?? "Perfect conditions for spraying."
    };
  }

  Map<String, dynamic> get plantComfort {
    final appLoc = AppLocalizations.of(context);
    double t = double.tryParse(temp) ?? 0;
    int h = int.tryParse(humidity.replaceAll('%', '')) ?? 0;

    if (t > 30) return {"score": appLoc?.translate("STRESS") ?? "STRESS", "color": Colors.red, "icon": Icons.sentiment_very_dissatisfied};
    if (t < 5) return {"score": appLoc?.translate("COLD") ?? "COLD", "color": Colors.blue, "icon": Icons.ac_unit};
    if (h > 80 && t > 25) return {"score": appLoc?.translate("HUMID") ?? "HUMID", "color": Colors.orange, "icon": Icons.wb_cloudy};
    return {"score": appLoc?.translate("IDEAL") ?? "IDEAL", "color": Colors.green, "icon": Icons.auto_awesome};
  }

  double get waterLossProgress {
    double t = double.tryParse(temp) ?? 0;
    double w = double.tryParse(windSpeed.split(' ')[0]) ?? 0;
    double loss = ((t * 1.5) + (w * 2)) / 100;
    return loss.clamp(0.1, 1.0);
  }

  Color _getWeatherThemeColor(String cond, bool isDark) {
    String c = cond.toLowerCase();
    if (c.contains("clear") || c.contains("sun")) return Colors.orange.shade400;
    if (c.contains("cloud")) return isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade400;
    if (c.contains("rain") || c.contains("storm")) return Colors.blue.shade400;
    return const Color(0xFF4CAF50);
  }

  Future<void> _fetchRealWeather() async {
    setState(() => isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      const apiKey = "9ccb07032dd4d3480d8e3d0dbadbe8a5";
      final url = "https://api.openweathermap.org/data/2.5/forecast?lat=${pos.latitude}&lon=${pos.longitude}&units=metric&appid=$apiKey";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['city'];
        final current = data['list'][0];

        int sunriseUnix = city['sunrise'];
        int sunsetUnix = city['sunset'];
        int nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        double progress = (nowUnix - sunriseUnix) / (sunsetUnix - sunriseUnix);

        List tempDaily = [];
        double minFound = 100;
        double maxFound = -100;

        for (int i = 0; i < data['list'].length; i += 8) {
          var dayData = data['list'][i];
          tempDaily.add(dayData);
          double dayLow = dayData['main']['temp_min'].toDouble();
          double dayHigh = dayData['main']['temp_max'].toDouble();
          if (dayLow < minFound) minFound = dayLow;
          if (dayHigh > maxFound) maxFound = dayHigh;
        }

        setState(() {
          location = city['name'];
          temp = "${current['main']['temp'].round()}";
          condition = current['weather'][0]['main'];
          humidity = "${current['main']['humidity']}%";
          pressure = "${current['main']['pressure']} hPa";
          visibility = "${(current['visibility'] / 1000).toStringAsFixed(1)} km";
          windSpeed = "${current['wind']['speed']} km/h";
          var rainVal = current['rain'] != null ? current['rain']['3h'] ?? 0 : 0;
          rainfall = "${rainVal}mm";

          int clouds = current['clouds']['all'];
          if (clouds < 20) uvIndex = "High";
          else if (clouds < 60) uvIndex = "Moderate";
          else uvIndex = "Low";

          sunriseTime = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sunriseUnix * 1000));
          sunsetTime = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sunsetUnix * 1000));
          dayProgress = progress.clamp(0.0, 1.0);
          moonPhaseName = _calculateMoonPhase();
          hourlyForecast = data['list'].take(8).toList();
          dailyForecast = tempDaily;
          globalMin = minFound;
          globalMax = maxFound;
        });
      }
    } catch (e) {
      debugPrint("Weather Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _calculateMoonPhase() {
    DateTime now = DateTime.now();
    double lp = 2551443;
    DateTime newMoon = DateTime(1970, 1, 7, 20, 35);
    double phase = ((now.difference(newMoon).inSeconds) % lp) / lp;
    if (phase < 0.06 || phase > 0.94) return "New Moon";
    if (phase < 0.5) return "Waxing";
    return "Waning";
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;
    final appLoc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 60),
                _buildHeader(isDark),
                const SizedBox(height: 30),
                _buildAmazingFeaturesRow(isDark, appLoc),
                const SizedBox(height: 20),
                _buildSectionTitle(appLoc?.translate("Hourly Forecast") ?? "Hourly Forecast"),
                _buildHourlySection(isDark),
                const SizedBox(height: 20),
                _buildSectionTitle(appLoc?.translate("5-Day Forecast") ?? "5-Day Forecast"),
                _buildModern5DayForecast(isDark, appLoc),
                const SizedBox(height: 20),
                _buildDetailGrid(appLoc),
                const SizedBox(height: 20),
                _buildSectionTitle(appLoc?.translate("Daylight Path") ?? "Daylight Path"),
                _buildSunPathCard(isDark, appLoc),
                const SizedBox(height: 20),
                _buildMoonSection(isDark, appLoc),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildModern5DayForecast(bool isDark, AppLocalizations? appLoc) {
    return _cleanCard(
      padding: 0,
      child: Column(
        children: dailyForecast.asMap().entries.map((entry) {
          int index = entry.key;
          var day = entry.value;
          DateTime date = DateTime.parse(day['dt_txt']);
          String dayLabel = index == 0 ? (appLoc?.translate("Today") ?? "Today") : DateFormat('EEE').format(date);
          double low = day['main']['temp_min'].toDouble();
          double high = day['main']['temp_max'].toDouble();
          double current = index == 0 ? double.tryParse(temp) ?? low : -100;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: index == dailyForecast.length - 1 ? null : Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(dayLabel, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                ),
                Image.network(
                  "https://openweathermap.org/img/wn/${day['weather'][0]['icon']}.png",
                  width: 30,
                ),
                const SizedBox(width: 10),
                Text("${low.round()}°", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 16)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _buildTempBar(low, high, current, isDark),
                  ),
                ),
                Text("${high.round()}°", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTempBar(double dayLow, double dayHigh, double current, bool isDark) {
    double totalRange = globalMax - globalMin;
    if (totalRange <= 0) totalRange = 1;
    double leftPaddingFactor = (dayLow - globalMin) / totalRange;
    double barWidthFactor = (dayHigh - dayLow) / totalRange;

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment(leftPaddingFactor * 2 - 1 + barWidthFactor, 0),
            child: FractionallySizedBox(
              widthFactor: barWidthFactor.clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
                  ),
                ),
              ),
            ),
          ),
          if (current != -100)
            Align(
              alignment: Alignment(((current - globalMin) / totalRange) * 2 - 1, 0),
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 2)]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmazingFeaturesRow(bool isDark, AppLocalizations? appLoc) {
    final spray = sprayLogic;
    final comfort = plantComfort;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _cleanCard(
                padding: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.opacity, size: 16, color: spray['color']),
                        const SizedBox(width: 5),
                        Text(appLoc?.translate("Spray Window") ?? "Spray Window", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(spray['status'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: spray['color'])),
                    Text(spray['msg'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _cleanCard(
                padding: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(comfort['icon'], size: 16, color: comfort['color']),
                        const SizedBox(width: 5),
                        Text(appLoc?.translate("Plant Comfort") ?? "Plant Comfort", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(comfort['score'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: comfort['color'])),
                    Text(appLoc?.translate("Vegetable Stress Level") ?? "Vegetable Stress Level", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _cleanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(appLoc?.translate("Soil Water Loss (Evaporation)") ?? "Soil Water Loss (Evaporation)", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text("${(waterLossProgress * 100).round()}%", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: waterLossProgress,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                color: Colors.blueAccent,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 5),
              Text(appLoc?.translate("High wind and heat increase thirst.") ?? "High wind and heat increase thirst.", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text(location, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1B5E20), fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text("$temp°", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF212121), fontSize: 80, fontWeight: FontWeight.w200)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getWeatherThemeColor(condition, isDark).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            condition.toUpperCase(),
            style: TextStyle(color: _getWeatherThemeColor(condition, isDark), fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlySection(bool isDark) {
    return _cleanCard(
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: hourlyForecast.length,
          itemBuilder: (context, i) {
            final item = hourlyForecast[i];
            String hourCond = item['weather'][0]['main'];
            return SizedBox(
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('HH:mm').format(DateTime.parse(item['dt_txt'])), 
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black45, fontSize: 11)),
                  Image.network(
                    "https://openweathermap.org/img/wn/${item['weather'][0]['icon']}.png", 
                    width: 35,
                    color: _getWeatherThemeColor(hourCond, isDark),
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  Text("${item['main']['temp'].round()}°", 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailGrid(AppLocalizations? appLoc) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.7,
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      children: [
        _detailTile(appLoc?.translate("UV Index") ?? "UV Index", uvIndex, Icons.wb_sunny_outlined),
        _detailTile(appLoc?.translate("Humidity") ?? "Humidity", humidity, Icons.water_drop_outlined),
        _detailTile(appLoc?.translate("Wind") ?? "Wind", windSpeed, Icons.air),
        _detailTile(appLoc?.translate("Pressure") ?? "Pressure", pressure, Icons.speed),
        _detailTile(appLoc?.translate("Visibility") ?? "Visibility", visibility, Icons.visibility_outlined),
        _detailTile(appLoc?.translate("Rainfall") ?? "Rainfall", rainfall, Icons.umbrella_outlined),
      ],
    );
  }

  Widget _detailTile(String label, String val, IconData icon) {
    bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return _cleanCard(
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38), 
            const SizedBox(width: 5), 
            Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11))
          ]),
          const Spacer(),
          Text(val, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSunPathCard(bool isDark, AppLocalizations? appLoc) {
    String sunriseLabel = appLoc?.translate("Sunrise: {}") ?? "Sunrise: $sunriseTime";
    String sunsetLabel = appLoc?.translate("Sunset: {}") ?? "Sunset: $sunsetTime";

    return _cleanCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sunriseLabel.replaceFirst("{}", sunriseTime), style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
              Text(sunsetLabel.replaceFirst("{}", sunsetTime), style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(height: 40, width: double.infinity, 
            child: CustomPaint(painter: SunPathPainter(progress: dayProgress, isDark: isDark))),
        ],
      ),
    );
  }

  Widget _buildMoonSection(bool isDark, AppLocalizations? appLoc) {
    String phaseLabel = appLoc?.translate("Moon Phase: {}") ?? "Moon Phase: $moonPhaseName";
    return _cleanCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.nightlight_round, color: isDark ? Colors.blue.shade200 : Colors.blueGrey.shade700, size: 20),
          const SizedBox(width: 10),
          Text(phaseLabel.replaceFirst("{}", moonPhaseName), 
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _cleanCard({required Widget child, double padding = 15}) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Text(title, style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }
}

class SunPathPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  SunPathPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    var path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, -size.height, size.width, size.height);
    canvas.drawPath(path, paint);

    double x = size.width * progress;
    double y = size.height - (4 * size.height * progress * (1 - progress));

    canvas.drawCircle(
      Offset(x, y), 
      6, 
      Paint()..color = isDark ? Colors.yellow.shade400 : Colors.orange.shade600
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}