import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../../weather/presentation/weather_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/gps_state.dart';
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
import '../../community/presentation/community_page.dart';

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
  final AuthService _auth  = AuthService();
  bool   isGuest           = true;
  int    _currentIndex     = 0;
  final  _tourKeys         = TourKeys();
  String _farmerName       = '';
  WeatherTip _weatherTip   = WeatherTipService.fallback();
  Timer? _weatherTimer;

  List<Map<String, dynamic>> _cropProfiles = [];
  bool _loadingCrops = false;

  int  _totalScans     = 0;
  int  _trackedStages  = 0;
  bool _loadingActivity = false;

  List<Map<String, dynamic>> _recentAlerts = [];
  int  _unreadAlertCount = 0;
  bool _loadingAlerts    = false;

  String t(String key) =>
      AppLocalizations.of(context)?.translate(key) ?? key;

  static const _vegEmojis = {
    'Cabbage':      '🥬',
    'Tomato':       '🍅',
    'Potato':       '🥔',
    'Onion':        '🧅',
    'Spinach':      '🌿',
    'Swiss Chard':  '🥬',
    'Green Pepper': '🫑',
    'Carrot':       '🥕',
    'Beetroot':     '🟣',
    'Pumpkin':      '🎃',
    'Green Beans':  '🫘',
    'Broccoli':     '🥦',
    'Cauliflower':  '🥦',
    'Maize':        '🌽',
    'Rice':         '🌾',
    'Cotton':       '🪴',
  };

  String _cropEmoji(String? name) => _vegEmojis[name ?? ''] ?? '🌱';

  final List<Widget> _pages = [
    const _HomeContent(),
    const CommunityPage(),
    const ResourcesScreen(),
    const SettingsScreen(),
  ];

  // ============================================================
  // GPS INITIALIZATION
  // ============================================================
  
  Future<void> _initializeGps() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('📍 GPS permission denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('📍 GPS permission permanently denied');
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      ).timeout(const Duration(seconds: 15));
      
      // Get district from user profile or crop profiles
      String district = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        district = prefs.getString('user_district') ?? '';
        
        // If no district in prefs, try to get from crop profiles
        if (district.isEmpty && _cropProfiles.isNotEmpty) {
          district = _cropProfiles.first['district']?.toString() ?? '';
        }
      } catch (e) {
        print('📍 Error getting district: $e');
      }
      
      // Update GpsState singleton
      GpsState.instance.update(
        lat: position.latitude,
        lon: position.longitude,
        alt: position.altitude,
        district: district,
      );
      
      print('📍 GPS initialized: lat=${position.latitude}, lon=${position.longitude}, alt=${position.altitude}, district=$district');
    } catch (e) {
      print('📍 GPS initialization failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _syncAuthStatus();
    _loadFarmerName();
    _fetchWeatherTip();
    _initializeGps();  // ✅ Initialize GPS on app start
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
    final prefs  = await SharedPreferences.getInstance();
    final cached = prefs.getString('farmer_name') ?? '';
    if (mounted && cached.isNotEmpty) {
      setState(() => _farmerName = cached.split(' ').first);
    }
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
          await prefs.setString('farmer_name', fullName);
          setState(() => _farmerName = firstName);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchWeatherTip() async {
    final tip = await WeatherTipService.fetch();
    if (mounted) setState(() => _weatherTip = tip);
  }

  Future<void> _syncAuthStatus() async {
    final loggedIn = await _auth.isLoggedIn();
    if (mounted) {
      setState(() => isGuest = !loggedIn);
      if (loggedIn) {
        _loadFarmerName();
        _loadCropProfiles();
        _loadActivityData();
        _loadRecentAlerts();
        _initializeGps();  // ✅ Refresh GPS after login
      }
    }
  }

  Future<void> _loadCropProfiles() async {
    if (isGuest) return;
    setState(() => _loadingCrops = true);
    try {
      final token = await _auth.getToken();
      if (token == null) return;
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/crop-profiles/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _cropProfiles = data
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
        
        // ✅ Update GPS district from crop profiles if available
        if (_cropProfiles.isNotEmpty) {
          final district = _cropProfiles.first['district']?.toString() ?? '';
          if (district.isNotEmpty && GpsState.instance.district.isEmpty) {
            GpsState.instance.update(
              lat: GpsState.instance.latitude ?? 0,
              lon: GpsState.instance.longitude ?? 0,
              alt: GpsState.instance.altitude ?? 0,
              district: district,
            );
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCrops = false);
    }
  }

  Future<void> _loadActivityData() async {
    if (isGuest) return;
    setState(() => _loadingActivity = true);
    try {
      final token = await _auth.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse(AppConstants.farmerReports),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        int recentScans = 0;
        for (final item in data) {
          final raw = item['ReportDate']?.toString() ?? '';
          final dt  = DateTime.tryParse(raw);
          if (dt != null && dt.isAfter(cutoff)) recentScans++;
        }
        final stageSet = <String>{};
        for (final p in _cropProfiles) {
          final s = p['growth_stage_label']?.toString() ?? '';
          if (s.isNotEmpty) stageSet.add(s);
        }
        if (mounted) {
          setState(() {
            _totalScans    = recentScans;
            _trackedStages = stageSet.isNotEmpty
                ? stageSet.length
                : _cropProfiles.length;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingActivity = false);
    }
  }

  Future<void> _loadRecentAlerts() async {
    if (isGuest) return;
    setState(() => _loadingAlerts = true);
    try {
      final token = await _auth.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/alerts/?limit=3'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        final List alertList = body is Map
            ? (body['alerts'] ?? [])
            : body;
        final int unread = body is Map
            ? (body['unread_count'] ?? 0) as int
            : 0;
        setState(() {
          _recentAlerts      = alertList
              .take(3)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _unreadAlertCount  = unread;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAlerts = false);
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _openWeather()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherServicePage()));
  void _openHistory()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  void _openAlerts()       => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
  void _openCropType()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropTypeScreen())).then((_) => _loadCropProfiles());
  void _openSettings()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  void _openResources()    => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()));
  void _openCalendar()     => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantingCalendarScreen()));
  void _openMarketPrices() => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketPricesScreen()));
  void _openJournal()      => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthJournalScreen()));

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize:     0.5,
        maxChildSize:     0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScannerSection(
                  key:            _tourKeys.scannerCard,
                  isGuest:        isGuest,
                  onAuthRequired: (feature) {
                    Navigator.pop(context);
                    _showSignInRequiredDialog(context, feature);
                  },
                  onLoginSuccess: _syncAuthStatus,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  int _parseStageIndex(Map<String, dynamic> profile) {
    final direct = profile['growth_stage_index'];
    if (direct is int) return direct;
    if (direct != null) {
      final parsed = int.tryParse(direct.toString());
      if (parsed != null) return parsed;
    }

    final rawDate = profile['PlantingDate']?.toString()
                 ?? profile['planting_date']?.toString() ?? '';
    if (rawDate.isNotEmpty) {
      final plantDate = DateTime.tryParse(rawDate);
      if (plantDate != null) {
        final days = DateTime.now().difference(plantDate).inDays;
        if (days < 14) return 1;
        if (days < 30) return 2;
        if (days < 60) return 3;
        if (days < 90) return 4;
        return 5;
      }
    }

    final label = (profile['growth_stage_label'] ?? '').toString();
    if (label.contains('Seedling'))   return 1;
    if (label.contains('Vegetative')) return 2;
    if (label.contains('Flower'))     return 3;
    if (label.contains('Fruit'))      return 4;
    if (label.contains('Harvest'))    return 5;
    return 0;
  }

  void _showCropDetailSheet(Map<String, dynamic> profile) {
    final String cropName = profile['VegetableType']?.toString() ?? 'Crop';
    final String emoji    = _cropEmoji(cropName);
    final String stage    = profile['growth_stage_label']?.toString() ?? '';

    final String district   = profile['district']?.toString()
                           ?? profile['District']?.toString() ?? '';
    final plotSizeRaw       = profile['plot_size_hectares']
                           ?? profile['plot_size'];
    final String plotSize   = plotSizeRaw != null
                              ? plotSizeRaw.toString() : '';
    final String soilType   = profile['SoilEnvironment']?.toString()
                           ?? profile['soil_type']?.toString() ?? '';
    final String irrigation = profile['irrigation_method']?.toString()
                           ?? profile['irrigation_type']?.toString() ?? '';
    final String planted    = profile['PlantingDate']?.toString()
                           ?? profile['planting_date']?.toString() ?? '';
    final String aiTip      = profile['ai_tip']?.toString() ?? '';
    final String estHarvest = profile['expected_harvest_date']?.toString()
                           ?? profile['estimated_harvest']?.toString() ?? '';
    final int    stageIndex = _parseStageIndex(profile);
    final int    stageTotal = (profile['growth_stage_total'] as int?) ?? 5;
    final String notes      = profile['notes']?.toString() ?? '';

    Color stageColor = const Color(0xFF388E3C);
    if (stage == 'Seedling')       stageColor = const Color(0xFF0288D1);
    if (stage == 'Flowering')      stageColor = const Color(0xFFF57C00);
    if (stage.contains('Harvest')) stageColor = const Color(0xFFAD1457);

    final double progressFraction =
        stageTotal > 0 ? (stageIndex / stageTotal).clamp(0.0, 1.0) : 0.0;
    final int progressPercent = (progressFraction * 100).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        minChildSize:     0.50,
        maxChildSize:     0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color:        Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  color: const Color(0xFFEAF3DE),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          color:        Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: const Color(0xFFC0DD97), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.green.withOpacity(0.10),
                              blurRadius: 8,
                              offset:     const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 34)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cropName,
                                style: const TextStyle(
                                  fontSize:   22,
                                  fontWeight: FontWeight.bold,
                                  color:      Color(0xFF1B5E20),
                                )),
                            if (district.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: Color(0xFF639922)),
                                const SizedBox(width: 3),
                                Text(district,
                                    style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF639922),
                                    )),
                              ]),
                            ],
                            if (stage.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:        stageColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(stage,
                                    style: const TextStyle(
                                      color:      Colors.white,
                                      fontSize:   11,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding:    const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:        Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFF555555)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailSectionTitle(t('Plot Details')),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _detailField(
                            Icons.straighten_rounded,
                            t('Plot Size'),
                            plotSize.isNotEmpty ? '$plotSize ha' : '--',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _detailField(
                            Icons.calendar_today_rounded,
                            t('Planting Date'),
                            _formatDate(planted),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _detailField(
                            Icons.water_drop_rounded,
                            t('Irrigation'),
                            irrigation.isNotEmpty
                                ? _capitalize(irrigation) : '--',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _detailField(
                            Icons.layers_rounded,
                            t('Soil Type'),
                            soilType.isNotEmpty
                                ? _capitalize(soilType) : '--',
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailSectionTitle(t('Growth Progress')),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stageIndex > 0
                                ? t('Stage {} of {}').replaceFirst('{}', stageIndex.toString()).replaceFirst('{}', stageTotal.toString())
                                : stage.isNotEmpty ? stage : t('Stage unknown'),
                            style: const TextStyle(
                              fontSize: 13, color: Color(0xFF666666),
                            ),
                          ),
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.bold,
                              color:      stageColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:           progressFraction,
                          minHeight:       8,
                          backgroundColor: const Color(0xFFE0E0E0),
                          valueColor:      AlwaysStoppedAnimation<Color>(stageColor),
                        ),
                      ),
                      if (estHarvest.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.event_available_rounded,
                                size: 12, color: Color(0xFF999999)),
                            const SizedBox(width: 4),
                            Text(
                              t('Est. harvest: {}').replaceFirst('{}', _formatDate(estHarvest)),
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (notes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailSectionTitle(t('My Notes')),
                        const SizedBox(height: 10),
                        Container(
                          width:   double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:        const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border:       Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(notes,
                              style: const TextStyle(
                                fontSize: 13, color: Color(0xFF444444),
                                height:   1.5,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
                if (aiTip.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailSectionTitle(t('AI Tip')),
                        const SizedBox(height: 10),
                        Container(
                          width:   double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:        const Color(0xFFFAEEDA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFAC775)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡',
                                  style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(t('Recommended action'),
                                        style: const TextStyle(
                                          fontSize:   11,
                                          fontWeight: FontWeight.w600,
                                          color:      Color(0xFF633806),
                                        )),
                                    const SizedBox(height: 4),
                                    Text(aiTip,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color:    Color(0xFF854F0B),
                                          height:   1.5,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                  child: Column(children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openScanner();
                        },
                        icon: const Icon(Icons.search_rounded,
                            size: 18, color: Colors.white),
                        label: Text(
                          t('Run AI Diagnosis on This Crop'),
                          style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CropTypeScreen()),
                          ).then((_) => _loadCropProfiles());
                        },
                        icon: const Icon(Icons.edit_rounded,
                            size: 16, color: Color(0xFF388E3C)),
                        label: Text(
                          t('Edit / Manage Crop'),
                          style: const TextStyle(
                            color:      Color(0xFF388E3C),
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(
                              color: Color(0xFF388E3C), width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '--';
    try {
      final dt = DateTime.parse(raw);
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _detailSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize:      11,
            fontWeight:    FontWeight.w700,
            color:         Color(0xFF888888),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }

  Widget _detailField(IconData icon, String label, String value) {
    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: const Color(0xFF888888)),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF888888))),
          ]),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF1B1B1B),
              )),
        ],
      ),
    );
  }

  void _showSignInRequiredDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title:   Text('${t("unlock")} $featureName'),
        content: Text(t('auth_required')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:     Text(t('later')),
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
            child: Text(t('signin'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Column(children: [
            _buildSlimGreenTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildGreetingSection(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildMyCrops(),
                    const SizedBox(height: 16),
                    _buildActivitySummary(),
                    const SizedBox(height: 16),
                    _buildRecentAlerts(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ]),
          const CommunityPage(),
          const ResourcesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSlimGreenTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            CircleAvatar(
              key:             _tourKeys.logo,
              backgroundColor: Colors.white.withOpacity(0.2),
              radius:          18,
              child: const Icon(Icons.eco, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('FarmAid',
                style: TextStyle(
                  color:         Colors.white,
                  fontSize:      20,
                  fontWeight:    FontWeight.bold,
                  letterSpacing: 0.3,
                )),
            const Spacer(),
            if (isGuest)
              IconButton(
                key:       _tourKeys.alertBell,
                tooltip:   t('alerts'),
                onPressed: () => _showSignInRequiredDialog(context, t('alerts')),
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
              )
            else
              KeyedSubtree(
                key:   _tourKeys.alertBell,
                child: const AlertBellIcon(),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.apps_rounded, color: Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              onSelected: (value) async {
                switch (value) {
                  case 'journal':
                    isGuest
                        ? _showSignInRequiredDialog(context, t('Growth Journal'))
                        : _openJournal();
                    break;
                  case 'resources': _openResources();    break;
                  case 'calendar':  _openCalendar();     break;
                  case 'prices':    _openMarketPrices(); break;
                  case 'logout':
                    await _auth.signOut();
                    setState(() { _cropProfiles = []; });
                    _syncAuthStatus();
                    break;
                  case 'login':
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                    leading: Icon(isGuest ? Icons.login : Icons.logout,
                        color: Colors.redAccent),
                    title: Text(isGuest ? t('signin') : t('logout')),
                    dense: true,
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    final appLoc = AppLocalizations.of(context);
    final String localizedFarmer = appLoc?.translate('Farmer') ?? 'Farmer';
    final String name = isGuest
        ? localizedFarmer
        : _farmerName.isNotEmpty ? _farmerName : localizedFarmer;

    String greeting = t('Hello, {}!').replaceFirst('{}', name);
    String subheading = t('What would you like to do today?');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.center,
                children: [
                  Text(greeting,
                      style: const TextStyle(
                        color:      Color(0xFF1B5E20),
                        fontSize:   16,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 2),
                  Text(subheading,
                      style: const TextStyle(
                        color: Color(0xFF666666), fontSize: 11,
                      )),
                  if (isGuest) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()));
                        if (result == true) _syncAuthStatus();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:        const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF388E3C).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_open_rounded,
                                color: Color(0xFF388E3C), size: 13),
                            const SizedBox(width: 6),
                            Text(t('signin'),
                                style: const TextStyle(
                                  color:      Color(0xFF388E3C),
                                  fontSize:   12,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildWeatherCard(),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final tip    = _weatherTip;
    final appLoc = AppLocalizations.of(context);
    String tempLine = '';
    if (tip.isLive) {
      tempLine = tip.weatherSummary((k) => appLoc?.translate(k) ?? k);
    }

    return Container(
      width:   130,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap:        _openWeather,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.center,
          children: [
            Text(
              t('Your Location'),
              style: const TextStyle(
                fontSize:   9,
                fontWeight: FontWeight.w600,
                color:      Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text(tip.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tempLine.isNotEmpty ? tempLine : '--°C',
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.bold,
                        color:      Color(0xFF1B1B1B),
                      ),
                    ),
                    Text(
                      appLoc?.translate(tip.conditionLabel) ?? tip.conditionLabel,
                      style: TextStyle(
                        fontSize:   10,
                        color:      tip.conditionColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final tiles = [
      _QuickTile(
        label:   t('Diagnosis'),
        sub:     t('Identify Plant Diseases'),
        icon:    Icons.search_rounded,
        color:   const Color(0xFF388E3C),
        onTap:   _openScanner,
        tourKey: _tourKeys.scannerCard,
      ),
      _QuickTile(
        label:   t('Weather'),
        sub:     t('Forecast & Updates'),
        icon:    Icons.wb_sunny_rounded,
        color:   const Color(0xFFF57C00),
        onTap:   _openWeather,
        tourKey: _tourKeys.navWeather,
      ),
      _QuickTile(
        label:   t('Settings'),
        sub:     t('App Preferences'),
        icon:    Icons.settings_rounded,
        color:   const Color(0xFF1976D2),
        onTap:   isGuest
            ? () => _showSignInRequiredDialog(context, t('Settings'))
            : _openSettings,
        tourKey: null,
      ),
      _QuickTile(
        label:   t('History'),
        sub:     t('Past Activities'),
        icon:    Icons.history_rounded,
        color:   const Color(0xFF7B1FA2),
        onTap:   isGuest
            ? () => _showSignInRequiredDialog(context, t('History'))
            : _openHistory,
        tourKey: _tourKeys.navHistory,
      ),
    ];

    return Row(
      children: tiles.map((tile) {
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: tile == tiles.last ? 0 : 8),
            child: _buildQuickTile(tile),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickTile(_QuickTile tile) {
    return GestureDetector(
      onTap: tile.onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tile.color, tile.color.withOpacity(0.80)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      tile.color.withOpacity(0.35),
              blurRadius: 8,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:  MainAxisAlignment.start,
            mainAxisSize:       MainAxisSize.max,
            children: [
              Icon(tile.icon, color: Colors.white, size: 26),
              const Spacer(),
              Text(tile.label,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(tile.sub,
                  style: TextStyle(
                    color:    Colors.white.withOpacity(0.80),
                    fontSize: 9,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyCrops() {
    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              t('My Crops'),
              style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.bold,
                color:      Color(0xFF1B1B1B),
              ),
            ),
            const Spacer(),
            if (!isGuest)
              GestureDetector(
                onTap: _loadCropProfiles,
                child: Icon(Icons.refresh_rounded,
                    size: 18, color: Colors.grey.shade400),
              ),
          ]),
          const SizedBox(height: 14),
          if (isGuest)
            _buildCropsGuestState()
          else if (_loadingCrops)
            const SizedBox(
              height: 72,
              child: Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF388E3C)),
                ),
              ),
            )
          else if (_cropProfiles.isEmpty)
            _buildCropsEmptyState()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ..._cropProfiles.map((p) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child:   _buildRealCropChip(p),
                    )),
                _buildAddCropButton(),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildRealCropChip(Map<String, dynamic> profile) {
    final String cropName = profile['VegetableType']?.toString() ?? 'Crop';
    final String emoji    = _cropEmoji(cropName);
    final String stage    = profile['growth_stage_label']?.toString() ?? '';
    final String district = profile['district']?.toString() ?? '';

    Color stageColor = const Color(0xFF388E3C);
    if (stage == 'Seedling')       stageColor = const Color(0xFF0288D1);
    if (stage == 'Flowering')      stageColor = const Color(0xFFF57C00);
    if (stage.contains('Harvest')) stageColor = const Color(0xFFAD1457);

    return GestureDetector(
      onTap: () => _showCropDetailSheet(profile),
      child: Column(children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width:  62, height: 62,
              decoration: BoxDecoration(
                color:        const Color(0xFFEFF8EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF388E3C).withOpacity(0.15),
                    width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.green.withOpacity(0.08),
                    blurRadius: 6, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            if (stage.isNotEmpty)
              Positioned(
                top: -3, right: -3,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color:  stageColor,
                    shape:  BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 62,
          child: Text(cropName,
              textAlign: TextAlign.center,
              maxLines:  1,
              overflow:  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      Color(0xFF333333),
              )),
        ),
        if (stage.isNotEmpty)
          SizedBox(
            width: 62,
            child: Text(stage,
                textAlign: TextAlign.center,
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize:   9,
                  color:      stageColor,
                  fontWeight: FontWeight.w500,
                )),
          ),
        if (stage.isEmpty && district.isNotEmpty)
          SizedBox(
            width: 62,
            child: Text(district,
                textAlign: TextAlign.center,
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9, color: Color(0xFF999999))),
          ),
      ]),
    );
  }

  Widget _buildAddCropButton() {
    return GestureDetector(
      onTap: _openCropType,
      child: Column(children: [
        Container(
          width:  62, height: 62,
          decoration: BoxDecoration(
            color:        const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: const Icon(Icons.add_rounded,
              color: Color(0xFF388E3C), size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          t('Add Crop'),
          style: const TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      Color(0xFF388E3C),
          ),
        ),
        const SizedBox(height: 9),
      ]),
    );
  }

  Widget _buildCropsEmptyState() {
    return GestureDetector(
      onTap: _openCropType,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF8EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF388E3C).withOpacity(0.20),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF388E3C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF388E3C), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('No plots yet'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t('Add your first crop plot to get personalised AI advice'),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF388E3C)),
          ],
        ),
      ),
    );
  }

  Widget _buildCropsGuestState() {
    return GestureDetector(
      onTap: () => _showSignInRequiredDialog(context, 'My Crops'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Sign in to manage your crops'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t('Track plots, growth stages & personalised advice'),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            Icon(Icons.lock_outline_rounded,
                color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary() {
    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              t('Field Activity Summary'),
              style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.bold,
                color:      Color(0xFF1B1B1B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                t('Last 7 Days'),
                style: const TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                  color:      Color(0xFF388E3C),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _loadingActivity
              ? const SizedBox(
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF388E3C)),
                    ),
                  ),
                )
              : Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isGuest ? null : _openHistory,
                      child: Row(children: [
                        const Text('🔍',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(t('Scans this week'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color:    Color(0xFF666666),
                                )),
                            Text(
                              isGuest ? '--' : '$_totalScans',
                              style: const TextStyle(
                                fontSize:   26,
                                fontWeight: FontWeight.bold,
                                color:      Color(0xFF1B1B1B),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  Container(
                    width: 1, height: 40,
                    color: const Color(0xFFE0E0E0),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: isGuest ? null : _openCropType,
                      child: Row(children: [
                        const Text('🌱',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(t('Tracked stages'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color:    Color(0xFF666666),
                                )),
                            Row(children: [
                              Text(
                                isGuest
                                    ? '--'
                                    : '$_trackedStages',
                                style: const TextStyle(
                                  fontSize:   26,
                                  fontWeight: FontWeight.bold,
                                  color:      Color(0xFF1B1B1B),
                                ),
                              ),
                              if (!isGuest &&
                                  _trackedStages > 0) ...[
                                const SizedBox(width: 6),
                                const Text('🌿',
                                    style: TextStyle(
                                        fontSize: 14)),
                              ],
                            ]),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ]),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              t('Recent Alerts'),
              style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.bold,
                color:      Color(0xFF1B1B1B),
              ),
            ),
            const Spacer(),
            if (!isGuest && _unreadAlertCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.red.withOpacity(0.25)),
                ),
                child: Text(
                  t('{} unread').replaceFirst('{}', '$_unreadAlertCount'),
                  style: const TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w600,
                    color:      Colors.redAccent,
                  ),
                ),
              ),
            GestureDetector(
              onTap: isGuest
                  ? () => _showSignInRequiredDialog(
                      context, t('alerts'))
                  : _openAlerts,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:        const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All',
                        style: TextStyle(
                          color:      Colors.white,
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                        )),
                    SizedBox(width: 3),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          if (isGuest)
            _alertGuestState()
          else if (_loadingAlerts)
            const SizedBox(
              height: 56,
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF388E3C)),
                ),
              ),
            )
          else if (_recentAlerts.isEmpty)
            _alertEmptyState()
          else
            Column(
              children: _recentAlerts.map((alert) =>
                  _buildAlertRow(alert)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(Map<String, dynamic> alert) {
    final String title     = alert['Title']?.toString()
                          ?? alert['title']?.toString()
                          ?? t('Alert');
    final String body      = alert['Message']?.toString()
                          ?? alert['message']?.toString()
                          ?? alert['body']?.toString() ?? '';
    final String type      = alert['alert_type']?.toString()
                          ?? alert['AlertType']?.toString() ?? 'info';
    final bool   isRead    = alert['IsRead'] == true
                          || alert['is_read'] == true;
    final String dateRaw   = alert['DateCreated']?.toString()
                          ?? alert['date_created']?.toString() ?? '';

    IconData alertIcon  = Icons.notifications_outlined;
    Color    alertColor = const Color(0xFF388E3C);
    if (type.contains('disease') || type.contains('pest')) {
      alertIcon  = Icons.bug_report_outlined;
      alertColor = Colors.orange;
    } else if (type.contains('weather') || type.contains('frost')) {
      alertIcon  = Icons.wb_cloudy_outlined;
      alertColor = Colors.blue;
    } else if (type.contains('market') || type.contains('price')) {
      alertIcon  = Icons.monetization_on_outlined;
      alertColor = Colors.purple;
    } else if (type.contains('critical') || type.contains('danger')) {
      alertIcon  = Icons.warning_amber_rounded;
      alertColor = Colors.red;
    }

    return GestureDetector(
      onTap: _openAlerts,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead
              ? (const Color(0xFFF9F9F9))
              : alertColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Colors.grey.shade200
                : alertColor.withOpacity(0.25),
          ),
        ),
        child: Row(children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        alertColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(alertIcon, color: alertColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: isRead
                              ? FontWeight.w500 : FontWeight.bold,
                          color: const Color(0xFF1B1B1B),
                        )),
                  ),
                  if (!isRead)
                    Container(
                      width:  7,
                      height: 7,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color:  alertColor,
                        shape:  BoxShape.circle,
                      ),
                    ),
                ]),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color:    Color(0xFF666666),
                        height:   1.3,
                      )),
                ],
                if (dateRaw.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(dateRaw),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: Color(0xFFCCCCCC)),
        ]),
      ),
    );
  }

  Widget _alertEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 36, color: Colors.grey.shade300),
          const SizedBox(height: 6),
          Text(
            t('No alerts at the moment'),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertGuestState() {
    return GestureDetector(
      onTap: () => _showSignInRequiredDialog(context, t('alerts')),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: Color(0xFF9E9E9E), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t('Sign in to receive disease and weather alerts for your district'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: t('Home')),
      _NavItem(icon: Icons.forum_rounded, label: t('Community')),
      _NavItem(icon: Icons.menu_book_rounded, label: t('Resources')),
      _NavItem(icon: Icons.account_circle_rounded, label: t('Profile')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap:    () => _onNavTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon,
                          size:  24,
                          color: selected
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF9E9E9E)),
                      const SizedBox(height: 3),
                      Text(items[i].label,
                          style: TextStyle(
                            fontSize:   10,
                            fontWeight: selected
                                ? FontWeight.w700 : FontWeight.w400,
                            color: selected
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFF9E9E9E),
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _QuickTile {
  final String       label;
  final String       sub;
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  final Key?         tourKey;
  _QuickTile({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tourKey,
  });
}

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home Content'));
  }
}
