import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_localizations.dart';
import '../../dashboard/presentation/home_dashboard.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen>
    with SingleTickerProviderStateMixin {

  bool _hasAcceptedLicense = false;

  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  static const _green      = Color(0xFF1B5E20);
  static const _lightGreen = Color(0xFF2E7D32);
  static const _accent     = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeDashboard(showTour: true),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  void _openLicense() {
    final isWide = MediaQuery.of(context).size.width > 600;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => isWide
          // ── DESKTOP: centered dialog ──────────────────────────
          ? Center(
              child: Container(
                width:  580,
                height: MediaQuery.of(context).size.height * 0.88,
                margin: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const _LicenseSheet(),
              ),
            )
          // ── MOBILE: full bottom sheet ─────────────────────────
          : const _LicenseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    if (appLoc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(
            color: Color(0xFF2E7D32))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

          // ── Background gradient ─────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                  colors: [
                    Color(0xFFF0FBF0),
                    Color(0xFFFFFFFF),
                    Color(0xFFF5FFF5),
                  ],
                ),
              ),
            ),
          ),

          // ── Green arc at top ────────────────────────────────────
          Positioned(
            top:   -MediaQuery.of(context).size.width * 0.4,
            left:  -MediaQuery.of(context).size.width * 0.2,
            right: -MediaQuery.of(context).size.width * 0.2,
            child: Container(
              height: MediaQuery.of(context).size.width * 1.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withOpacity(0.06),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: isWide
                    // ── DESKTOP: centered card ──────────────────
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color:     Colors.black.withOpacity(0.08),
                                  blurRadius: 40,
                                  offset:    const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: _buildScrollableContent(appLoc),
                          ),
                        ),
                      )
                    // ── MOBILE: full screen ─────────────────────
                    : _buildScrollableContent(appLoc),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scrollable body + CTA ──────────────────────────────────────
  Widget _buildScrollableContent(AppLocalizations appLoc) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 32),
                _buildTitleBlock(appLoc),
                const SizedBox(height: 40),
                const SizedBox(height: 48),
                _buildLicenseSection(appLoc),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        _buildBottomCTA(appLoc),
      ],
    );
  }

  // ── Logo ───────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130, height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _green.withOpacity(0.06),
          ),
        ),
        Container(
          width: 108, height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _green.withOpacity(0.10),
          ),
        ),
        Container(
          width: 86, height: 86,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color:     Color(0x442E7D32),
                blurRadius: 20,
                offset:    Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded,
              color: Colors.white, size: 42),
        ),
      ],
    );
  }

  // ── Title block ────────────────────────────────────────────────
  Widget _buildTitleBlock(AppLocalizations appLoc) {
    return Column(
      children: [
        const Text(
          'FarmAid Lesotho',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize:   36,
            fontWeight: FontWeight.w900,
            color:      _green,
            letterSpacing: -1.0,
            height:     1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color:        _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: _accent.withOpacity(0.3)),
          ),
          child: const Text(
            'AI-Powered Crop Health Advisor',
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      Color(0xFF00A844),
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          appLoc.translate(''),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color:    Colors.grey.shade600,
            height:   1.6,
          ),
        ),
      ],
    );
  }

  // ── License section ────────────────────────────────────────────
  Widget _buildLicenseSection(AppLocalizations appLoc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
              color:        _lightGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'License Agreement',
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
        ]),

        const SizedBox(height: 14),

        GestureDetector(
          onTap: _openLicense,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _lightGreen.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset:     const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:        _green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined,
                            color: _lightGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FarmAid Terms of Use',
                              style: TextStyle(
                                  fontSize:   14,
                                  fontWeight: FontWeight.bold,
                                  color:      _green)),
                          Text('Version 1.0 · 2026',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:        _green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Read →',
                          style: TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.bold,
                              color:      _lightGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'By using FarmAid Lesotho, you agree to use this application for lawful agricultural purposes only. '
                  'This app provides AI-based crop disease guidance — always consult a certified agronomist for critical '
                  'decisions. We do not guarantee 100% accuracy of AI diagnoses.',
                  style: TextStyle(
                    fontSize: 12,
                    color:    Colors.grey.shade600,
                    height:   1.55,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openLicense,
                  child: Text(
                    'Read full agreement…',
                    style: TextStyle(
                      fontSize:   12,
                      color:      _lightGreen,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: _lightGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _hasAcceptedLicense = !_hasAcceptedLicense);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hasAcceptedLicense
                  ? _green.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hasAcceptedLicense
                    ? _lightGreen.withOpacity(0.5)
                    : Colors.grey.shade200,
                width: _hasAcceptedLicense ? 1.5 : 1.0,
              ),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: _hasAcceptedLicense
                      ? _lightGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _hasAcceptedLicense
                        ? _lightGreen
                        : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: _hasAcceptedLicense
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  appLoc.translate('accept_license'),
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color: _hasAcceptedLicense
                        ? _green
                        : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Bottom CTA ─────────────────────────────────────────────────
  Widget _buildBottomCTA(AppLocalizations appLoc) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        28, 16, 28,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width:  i == (_hasAcceptedLicense ? 2 : 0) ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i <= (_hasAcceptedLicense ? 2 : 0)
                    ? _lightGreen
                    : Colors.grey.shade300,
              ),
            )),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width:  double.infinity,
            height: 58,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: _hasAcceptedLicense
                    ? const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end:   Alignment.bottomRight,
                      )
                    : null,
                color: _hasAcceptedLicense
                    ? null
                    : Colors.grey.shade200,
                boxShadow: _hasAcceptedLicense
                    ? [
                        BoxShadow(
                          color:      _lightGreen.withOpacity(0.4),
                          blurRadius: 16,
                          offset:     const Offset(0, 6),
                        )
                      ]
                    : [],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor:     Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _hasAcceptedLicense
                    ? _completeOnboarding
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _hasAcceptedLicense
                          ? appLoc.translate('get_started').toUpperCase()
                          : 'ACCEPT TERMS TO CONTINUE',
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: _hasAcceptedLicense
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                    if (_hasAcceptedLicense) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// LICENSE BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════
class _LicenseSheet extends StatelessWidget {
  const _LicenseSheet();

  static const _green      = Color(0xFF1B5E20);
  static const _lightGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    // On desktop the parent Container already has a fixed height + rounded corners.
    // On mobile we size it to 88% of screen height with rounded top.
    final isWide = MediaQuery.of(context).size.width > 600;

    Widget sheet = Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          height: 5, width: 48,
          decoration: BoxDecoration(
            color:        Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        _green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined,
                    color: _lightGreen, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FarmAid Lesotho',
                        style: TextStyle(
                            fontSize:   18,
                            fontWeight: FontWeight.bold,
                            color:      _green)),
                    Text('Terms of Use & License Agreement · v1.0',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
        ),

        const Divider(height: 24),

        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: const [
              _LicenseSection(number: '1', title: 'Acceptance of Terms',
                body: 'By downloading, installing or using the FarmAid Lesotho application, '
                    'you confirm that you are at least 16 years old and agree to be bound by these '
                    'Terms of Use. If you do not agree to these terms, do not use this application.'),
              _LicenseSection(number: '2', title: 'Purpose of the Application',
                body: 'FarmAid Lesotho is an agricultural support tool designed to help smallholder '
                    'farmers in Lesotho identify crop diseases using artificial intelligence and '
                    'receive treatment guidance. The App is provided as a decision-support tool '
                    'only and is not a substitute for professional agronomic advice.'),
              _LicenseSection(number: '3', title: 'Accuracy of AI Diagnoses',
                body: 'The AI-powered disease detection feature provides guidance based on visual '
                    'analysis of crop images. FarmAid does not guarantee 100% accuracy of any '
                    'diagnosis. Always confirm critical treatment decisions with a certified '
                    'agronomist or extension officer before applying pesticides, herbicides or '
                    'other agricultural chemicals.'),
              _LicenseSection(number: '4', title: 'Permitted Use',
                body: 'You may use this App solely for lawful agricultural purposes. You may not: '
                    '(a) reverse engineer or modify the App; (b) use the App to cause harm to crops, '
                    'the environment or other persons; (c) distribute or sell this App or its content '
                    'without written permission from the FarmAid development team.'),
              _LicenseSection(number: '5', title: 'Data Collection & Privacy',
                body: 'FarmAid collects crop scan images, GPS location data, and farm profile '
                    'information to provide personalised recommendations. Your data is stored '
                    'securely and is not sold to third parties. Location data is used solely '
                    'to provide district-specific disease alerts and weather information relevant '
                    'to your farming area in Lesotho.'),
              _LicenseSection(number: '6', title: 'Chemical Treatment Advice',
                body: 'Pesticide and treatment recommendations in this App are general guidelines '
                    'based on standard agricultural practices in Lesotho. Always read and follow '
                    'the product label before applying any chemical. Observe pre-harvest intervals '
                    '(PHI) as displayed in the App. FarmAid is not liable for any crop loss, '
                    'environmental damage or health issues resulting from chemical misuse.'),
              _LicenseSection(number: '7', title: 'Intellectual Property',
                body: 'All content, AI models, code, and brand elements of FarmAid Lesotho are the '
                    'intellectual property of the FarmAid development team. The AI disease '
                    'detection model was trained specifically for crop varieties common to Lesotho '
                    'and the southern African region.'),
              _LicenseSection(number: '8', title: 'Disclaimer of Liability',
                body: 'FarmAid Lesotho is provided "as is" without warranty of any kind, express or '
                    'implied. The development team is not liable for any direct, indirect, incidental '
                    'or consequential damages arising from the use or inability to use the App, '
                    'including but not limited to crop loss, financial loss or data loss.'),
              _LicenseSection(number: '9', title: 'Updates & Changes',
                body: 'FarmAid reserves the right to update these Terms of Use at any time. '
                    'Continued use of the App after any update constitutes acceptance of the '
                    'revised terms. Major changes will be communicated through an in-app notification.'),
              _LicenseSection(number: '10', title: 'Governing Law',
                body: 'These Terms of Use are governed by the laws of the Kingdom of Lesotho. '
                    'Any disputes arising from the use of this application shall be subject to '
                    'the jurisdiction of the courts of Lesotho.'),
              SizedBox(height: 12),
              Center(
                child: Text(
                  '© 2026 FarmAid Lesotho Development Team\nAll rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.6),
                ),
              ),
            ],
          ),
        ),

        // Close button
        Padding(
          padding: EdgeInsets.fromLTRB(
            24, 8, 24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: SizedBox(
            width:  double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _lightGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:   15)),
            ),
          ),
        ),
      ],
    );

    if (isWide) return sheet;

    // Mobile: size to 88% screen height with rounded top corners
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: sheet,
    );
  }
}

// ── License section widget ─────────────────────────────────────────
class _LicenseSection extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _LicenseSection({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color:  const Color(0xFF1B5E20).withOpacity(0.10),
              shape:  BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.bold,
                      color:      Color(0xFF1B5E20))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.bold,
                        color:      Color(0xFF1B5E20),
                        height:     1.2)),
                const SizedBox(height: 6),
                Text(body,
                    style: TextStyle(
                        fontSize: 13,
                        color:    Colors.grey.shade700,
                        height:   1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}