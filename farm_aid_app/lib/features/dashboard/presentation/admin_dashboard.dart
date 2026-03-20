import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';

// ── Data model for live stats ──────────────────────────────────────────────
class _AdminStats {
  final int totalFarmers;
  final int totalScans;
  final int totalAlerts;
  final int totalProfiles;
  final int unresolvedAlerts;
  final String topDisease;
  final String topDistrict;

  const _AdminStats({
    this.totalFarmers     = 0,
    this.totalScans       = 0,
    this.totalAlerts      = 0,
    this.totalProfiles    = 0,
    this.unresolvedAlerts = 0,
    this.topDisease       = '—',
    this.topDistrict      = '—',
  });
}

// ── Admin Dashboard ────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {

  final AuthService _auth = AuthService();

  bool        _loading = true;
  String?     _error;
  _AdminStats _stats   = const _AdminStats();

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  // ── Colours ───────────────────────────────────────────────────────────────
  static const _darkGreen  = Color(0xFF0A3D12);
  static const _midGreen   = Color(0xFF1B5E20);
  static const _green      = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFF43A047);
  static const _accent     = Color(0xFF00C853);
  static const _bg         = Color(0xFFF0F4F1);
  static const _cardBg     = Colors.white;
  static const _textDark   = Color(0xFF1A1A1A);
  static const _textMid    = Color(0xFF555555);
  static const _textLight  = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadStats();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Load live stats from backend ──────────────────────────────────────────
  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Not authenticated');

      final headers = {
        'Authorization': 'Token $token',
        'Content-Type':  'application/json',
      };

      // Fetch in parallel
      final results = await Future.wait([
        http.get(Uri.parse('${AppConstants.baseUrl}/farmer-reports/'), headers: headers)
            .timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('${AppConstants.baseUrl}/alerts/'), headers: headers)
            .timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('${AppConstants.baseUrl}/crop-profiles/'), headers: headers)
            .timeout(const Duration(seconds: 15)),
      ]);

      // Parse reports
      int scans = 0; String topDisease = '—'; String topDistrict = '—';
      if (results[0].statusCode == 200) {
        final reports = jsonDecode(results[0].body) as List? ?? [];
        scans = reports.length;
        // Find most common disease
        final diseaseCount = <String, int>{};
        final districtCount = <String, int>{};
        for (final r in reports) {
          final d = r['disease_name']?.toString() ?? '';
          final dist = r['district']?.toString() ?? r['gps_district']?.toString() ?? '';
          if (d.isNotEmpty && d != 'null') diseaseCount[d] = (diseaseCount[d] ?? 0) + 1;
          if (dist.isNotEmpty && dist != 'null') districtCount[dist] = (districtCount[dist] ?? 0) + 1;
        }
        if (diseaseCount.isNotEmpty) {
          topDisease = diseaseCount.entries
              .reduce((a, b) => a.value >= b.value ? a : b).key
              .replaceAll('_', ' ');
        }
        if (districtCount.isNotEmpty) {
          topDistrict = districtCount.entries
              .reduce((a, b) => a.value >= b.value ? a : b).key;
        }
      }

      // Parse alerts
      int totalAlerts = 0; int unresolved = 0;
      if (results[1].statusCode == 200) {
        final alerts = jsonDecode(results[1].body) as List? ?? [];
        totalAlerts = alerts.length;
        unresolved  = alerts.where((a) => a['IsRead'] == false).length;
      }

      // Parse crop profiles
      int profiles = 0;
      if (results[2].statusCode == 200) {
        final p = jsonDecode(results[2].body);
        profiles = p is List ? p.length : 0;
      }

      if (mounted) {
        setState(() {
          _stats = _AdminStats(
            totalScans:       scans,
            totalAlerts:      totalAlerts,
            totalProfiles:    profiles,
            unresolvedAlerts: unresolved,
            topDisease:       topDisease,
            topDistrict:      topDistrict,
          );
          _loading = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open link'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildBody(),
          ),
        ],
      ),
    );
  }

  // ── Top navigation bar ────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_darkGreen, _midGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
          child: Row(
            children: [
              // Logo + title
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Color(0xFF69F0AE), size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FarmAid Lesotho',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    )),
                  Text('Admin Control Centre',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    )),
                ],
              ),
              const Spacer(),
              // Refresh
              _topBarBtn(Icons.refresh_rounded, 'Refresh', _loadStats),
              // Django admin
              _topBarBtn(Icons.open_in_browser_rounded, 'Django',
                  () => _launchUrl(AppConstants.adminPortalUrl)),
              // Sign out
              _topBarBtn(Icons.logout_rounded, 'Sign out', _signOut,
                  color: Colors.redAccent.withOpacity(0.8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBarBtn(IconData icon, String tooltip, VoidCallback onTap,
      {Color? color}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color ?? Colors.white70, size: 22),
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _green),
          SizedBox(height: 16),
          Text('Loading dashboard…',
              style: TextStyle(color: _textMid, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Could not load dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: _textDark)),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center,
                style: const TextStyle(color: _textMid, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main body ─────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: _green,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Welcome banner ───────────────────────────────────
              _buildWelcomeBanner(),
              const SizedBox(height: 24),

              // ── KPI stat row ─────────────────────────────────────
              _sectionLabel('LIVE STATISTICS'),
              const SizedBox(height: 10),
              _buildStatGrid(),
              const SizedBox(height: 24),

              // ── Insight cards ────────────────────────────────────
              _sectionLabel('INSIGHTS'),
              const SizedBox(height: 10),
              _buildInsightRow(),
              const SizedBox(height: 24),

              // ── Quick actions ────────────────────────────────────
              _sectionLabel('QUICK ACTIONS'),
              const SizedBox(height: 10),
              _buildActionGrid(),
              const SizedBox(height: 24),

              // ── External links ───────────────────────────────────
              _sectionLabel('SYSTEM LINKS'),
              const SizedBox(height: 10),
              _buildSystemLinks(),

            ],
          ),
        ),
      ),
    );
  }

  // ── Welcome banner ────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_midGreen, _lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _green.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  )),
                const SizedBox(height: 6),
                Text(
                  'FarmAid is running · ${_stats.totalScans} total scans recorded',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  )),
                const SizedBox(height: 14),
                _buildStatusPill(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dashboard_rounded,
                color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF69F0AE),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text('System Online',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          )),
      ]),
    );
  }

  // ── Stat grid ─────────────────────────────────────────────────────────────
  Widget _buildStatGrid() {
    final items = [
      _StatItem(
        label: 'Total Scans',
        value: '${_stats.totalScans}',
        icon: Icons.document_scanner_outlined,
        color: const Color(0xFF1565C0),
        bg:    const Color(0xFFE3F2FD),
      ),
      _StatItem(
        label: 'Crop Profiles',
        value: '${_stats.totalProfiles}',
        icon: Icons.grass_rounded,
        color: _green,
        bg:    const Color(0xFFE8F5E9),
      ),
      _StatItem(
        label: 'Active Alerts',
        value: '${_stats.unresolvedAlerts}',
        icon: Icons.notifications_active_outlined,
        color: const Color(0xFFE65100),
        bg:    const Color(0xFFFFF3E0),
      ),
      _StatItem(
        label: 'Total Alerts',
        value: '${_stats.totalAlerts}',
        icon: Icons.campaign_outlined,
        color: const Color(0xFF6A1B9A),
        bg:    const Color(0xFFF3E5F5),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(items[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                    height: 1.0,
                  )),
                const SizedBox(height: 3),
                Text(item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textLight,
                    fontWeight: FontWeight.w500,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Insight row ───────────────────────────────────────────────────────────
  Widget _buildInsightRow() {
    return Row(
      children: [
        Expanded(child: _buildInsightCard(
          icon:  Icons.coronavirus_outlined,
          label: 'Most Reported Disease',
          value: _stats.topDisease,
          color: const Color(0xFFB71C1C),
          bg:    const Color(0xFFFFEBEE),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildInsightCard(
          icon:  Icons.location_on_outlined,
          label: 'Most Active District',
          value: _stats.topDistrict,
          color: const Color(0xFF1565C0),
          bg:    const Color(0xFFE3F2FD),
        )),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String   label,
    required String   value,
    required Color    color,
    required Color    bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label,
            style: const TextStyle(
              fontSize: 11, color: _textLight,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            )),
        ],
      ),
    );
  }

  // ── Quick action grid ─────────────────────────────────────────────────────
  Widget _buildActionGrid() {
    final actions = [
      _ActionItem(
        icon:    Icons.people_alt_outlined,
        title:   'Farmer Accounts',
        subtitle: 'View & manage users',
        color:   _green,
        bg:      const Color(0xFFE8F5E9),
        url:     '${AppConstants.adminPortalUrl}api/farmer/',
      ),
      _ActionItem(
        icon:    Icons.biotech_outlined,
        title:   'Disease Rules',
        subtitle: 'Personalization engine',
        color:   const Color(0xFF6A1B9A),
        bg:      const Color(0xFFF3E5F5),
        url:     '${AppConstants.adminPortalUrl}api/personalizedrule/',
      ),
      _ActionItem(
        icon:    Icons.menu_book_outlined,
        title:   'Knowledge Base',
        subtitle: 'Treatments & diseases',
        color:   const Color(0xFF1565C0),
        bg:      const Color(0xFFE3F2FD),
        url:     '${AppConstants.adminPortalUrl}api/knowledgebase/',
      ),
      _ActionItem(
        icon:    Icons.document_scanner_outlined,
        title:   'Scan Diagnoses',
        subtitle: 'All AI scan results',
        color:   const Color(0xFFE65100),
        bg:      const Color(0xFFFFF3E0),
        url:     '${AppConstants.adminPortalUrl}api/diagnosis/',
      ),
      _ActionItem(
        icon:    Icons.campaign_outlined,
        title:   'Disease Alerts',
        subtitle: 'Push alerts to farmers',
        color:   const Color(0xFFB71C1C),
        bg:      const Color(0xFFFFEBEE),
        url:     '${AppConstants.adminPortalUrl}api/appalert/',
      ),
      _ActionItem(
        icon:    Icons.monetization_on_outlined,
        title:   'Market Prices',
        subtitle: 'Update crop prices',
        color:   const Color(0xFF2E7D32),
        bg:      const Color(0xFFE8F5E9),
        url:     '${AppConstants.adminPortalUrl}api/marketprice/',
      ),
      _ActionItem(
        icon:    Icons.wb_sunny_outlined,
        title:   'Weather Data',
        subtitle: 'District conditions',
        color:   const Color(0xFFF57F17),
        bg:      const Color(0xFFFFFDE7),
        url:     '${AppConstants.adminPortalUrl}api/weatherdata/',
      ),
      _ActionItem(
        icon:    Icons.psychology_outlined,
        title:   'AI Treatments',
        subtitle: 'Dosage & products',
        color:   const Color(0xFF00695C),
        bg:      const Color(0xFFE0F2F1),
        url:     '${AppConstants.adminPortalUrl}api/treatment/',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => _buildActionCard(actions[i]),
    );
  }

  Widget _buildActionCard(_ActionItem item) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _launchUrl(item.url),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      )),
                    const SizedBox(height: 3),
                    Text(item.subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _textLight,
                      )),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: item.color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ── System links ──────────────────────────────────────────────────────────
  Widget _buildSystemLinks() {
    return Column(
      children: [
        _buildLinkRow(
          icon:    Icons.admin_panel_settings_outlined,
          title:   'Django Admin Panel',
          subtitle: 'Full database management',
          url:     AppConstants.adminPortalUrl,
          color:   _green,
        ),
        const SizedBox(height: 10),
        _buildLinkRow(
          icon:    Icons.api_outlined,
          title:   'REST API Explorer',
          subtitle: 'Browse all API endpoints',
          url:     '${AppConstants.baseUrl}/',
          color:   const Color(0xFF1565C0),
        ),
        const SizedBox(height: 10),
        _buildLinkRow(
          icon:    Icons.bar_chart_rounded,
          title:   'Render Dashboard',
          subtitle: 'Server logs & metrics',
          url:     'https://dashboard.render.com',
          color:   const Color(0xFF6A1B9A),
        ),
      ],
    );
  }

  Widget _buildLinkRow({
    required IconData icon,
    required String   title,
    required String   subtitle,
    required String   url,
    required Color    color,
  }) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _launchUrl(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      )),
                    Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: _textLight)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  size: 16, color: color.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: _textLight,
        letterSpacing: 1.2,
      ));
  }
}

// ── Data classes ──────────────────────────────────────────────────────────
class _StatItem {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final Color    bg;
  const _StatItem({
    required this.label, required this.value,
    required this.icon,  required this.color, required this.bg,
  });
}

class _ActionItem {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    color;
  final Color    bg;
  final String   url;
  const _ActionItem({
    required this.icon,  required this.title, required this.subtitle,
    required this.color, required this.bg,    required this.url,
  });
}
