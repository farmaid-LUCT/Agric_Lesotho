// lib/features/dashboard/presentation/settings_screen.dart

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

  bool _notifyDiseases = true;
  bool _notifyWeather  = true;
  bool _notifyMarket   = false;

  Map<String, dynamic>? _cachedProfile;

  Color get textColor    => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  Color get subTextColor => Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
  Color get cardColor    => Theme.of(context).cardColor;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = await _authService.getCachedProfile();
    if (cached != null && mounted) {
      setState(() {
        _cachedProfile  = cached;
        _notifyDiseases = cached['notification_diseases'] ?? true;
        _notifyWeather  = cached['notification_weather']  ?? true;
        _notifyMarket   = cached['notification_market']   ?? false;
      });
    }
    final fresh = await _authService.getCurrentUser();
    if (fresh != null && mounted) {
      setState(() {
        _cachedProfile  = fresh;
        _notifyDiseases = fresh['notification_diseases'] ?? true;
        _notifyWeather  = fresh['notification_weather']  ?? true;
        _notifyMarket   = fresh['notification_market']   ?? false;
      });
    }
  }

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

  void _showPasswordDialog() {
    final appLoc  = AppLocalizations.of(context);
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: Text(
              appLoc?.translate('password') ?? 'Password',
              style: const TextStyle(
                  color: primaryGreen, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: obscureOld,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: appLoc?.translate('current_password') ??
                      'Current Password',
                  labelStyle: TextStyle(color: subTextColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscureOld
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: primaryGreen),
                    onPressed: () =>
                        setDialogState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText:
                      appLoc?.translate('new_password') ?? 'New Password',
                  labelStyle: TextStyle(color: subTextColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: primaryGreen),
                    onPressed: () =>
                        setDialogState(() => obscureNew = !obscureNew),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      final result = await _authService.changePassword(
                          oldCtrl.text, newCtrl.text);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _showSnackBar(result['success'] == true
                          ? (appLoc?.translate('password_updated') ??
                              'Password updated!')
                          : result['message'] ?? 'Failed');
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(appLoc?.translate('update') ?? 'UPDATE',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

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
      _showSnackBar(AppLocalizations.of(context)
              ?.translate('cache_cleared') ??
          'Cache cleared');
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                appLoc?.translate('lang_pref') ?? 'Language Preference',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen)),
            const SizedBox(height: 20),
            for (final lang in [
              {'code': 'en', 'label': '🇬🇧  English'},
              {'code': 'st', 'label': '🇱🇸  Sesotho'},
            ])
              ListTile(
                title: Text(lang['label']!,
                    style: TextStyle(color: textColor)),
                trailing:
                    langProv.appLocale.languageCode == lang['code']
                        ? const Icon(Icons.check_circle,
                            color: primaryGreen)
                        : null,
                onTap: () async {
                  final code = lang['code']!;
                  langProv.changeLanguage(Locale(code));
                  Navigator.pop(context);
                  final user = _cachedProfile;
                  if (user != null) {
                    await _authService.updateProfile(
                        language: code,
                        district: user['district']);
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

  void _showFAQ() {
    final isWide = MediaQuery.of(context).size.width > 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => isWide
          // ── DESKTOP: centered dialog ────────────────────────
          ? Center(
              child: Container(
                width: 600,
                height: MediaQuery.of(context).size.height * 0.85,
                margin: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _buildFaqContent(),
              ),
            )
          // ── MOBILE: draggable sheet ─────────────────────────
          : DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize:     0.95,
              minChildSize:     0.5,
              builder: (_, scrollCtrl) => Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26)),
                ),
                child: _buildFaqContent(scrollCtrl: scrollCtrl),
              ),
            ),
    );
  }

  Widget _buildFaqContent({ScrollController? scrollCtrl}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: Column(children: [
            Container(
              width: 44, height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_outline,
                    color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Help & FAQ',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const Text('FarmAid Lesotho  v1.1',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        ),

        const Divider(height: 1),

        Expanded(
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _faqSection('Getting Started', [
                _FaqItem('What is FarmAid Lesotho?',
                    'FarmAid is an AI-powered crop disease detection app built for farmers in Lesotho. '
                    'Take a photo of a sick plant and the app identifies the disease and gives personalised '
                    'treatment advice within seconds.'),
                _FaqItem('Do I need internet to use the app?',
                    'The AI disease scan works fully offline using a model stored on your device. '
                    'You need internet to save results, receive disease alerts, get live weather data, '
                    'and access personalised recommendations from the server.'),
                _FaqItem('Is the app free to use?',
                    'Yes. FarmAid Lesotho is completely free for all farmers. '
                    'There are no subscription fees or hidden charges.'),
              ]),
              _faqSection('Supported Crops', [
                _FaqItem('Which vegetables does the AI recognise?',
                    'The model is trained on 15 crops common to Lesotho:\n\n'
                    'Tomato, Cabbage, Cauliflower, Potato, Onion, Spinach, Kale, '
                    'Lettuce, Carrot, Beans, Cucumber, Eggplant, Bitter Gourd, '
                    'Bottle Gourd, Pumpkin and Radish.'),
                _FaqItem('How many diseases can the AI detect?',
                    'Over 90 disease and pest conditions across all supported crops, '
                    'including fungal, bacterial, viral and pest damage categories. '
                    'The model also correctly identifies healthy crops.'),
              ]),
              _faqSection('Scanning Tips', [
                _FaqItem('How do I get the most accurate scan?',
                    '- Use good natural light and avoid harsh shadows\n'
                    '- Hold the camera 20-30cm from the leaf\n'
                    '- Fill the frame with the affected leaf or symptom\n'
                    '- Capture the most severe symptom visible\n'
                    '- Keep the phone steady to avoid blur\n'
                    '- Use the "Adjust image" tool to rotate and zoom before scanning'),
                _FaqItem('What is the difference between General and Personalised scan?',
                    'General scan gives standard treatment advice for the detected disease.\n\n'
                    'Personalised scan uses your full farm profile (soil type, irrigation method, '
                    'plot size, district, altitude, growth stage, variety, season and rainfall) '
                    'to calculate the exact product amount for your plot and give advice '
                    'tailored to your specific farming conditions.'),
                _FaqItem('Why was my image rejected?',
                    'The AI only accepts images of crop leaves or plant parts. '
                    'Photos of soil, tools, people, or unrelated objects will be rejected. '
                    'Take a clear close-up photo of the affected leaf or stem and try again.'),
              ]),
              _faqSection('Location & Personalisation', [
                _FaqItem('Why does the app need GPS?',
                    'GPS is used to:\n'
                    '- Match disease alerts specific to your district\n'
                    '- Provide live weather data and spray window advice\n'
                    '- Personalise treatment rules based on your altitude and rainfall level\n\n'
                    'Location data is never shared or sold. If you deny permission, '
                    'the app falls back to your registered district.'),
                _FaqItem('What is a Crop Profile?',
                    'A Crop Profile stores your farm details including crop type, soil type, '
                    'irrigation method, plot size and planting date. '
                    'In Personalised mode the app uses all 9 factors to match the best '
                    'treatment rule for your exact conditions and calculates '
                    'the correct chemical dosage for your specific plot size.'),
              ]),
              _faqSection('Treatment & Dosage', [
                _FaqItem('Are the treatment recommendations safe to follow?',
                    'Recommendations follow standard agronomic practices used in Lesotho. '
                    'Always read the product label before applying any chemical, '
                    'observe the pre-harvest interval (PHI) shown in the app, '
                    'and wear appropriate protective equipment.\n\n'
                    'For critical decisions always consult a certified agronomist '
                    'or agricultural extension officer.'),
                _FaqItem('How is the dosage calculated?',
                    'When your Crop Profile includes a plot size, the app multiplies '
                    'the standard per-hectare rate by your actual plot size to give '
                    'you the exact amount needed.\n\n'
                    'Example: instead of "25g per 10L", you see '
                    '"12.5g of Mancozeb in 100L of water for your 0.5ha plot".'),
              ]),
              _faqSection('Account & Data', [
                _FaqItem('Can I use the app without an account?',
                    'Yes, as a guest for scanning. But scan history, disease alerts, '
                    'crop profiles, personalised recommendations and the Growth Journal '
                    'all require a registered account.'),
                _FaqItem('How do I change the app language?',
                    'Go to Settings then Language Preference to switch between '
                    'English and Sesotho. The app supports full translation for all screens.'),
                _FaqItem('Is my data backed up?',
                    'Yes. All scan history, diagnoses, crop profiles and journal entries '
                    'are saved to a secure cloud database. You can access your full '
                    'history on any device by logging into your account.'),
              ]),
              _faqSection('Support', [
                _FaqItem('The AI gave the wrong diagnosis — what do I do?',
                    'AI diagnoses are not always 100% accurate. If the result seems wrong:\n'
                    '- Re-scan with a clearer, better-lit photo\n'
                    '- Use the feedback option after scanning to report the result\n'
                    '- Consult your local agricultural extension officer to confirm\n\n'
                    'Your feedback directly helps improve the model for all Lesotho farmers.'),
                _FaqItem('How do I contact support?',
                    'Use "Contact Support" in Settings to call the FarmAid team directly. '
                    'Include your device model, app version (shown at the bottom of Settings) '
                    'and a clear description of the issue for faster assistance.'),
              ]),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _faqSection(String title, List<_FaqItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                  letterSpacing: 0.3)),
        ),
        ...items.map((item) => Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:    EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                iconColor:          primaryGreen,
                collapsedIconColor: Colors.grey,
                title: Text(item.q,
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color:      textColor)),
                children: [
                  Text(item.a,
                      style: TextStyle(
                          fontSize: 13,
                          height:   1.65,
                          color:    subTextColor)),
                ],
              ),
            )),
      ],
    );
  }

  void _showSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  void _showInfoModal(String title, String content) {
    final isWide = MediaQuery.of(context).size.width > 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => isWide
          ? Center(
              child: Container(
                width:  500,
                margin: const EdgeInsets.symmetric(vertical: 60),
                decoration: BoxDecoration(
                  color:        cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize:   22,
                            fontWeight: FontWeight.bold,
                            color:      primaryGreen)),
                    const Divider(height: 30),
                    Text(content,
                        style: TextStyle(
                            fontSize: 16,
                            height:   1.6,
                            color:    subTextColor)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context)
                                  ?.translate('i_understand') ??
                              'I UNDERSTAND',
                          style: const TextStyle(
                              color:      Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : DraggableScrollableSheet(
              initialChildSize: 0.6,
              builder: (_, scrollController) => Container(
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25))),
                padding: const EdgeInsets.all(24.0),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize:   22,
                            fontWeight: FontWeight.bold,
                            color:      primaryGreen)),
                    const Divider(height: 30),
                    Text(content,
                        style: TextStyle(
                            fontSize: 16,
                            height:   1.6,
                            color:    subTextColor)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.of(context)
                                ?.translate('i_understand') ??
                            'I UNDERSTAND',
                        style: const TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final langProv  = Provider.of<LanguageProvider>(context);
    final appLoc    = AppLocalizations.of(context);
    final isWide    = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isWide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildScrollContent(themeProv, langProv, appLoc),
              ),
            )
          : _buildScrollContent(themeProv, langProv, appLoc),
    );
  }

  Widget _buildScrollContent(
    ThemeProvider themeProv,
    LanguageProvider langProv,
    AppLocalizations? appLoc,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ── Floating back button row ────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size:  18,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    appLoc?.translate('settings_title') ?? 'Settings',
                    style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.bold,
                      color:      textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildProfileHeader(),
          const SizedBox(height: 25),

          _buildSectionLabel('Account'),
          _buildSettingsCard([
            _buildListTile(
              Icons.person_outline,
              appLoc?.translate('profile_details') ??
                  'Profile & Experience',
              onTap: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()));
                if (result == true) _loadProfile();
              },
            ),
            _buildListTile(
              Icons.lock_outline,
              appLoc?.translate('password') ?? 'Password',
              onTap: _showPasswordDialog,
            ),
            _buildSwitchTile(
              Icons.dark_mode_outlined,
              appLoc?.translate('dark_mode') ?? 'Dark Mode',
              themeProv.isDarkMode,
              (val) => themeProv.toggleTheme(val),
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionLabel('Notifications'),
          _buildSettingsCard([
            _buildSwitchTile(
              Icons.biotech_outlined,
              'Disease Alerts',
              _notifyDiseases,
              (val) => _toggleNotification('diseases', val),
              subtitle: 'Get notified when diseases are detected nearby',
            ),
            _buildSwitchTile(
              Icons.wb_cloudy_outlined,
              'Weather Alerts',
              _notifyWeather,
              (val) => _toggleNotification('weather', val),
              subtitle: 'Frost, heavy rain and drought warnings',
            ),
            _buildSwitchTile(
              Icons.monetization_on_outlined,
              'Market Price Alerts',
              _notifyMarket,
              (val) => _toggleNotification('market', val),
              subtitle: 'Price changes for your active crops',
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionLabel('Language & Data'),
          _buildSettingsCard([
            _buildListTile(
              Icons.translate,
              appLoc?.translate('lang_pref') ?? 'Language Preference',
              subtitle: langProv.appLocale.languageCode == 'en'
                  ? 'English'
                  : 'Sesotho',
              onTap: _showLanguagePicker,
            ),
            _buildListTile(
              Icons.cloud_sync_outlined,
              appLoc?.translate('sync_neon') ?? 'Sync Profile',
              subtitle: _isSyncing
                  ? (appLoc?.translate('syncing') ?? 'Syncing...')
                  : (_syncSuccess
                      ? (appLoc?.translate('synced') ?? 'Synced')
                      : (appLoc?.translate('sync_desc') ??
                          'Refresh from server')),
              onTap: _isSyncing ? null : _handleNeonSync,
              trailing: _isSyncing
                  ? const SizedBox(
                      width:  15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : (_syncSuccess
                      ? const Icon(Icons.check_circle,
                          color: primaryGreen, size: 20)
                      : null),
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionLabel('Support'),
          _buildSettingsCard([
            _buildListTile(
              Icons.description_outlined,
              appLoc?.translate('terms_cond') ?? 'Terms & Conditions',
              onTap: _showTerms,
            ),
            _buildListTile(
              Icons.contact_support,
              appLoc?.translate('contact_support') ?? 'Contact Support',
              onTap: _contactSupport,
            ),
            _buildListTile(
              Icons.help_outline,
              appLoc?.translate('help_faq') ?? 'Help & FAQ',
              onTap: _showFAQ,
            ),
            _buildListTile(
              Icons.share_outlined,
              appLoc?.translate('share_app') ?? 'Share App',
              onTap: _shareApp,
            ),
          ]),
          const SizedBox(height: 20),

          _buildSectionLabel('Account Actions'),
          _buildSettingsCard([
            _buildListTile(
              Icons.logout,
              appLoc?.translate('logout') ?? 'Logout',
              textColor: Colors.red,
              onTap: _handleLogout,
            ),
            _buildListTile(
              Icons.delete_sweep_outlined,
              appLoc?.translate('clear_cache') ?? 'Clear Cache',
              textColor: Colors.red,
              subtitle: appLoc?.translate('clear_cache_desc') ??
                  'Clears local data and logs you out',
              onTap: _handleClearCache,
            ),
          ]),

          const SizedBox(height: 40),
          Text('FarmAid Lesotho v1.1.0',
              style: TextStyle(color: subTextColor, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final appLoc     = AppLocalizations.of(context);
    final name       = _cachedProfile?['full_name'] ?? 'Loading...';
    final district   = _cachedProfile?['district']  ?? '';
    final experience = _cachedProfile?['experience_level'] ?? 'beginner';
    final photoUrl   = _cachedProfile?['profile_photo_url'];
    final districtLabel =
        appLoc?.translate('district_suffix') ?? 'District, LS';

    final experienceIcon = {
      'beginner':     '🌱',
      'intermediate': '🌿',
      'expert':       '🌾',
    }[experience] ?? '🌱';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE8F5E9),
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl) : null,
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
                        fontSize:   17,
                        fontWeight: FontWeight.bold,
                        color:      textColor)),
                Text('$district $districtLabel',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '$experienceIcon ${experience[0].toUpperCase()}${experience.substring(1)} Farmer',
                  style: const TextStyle(
                      color: primaryGreen, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user,
              size: 20, color: primaryGreen),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.bold,
                color:      subTextColor,
                letterSpacing: 1.2)),
      );

  Widget _buildSettingsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset:     const Offset(0, 5))
          ],
        ),
        child: Column(children: children),
      );

  Widget _buildListTile(
    IconData icon,
    String title, {
    String?       subtitle,
    Color?        textColor,
    VoidCallback? onTap,
    Widget?       trailing,
  }) =>
      ListTile(
        leading: Icon(icon, color: textColor ?? primaryGreen),
        title: Text(title,
            style: TextStyle(
                color:      textColor ?? this.textColor,
                fontWeight: FontWeight.w500,
                fontSize:   15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey))
            : null,
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey),
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
                color:      textColor,
                fontWeight: FontWeight.w500,
                fontSize:   15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey))
            : null,
        value:       value,
        onChanged:   onChanged,
        activeColor: primaryGreen,
      );
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem(this.q, this.a);
}