
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../core/app_localizations.dart';
// import '../../../services/language_provider.dart';
// import '../../dashboard/presentation/home_dashboard.dart';

// class WizardScreen extends StatefulWidget {
//   const WizardScreen({super.key});

//   @override
//   State<WizardScreen> createState() => _WizardScreenState();
// }

// class _WizardScreenState extends State<WizardScreen> {
//   bool _hasAcceptedLicense = false;

//   Future<void> _completeOnboarding() async {
//     final prefs = await SharedPreferences.getInstance();
//     // Saving the flag so the farmer doesn't see the wizard again
//     await prefs.setBool('first_run', false);
    
//     if (!mounted) return;
    
//     // --- FIXED: Removed 'const' keyword here ---
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => HomeDashboard()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final langProv = Provider.of<LanguageProvider>(context);
//     final appLoc = AppLocalizations.of(context);

//     if (appLoc == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.agriculture, size: 80, color: Color(0xFF2E7D32)),
//               const SizedBox(height: 24),
//               Text(
//                 appLoc.translate('welcome to FarmAid') ?? 'FarmAid Lesotho',
//                 style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 appLoc.translate('welcome to FarmAid') ?? 'Your AI partner for healthy crops.',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//               const Spacer(),
              
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _langButton("English", "en", langProv.appLocale.languageCode == 'en'),
//                   const SizedBox(width: 10),
//                   _langButton("Sesotho", "st", langProv.appLocale.languageCode == 'st'),
//                 ],
//               ),
              
//               const SizedBox(height: 20),
              
//               CheckboxListTile(
//                 title: Text(appLoc.translate('Accept_license')),
//                 value: _hasAcceptedLicense,
//                 onChanged: (val) => setState(() => _hasAcceptedLicense = val!),
//                 controlAffinity: ListTileControlAffinity.leading,
//                 activeColor: const Color(0xFF2E7D32),
//               ),
              
//               const SizedBox(height: 20),
              
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF2E7D32),
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: _hasAcceptedLicense ? _completeOnboarding : null,
//                   child: Text(appLoc.translate('Get_started').toUpperCase()),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _langButton(String label, String code, bool isSelected) {
//     return isSelected 
//       ? ElevatedButton(
//           onPressed: () {}, 
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF2E7D32), 
//             foregroundColor: Colors.white,
//             elevation: 0,
//           ),
//           child: Text(label),
//         )
//       : OutlinedButton(
//           onPressed: () => Provider.of<LanguageProvider>(context, listen: false).changeLanguage(code), 
//           style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2E7D32))),
//           child: Text(label, style: const TextStyle(color: Color(0xFF2E7D32))),
//         );
//   }
// }


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
    // Saving the flag so the farmer doesn't see the wizard again
    await prefs.setBool('first_run', false);
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProv = Provider.of<LanguageProvider>(context);
    final appLoc = AppLocalizations.of(context);

    // If localizations haven't loaded yet, show a loader
    if (appLoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.agriculture, size: 80, color: Color(0xFF2E7D32)),
              const SizedBox(height: 24),
              Text(
                appLoc.translate('welcome_title'), // Translation key: welcome_title
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                appLoc.translate('welcome_subtitle'), // Translation key: welcome_subtitle
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(),
              
              // Language Selection Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _langButton("English", "en", langProv.appLocale.languageCode == 'en'),
                  const SizedBox(width: 10),
                  _langButton("Sesotho", "st", langProv.appLocale.languageCode == 'st'),
                ],
              ),
              
              const SizedBox(height: 20),
              
              CheckboxListTile(
                title: Text(appLoc.translate('accept_license')), // Translation key: accept_license
                value: _hasAcceptedLicense,
                onChanged: (val) => setState(() => _hasAcceptedLicense = val!),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF2E7D32),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _hasAcceptedLicense ? _completeOnboarding : null,
                  child: Text(appLoc.translate('get_started').toUpperCase()), // Translation key: get_started
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langButton(String label, String code, bool isSelected) {
    final langProv = Provider.of<LanguageProvider>(context, listen: false);

    return isSelected 
      ? ElevatedButton(
          onPressed: () {}, 
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32), 
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label),
        )
      : OutlinedButton(
          onPressed: () => langProv.changeLanguage(Locale(code)), // Corrected to use Locale object
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2E7D32)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label, style: const TextStyle(color: Color(0xFF2E7D32))),
        );
  }
}