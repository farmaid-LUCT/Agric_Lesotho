
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_localizations.dart';
import '../../../services/language_provider.dart';
import '../../dashboard/presentation/home_dashboard.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  bool _hasAcceptedLicense = false;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run', false);

    if (!mounted) return;

    // showTour: true  → HomeDashboard triggers spotlight tour on first load
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeDashboard(showTour: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProv = Provider.of<LanguageProvider>(context);
    final appLoc = AppLocalizations.of(context);

    if (appLoc == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E7D32).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    size: 100,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  appLoc.translate('welcome_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  appLoc.translate('welcome_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const Spacer(),

                Text(
                  "Choose Language / Khetha Puo",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _langButton("English", "en", langProv.appLocale.languageCode == 'en')),
                      Expanded(child: _langButton("Sesotho", "st", langProv.appLocale.languageCode == 'st')),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Theme(
                  data: ThemeData(unselectedWidgetColor: const Color(0xFF2E7D32)),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      appLoc.translate('accept_license'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    value: _hasAcceptedLicense,
                    onChanged: (val) => setState(() => _hasAcceptedLicense = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    onPressed: _hasAcceptedLicense ? _completeOnboarding : null,
                    child: Text(
                      appLoc.translate('get_started').toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _langButton(String label, String code, bool isSelected) {
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => langProv.changeLanguage(Locale(code)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
