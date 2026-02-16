
// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart'; 
// import 'package:camera/camera.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'core/app_localizations.dart';
// import 'services/language_provider.dart';
// // Assuming you create this service file (shown below)
// import 'services/theme_provider.dart'; 

// import 'features/dashboard/presentation/home_dashboard.dart';
// import 'features/dashboard/presentation/admin_dashboard.dart';
// import 'features/auth/presentation/login_screen.dart';
// import 'features/onboarding/presentation/wizard_screen.dart';

// class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
//   const FallbackMaterialLocalizationsDelegate();
//   @override
//   bool isSupported(Locale locale) => true;
//   @override
//   Future<MaterialLocalizations> load(Locale locale) async => const DefaultMaterialLocalizations();
//   @override
//   bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
// }

// late List<CameraDescription> cameras;

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Supabase.initialize(
//     url: 'https://fxrciblynozufxnxaskf.supabase.co', 
//     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4cmNpYmx5bm96dWZ4bnhhc2tmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyODI3MDQsImV4cCI6MjA4Mzg1ODcwNH0.HRjhYD538mThh9yejcWNcsufuJsf-QYK2_HVAAJ4maI',
//   );

//   try {
//     cameras = await availableCameras();
//   } on CameraException catch (e) {
//     debugPrint('Error fetching cameras: $e');
//     cameras = []; 
//   }

//   final prefs = await SharedPreferences.getInstance();
//   bool isFirstRun = prefs.getBool('first_run') ?? true;

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => LanguageProvider()),
//         ChangeNotifierProvider(create: (context) => ThemeProvider()), // Added ThemeProvider
//       ],
//       child: FarmAidApp(isFirstRun: isFirstRun),
//     ),
//   );
// }

// class FarmAidApp extends StatelessWidget {
//   final bool isFirstRun;
//   const FarmAidApp({super.key, required this.isFirstRun});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<LanguageProvider, ThemeProvider>(
//       builder: (context, langProv, themeProv, child) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'FarmAid Lesotho',
          
//           locale: langProv.appLocale,
//           supportedLocales: const [
//             Locale('en'),
//             Locale('st'),
//           ],
          
//           localizationsDelegates: const [
//             AppLocalizations.delegate,
//             GlobalMaterialLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//             FallbackMaterialLocalizationsDelegate(),
//             DefaultCupertinoLocalizations.delegate,
//           ],

//           // LIGHT THEME
//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: const Color(0xFF2E7D32),
//               brightness: Brightness.light,
//             ),
//             useMaterial3: true,
//           ),

//           // DARK THEME
//           darkTheme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: const Color(0xFF2E7D32),
//               brightness: Brightness.dark,
//             ),
//             useMaterial3: true,
//             scaffoldBackgroundColor: const Color(0xFF121212),
//           ),

//           // GLOBAL CONTROL
//           themeMode: themeProv.themeMode,
          
//           home: isFirstRun ? const WizardScreen() : const HomeDashboard(), 
          
//           routes: {
//             '/login': (context) => const LoginScreen(),
//             '/dashboard': (context) => const HomeDashboard(),
//             '/admin_dashboard': (context) => const AdminDashboard(),
//           },
//         );
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_localizations.dart';
import 'services/language_provider.dart';
import 'services/theme_provider.dart'; 

import 'features/dashboard/presentation/home_dashboard.dart';
import 'features/dashboard/presentation/admin_dashboard.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/onboarding/presentation/wizard_screen.dart';

// --- FALLBACK DELEGATES ---
// These ensure the app doesn't crash when using Sesotho (st) for system components

class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) async => const DefaultMaterialLocalizations();
  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<CupertinoLocalizations> load(Locale locale) async => const DefaultCupertinoLocalizations();
  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase for your vegetable image storage
  await Supabase.initialize(
    url: 'https://fxrciblynozufxnxaskf.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4cmNpYmx5bm96dWZ4bnhhc2tmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyODI3MDQsImV4cCI6MjA4Mzg1ODcwNH0.HRjhYD538mThh9yejcWNcsufuJsf-QYK2_HVAAJ4maI',
  );

  // Initialize Camera for the AI Scanner
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error fetching cameras: $e');
    cameras = []; 
  }

  // Load language and theme preferences before the app starts
  final prefs = await SharedPreferences.getInstance();
  bool isFirstRun = prefs.getBool('first_run') ?? true;
  
  final langProvider = LanguageProvider();
  await langProvider.loadSavedLanguage(); 

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: langProvider),
        ChangeNotifierProvider(create: (context) => ThemeProvider()), 
      ],
      child: FarmAidApp(isFirstRun: isFirstRun),
    ),
  );
}

class FarmAidApp extends StatelessWidget {
  final bool isFirstRun;
  const FarmAidApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    // Consumer2 listens to both Language and Theme changes instantly
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, langProv, themeProv, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FarmAid Lesotho',
          
          // Dynamic locale from Provider
          locale: langProv.appLocale,
          supportedLocales: const [
            Locale('en'), // English
            Locale('st'), // Sesotho
          ],
          
          localizationsDelegates: const [
            AppLocalizations.delegate, // Your custom JSON loader
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // Fallbacks for Sesotho support
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
          ],

          // Lesotho-inspired Green Theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),

          themeMode: themeProv.themeMode,
          
          home: isFirstRun ? const WizardScreen() : const HomeDashboard(), 
          
          routes: {
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const HomeDashboard(),
            '/admin_dashboard': (context) => const AdminDashboard(),
          },
        );
      },
    );
  }
}