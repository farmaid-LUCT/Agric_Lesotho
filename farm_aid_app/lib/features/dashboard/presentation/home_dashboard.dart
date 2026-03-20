
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Correct Imports
import '../../weather/presentation/weather_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../history/presentation/history_screen.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../alerts/presentation/widgets/alert_bell_icon.dart'; // NEW
import '../../crops/presentation/crop_type_screen.dart';
import './settings_screen.dart';
import '../../../core/constants.dart';
import '../../../core/app_localizations.dart';

// RESOURCE & NEW FEATURE IMPORTS
import '../../resources/presentation/resources_screen.dart';
import '../../resources/presentation/planting_calendar_screen.dart';
import '../../resources/presentation/market_prices_screen.dart';
import '../../history/presentation/growth_journal_screen.dart';

// Import the new separated widget
import 'widgets/scanner_section.dart';

// Tour guide
import '../../onboarding/presentation/tour_guide.dart';

class HomeDashboard extends StatefulWidget {
  final bool showTour;
  const HomeDashboard({super.key, this.showTour = false});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final AuthService _auth = AuthService();
  bool isGuest     = true;
  int _currentIndex = 0;
  final _tourKeys  = TourKeys();

  // ── _alertCount and _alertTimer are REMOVED ───────────────────────────────
  // Polling is now handled entirely by AlertBellIcon widget which calls
  // GET /api/alerts/unread-count/ every 60 s automatically.
  // _notifyFarmerOfNewAlert snackbar is also handled inside AlertBellIcon.

  String t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _syncAuthStatus();
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
    super.dispose();
  }

  Future<void> _syncAuthStatus() async {
    final loggedIn = await _auth.isLoggedIn();
    if (mounted) {
      setState(() => isGuest = !loggedIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool  isDark       = Theme.of(context).brightness == Brightness.dark;
    final Color primaryGreen = isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildHeader(),
              const SizedBox(height: 15),
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
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type:                  BottomNavigationBarType.fixed,
        backgroundColor:       isDark ? const Color(0xFF1E1E1E) : Colors.white,
        currentIndex:          _currentIndex,
        selectedItemColor:     primaryGreen,
        unselectedItemColor:   isDark ? Colors.white54 : Colors.black54,
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
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _onNavTap(String key) {
    if (key == 'weather') {
      _openWeather();
    } else if (isGuest) {
      _showSignInRequiredDialog(context, t(key));
    } else {
      if (key == 'history')  _openHistory();
      if (key == 'crops')    _openCropType();
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

  // ── Sign-in required dialog ────────────────────────────────────────────────
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

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final bool  isDark    = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.greenAccent : Colors.green;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Logo + app name ────────────────────────────────────────────────
        Row(
          children: [
            CircleAvatar(
              key:             _tourKeys.logo,
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

        // ── Action icons ───────────────────────────────────────────────────
        Row(
          children: [
            // ── BELL ICON ─────────────────────────────────────────────────
            // AlertBellIcon handles its own polling, badge, shake animation,
            // and navigation to AlertsScreen.
            // For guests we wrap it so tapping shows the sign-in dialog.
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
              // Keyed so the tour guide can still highlight it
              KeyedSubtree(
                key: _tourKeys.alertBell,
                child: const AlertBellIcon(), // ← NEW widget takes over
              ),

            // ── Overflow menu ──────────────────────────────────────────────
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
                  case 'resources':
                    _openResources();
                    break;
                  case 'calendar':
                    _openCalendar();
                    break;
                  case 'prices':
                    _openMarketPrices();
                    break;
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
                PopupMenuItem(
                  value: 'journal',
                  child: ListTile(
                    leading: const Icon(Icons.book_outlined,
                        color: Colors.green),
                    title: Text(t('Growth Journal')),
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'resources',
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined,
                        color: Colors.green),
                    title: Text(t('Resources')),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'calendar',
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month_outlined,
                        color: Colors.green),
                    title: Text(t('Planting Calendar')),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'prices',
                  child: ListTile(
                    leading: const Icon(Icons.monetization_on_outlined,
                        color: Colors.green),
                    title: Text(t('Market Prices')),
                    dense: true,
                  ),
                ),
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

  // ── Guest banner ───────────────────────────────────────────────────────────
  Widget _buildGuestBanner() {
    if (!isGuest) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
          Icon(
            Icons.info_outline,
            color: isDark
                ? Colors.greenAccent
                : const Color(0xFF2E7D32),
          ),
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
