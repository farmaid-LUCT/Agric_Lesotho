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

  // ── Brand colors — same as home page ──────────────────────────
  static const Color _deepForest  = Color(0xFF1B5E20);
  static const Color _midForest   = Color(0xFF2D6A4F);
  static const Color _accent      = Color(0xFF2E7D32);
  static const Color _lightGreen  = Color(0xFF40916C);

  bool _isSyncing   = false;
  bool _syncSuccess = false;

  bool _notifyDiseases = true;
  bool _notifyWeather  = true;
  bool _notifyMarket   = false;

  Map<String, dynamic>? _cachedProfile;

  // ── Theme helpers — read locally like home page does ──────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _textPrimary   => _isDark ? Colors.white        : const Color(0xFF1A1A1A);
  Color get _textSecondary => _isDark ? Colors.white54      : const Color(0xFF666666);
  Color get _cardBg        => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _pageBg        => _isDark ? const Color(0xFF121212) : const Color(0xFFF0F7F0);
  Color get _brandColor    => _isDark ? Colors.greenAccent  : _deepForest;

  String t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

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
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool isLoading  = false;
    bool obscureOld = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            t('password'),
            style: TextStyle(
                color: _brandColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller:  oldCtrl,
                obscureText: obscureOld,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  labelText:  t('current_password'),
                  labelStyle: TextStyle(color: _textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureOld ? Icons.visibility_off : Icons.visibility,
                      color: _accent,
                    ),
                    onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller:  newCtrl,
                obscureText: obscureNew,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  labelText:  t('new_password'),
                  labelStyle: TextStyle(color: _textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: _accent,
                    ),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel'),
                  style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      final result = await _authService.changePassword(
                          oldCtrl.text, newCtrl.text);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _showSnackBar(result['success'] == true
                          ? t('password_updated')
                          : result['message'] ?? t('failed'));
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(t('update'),
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
      _showSnackBar(t('cache_cleared_msg'));
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showLanguagePicker() {
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color:        _cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        _isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t('lang_pref'),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: _brandColor),
            ),
            const SizedBox(height: 16),
            for (final lang in [
              {'code': 'en', 'label': '🇬🇧  English'},
              {'code': 'st', 'label': '🇱🇸  Sesotho'},
            ])
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: langProv.appLocale.languageCode == lang['code']
                      ? _accent.withOpacity(_isDark ? 0.15 : 0.08)
                      : _isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: langProv.appLocale.languageCode == lang['code']
                        ? _accent.withOpacity(0.4)
                        : _isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  title: Text(lang['label']!,
                      style: TextStyle(
                        color:      _textPrimary,
                        fontWeight: langProv.appLocale.languageCode == lang['code']
                            ? FontWeight.bold : FontWeight.normal,
                      )),
                  trailing: langProv.appLocale.languageCode == lang['code']
                      ? Icon(Icons.check_circle_rounded,
                          color: _accent, size: 20)
                      : null,
                  onTap: () async {
                    final code = lang['code']!;
                    langProv.changeLanguage(Locale(code));
                    Navigator.pop(context);
                    final user = _cachedProfile;
                    if (user != null) {
                      await _authService.updateProfile(
                          language: code, district: user['district']);
                    }
                  },
                ),
              ),
            const SizedBox(height: 8),
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
      t('share_app_message'),
      subject: t('share_app_subject'));

  void _showTerms() => _showInfoModal(t('terms_cond'), t('terms_content'));

  void _showFAQ() {
    final isWide = MediaQuery.of(context).size.width > 600;
    showModalBottomSheet(
      context: context,
      isScrollControlled:  true,
      backgroundColor: Colors.transparent,
      builder: (_) => isWide
          ? Center(
              child: Container(
                width:  600,
                height: MediaQuery.of(context).size.height * 0.85,
                margin: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color:        _cardBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _buildFaqContent(),
              ),
            )
          : DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize:     0.95,
              minChildSize:     0.5,
              builder: (_, scrollCtrl) => Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        _isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding:    const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:        _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.help_outline,
                    color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('help_faq'),
                        style: TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.bold,
                          color:      _textPrimary,
                        )),
                    Text('FarmAid Lesotho  v1.1',
                        style: TextStyle(
                            fontSize: 11, color: _textSecondary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: _textSecondary),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        ),
        Divider(color: _isDark ? Colors.white12 : Colors.grey.shade200,
            height: 1),
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _faqSection(t('faq_getting_started'), [
                _FaqItem(t('faq_what_is_farmaid_q'), t('faq_what_is_farmaid_a')),
                _FaqItem(t('faq_internet_q'), t('faq_internet_a')),
                _FaqItem(t('faq_free_q'), t('faq_free_a')),
              ]),
              _faqSection(t('faq_supported_crops'), [
                _FaqItem(t('faq_which_vegetables_q'), t('faq_which_vegetables_a')),
                _FaqItem(t('faq_how_many_diseases_q'), t('faq_how_many_diseases_a')),
              ]),
              _faqSection(t('faq_scanning_tips'), [
                _FaqItem(t('faq_accurate_scan_q'), t('faq_accurate_scan_a')),
                _FaqItem(t('faq_scan_modes_q'), t('faq_scan_modes_a')),
                _FaqItem(t('faq_image_rejected_q'), t('faq_image_rejected_a')),
              ]),
              _faqSection(t('faq_location'), [
                _FaqItem(t('faq_gps_q'), t('faq_gps_a')),
                _FaqItem(t('faq_crop_profile_q'), t('faq_crop_profile_a')),
              ]),
              _faqSection(t('faq_treatment'), [
                _FaqItem(t('faq_treatment_safe_q'), t('faq_treatment_safe_a')),
                _FaqItem(t('faq_dosage_calc_q'), t('faq_dosage_calc_a')),
              ]),
              _faqSection(t('faq_account'), [
                _FaqItem(t('faq_guest_q'), t('faq_guest_a')),
                _FaqItem(t('faq_language_q'), t('faq_language_a')),
                _FaqItem(t('faq_backup_q'), t('faq_backup_a')),
              ]),
              _faqSection(t('faq_support'), [
                _FaqItem(t('faq_wrong_diagnosis_q'), t('faq_wrong_diagnosis_a')),
                _FaqItem(t('faq_contact_q'), t('faq_contact_a')),
              ]),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(t('got_it'),
                    style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize:   15)),
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
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 6),
          child: Row(children: [
            Container(
              width:  3,
              height: 14,
              decoration: BoxDecoration(
                color:        _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                  fontSize:      12,
                  fontWeight:    FontWeight.bold,
                  color:         _brandColor,
                  letterSpacing: 0.4,
                )),
          ]),
        ),
        ...items.map((item) => Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:     EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                iconColor:          _accent,
                collapsedIconColor: _textSecondary,
                title: Text(item.q,
                    style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      _textPrimary,
                    )),
                children: [
                  Text(item.a,
                      style: TextStyle(
                        fontSize: 13,
                        height:   1.65,
                        color:    _textSecondary,
                      )),
                ],
              ),
            )),
      ],
    );
  }

  void _showSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:  Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _accent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));

  void _showInfoModal(String title, String content) {
    final isWide = MediaQuery.of(context).size.width > 600;
    showModalBottomSheet(
      context: context,
      isScrollControlled:  true,
      backgroundColor: Colors.transparent,
      builder: (_) => isWide
          ? Center(
              child: Container(
                width:  500,
                margin: const EdgeInsets.symmetric(vertical: 60),
                decoration: BoxDecoration(
                  color:        _cardBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize:   22,
                          fontWeight: FontWeight.bold,
                          color:      _brandColor,
                        )),
                    Divider(
                        height: 30,
                        color: _isDark
                            ? Colors.white12
                            : Colors.grey.shade200),
                    Text(content,
                        style: TextStyle(
                          fontSize: 15,
                          height:   1.6,
                          color:    _textSecondary,
                        )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          elevation:       0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(t('i_understand'),
                            style: const TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.bold)),
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
                  color: _cardBg,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(24.0),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color:        _isDark
                              ? Colors.white24
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(title,
                        style: TextStyle(
                          fontSize:   22,
                          fontWeight: FontWeight.bold,
                          color:      _brandColor,
                        )),
                    Divider(
                        height: 30,
                        color: _isDark
                            ? Colors.white12
                            : Colors.grey.shade200),
                    Text(content,
                        style: TextStyle(
                          fontSize: 15,
                          height:   1.6,
                          color:    _textSecondary,
                        )),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        elevation:       0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(t('i_understand'),
                          style: const TextStyle(
                              color:      Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final langProv  = Provider.of<LanguageProvider>(context);
    final isWide    = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _pageBg,
      body: isWide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildScrollContent(themeProv, langProv),
              ),
            )
          : _buildScrollContent(themeProv, langProv),
    );
  }

  Widget _buildScrollContent(
    ThemeProvider themeProv,
    LanguageProvider langProv,
  ) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildSectionLabel(t('account_section')),
                _buildSettingsCard([
                  _buildListTile(
                    Icons.person_outline,
                    t('profile_details'),
                    onTap: () async {
                      final result = await Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()));
                      if (result == true) _loadProfile();
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    Icons.lock_outline,
                    t('password'),
                    onTap: _showPasswordDialog,
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    Icons.dark_mode_outlined,
                    t('dark_mode'),
                    themeProv.isDarkMode,
                    (val) => themeProv.toggleTheme(val),
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionLabel(t('notifications_section')),
                _buildSettingsCard([
                  _buildSwitchTile(
                    Icons.biotech_outlined,
                    t('disease_alerts'),
                    _notifyDiseases,
                    (val) => _toggleNotification('diseases', val),
                    subtitle: t('disease_alerts_sub'),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    Icons.wb_cloudy_outlined,
                    t('weather_alerts'),
                    _notifyWeather,
                    (val) => _toggleNotification('weather', val),
                    subtitle: t('weather_alerts_sub'),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    Icons.monetization_on_outlined,
                    t('market_alerts'),
                    _notifyMarket,
                    (val) => _toggleNotification('market', val),
                    subtitle: t('market_alerts_sub'),
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionLabel(t('language_data_section')),
                _buildSettingsCard([
                  _buildListTile(
                    Icons.translate,
                    t('lang_pref'),
                    subtitle: langProv.appLocale.languageCode == 'en'
                        ? 'English'
                        : 'Sesotho',
                    onTap: _showLanguagePicker,
                  ),
                  _buildDivider(),
                  _buildListTile(
                    Icons.cloud_sync_outlined,
                    t('sync_neon'),
                    subtitle: _isSyncing
                        ? t('syncing')
                        : (_syncSuccess
                            ? t('synced')
                            : t('sync_desc')),
                    onTap: _isSyncing ? null : _handleNeonSync,
                    trailing: _isSyncing
                        ? SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _accent))
                        : (_syncSuccess
                            ? Icon(Icons.check_circle_rounded,
                                color: _accent, size: 20)
                            : null),
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionLabel(t('support_section')),
                _buildSettingsCard([
                  _buildListTile(
                    Icons.description_outlined,
                    t('terms_cond'),
                    onTap: _showTerms,
                  ),
                  _buildDivider(),
                  _buildListTile(
                    Icons.contact_support,
                    t('contact_support'),
                    onTap: _contactSupport,
                  ),
                  _buildDivider(),
                  _buildListTile(
                    Icons.help_outline,
                    t('help_faq'),
                    onTap: _showFAQ,
                  ),
                  _buildDivider(),
                  _buildListTile(
                    Icons.share_outlined,
                    t('share_app'),
                    onTap: _shareApp,
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionLabel(t('account_actions_section')),
                _buildSettingsCard([
                  _buildListTile(
                    Icons.logout,
                    t('logout'),
                    isDestructive: true,
                    onTap: _handleLogout,
                  ),
                  _buildDivider(),
                  _buildListTile(
                    Icons.delete_sweep_outlined,
                    t('clear_cache'),
                    isDestructive: true,
                    subtitle: t('clear_cache_desc'),
                    onTap: _handleClearCache,
                  ),
                ]),
                const SizedBox(height: 32),
                Center(
                  child: Text('FarmAid Lesotho v1.1.0',
                      style: TextStyle(color: _textSecondary, fontSize: 12)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0B2E18), const Color(0xFF1B4332)]
              : [_deepForest, _midForest],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:    const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('settings_title'),
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  t('settings_subtitle'),
                  style: TextStyle(
                    color:    Colors.white.withOpacity(0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name       = _cachedProfile?['full_name'] ?? t('loading');
    final district   = _cachedProfile?['district']  ?? '';
    final experience = _cachedProfile?['experience_level'] ?? 'beginner';
    final photoUrl   = _cachedProfile?['profile_photo_url'];
    final districtLabel = t('district_suffix');

    final experienceIcon = {
      'beginner':     '🌱',
      'intermediate': '🌿',
      'expert':       '🌾',
    }[experience] ?? '🌱';

    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(_isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        CircleAvatar(
          radius:          28,
          backgroundColor: _accent.withOpacity(0.12),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(Icons.person, size: 30, color: _accent)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.bold,
                    color:      _textPrimary,
                  )),
              const SizedBox(height: 2),
              Text('$district $districtLabel',
                  style: TextStyle(
                    color:    _textSecondary,
                    fontSize: 12,
                  )),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        _accent.withOpacity(_isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _accent.withOpacity(0.25)),
                ),
                child: Text(
                  '$experienceIcon  '
                  '${experience[0].toUpperCase()}${experience.substring(1)} Farmer',
                  style: TextStyle(
                    color:      _isDark ? Colors.greenAccent : _accent,
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.verified_user_rounded, size: 20, color: _accent),
      ]),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(children: [
        Container(
          width:  3,
          height: 16,
          decoration: BoxDecoration(
            color:        _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize:      11,
            fontWeight:    FontWeight.bold,
            color:         _textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ]),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color:        _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => Divider(
        height: 1,
        indent:    16,
        endIndent: 16,
        color: _isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
      );

  Widget _buildListTile(
    IconData icon,
    String title, {
    String?       subtitle,
    bool          isDestructive = false,
    VoidCallback? onTap,
    Widget?       trailing,
  }) {
    final Color iconColor  = isDestructive ? Colors.redAccent : _accent;
    final Color titleColor = isDestructive ? Colors.redAccent : _textPrimary;

    return ListTile(
      leading: Container(
        width:  36,
        height: 36,
        decoration: BoxDecoration(
          color:        iconColor.withOpacity(_isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: TextStyle(
            color:      titleColor,
            fontWeight: FontWeight.w500,
            fontSize:   14,
          )),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                fontSize: 12,
                color:    _textSecondary,
              ))
          : null,
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: _textSecondary),
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return SwitchListTile(
      secondary: Container(
        width:  36,
        height: 36,
        decoration: BoxDecoration(
          color:        _accent.withOpacity(_isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _accent, size: 18),
      ),
      title: Text(title,
          style: TextStyle(
            color:      _textPrimary,
            fontWeight: FontWeight.w500,
            fontSize:   14,
          )),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                fontSize: 12,
                color:    _textSecondary,
              ))
          : null,
      value:       value,
      onChanged:   onChanged,
      activeColor: _accent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem(this.q, this.a);
}
