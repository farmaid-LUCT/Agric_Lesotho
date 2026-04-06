// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // Correct Imports
// import '../../weather/presentation/weather_service.dart';
// import '../../auth/presentation/login_screen.dart';
// import '../../../services/auth_service.dart';
// import '../../history/presentation/history_screen.dart';
// import '../../alerts/presentation/alerts_screen.dart';
// import '../../alerts/presentation/widgets/alert_bell_icon.dart';
// import '../../crops/presentation/crop_type_screen.dart';
// import './settings_screen.dart';
// import '../../../core/constants.dart';
// import '../../../core/app_localizations.dart';

// import '../../resources/presentation/resources_screen.dart';
// import '../../resources/presentation/planting_calendar_screen.dart';
// import '../../resources/presentation/market_prices_screen.dart';
// import '../../history/presentation/growth_journal_screen.dart';

// import 'widgets/scanner_section.dart';
// import '../../onboarding/presentation/tour_guide.dart';
// import '../../../services/weather_tip_service.dart';

// class HomeDashboard extends StatefulWidget {
//   final bool showTour;
//   const HomeDashboard({super.key, this.showTour = false});

//   @override
//   State<HomeDashboard> createState() => _HomeDashboardState();
// }

// class _HomeDashboardState extends State<HomeDashboard> {
//   final AuthService _auth = AuthService();
//   bool isGuest      = true;
//   int  _currentIndex = 0;
//   final _tourKeys   = TourKeys();

//   // Greeting + name
//   String _farmerName = '';

//   // Live weather tip — fully dynamic from OpenWeatherMap
//   WeatherTip _weatherTip = WeatherTipService.fallback();
//   Timer? _weatherTimer;

//   String t(String key) =>
//       AppLocalizations.of(context)?.translate(key) ?? key;

//   @override
//   void initState() {
//     super.initState();
//     _syncAuthStatus();
//     _loadFarmerName();
//     _fetchWeatherTip();
//     // Refresh every 30 minutes silently
//     _weatherTimer = Timer.periodic(
//       const Duration(minutes: 30),
//       (_) => _fetchWeatherTip(),
//     );
//     if (widget.showTour) {
//       WidgetsBinding.instance.addPostFrameCallback(
//         (_) => TourGuide.show(
//           context,
//           steps: TourGuide.homeDashboardSteps(_tourKeys),
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _weatherTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadFarmerName() async {
//     // 1. Show cached name immediately (fast)
//     final prefs = await SharedPreferences.getInstance();
//     final cached = prefs.getString('farmer_name') ?? '';
//     if (mounted && cached.isNotEmpty) {
//       setState(() => _farmerName = cached.split(' ').first);
//     }

//     // 2. Fetch fresh name from backend profile API
//     if (isGuest) return;
//     try {
//       final token = await _auth.getToken();
//       if (token == null) return;
//       final res = await http.get(
//         Uri.parse(AppConstants.profileUrl),
//         headers: {'Authorization': 'Token $token'},
//       ).timeout(const Duration(seconds: 10));

//       if (res.statusCode == 200) {
//         final data      = jsonDecode(res.body) as Map<String, dynamic>;
//         final firstName = (data['first_name'] as String? ?? '').trim();
//         final fullName  = '$firstName ${data['last_name'] ?? ''}'.trim();
//         if (firstName.isNotEmpty && mounted) {
//           // Update cache + state
//           await prefs.setString('farmer_name', fullName);
//           setState(() => _farmerName = firstName);
//         }
//       }
//     } catch (_) {
//       // Keep cached name on network error
//     }
//   }

//   Future<void> _fetchWeatherTip() async {
//     final tip = await WeatherTipService.fetch();
//     if (mounted) setState(() => _weatherTip = tip);
//   }

//   Future<void> _syncAuthStatus() async {
//     final loggedIn = await _auth.isLoggedIn();
//     if (mounted) {
//       setState(() => isGuest = !loggedIn);
//       if (loggedIn) _loadFarmerName(); // refresh name after login
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool  isDark       = Theme.of(context).brightness == Brightness.dark;
//     final Color primaryGreen = isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               _buildHeader(),
//               const SizedBox(height: 10),
//               _buildGreeting(),           // ← NEW
//               const SizedBox(height: 8),
//               _buildTipCard(),            // ← NEW
//               const SizedBox(height: 10),
//               _buildGuestBanner(),
//               Expanded(
//                 child: ScannerSection(
//                   key: _tourKeys.scannerCard,
//                   isGuest: isGuest,
//                   onAuthRequired: (feature) =>
//                       _showSignInRequiredDialog(context, feature),
//                   onLoginSuccess: _syncAuthStatus,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type:                BottomNavigationBarType.fixed,
//         backgroundColor:     isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         currentIndex:        _currentIndex,
//         selectedItemColor:   primaryGreen,
//         unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
//         onTap: (i) {
//           setState(() => _currentIndex = i);
//           final labels = ['weather', 'crops', 'history', 'settings'];
//           _onNavTap(labels[i]);
//         },
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.wb_sunny_outlined, key: _tourKeys.navWeather),
//             label: t('weather'),
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.grass_rounded, key: _tourKeys.navCrops),
//             label: t('crops'),
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.history_rounded, key: _tourKeys.navHistory),
//             label: t('history'),
//           ),
//           BottomNavigationBarItem(
//             icon: const Icon(Icons.settings_suggest_outlined),
//             label: t('settings'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Greeting row ──────────────────────────────────────────────
//   Widget _buildGreeting() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final hour   = DateTime.now().hour;
//     final String timeGreeting = hour < 12
//         ? '☀️ Good morning'
//         : hour < 17
//             ? '🌤 Good afternoon'
//             : '🌙 Good evening';
//     final String name = isGuest
//         ? 'Farmer'
//         : _farmerName.isNotEmpty
//             ? _farmerName
//             : 'Farmer';

//     return Row(
//       children: [
//         Expanded(
//           child: RichText(
//             text: TextSpan(children: [
//               TextSpan(
//                 text: '$timeGreeting, ',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: isDark ? Colors.white70 : const Color(0xFF444444),
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               TextSpan(
//                 text: name,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: isDark
//                       ? Colors.greenAccent
//                       : const Color(0xFF1B5E20),
//                 ),
//               ),
//             ]),
//           ),
//         ),
//         // Date chip
//         Container(
//           padding: const EdgeInsets.symmetric(
//               horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: isDark
//                 ? Colors.white.withOpacity(0.07)
//                 : const Color(0xFF1B5E20).withOpacity(0.07),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             _formatDate(),
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//               color: isDark
//                   ? Colors.white54
//                   : const Color(0xFF1B5E20).withOpacity(0.65),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatDate() {
//     final now = DateTime.now();
//     const months = ['Jan','Feb','Mar','Apr','May','Jun',
//                     'Jul','Aug','Sep','Oct','Nov','Dec'];
//     const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
//     return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
//   }

//   // ── Tip of the day (live weather-driven) ────────────────────
//   Widget _buildTipCard() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final tip    = _weatherTip;
//     final color  = tip.conditionColor;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isDark
//               ? [const Color(0xFF0A2E0A), const Color(0xFF1A3A1B)]
//               : [const Color(0xFFE8F5E9), const Color(0xFFF1FAF5)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: color.withOpacity(isDark ? 0.35 : 0.22),
//         ),
//       ),
//       child: Row(
//         children: [
//           // Emoji icon
//           Container(
//             width: 42, height: 42,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Text(tip.emoji,
//                   style: const TextStyle(fontSize: 21)),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Badge row
//                 Row(children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.14),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       tip.isLive
//                           ? "TODAY'S WEATHER TIP"
//                           : 'DAILY TIP',
//                       style: TextStyle(
//                         fontSize: 9,
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                   ),
//                   if (tip.isLive) ...[
//                     const SizedBox(width: 5),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.10),
//                         borderRadius: BorderRadius.circular(6),
//                         border: Border.all(
//                             color: color.withOpacity(0.3)),
//                       ),
//                       child: Text(
//                         tip.conditionLabel,
//                         style: TextStyle(
//                           fontSize: 9,
//                           fontWeight: FontWeight.w600,
//                           color: color,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ]),
//                 const SizedBox(height: 3),
//                 Text(
//                   tip.title,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: isDark ? Colors.white : const Color(0xFF1B5E20),
//                   ),
//                 ),
//                 if (tip.isLive && tip.weatherSummary.isNotEmpty)
//                   Text(
//                     tip.weatherSummary,
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: color.withOpacity(0.7),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   )
//                 else
//                   Text(
//                     tip.body,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 11,
//                       height: 1.4,
//                       color: isDark
//                           ? Colors.white54
//                           : const Color(0xFF1B5E20).withOpacity(0.6),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Navigation ─────────────────────────────────────────────────
//   void _onNavTap(String key) {
//     if (key == 'weather') {
//       _openWeather();
//     } else if (isGuest) {
//       _showSignInRequiredDialog(context, t(key));
//     } else {
//       if (key == 'history')  _openHistory();
//       if (key == 'crops')    _openCropType();
//       if (key == 'settings') _openSettings();
//     }
//   }

//   void _openWeather()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherServicePage()));
//   void _openHistory()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
//   void _openAlerts()       => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
//   void _openCropType()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropTypeScreen()));
//   void _openSettings()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
//   void _openResources()    => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()));
//   void _openCalendar()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantingCalendarScreen()));
//   void _openMarketPrices() => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketPricesScreen()));
//   void _openJournal()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthJournalScreen()));

//   void _showSignInRequiredDialog(BuildContext context, String featureName) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20)),
//         title: Text('${t("unlock")} $featureName'),
//         content: Text(t('auth_required')),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(t('later')),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//               );
//               if (result == true) _syncAuthStatus();
//             },
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF00A844)),
//             child: Text(
//               t('signin'),
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Header ─────────────────────────────────────────────────────
//   Widget _buildHeader() {
//     final bool  isDark    = Theme.of(context).brightness == Brightness.dark;
//     final Color iconColor = isDark ? Colors.greenAccent : Colors.green;

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             CircleAvatar(
//               key:             _tourKeys.logo,
//               backgroundColor: const Color(0xFF00A844),
//               child:           const Icon(Icons.eco, color: Colors.white),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'FarmAid',
//                   style: TextStyle(
//                     fontSize:   22,
//                     fontWeight: FontWeight.bold,
//                     color: isDark
//                         ? Colors.greenAccent
//                         : const Color(0xFF1B5E20),
//                   ),
//                 ),
//                 Text(
//                   t('subtitle'),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isDark
//                         ? Colors.greenAccent.withOpacity(0.7)
//                         : Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         Row(
//           children: [
//             if (isGuest)
//               IconButton(
//                 key:      _tourKeys.alertBell,
//                 tooltip:  t('alerts'),
//                 onPressed: () =>
//                     _showSignInRequiredDialog(context, t('alerts')),
//                 icon: Icon(
//                   Icons.notifications_none_rounded,
//                   color: iconColor,
//                 ),
//               )
//             else
//               KeyedSubtree(
//                 key: _tourKeys.alertBell,
//                 child: const AlertBellIcon(),
//               ),
//             PopupMenuButton<String>(
//               icon:  Icon(Icons.menu_rounded, color: iconColor),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               onSelected: (value) async {
//                 switch (value) {
//                   case 'journal':
//                     isGuest
//                         ? _showSignInRequiredDialog(
//                             context, t('Growth Journal'))
//                         : _openJournal();
//                     break;
//                   case 'resources': _openResources();    break;
//                   case 'calendar':  _openCalendar();     break;
//                   case 'prices':    _openMarketPrices(); break;
//                   case 'logout':
//                     await _auth.signOut();
//                     _syncAuthStatus();
//                     break;
//                   case 'login':
//                     final result = await Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const LoginScreen()),
//                     );
//                     if (result == true) _syncAuthStatus();
//                     break;
//                 }
//               },
//               itemBuilder: (context) => [
//                 PopupMenuItem(value: 'journal',
//                   child: ListTile(leading: const Icon(Icons.book_outlined, color: Colors.green),
//                     title: Text(t('Growth Journal')), dense: true)),
//                 const PopupMenuDivider(),
//                 PopupMenuItem(value: 'resources',
//                   child: ListTile(leading: const Icon(Icons.menu_book_outlined, color: Colors.green),
//                     title: Text(t('Resources')), dense: true)),
//                 PopupMenuItem(value: 'calendar',
//                   child: ListTile(leading: const Icon(Icons.calendar_month_outlined, color: Colors.green),
//                     title: Text(t('Planting Calendar')), dense: true)),
//                 PopupMenuItem(value: 'prices',
//                   child: ListTile(leading: const Icon(Icons.monetization_on_outlined, color: Colors.green),
//                     title: Text(t('Market Prices')), dense: true)),
//                 const PopupMenuDivider(),
//                 PopupMenuItem(
//                   value: isGuest ? 'login' : 'logout',
//                   child: ListTile(
//                     leading: Icon(
//                       isGuest ? Icons.login : Icons.logout,
//                       color: Colors.redAccent,
//                     ),
//                     title: Text(isGuest ? t('signin') : t('logout')),
//                     dense: true,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // ── Guest banner ────────────────────────────────────────────────
//   Widget _buildGuestBanner() {
//     if (!isGuest) return const SizedBox.shrink();
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: isDark
//             ? Colors.green.withOpacity(0.1)
//             : Colors.green.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isDark
//               ? Colors.green.shade800
//               : Colors.green.shade200,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline,
//               color: isDark
//                   ? Colors.greenAccent
//                   : const Color(0xFF2E7D32)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   t('guest_title'),
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: isDark
//                         ? Colors.greenAccent
//                         : const Color(0xFF1B5E20),
//                   ),
//                 ),
//                 Text(
//                   t('guest_subtitle'),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isDark
//                         ? Colors.white70
//                         : Colors.green.shade900,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//               );
//               if (result == true) _syncAuthStatus();
//             },
//             child: Text(
//               t('signin'),
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF00A844),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // Correct Imports
// import '../../weather/presentation/weather_service.dart';
// import '../../auth/presentation/login_screen.dart';
// import '../../../services/auth_service.dart';
// import '../../history/presentation/history_screen.dart';
// import '../../alerts/presentation/alerts_screen.dart';
// import '../../alerts/presentation/widgets/alert_bell_icon.dart';
// import '../../crops/presentation/crop_type_screen.dart';
// import './settings_screen.dart';
// import '../../../core/constants.dart';
// import '../../../core/app_localizations.dart';

// import '../../resources/presentation/resources_screen.dart';
// import '../../resources/presentation/planting_calendar_screen.dart';
// import '../../resources/presentation/market_prices_screen.dart';
// import '../../history/presentation/growth_journal_screen.dart';

// import 'widgets/scanner_section.dart';
// import '../../onboarding/presentation/tour_guide.dart';
// import '../../../services/weather_tip_service.dart';

// class HomeDashboard extends StatefulWidget {
//   final bool showTour;
//   const HomeDashboard({super.key, this.showTour = false});

//   @override
//   State<HomeDashboard> createState() => _HomeDashboardState();
// }

// class _HomeDashboardState extends State<HomeDashboard> {
//   final AuthService _auth = AuthService();
//   bool isGuest      = true;
//   int  _currentIndex = 0;
//   final _tourKeys   = TourKeys();

//   // Greeting + name
//   String _farmerName = '';

//   // Live weather tip — fully dynamic from OpenWeatherMap
//   WeatherTip _weatherTip = WeatherTipService.fallback();
//   Timer? _weatherTimer;

//   String t(String key) =>
//       AppLocalizations.of(context)?.translate(key) ?? key;

//   @override
//   void initState() {
//     super.initState();
//     _syncAuthStatus();
//     _loadFarmerName();
//     _fetchWeatherTip();
//     // Refresh every 30 minutes silently
//     _weatherTimer = Timer.periodic(
//       const Duration(minutes: 30),
//       (_) => _fetchWeatherTip(),
//     );
//     if (widget.showTour) {
//       WidgetsBinding.instance.addPostFrameCallback(
//         (_) => TourGuide.show(
//           context,
//           steps: TourGuide.homeDashboardSteps(_tourKeys),
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _weatherTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadFarmerName() async {
//     // 1. Show cached name immediately (fast)
//     final prefs = await SharedPreferences.getInstance();
//     final cached = prefs.getString('farmer_name') ?? '';
//     if (mounted && cached.isNotEmpty) {
//       setState(() => _farmerName = cached.split(' ').first);
//     }

//     // 2. Fetch fresh name from backend profile API
//     if (isGuest) return;
//     try {
//       final token = await _auth.getToken();
//       if (token == null) return;
//       final res = await http.get(
//         Uri.parse(AppConstants.profileUrl),
//         headers: {'Authorization': 'Token $token'},
//       ).timeout(const Duration(seconds: 10));

//       if (res.statusCode == 200) {
//         final data      = jsonDecode(res.body) as Map<String, dynamic>;
//         final firstName = (data['first_name'] as String? ?? '').trim();
//         final fullName  = '$firstName ${data['last_name'] ?? ''}'.trim();
//         if (firstName.isNotEmpty && mounted) {
//           // Update cache + state
//           await prefs.setString('farmer_name', fullName);
//           setState(() => _farmerName = firstName);
//         }
//       }
//     } catch (_) {
//       // Keep cached name on network error
//     }
//   }

//   Future<void> _fetchWeatherTip() async {
//     final tip = await WeatherTipService.fetch();
//     if (mounted) setState(() => _weatherTip = tip);
//   }

//   Future<void> _syncAuthStatus() async {
//     final loggedIn = await _auth.isLoggedIn();
//     if (mounted) {
//       setState(() => isGuest = !loggedIn);
//       if (loggedIn) _loadFarmerName(); // refresh name after login
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool  isDark       = Theme.of(context).brightness == Brightness.dark;
//     final Color primaryGreen = isDark ? Colors.greenAccent : const Color(0xFF1B5E20);
//     final bool  isWide       = MediaQuery.of(context).size.width > 600;
//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       body: SafeArea(
//         child: isWide
//             ? Align(
//                 alignment: Alignment.topCenter,
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 680),
//                   child: _buildBody(),
//                 ),
//               )
//             : _buildBody(),
//       ),
//       bottomNavigationBar: _buildNavBar(isDark, primaryGreen),
//     );
//   }

//   Widget _buildNavBar(bool isDark, Color primaryGreen) {
//     return BottomNavigationBar(
//       type:                BottomNavigationBarType.fixed,
//       backgroundColor:     isDark ? const Color(0xFF1E1E1E) : Colors.white,
//       currentIndex:        _currentIndex,
//       selectedItemColor:   primaryGreen,
//       unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
//       onTap: (i) {
//         setState(() => _currentIndex = i);
//         final labels = ['weather', 'crops', 'history', 'settings'];
//         _onNavTap(labels[i]);
//       },
//       items: [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.wb_sunny_outlined, key: _tourKeys.navWeather),
//           label: t('weather'),
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.grass_rounded, key: _tourKeys.navCrops),
//           label: t('crops'),
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.history_rounded, key: _tourKeys.navHistory),
//           label: t('history'),
//         ),
//         BottomNavigationBarItem(
//           icon: const Icon(Icons.settings_suggest_outlined),
//           label: t('settings'),
//         ),
//       ],
//     );
//   }

//   // ── Extracted body (shared by mobile & desktop) ───────────────
//   Widget _buildBody() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: Column(
//         children: [
//           const SizedBox(height: 10),
//           _buildHeader(),
//           const SizedBox(height: 10),
//           _buildGreeting(),           // ← NEW
//           const SizedBox(height: 8),
//           _buildTipCard(),            // ← NEW
//           const SizedBox(height: 10),
//           _buildGuestBanner(),
//           Expanded(
//             child: ScannerSection(
//               key: _tourKeys.scannerCard,
//               isGuest: isGuest,
//               onAuthRequired: (feature) =>
//                   _showSignInRequiredDialog(context, feature),
//               onLoginSuccess: _syncAuthStatus,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Greeting row ──────────────────────────────────────────────
//   Widget _buildGreeting() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final hour   = DateTime.now().hour;
//     final String timeGreeting = hour < 12
//         ? '☀️ Good morning'
//         : hour < 17
//             ? '🌤 Good afternoon'
//             : '🌙 Good evening';
//     final String name = isGuest
//         ? 'Farmer'
//         : _farmerName.isNotEmpty
//             ? _farmerName
//             : 'Farmer';

//     return Row(
//       children: [
//         Expanded(
//           child: RichText(
//             text: TextSpan(children: [
//               TextSpan(
//                 text: '$timeGreeting, ',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: isDark ? Colors.white70 : const Color(0xFF444444),
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               TextSpan(
//                 text: name,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: isDark
//                       ? Colors.greenAccent
//                       : const Color(0xFF1B5E20),
//                 ),
//               ),
//             ]),
//           ),
//         ),
//         // Date chip
//         Container(
//           padding: const EdgeInsets.symmetric(
//               horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: isDark
//                 ? Colors.white.withOpacity(0.07)
//                 : const Color(0xFF1B5E20).withOpacity(0.07),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             _formatDate(),
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//               color: isDark
//                   ? Colors.white54
//                   : const Color(0xFF1B5E20).withOpacity(0.65),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatDate() {
//     final now = DateTime.now();
//     const months = ['Jan','Feb','Mar','Apr','May','Jun',
//                     'Jul','Aug','Sep','Oct','Nov','Dec'];
//     const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
//     return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
//   }

//   // ── Tip of the day (live weather-driven) ────────────────────
//   Widget _buildTipCard() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final tip    = _weatherTip;
//     final color  = tip.conditionColor;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isDark
//               ? [const Color(0xFF0A2E0A), const Color(0xFF1A3A1B)]
//               : [const Color(0xFFE8F5E9), const Color(0xFFF1FAF5)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: color.withOpacity(isDark ? 0.35 : 0.22),
//         ),
//       ),
//       child: Row(
//         children: [
//           // Emoji icon
//           Container(
//             width: 42, height: 42,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Text(tip.emoji,
//                   style: const TextStyle(fontSize: 21)),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Badge row
//                 Row(children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.14),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       tip.isLive
//                           ? "TODAY'S WEATHER TIP"
//                           : 'DAILY TIP',
//                       style: TextStyle(
//                         fontSize: 9,
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                   ),
//                   if (tip.isLive) ...[
//                     const SizedBox(width: 5),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.10),
//                         borderRadius: BorderRadius.circular(6),
//                         border: Border.all(
//                             color: color.withOpacity(0.3)),
//                       ),
//                       child: Text(
//                         tip.conditionLabel,
//                         style: TextStyle(
//                           fontSize: 9,
//                           fontWeight: FontWeight.w600,
//                           color: color,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ]),
//                 const SizedBox(height: 3),
//                 Text(
//                   tip.title,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: isDark ? Colors.white : const Color(0xFF1B5E20),
//                   ),
//                 ),
//                 if (tip.isLive && tip.weatherSummary.isNotEmpty)
//                   Text(
//                     tip.weatherSummary,
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: color.withOpacity(0.7),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   )
//                 else
//                   Text(
//                     tip.body,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 11,
//                       height: 1.4,
//                       color: isDark
//                           ? Colors.white54
//                           : const Color(0xFF1B5E20).withOpacity(0.6),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Navigation ─────────────────────────────────────────────────
//   void _onNavTap(String key) {
//     if (key == 'weather') {
//       _openWeather();
//     } else if (isGuest) {
//       _showSignInRequiredDialog(context, t(key));
//     } else {
//       if (key == 'history')  _openHistory();
//       if (key == 'crops')    _openCropType();
//       if (key == 'settings') _openSettings();
//     }
//   }

//   void _openWeather()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherServicePage()));
//   void _openHistory()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
//   void _openAlerts()       => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
//   void _openCropType()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropTypeScreen()));
//   void _openSettings()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
//   void _openResources()    => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()));
//   void _openCalendar()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantingCalendarScreen()));
//   void _openMarketPrices() => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketPricesScreen()));
//   void _openJournal()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthJournalScreen()));

//   void _showSignInRequiredDialog(BuildContext context, String featureName) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20)),
//         title: Text('${t("unlock")} $featureName'),
//         content: Text(t('auth_required')),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(t('later')),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//               );
//               if (result == true) _syncAuthStatus();
//             },
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF00A844)),
//             child: Text(
//               t('signin'),
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Header ─────────────────────────────────────────────────────
//   Widget _buildHeader() {
//     final bool  isDark    = Theme.of(context).brightness == Brightness.dark;
//     final Color iconColor = isDark ? Colors.greenAccent : Colors.green;

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             CircleAvatar(
//               key:             _tourKeys.logo,
//               backgroundColor: const Color(0xFF00A844),
//               child:           const Icon(Icons.eco, color: Colors.white),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'FarmAid',
//                   style: TextStyle(
//                     fontSize:   22,
//                     fontWeight: FontWeight.bold,
//                     color: isDark
//                         ? Colors.greenAccent
//                         : const Color(0xFF1B5E20),
//                   ),
//                 ),
//                 Text(
//                   t('subtitle'),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isDark
//                         ? Colors.greenAccent.withOpacity(0.7)
//                         : Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         Row(
//           children: [
//             if (isGuest)
//               IconButton(
//                 key:      _tourKeys.alertBell,
//                 tooltip:  t('alerts'),
//                 onPressed: () =>
//                     _showSignInRequiredDialog(context, t('alerts')),
//                 icon: Icon(
//                   Icons.notifications_none_rounded,
//                   color: iconColor,
//                 ),
//               )
//             else
//               KeyedSubtree(
//                 key: _tourKeys.alertBell,
//                 child: const AlertBellIcon(),
//               ),
//             PopupMenuButton<String>(
//               icon:  Icon(Icons.menu_rounded, color: iconColor),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15)),
//               onSelected: (value) async {
//                 switch (value) {
//                   case 'journal':
//                     isGuest
//                         ? _showSignInRequiredDialog(
//                             context, t('Growth Journal'))
//                         : _openJournal();
//                     break;
//                   case 'resources': _openResources();    break;
//                   case 'calendar':  _openCalendar();     break;
//                   case 'prices':    _openMarketPrices(); break;
//                   case 'logout':
//                     await _auth.signOut();
//                     _syncAuthStatus();
//                     break;
//                   case 'login':
//                     final result = await Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const LoginScreen()),
//                     );
//                     if (result == true) _syncAuthStatus();
//                     break;
//                 }
//               },
//               itemBuilder: (context) => [
//                 PopupMenuItem(value: 'journal',
//                   child: ListTile(leading: const Icon(Icons.book_outlined, color: Colors.green),
//                     title: Text(t('Growth Journal')), dense: true)),
//                 const PopupMenuDivider(),
//                 PopupMenuItem(value: 'resources',
//                   child: ListTile(leading: const Icon(Icons.menu_book_outlined, color: Colors.green),
//                     title: Text(t('Resources')), dense: true)),
//                 PopupMenuItem(value: 'calendar',
//                   child: ListTile(leading: const Icon(Icons.calendar_month_outlined, color: Colors.green),
//                     title: Text(t('Planting Calendar')), dense: true)),
//                 PopupMenuItem(value: 'prices',
//                   child: ListTile(leading: const Icon(Icons.monetization_on_outlined, color: Colors.green),
//                     title: Text(t('Market Prices')), dense: true)),
//                 const PopupMenuDivider(),
//                 PopupMenuItem(
//                   value: isGuest ? 'login' : 'logout',
//                   child: ListTile(
//                     leading: Icon(
//                       isGuest ? Icons.login : Icons.logout,
//                       color: Colors.redAccent,
//                     ),
//                     title: Text(isGuest ? t('signin') : t('logout')),
//                     dense: true,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // ── Guest banner ────────────────────────────────────────────────
//   Widget _buildGuestBanner() {
//     if (!isGuest) return const SizedBox.shrink();
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: isDark
//             ? Colors.green.withOpacity(0.1)
//             : Colors.green.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isDark
//               ? Colors.green.shade800
//               : Colors.green.shade200,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline,
//               color: isDark
//                   ? Colors.greenAccent
//                   : const Color(0xFF2E7D32)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   t('guest_title'),
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: isDark
//                         ? Colors.greenAccent
//                         : const Color(0xFF1B5E20),
//                   ),
//                 ),
//                 Text(
//                   t('guest_subtitle'),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isDark
//                         ? Colors.white70
//                         : Colors.green.shade900,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//               );
//               if (result == true) _syncAuthStatus();
//             },
//             child: Text(
//               t('signin'),
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF00A844),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Correct Imports
import '../../weather/presentation/weather_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../history/presentation/history_screen.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../alerts/presentation/widgets/alert_bell_icon.dart';
import '../../crops/presentation/crop_type_screen.dart';
import './settings_screen.dart';
import '../../../core/constants.dart';
import '../../../core/app_localizations.dart';

import '../../resources/presentation/resources_screen.dart';
import '../../resources/presentation/planting_calendar_screen.dart';
import '../../resources/presentation/market_prices_screen.dart';
import '../../history/presentation/growth_journal_screen.dart';

import 'widgets/scanner_section.dart';
import '../../onboarding/presentation/tour_guide.dart';
import '../../../services/weather_tip_service.dart';

class HomeDashboard extends StatefulWidget {
  final bool showTour;
  const HomeDashboard({super.key, this.showTour = false});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final AuthService _auth = AuthService();
  bool isGuest      = true;
  int  _currentIndex = 0;
  final _tourKeys   = TourKeys();

  // Greeting + name
  String _farmerName = '';

  // Live weather tip — fully dynamic from OpenWeatherMap
  WeatherTip _weatherTip = WeatherTipService.fallback();
  Timer? _weatherTimer;

  String t(String key) =>
      AppLocalizations.of(context)?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _syncAuthStatus();
    _loadFarmerName();
    _fetchWeatherTip();
    // Refresh every 30 minutes silently
    _weatherTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _fetchWeatherTip(),
    );
    if (widget.showTour) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => TourGuide.show(
          context,
          steps: TourGuide.homeDashboardSteps(_tourKeys),
        ),
      );
    }
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFarmerName() async {
    // 1. Show cached name immediately (fast)
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('farmer_name') ?? '';
    if (mounted && cached.isNotEmpty) {
      setState(() => _farmerName = cached.split(' ').first);
    }

    // 2. Fetch fresh name from backend profile API
    if (isGuest) return;
    try {
      final token = await _auth.getToken();
      if (token == null) return;
      final res = await http.get(
        Uri.parse(AppConstants.profileUrl),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data      = jsonDecode(res.body) as Map<String, dynamic>;
        final firstName = (data['first_name'] as String? ?? '').trim();
        final fullName  = '$firstName ${data['last_name'] ?? ''}'.trim();
        if (firstName.isNotEmpty && mounted) {
          // Update cache + state
          await prefs.setString('farmer_name', fullName);
          setState(() => _farmerName = firstName);
        }
      }
    } catch (_) {
      // Keep cached name on network error
    }
  }

  Future<void> _fetchWeatherTip() async {
    final tip = await WeatherTipService.fetch();
    if (mounted) setState(() => _weatherTip = tip);
  }

  Future<void> _syncAuthStatus() async {
    final loggedIn = await _auth.isLoggedIn();
    if (mounted) {
      setState(() => isGuest = !loggedIn);
      if (loggedIn) _loadFarmerName(); // refresh name after login
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool  isDark       = Theme.of(context).brightness == Brightness.dark;
    final Color primaryGreen = isDark ? Colors.greenAccent : const Color(0xFF1B5E20);
    final bool  isWide       = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      body: SafeArea(
        child: isWide
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _buildBody(),
                ),
              )
            : _buildBody(),
      ),
      bottomNavigationBar: _buildNavBar(isDark, primaryGreen),
    );
  }

  Widget _buildNavBar(bool isDark, Color primaryGreen) {
    return BottomNavigationBar(
      type:                 BottomNavigationBarType.fixed,
      backgroundColor:      isDark ? const Color(0xFF1E1E1E) : Colors.white,
      currentIndex:         _currentIndex,
      selectedItemColor:    primaryGreen,
      unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
      onTap: (i) {
        setState(() => _currentIndex = i);
        final labels = ['weather', 'crops', 'history', 'settings'];
        _onNavTap(labels[i]);
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.wb_sunny_outlined, key: _tourKeys.navWeather),
          label: t('weather'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grass_rounded, key: _tourKeys.navCrops),
          label: t('crops'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded, key: _tourKeys.navHistory),
          label: t('history'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_suggest_outlined),
          label: t('settings'),
        ),
      ],
    );
  }

  // ── Extracted body (shared by mobile & desktop) ───────────────
  Widget _buildBody() {
    final appLoc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildHeader(),
          const SizedBox(height: 10),
          _buildGreeting(appLoc),
          const SizedBox(height: 8),
          _buildTipCard(appLoc),
          const SizedBox(height: 10),
          _buildGuestBanner(),
          Expanded(
            child: ScannerSection(
              key: _tourKeys.scannerCard,
              isGuest: isGuest,
              onAuthRequired: (feature) =>
                  _showSignInRequiredDialog(context, feature),
              onLoginSuccess: _syncAuthStatus,
            ),
          ),
        ],
      ),
    );
  }

  // ── Greeting row ──────────────────────────────────────────────
  Widget _buildGreeting(AppLocalizations? appLoc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour   = DateTime.now().hour;
    
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = '☀️ ${appLoc?.translate("Good morning") ?? "Good morning"}';
    } else if (hour < 17) {
      timeGreeting = '🌤 ${appLoc?.translate("Good afternoon") ?? "Good afternoon"}';
    } else {
      timeGreeting = '🌙 ${appLoc?.translate("Good evening") ?? "Good evening"}';
    }

    final String localizedFarmer = appLoc?.translate("Farmer") ?? "Farmer";
    final String name = isGuest
        ? localizedFarmer
        : _farmerName.isNotEmpty
            ? _farmerName
            : localizedFarmer;

    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '$timeGreeting, ',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF444444),
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.greenAccent
                      : const Color(0xFF1B5E20),
                ),
              ),
            ]),
          ),
        ),
        // Date chip
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFF1B5E20).withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatDate(appLoc),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white54
                  : const Color(0xFF1B5E20).withOpacity(0.65),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(AppLocalizations? appLoc) {
    final now = DateTime.now();
    final months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
    final days   = ['mon','tue','wed','thu','fri','sat','sun'];
    
    String d = appLoc?.translate(days[now.weekday - 1]) ?? days[now.weekday - 1];
    String m = appLoc?.translate(months[now.month - 1]) ?? months[now.month - 1];
    
    return '$d, $m ${now.day}';
  }

  // ── Tip of the day (live weather-driven) ────────────────────
  Widget _buildTipCard(AppLocalizations? appLoc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tip    = _weatherTip;
    final color  = tip.conditionColor;

    // Fix: Call weatherSummary as a method first
    final summary = tip.isLive 
        ? tip.weatherSummary((k) => appLoc?.translate(k) ?? k) 
        : "";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A2E0A), const Color(0xFF1A3A1B)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1FAF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.35 : 0.22),
        ),
      ),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(tip.emoji,
                  style: const TextStyle(fontSize: 21)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge row
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tip.isLive
                          ? (appLoc?.translate("tip_label_daily_weather") ?? "TODAY'S WEATHER TIP")
                          : (appLoc?.translate("tip_label_daily") ?? 'DAILY TIP'),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (tip.isLive) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        appLoc?.translate(tip.conditionLabel) ?? tip.conditionLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(
                  tip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  ),
                ),
                // Fix: Check if summary is not empty after execution
                if (tip.isLive && summary.isNotEmpty)
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    tip.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF1B5E20).withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────
  void _onNavTap(String key) {
    if (key == 'weather') {
      _openWeather();
    } else if (isGuest) {
      _showSignInRequiredDialog(context, t(key));
    } else {
      if (key == 'history')  _openHistory();
      if (key == 'crops')     _openCropType();
      if (key == 'settings') _openSettings();
    }
  }

  void _openWeather()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherServicePage()));
  void _openHistory()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  void _openAlerts()       => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
  void _openCropType()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropTypeScreen()));
  void _openSettings()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  void _openResources()    => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()));
  void _openCalendar()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantingCalendarScreen()));
  void _openMarketPrices() => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketPricesScreen()));
  void _openJournal()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthJournalScreen()));

  void _showSignInRequiredDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('${t("unlock")} $featureName'),
        content: Text(t('auth_required')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('later')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (result == true) _syncAuthStatus();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A844)),
            child: Text(
              t('signin'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    final bool  isDark    = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.greenAccent : Colors.green;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              key:               _tourKeys.logo,
              backgroundColor: const Color(0xFF00A844),
              child:           const Icon(Icons.eco, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FarmAid',
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.greenAccent
                        : const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  t('subtitle'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.greenAccent.withOpacity(0.7)
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            if (isGuest)
              IconButton(
                key:      _tourKeys.alertBell,
                tooltip:  t('alerts'),
                onPressed: () =>
                    _showSignInRequiredDialog(context, t('alerts')),
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: iconColor,
                ),
              )
            else
              KeyedSubtree(
                key: _tourKeys.alertBell,
                child: const AlertBellIcon(),
              ),
            PopupMenuButton<String>(
              icon:  Icon(Icons.menu_rounded, color: iconColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              onSelected: (value) async {
                switch (value) {
                  case 'journal':
                    isGuest
                        ? _showSignInRequiredDialog(
                            context, t('Growth Journal'))
                        : _openJournal();
                    break;
                  case 'resources': _openResources();    break;
                  case 'calendar':  _openCalendar();     break;
                  case 'prices':    _openMarketPrices(); break;
                  case 'logout':
                    await _auth.signOut();
                    _syncAuthStatus();
                    break;
                  case 'login':
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                    if (result == true) _syncAuthStatus();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'journal',
                  child: ListTile(leading: const Icon(Icons.book_outlined, color: Colors.green),
                    title: Text(t('Growth Journal')), dense: true)),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'resources',
                  child: ListTile(leading: const Icon(Icons.menu_book_outlined, color: Colors.green),
                    title: Text(t('Resources')), dense: true)),
                PopupMenuItem(value: 'calendar',
                  child: ListTile(leading: const Icon(Icons.calendar_month_outlined, color: Colors.green),
                    title: Text(t('Planting Calendar')), dense: true)),
                PopupMenuItem(value: 'prices',
                  child: ListTile(leading: const Icon(Icons.monetization_on_outlined, color: Colors.green),
                    title: Text(t('Market Prices')), dense: true)),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: isGuest ? 'login' : 'logout',
                  child: ListTile(
                    leading: Icon(
                      isGuest ? Icons.login : Icons.logout,
                      color: Colors.redAccent,
                    ),
                    title: Text(isGuest ? t('signin') : t('logout')),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Guest banner ────────────────────────────────────────────────
  Widget _buildGuestBanner() {
    if (!isGuest) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.withOpacity(0.1)
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.green.shade800
              : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: isDark
                  ? Colors.greenAccent
                  : const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('guest_title'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.greenAccent
                        : const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  t('guest_subtitle'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white70
                        : Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (result == true) _syncAuthStatus();
            },
            child: Text(
              t('signin'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A844),
              ),
            ),
          ),
        ],
      ),
    );
  }
}