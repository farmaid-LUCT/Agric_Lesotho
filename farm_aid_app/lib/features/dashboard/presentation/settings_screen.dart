
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import 'package:farm_aid_app/services/auth_service.dart';
import 'package:farm_aid_app/features/scanner/data/ai_service.dart';
import 'package:farm_aid_app/features/dashboard/presentation/profile_screen.dart';
import 'package:farm_aid_app/services/theme_provider.dart';
import 'package:farm_aid_app/services/language_provider.dart';
import 'package:farm_aid_app/core/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final AIService   _aiService   = AIService();

  static const Color primaryGreen = Color(0xFF2E7D32);

  bool _isSyncing   = false;
  bool _syncSuccess = false;

  // Notification prefs — loaded from cached profile
  bool _notifyDiseases = true;
  bool _notifyWeather  = true;
  bool _notifyMarket   = false;

  // Cached profile data for header
  Map<String, dynamic>? _cachedProfile;

  Color get textColor    => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  Color get subTextColor => Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
  Color get cardColor    => Theme.of(context).cardColor;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // --------------------------------------------------------
  // Load profile (instant from cache, then refresh)
  // --------------------------------------------------------
  Future<void> _loadProfile() async {
    final cached = await _authService.getCachedProfile();
    if (cached != null && mounted) {
      setState(() {
        _cachedProfile   = cached;
        _notifyDiseases  = cached['notification_diseases'] ?? true;
        _notifyWeather   = cached['notification_weather']  ?? true;
        _notifyMarket    = cached['notification_market']   ?? false;
      });
    }

    // Refresh from network in background
    final fresh = await _authService.getCurrentUser();
    if (fresh != null && mounted) {
      setState(() {
        _cachedProfile   = fresh;
        _notifyDiseases  = fresh['notification_diseases'] ?? true;
        _notifyWeather   = fresh['notification_weather']  ?? true;
        _notifyMarket    = fresh['notification_market']   ?? false;
      });
    }
  }

  // --------------------------------------------------------
  // Notification toggle — saves to backend immediately
  // --------------------------------------------------------
  Future<void> _toggleNotification(String field, bool value) async {
    setState(() {
      if (field == 'diseases') _notifyDiseases = value;
      if (field == 'weather')  _notifyWeather  = value;
      if (field == 'market')   _notifyMarket   = value;
    });

    await _authService.updateProfile(
      notificationDiseases: field == 'diseases' ? value : null,
      notificationWeather:  field == 'weather'  ? value : null,
      notificationMarket:   field == 'market'   ? value : null,
    );
  }

  // --------------------------------------------------------
  // Password dialog
  // --------------------------------------------------------
  void _showPasswordDialog() {
    final appLoc = AppLocalizations.of(context);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool isLoading  = false;
    bool obscureOld = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            appLoc?.translate('password') ?? 'Password',
            style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: obscureOld,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: appLoc?.translate('current_password') ?? 'Current Password',
                  labelStyle: TextStyle(color: subTextColor),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, color: primaryGreen),
                    onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: appLoc?.translate('new_password') ?? 'New Password',
                  labelStyle: TextStyle(color: subTextColor),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: primaryGreen),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLoc?.translate('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      final result = await _authService.changePassword(
                          oldCtrl.text, newCtrl.text);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _showSnackBar(result['success'] == true
                          ? (appLoc?.translate('password_updated') ?? 'Password updated!')
                          : result['message'] ?? 'Failed');
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      appLoc?.translate('update') ?? 'UPDATE',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // Sync, language, cache, logout
  // --------------------------------------------------------
  Future<void> _handleNeonSync() async {
    setState(() { _isSyncing = true; _syncSuccess = false; });
    await _authService.getCurrentUser();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() { _isSyncing = false; _syncSuccess = true; });
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _handleClearCache() async {
    await _authService.signOut();
    if (mounted) {
      _showSnackBar(AppLocalizations.of(context)?.translate('cache_cleared') ?? 'Cache cleared');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showLanguagePicker() {
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    final appLoc   = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLoc?.translate('lang_pref') ?? 'Language Preference',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen),
            ),
            const SizedBox(height: 20),
            for (final lang in [
              {'code': 'en', 'label': '🇬🇧  English'},
              {'code': 'st', 'label': '🇱🇸  Sesotho'},
            ])
              ListTile(
                title: Text(lang['label']!, style: TextStyle(color: textColor)),
                trailing: langProv.appLocale.languageCode == lang['code']
                    ? const Icon(Icons.check_circle, color: primaryGreen)
                    : null,
                onTap: () async {
                  final code = lang['code']!;
                  langProv.changeLanguage(Locale(code));
                  Navigator.pop(context);
                  final user = _cachedProfile;
                  if (user != null) {
                    await _authService.updateProfile(
                      language: code,
                      district: user['district'],
                    );
                  }
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final Uri tel = Uri(scheme: 'tel', path: '+26658575277');
    if (await canLaunchUrl(tel)) await launchUrl(tel);
  }

  void _shareApp() => Share.share(
      'Protect your vegetables with FarmAid Lesotho!',
      subject: 'Check out FarmAid Lesotho');

  void _showTerms() => _showInfoModal(
      AppLocalizations.of(context)?.translate('terms_cond') ?? 'Terms',
      '1. AI Accuracy: Supportive guide for Vegetables only.\n\n2. Data: Results saved in Neon DB.');

  void _showFAQ() => _showInfoModal(
      AppLocalizations.of(context)?.translate('help_faq') ?? 'Help',
      '• Supported crops: Tomato, Cabbage, Pepper, Onion, Potato.\n\n• GPS is used to personalise disease advice for your location.\n\n• Soil type and irrigation method improve recommendation accuracy.');

  void _showSnackBar(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  void _showInfoModal(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen)),
              const Divider(height: 30),
              Text(content, style: TextStyle(fontSize: 16, height: 1.6, color: subTextColor)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)?.translate('i_understand') ?? 'I UNDERSTAND',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final langProv  = Provider.of<LanguageProvider>(context);
    final appLoc    = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          appLoc?.translate('settings_title') ?? 'Settings',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileHeader(),
            const SizedBox(height: 25),

            // --- Account ---
            _buildSectionLabel('Account'),
            _buildSettingsCard([
              _buildListTile(Icons.person_outline,
                  appLoc?.translate('profile_details') ?? 'Profile & Experience',
                  onTap: () async {
                    final result = await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    if (result == true) _loadProfile();
                  }),
              _buildListTile(Icons.lock_outline,
                  appLoc?.translate('password') ?? 'Password',
                  onTap: _showPasswordDialog),
              _buildSwitchTile(
                  Icons.dark_mode_outlined,
                  appLoc?.translate('dark_mode') ?? 'Dark Mode',
                  themeProv.isDarkMode,
                  (val) => themeProv.toggleTheme(val)),
            ]),
            const SizedBox(height: 20),

            // --- Notifications (NEW) ---
            _buildSectionLabel('Notifications'),
            _buildSettingsCard([
              _buildSwitchTile(
                  Icons.biotech_outlined,
                  'Disease Alerts',
                  _notifyDiseases,
                  (val) => _toggleNotification('diseases', val),
                  subtitle: 'Get notified when diseases are detected nearby'),
              _buildSwitchTile(
                  Icons.wb_cloudy_outlined,
                  'Weather Alerts',
                  _notifyWeather,
                  (val) => _toggleNotification('weather', val),
                  subtitle: 'Frost, heavy rain and drought warnings'),
              _buildSwitchTile(
                  Icons.monetization_on_outlined,
                  'Market Price Alerts',
                  _notifyMarket,
                  (val) => _toggleNotification('market', val),
                  subtitle: 'Price changes for your active crops'),
            ]),
            const SizedBox(height: 20),

            // --- Language & Sync ---
            _buildSectionLabel('Language & Data'),
            _buildSettingsCard([
              _buildListTile(
                Icons.translate,
                appLoc?.translate('lang_pref') ?? 'Language Preference',
                subtitle: langProv.appLocale.languageCode == 'en' ? 'English' : 'Sesotho',
                onTap: _showLanguagePicker,
              ),
              _buildListTile(
                Icons.cloud_sync_outlined,
                appLoc?.translate('sync_neon') ?? 'Sync Profile',
                subtitle: _isSyncing
                    ? (appLoc?.translate('syncing') ?? 'Syncing...')
                    : (_syncSuccess
                        ? (appLoc?.translate('synced') ?? 'Synced ✓')
                        : (appLoc?.translate('sync_desc') ?? 'Refresh from server')),
                onTap: _isSyncing ? null : _handleNeonSync,
                trailing: _isSyncing
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : (_syncSuccess
                        ? const Icon(Icons.check_circle, color: primaryGreen, size: 20)
                        : null),
              ),
            ]),
            const SizedBox(height: 20),

            // --- Support ---
            _buildSectionLabel('Support'),
            _buildSettingsCard([
              _buildListTile(Icons.description_outlined,
                  appLoc?.translate('terms_cond') ?? 'Terms & Conditions',
                  onTap: _showTerms),
              _buildListTile(Icons.contact_support,
                  appLoc?.translate('contact_support') ?? 'Contact Support',
                  onTap: _contactSupport),
              _buildListTile(Icons.help_outline,
                  appLoc?.translate('help_faq') ?? 'Help & FAQ',
                  onTap: _showFAQ),
              _buildListTile(Icons.share_outlined,
                  appLoc?.translate('share_app') ?? 'Share App',
                  onTap: _shareApp),
            ]),
            const SizedBox(height: 20),

            // --- Danger Zone ---
            _buildSectionLabel('Account Actions'),
            _buildSettingsCard([
              _buildListTile(Icons.logout,
                  appLoc?.translate('logout') ?? 'Logout',
                  textColor: Colors.red,
                  onTap: _handleLogout),
              _buildListTile(Icons.delete_sweep_outlined,
                  appLoc?.translate('clear_cache') ?? 'Clear Cache',
                  textColor: Colors.red,
                  subtitle: appLoc?.translate('clear_cache_desc') ?? 'Clears local data and logs you out',
                  onTap: _handleClearCache),
            ]),

            const SizedBox(height: 40),
            Text('FarmAid Lesotho v1.1.0',
                style: TextStyle(color: subTextColor, fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // WIDGETS
  // --------------------------------------------------------
  Widget _buildProfileHeader() {
    final appLoc       = AppLocalizations.of(context);
    final name         = _cachedProfile?['full_name'] ?? 'Loading...';
    final district     = _cachedProfile?['district'] ?? '';
    final experience   = _cachedProfile?['experience_level'] ?? 'beginner';
    final photoUrl     = _cachedProfile?['profile_photo_url'];
    final districtLabel = appLoc?.translate('district_suffix') ?? 'District, LS';

    final experienceIcon = {
      'beginner':     '🌱',
      'intermediate': '🌿',
      'expert':       '🌾',
    }[experience] ?? '🌱';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE8F5E9),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, size: 40, color: primaryGreen)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Text('$district $districtLabel',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('$experienceIcon ${experience[0].toUpperCase()}${experience.substring(1)} Farmer',
                    style: const TextStyle(color: primaryGreen, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.verified_user, size: 20, color: primaryGreen),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: subTextColor,
                letterSpacing: 1.2)),
      );

  Widget _buildSettingsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(children: children),
      );

  Widget _buildListTile(
    IconData icon,
    String title, {
    String? subtitle,
    Color? textColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) =>
      ListTile(
        leading: Icon(icon, color: textColor ?? primaryGreen),
        title: Text(title,
            style: TextStyle(
                color: textColor ?? this.textColor,
                fontWeight: FontWeight.w500,
                fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      );

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) =>
      SwitchListTile(
        secondary: Icon(icon, color: primaryGreen),
        title: Text(title,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: primaryGreen,
      );
}
