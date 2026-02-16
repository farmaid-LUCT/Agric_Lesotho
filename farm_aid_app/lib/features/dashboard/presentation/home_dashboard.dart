// import 'dart:io';
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; 
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // Correct Imports based on folder structure
// import '../../weather/presentation/weather_service.dart';
// import '../../auth/presentation/login_screen.dart';
// import '../../../services/auth_service.dart';
// import '../../scanner/data/ai_service.dart';
// import '../../scanner/data/scanner_service.dart'; 
// import '../../history/presentation/history_screen.dart';
// import '../../alerts/presentation/alerts_screen.dart';
// import '../../crops/presentation/crop_type_screen.dart';
// import './settings_screen.dart'; 
// import '../../../core/constants.dart'; 

// class HomeDashboard extends StatefulWidget {
//   const HomeDashboard({super.key});

//   @override
//   State<HomeDashboard> createState() => _HomeDashboardState();
// }

// class _HomeDashboardState extends State<HomeDashboard> {
//   final AuthService _auth = AuthService();
//   final ScannerService _scannerService = ScannerService(); 
//   final ImagePicker _picker = ImagePicker();
//   final _supabase = Supabase.instance.client;

//   File? _selectedImage;
//   Uint8List? _imageBytes;

//   bool isGuest = true;
//   String selectedButton = "";

//   // --- ALERT STATE ---
//   int _alertCount = 0;
//   Timer? _alertTimer;

//   @override
//   void initState() {
//     super.initState();
//     _syncAuthStatus();
//     AIService.loadModel();
//     _startAlertPolling();
//   }

//   @override
//   void dispose() {
//     _alertTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _syncAuthStatus() async {
//     bool loggedIn = await _auth.isLoggedIn();
//     setState(() {
//       isGuest = !loggedIn;
//     });
//     if (loggedIn) {
//       _fetchAlertCount();
//     }
//   }

//   void _startAlertPolling() {
//     _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (!isGuest) _fetchAlertCount();
//     });
//   }

//   Future<void> _fetchAlertCount() async {
//     try {
//       final String? token = await _auth.getToken();
//       final response = await http.get(
//         Uri.parse(AppConstants.alertsUrl),
//         headers: {"Authorization": "Token $token"},
//       );

//       if (response.statusCode == 200) {
//         final List alerts = jsonDecode(response.body);
//         final unreadAlerts = alerts.where((a) => a['IsRead'] == false).toList();
//         final int newCount = unreadAlerts.length;

//         if (newCount > _alertCount && mounted) {
//           final newest = unreadAlerts.first;
//           _notifyFarmerOfNewAlert(
//             newest['Title'] ?? "New Vegetable Alert", 
//             newest['Message'] ?? "Check your alerts for important farm updates."
//           );
//         }

//         setState(() {
//           _alertCount = newCount;
//         });
//       }
//     } catch (e) {
//       debugPrint("Alert Polling Error: $e");
//     }
//   }

//   void _notifyFarmerOfNewAlert(String title, String message) {
//     HapticFeedback.vibrate(); 
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         duration: const Duration(seconds: 6),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
//         backgroundColor: Colors.orange.shade900,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         content: Row(
//           children: [
//             const Icon(Icons.notification_important, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
//                   Text(message, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
//                 ],
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                 _openAlerts();
//               },
//               child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGuestBanner() {
//     if (!isGuest) return const SizedBox.shrink();
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: isDark ? Colors.green.shade800 : Colors.green.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline, color: isDark ? Colors.greenAccent : const Color(0xFF2E7D32)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Using Guest Mode",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold, 
//                     color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20)
//                   ),
//                 ),
//                 Text(
//                   "Sign in to save scan history and get weather alerts.",
//                   style: TextStyle(
//                     fontSize: 12, 
//                     color: isDark ? Colors.white70 : Colors.green.shade900
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
//               if (result == true) _syncAuthStatus();
//             },
//             child: const Text("SIGN IN", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A844))),
//           )
//         ],
//       ),
//     );
//   }

//   Future<void> _handleAnalyzePrompt() async {
//     if (_imageBytes == null) return;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         title: const Text("Analysis Mode"),
//         content: const Text("Would you like personalized recommendations based on your vegetable profile?"),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _startAIAnalysis(isPersonalized: false);
//             },
//             child: const Text("General Tips Only"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               final dynamic result = await Navigator.push(
//                 context, 
//                 MaterialPageRoute(builder: (context) => CropTypeScreen(pendingImage: _imageBytes))
//               );
              
//               String? newId;
//               if (result is String) newId = result;
//               if (result is Map) newId = result['ProfileID']?.toString();

//               if (newId != null || !isGuest) {
//                 _startAIAnalysis(isPersonalized: true, forcedProfileId: newId);
//               }
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             child: const Text("Yes, Personalize", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _startAIAnalysis({required bool isPersonalized, String? forcedProfileId}) async {
//     if (_imageBytes == null || _selectedImage == null) return;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
//     );

//     try {
//       final aiResult = await AIService.runInference(_imageBytes!);

//       if (aiResult['isRejected'] == true) {
//         if (mounted) Navigator.pop(context);
//         _showErrorSnackBar(aiResult['label']);
//         return;
//       }

//       final String? publicUrl = await _scannerService.uploadCropImage(_selectedImage!);
//       if (publicUrl == null) throw Exception("Upload failed");

//       final backendResponse = await _scannerService.saveScanToBackend(
//         imageUrl: publicUrl,
//         diseaseName: aiResult['label'] ?? "Healthy",
//         confidence: aiResult['confidence'] ?? 0.0,
//         profileId: forcedProfileId, 
//       );

//       if (mounted) {
//         Navigator.pop(context); 
        
//         if (backendResponse != null) {
//           final Map<String, dynamic> results = backendResponse['results'] ?? {};
//           List<String> advice = [];
          
//           if (backendResponse['personalized_rules'] != null) {
//             advice = (backendResponse['personalized_rules'] as List)
//                 .map((rule) => rule['ExpertAdvice']?.toString() ?? "")
//                 .toList();
//           }

//           _showResultDialog(
//             diagnosis: results['disease'] ?? aiResult['label'],
//             pesticide: results['pesticide'] ?? "No specific pesticide recommended.",
//             dosage: results['dosage'] ?? "N/A",
//             steps: results['steps'] ?? "Please monitor the plant.",
//             confidence: "${((aiResult['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%",
//             personalizedRules: advice,
//           );

//           setState(() { 
//             _imageBytes = null; 
//             _selectedImage = null;
//           });
//         } else {
//           _showErrorSnackBar("Sync Failed: Check server connection.");
//         }
//       }
//     } catch (e) {
//       if (mounted) Navigator.pop(context);
//       _showErrorSnackBar("Connection Error: $e");
//     }
//   }

//   void _showResultDialog({
//     required String diagnosis,
//     required String pesticide,
//     required String dosage,
//     required String steps,
//     required String confidence,
//     List<String> personalizedRules = const [],
//   }) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(diagnosis.replaceAll('_', ' '), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
//             Text("Confidence: $confidence", style: const TextStyle(fontSize: 12, color: Colors.grey)),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Divider(),
//               _buildInfoRow(Icons.medication_liquid, "Treatment", pesticide),
//               _buildInfoRow(Icons.straighten, "Dosage", dosage),
//               _buildInfoRow(Icons.list_alt_rounded, "Application Steps", steps),
              
//               if (personalizedRules.isNotEmpty) ...[
//                 const SizedBox(height: 10),
//                 const Text("EXPERT ADVICE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
//                 const Divider(color: Colors.blue),
//                 ...personalizedRules.map((rule) => Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 2.0),
//                   child: Text("• $rule", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
//                 )),
//               ]
//             ],
//           ),
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context), 
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             child: const Text("Done", style: TextStyle(color: Colors.white))
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 20, color: Colors.green), // Fix: Removed const
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)), // Fix: Removed const
//                 Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _handleImageAction(ImageSource source) async {
//     try {
//       final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
//       if (pickedFile != null) {
//         final Uint8List bytes = await pickedFile.readAsBytes();
//         setState(() {
//           _imageBytes = bytes;
//           if (!kIsWeb) _selectedImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       debugPrint("Error picking image: $e");
//     }
//   }

//   void _showSignInRequiredDialog(BuildContext context, String featureName) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text("Unlock $featureName"),
//         content: const Text("Please sign in to link your farm data to our AI Expert System."),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maybe Later")),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
//               if (result == true) _syncAuthStatus();
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844)),
//             child: const Text("Sign In", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 10),
//               _buildHeader(),
//               const SizedBox(height: 15),
//               _buildGuestBanner(), 
//               Expanded(
//                 child: Column(
//                   children: [
//                     Expanded(child: _buildScannerCard()),
//                     const SizedBox(height: 25),
//                     Row(
//                       children: [
//                         Expanded(child: _buildMainActionButton(label: "Upload", icon: Icons.file_upload_outlined, isPrimary: false, onTap: () => _handleImageAction(ImageSource.gallery))),
//                         const SizedBox(width: 12),
//                         Expanded(child: _buildMainActionButton(label: "Take Photo", icon: Icons.camera_alt_rounded, isPrimary: true, onTap: () => _handleImageAction(ImageSource.camera))),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         selectedItemColor: Colors.green,
//         unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
//         onTap: (index) {
//           final pages = ["Weather", "Crop Type", "History", "Settings"];
//           _onNavTap(pages[index]);
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.wb_sunny_outlined), label: "Weather"),
//           BottomNavigationBarItem(icon: Icon(Icons.grass_rounded), label: "Crop Type"),
//           BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "History"),
//           BottomNavigationBarItem(icon: Icon(Icons.settings_suggest_outlined), label: "Settings"),
//         ],
//       ),
//     );
//   }

//   void _onNavTap(String text) {
//     if (text == "Weather") {
//       _openWeather();
//     } else {
//       if (isGuest) {
//         _showSignInRequiredDialog(context, text);
//       } else {
//         switch (text) {
//           case "History": _openHistory(); break;
//           case "Crop Type": _openCropType(); break;
//           case "Settings": _openSettings(); break;
//         }
//       }
//     }
//   }

//   void _openWeather() => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherServicePage()));
//   void _openHistory() => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
//   void _openAlerts() => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
//   void _openCropType() => Navigator.push(context, MaterialPageRoute(builder: (context) => const CropTypeScreen()));
//   void _openSettings() => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));

//   Widget _buildHeader() {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(children: [
//           const CircleAvatar(backgroundColor: Color(0xFF00A844), child: Icon(Icons.eco, color: Colors.white)),
//           const SizedBox(width: 12),
//           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text("FarmAid", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
//             Text("Lesotho Crop Assistant", style: TextStyle(fontSize: 12, color: isDark ? Colors.greenAccent.withOpacity(0.7) : Colors.green))
//           ])
//         ]),
//         Row(children: [
//           IconButton(
//             onPressed: isGuest ? () => _showSignInRequiredDialog(context, "Alerts") : _openAlerts,
//             icon: Badge(
//               label: Text("$_alertCount"),
//               isLabelVisible: _alertCount > 0,
//               child: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.greenAccent : Colors.green)
//             ),
//           ),
//           IconButton(
//             onPressed: () {
//               if (isGuest) _showSignInRequiredDialog(context, "Profile");
//               else { _auth.signOut(); _syncAuthStatus(); }
//             },
//             icon: Icon(isGuest ? Icons.account_circle_outlined : Icons.logout, color: isDark ? Colors.greenAccent : Colors.green)
//           )
//         ])
//       ],
//     );
//   }

//   Widget _buildMainActionButton({required String label, required IconData icon, required bool isPrimary, required VoidCallback onTap}) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return SizedBox(
//       height: 55,
//       child: isPrimary
//         ? ElevatedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))
//         : OutlinedButton.icon(
//             onPressed: onTap, 
//             icon: Icon(icon), 
//             label: Text(label), 
//             style: OutlinedButton.styleFrom(
//               side: BorderSide(color: isDark ? Colors.green.shade800 : Colors.green.shade200), 
//               foregroundColor: isDark ? Colors.greenAccent : Colors.green,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
//             )
//           )
//     );
//   }

//   Widget _buildScannerCard() {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
//         borderRadius: BorderRadius.circular(20), 
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)]
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: _imageBytes != null
//           ? Stack(fit: StackFit.expand, children: [
//               Image.memory(_imageBytes!, fit: BoxFit.cover),
//               Positioned(top: 10, right: 10, child: IconButton(onPressed: () => setState(() { _imageBytes = null; }), icon: const CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.close, color: Colors.red)))),
//               Positioned(bottom: 20, left: 50, right: 50, child: ElevatedButton(onPressed: _handleAnalyzePrompt, child: const Text("Analyze Crop")))
//             ])
//           : Center(child: Text("Position leaf here", style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green))),
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
//   }
// }

// import 'dart:io';
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; 
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // Correct Imports
// import '../../weather/presentation/weather_service.dart';
// import '../../auth/presentation/login_screen.dart';
// import '../../../services/auth_service.dart';
// import '../../scanner/data/ai_service.dart';
// import '../../scanner/data/scanner_service.dart'; 
// import '../../history/presentation/history_screen.dart';
// import '../../alerts/presentation/alerts_screen.dart';
// import '../../crops/presentation/crop_type_screen.dart';
// import './settings_screen.dart'; 
// import '../../../core/constants.dart'; 
// import '../../../core/app_localizations.dart';

// class HomeDashboard extends StatefulWidget {
//   const HomeDashboard({super.key});

//   @override
//   State<HomeDashboard> createState() => _HomeDashboardState();
// }

// class _HomeDashboardState extends State<HomeDashboard> {
//   final AuthService _auth = AuthService();
//   final ScannerService _scannerService = ScannerService(); 
//   final ImagePicker _picker = ImagePicker();
//   final _supabase = Supabase.instance.client;

//   File? _selectedImage;
//   Uint8List? _imageBytes;

//   bool isGuest = true;
//   int _alertCount = 0;
//   Timer? _alertTimer;

//   // Localization Helper with Null Safety
//   String t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

//   @override
//   void initState() {
//     super.initState();
//     _syncAuthStatus();
//     AIService.loadModel();
//     _startAlertPolling();
//   }

//   @override
//   void dispose() {
//     _alertTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _syncAuthStatus() async {
//     bool loggedIn = await _auth.isLoggedIn();
//     if (mounted) {
//       setState(() { isGuest = !loggedIn; });
//       if (loggedIn) _fetchAlertCount();
//     }
//   }

//   void _startAlertPolling() {
//     _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (!isGuest) _fetchAlertCount();
//     });
//   }

//   Future<void> _fetchAlertCount() async {
//     try {
//       final String? token = await _auth.getToken();
//       final response = await http.get(
//         Uri.parse(AppConstants.alertsUrl),
//         headers: {"Authorization": "Token $token"},
//       );

//       if (response.statusCode == 200) {
//         final List alerts = jsonDecode(response.body);
//         final unreadAlerts = alerts.where((a) => a['IsRead'] == false).toList();
//         final int newCount = unreadAlerts.length;

//         if (newCount > _alertCount && mounted) {
//           final newest = unreadAlerts.first;
//           _notifyFarmerOfNewAlert(
//             newest['Title'] ?? t("new_alert"), 
//             newest['Message'] ?? t("check_updates")
//           );
//         }

//         if (mounted) setState(() { _alertCount = newCount; });
//       }
//     } catch (e) {
//       debugPrint("Alert Polling Error: $e");
//     }
//   }

//   void _notifyFarmerOfNewAlert(String title, String message) {
//     HapticFeedback.vibrate(); 
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         duration: const Duration(seconds: 6),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
//         backgroundColor: Colors.orange.shade900,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         content: Row(
//           children: [
//             const Icon(Icons.notification_important, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
//                   Text(message, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
//                 ],
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                 _openAlerts();
//               },
//               child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGuestBanner() {
//     if (!isGuest) return const SizedBox.shrink();
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: isDark ? Colors.green.shade800 : Colors.green.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline, color: isDark ? Colors.greenAccent : const Color(0xFF2E7D32)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(t("guest_title"), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
//                 Text(t("guest_subtitle"), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.green.shade900)),
//               ],
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
//               if (result == true) _syncAuthStatus();
//             },
//             child: Text(t("signin"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A844))),
//           )
//         ],
//       ),
//     );
//   }

//   Future<void> _handleAnalyzePrompt() async {
//     if (_imageBytes == null) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         title: Text(t("analysis_title")),
//         content: Text(t("analysis_question")),
//         actions: [
//           TextButton(onPressed: () { Navigator.pop(context); _startAIAnalysis(isPersonalized: false); }, child: Text(t("general_tips"))),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               final dynamic result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CropTypeScreen(pendingImage: _imageBytes)));
//               String? newId = (result is String) ? result : result?['ProfileID']?.toString();
//               if (newId != null || !isGuest) _startAIAnalysis(isPersonalized: true, forcedProfileId: newId);
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             child: Text(t("personalize"), style: const TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _startAIAnalysis({required bool isPersonalized, String? forcedProfileId}) async {
//     if (_imageBytes == null || _selectedImage == null) return;
//     showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)));

//     try {
//       final aiResult = await AIService.runInference(_imageBytes!);
//       if (aiResult['isRejected'] == true) {
//         if (mounted) Navigator.pop(context);
//         _showErrorSnackBar(aiResult['label']);
//         return;
//       }
//       final String? publicUrl = await _scannerService.uploadCropImage(_selectedImage!);
//       if (publicUrl == null) throw Exception("Upload failed");

//       final backendResponse = await _scannerService.saveScanToBackend(
//         imageUrl: publicUrl,
//         diseaseName: aiResult['label'] ?? "Healthy",
//         confidence: aiResult['confidence'] ?? 0.0,
//         profileId: forcedProfileId, 
//       );

//       if (mounted) {
//         Navigator.pop(context); 
//         if (backendResponse != null) {
//           final Map<String, dynamic> res = backendResponse['results'] ?? {};
//           List<String> advice = (backendResponse['personalized_rules'] as List?)?.map((r) => r['ExpertAdvice']?.toString() ?? "").toList() ?? [];
//           _showResultDialog(diagnosis: res['disease'] ?? aiResult['label'], pesticide: res['pesticide'] ?? "N/A", dosage: res['dosage'] ?? "N/A", steps: res['steps'] ?? "Monitor plant.", confidence: "${((aiResult['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%", personalizedRules: advice);
//           setState(() { _imageBytes = null; _selectedImage = null; });
//         } else {
//           _showErrorSnackBar("Sync Failed.");
//         }
//       }
//     } catch (e) {
//       if (mounted) Navigator.pop(context);
//       _showErrorSnackBar("Error: $e");
//     }
//   }

//   void _showResultDialog({required String diagnosis, required String pesticide, required String dosage, required String steps, required String confidence, List<String> personalizedRules = const []}) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(diagnosis.replaceAll('_', ' '), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
//           Text("Confidence: $confidence", style: const TextStyle(fontSize: 12, color: Colors.grey)),
//         ]),
//         content: SingleChildScrollView(
//           child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
//             const Divider(),
//             _buildInfoRow(Icons.medication_liquid, t("treatment"), pesticide),
//             _buildInfoRow(Icons.straighten, t("dosage"), dosage),
//             _buildInfoRow(Icons.list_alt_rounded, t("steps"), steps),
//             if (personalizedRules.isNotEmpty) ...[
//               const SizedBox(height: 10),
//               Text(t("expert_advice"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
//               const Divider(color: Colors.blue),
//               ...personalizedRules.map((rule) => Text("• $rule", style: const TextStyle(fontSize: 13))),
//             ]
//           ]),
//         ),
//         actions: [ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text(t("done"), style: const TextStyle(color: Colors.white)))],
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(children: [
//         Icon(icon, size: 20, color: Colors.green),
//         const SizedBox(width: 10),
//         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
//           Text(value, style: const TextStyle(fontSize: 14)),
//         ])),
//       ]),
//     );
//   }

//   Future<void> _handleImageAction(ImageSource source) async {
//     final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
//     if (pickedFile != null) {
//       final Uint8List bytes = await pickedFile.readAsBytes();
//       setState(() { _imageBytes = bytes; if (!kIsWeb) _selectedImage = File(pickedFile.path); });
//     }
//   }

//   void _showSignInRequiredDialog(BuildContext context, String featureName) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text("${t("unlock")}$featureName"),
//         content: Text(t("auth_required")),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: Text(t("later"))),
//           ElevatedButton(onPressed: () async { Navigator.pop(context); final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())); if (result == true) _syncAuthStatus(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844)), child: Text(t("signin"), style: const TextStyle(color: Colors.white))),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(children: [
//             const SizedBox(height: 10),
//             _buildHeader(),
//             const SizedBox(height: 15),
//             _buildGuestBanner(), 
//             Expanded(child: Column(children: [
//               Expanded(child: _buildScannerCard()),
//               const SizedBox(height: 25),
//               Row(children: [
//                 Expanded(child: _buildMainActionButton(label: t("upload"), icon: Icons.file_upload_outlined, isPrimary: false, onTap: () => _handleImageAction(ImageSource.gallery))),
//                 const SizedBox(width: 12),
//                 Expanded(child: _buildMainActionButton(label: t("take_photo"), icon: Icons.camera_alt_rounded, isPrimary: true, onTap: () => _handleImageAction(ImageSource.camera))),
//               ]),
//               const SizedBox(height: 20),
//             ])),
//           ]),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         selectedItemColor: Colors.green,
//         unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
//         onTap: (i) => _onNavTap([t("weather"), t("crops"), t("history"), t("settings")][i]),
//         items: [
//           BottomNavigationBarItem(icon: const Icon(Icons.wb_sunny_outlined), label: t("weather")),
//           BottomNavigationBarItem(icon: const Icon(Icons.grass_rounded), label: t("crops")),
//           BottomNavigationBarItem(icon: const Icon(Icons.history_rounded), label: t("history")),
//           BottomNavigationBarItem(icon: const Icon(Icons.settings_suggest_outlined), label: t("settings")),
//         ],
//       ),
//     );
//   }

//   void _onNavTap(String text) {
//     if (text == t("weather")) _openWeather();
//     else if (isGuest) _showSignInRequiredDialog(context, text);
//     else {
//       if (text == t("history")) _openHistory();
//       else if (text == t("crops")) _openCropType();
//       else if (text == t("settings")) _openSettings();
//     }
//   }

//   void _openWeather() => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherServicePage()));
//   void _openHistory() => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
//   void _openAlerts() => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
//   void _openCropType() => Navigator.push(context, MaterialPageRoute(builder: (context) => const CropTypeScreen()));
//   void _openSettings() => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));

//   Widget _buildHeader() {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//       Row(children: [
//         const CircleAvatar(backgroundColor: Color(0xFF00A844), child: Icon(Icons.eco, color: Colors.white)),
//         const SizedBox(width: 12),
//         Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text("FarmAid", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
//           Text(t("subtitle"), style: TextStyle(fontSize: 12, color: isDark ? Colors.greenAccent.withOpacity(0.7) : Colors.green))
//         ])
//       ]),
//       Row(children: [
//         IconButton(onPressed: isGuest ? () => _showSignInRequiredDialog(context, "Alerts") : _openAlerts, icon: Badge(label: Text("$_alertCount"), isLabelVisible: _alertCount > 0, child: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.greenAccent : Colors.green))),
//         IconButton(onPressed: () { if (isGuest) _showSignInRequiredDialog(context, "Profile"); else { _auth.signOut(); _syncAuthStatus(); } }, icon: Icon(isGuest ? Icons.account_circle_outlined : Icons.logout, color: isDark ? Colors.greenAccent : Colors.green))
//       ])
//     ]);
//   }

//   Widget _buildMainActionButton({required String label, required IconData icon, required bool isPrimary, required VoidCallback onTap}) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     final style = isPrimary 
//       ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
//       : OutlinedButton.styleFrom(side: BorderSide(color: isDark ? Colors.green.shade800 : Colors.green.shade200), foregroundColor: isDark ? Colors.greenAccent : Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
//     return SizedBox(height: 55, child: isPrimary ? ElevatedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label), style: style) : OutlinedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label), style: style));
//   }

//   Widget _buildScannerCard() {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)]),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: _imageBytes != null
//           ? Stack(fit: StackFit.expand, children: [
//               Image.memory(_imageBytes!, fit: BoxFit.cover),
//               Positioned(top: 10, right: 10, child: IconButton(onPressed: () => setState(() { _imageBytes = null; }), icon: const CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.close, color: Colors.red)))),
//               Positioned(bottom: 20, left: 50, right: 50, child: ElevatedButton(onPressed: _handleAnalyzePrompt, child: Text(t("analyze"))))
//             ])
//           : Center(child: Text(t("placeholder"), style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green))),
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
//   }
// }



// import 'dart:io';
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; 
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // Correct Imports
// import '../../weather/presentation/weather_service.dart';
// import '../../auth/presentation/login_screen.dart';
// import '../../../services/auth_service.dart';
// import '../../scanner/data/ai_service.dart';
// import '../../scanner/data/scanner_service.dart'; 
// import '../../history/presentation/history_screen.dart';
// import '../../alerts/presentation/alerts_screen.dart';
// import '../../crops/presentation/crop_type_screen.dart';
// import './settings_screen.dart'; 
// import '../../../core/constants.dart'; 
// import '../../../core/app_localizations.dart';

// class HomeDashboard extends StatefulWidget {
//   const HomeDashboard({super.key});

//   @override
//   State<HomeDashboard> createState() => _HomeDashboardState();
// }

// class _HomeDashboardState extends State<HomeDashboard> {
//   final AuthService _auth = AuthService();
//   final ScannerService _scannerService = ScannerService(); 
//   final ImagePicker _picker = ImagePicker();
//   final _supabase = Supabase.instance.client;

//   File? _selectedImage;
//   Uint8List? _imageBytes;

//   bool isGuest = true;
//   int _alertCount = 0;
//   Timer? _alertTimer;

//   // Localization Helper with Null Safety
//   String t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

//   @override
//   void initState() {
//     super.initState();
//     _syncAuthStatus();
//     AIService.loadModel();
//     _startAlertPolling();
//   }

//   @override
//   void dispose() {
//     _alertTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _syncAuthStatus() async {
//     bool loggedIn = await _auth.isLoggedIn();
//     if (mounted) {
//       setState(() { isGuest = !loggedIn; });
//       if (loggedIn) _fetchAlertCount();
//     }
//   }

//   void _startAlertPolling() {
//     _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (!isGuest) _fetchAlertCount();
//     });
//   }

//   Future<void> _fetchAlertCount() async {
//     try {
//       final String? token = await _auth.getToken();
//       final response = await http.get(
//         Uri.parse(AppConstants.alertsUrl),
//         headers: {"Authorization": "Token $token"},
//       );

//       if (response.statusCode == 200) {
//         final List alerts = jsonDecode(response.body);
//         final unreadAlerts = alerts.where((a) => a['IsRead'] == false).toList();
//         final int newCount = unreadAlerts.length;

//         if (newCount > _alertCount && mounted) {
//           final newest = unreadAlerts.first;
//           _notifyFarmerOfNewAlert(
//             newest['Title'] ?? t("new_alert"), 
//             newest['Message'] ?? t("check_updates")
//           );
//         }

//         if (mounted) setState(() { _alertCount = newCount; });
//       }
//     } catch (e) {
//       debugPrint("Alert Polling Error: $e");
//     }
//   }

//   void _notifyFarmerOfNewAlert(String title, String message) {
//     HapticFeedback.vibrate(); 
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         duration: const Duration(seconds: 6),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
//         backgroundColor: Colors.orange.shade900,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         content: Row(
//           children: [
//             const Icon(Icons.notification_important, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
//                   Text(message, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
//                 ],
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                 _openAlerts();
//               },
//               child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGuestBanner() {
//     if (!isGuest) return const SizedBox.shrink();
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: isDark ? Colors.green.shade800 : Colors.green.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline, color: isDark ? Colors.greenAccent : const Color(0xFF2E7D32)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(t("guest_title"), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
//                 Text(t("guest_subtitle"), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.green.shade900)),
//               ],
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
//               if (result == true) _syncAuthStatus();
//             },
//             child: Text(t("signin"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A844))),
//           )
//         ],
//       ),
//     );
//   }

// Future<void> _handleAnalyzePrompt() async {
//   if (_imageBytes == null) return;

//   // 1. Ask the user what they want to do
//   final String? action = await showDialog<String>(
//     context: context,
//     builder: (context) => AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       title: Text(t("analysis_title")),
//       content: Text(t("analysis_question")),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context, 'general'), 
//           child: Text(t("general_tips"))
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.pop(context, 'personalize'),
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//           child: Text(t("personalize"), style: const TextStyle(color: Colors.white)),
//         ),
//       ],
//     ),
//   );

//   if (action == null) return; // User dismissed the dialog

//   if (action == 'general') {
//     // Run general analysis immediately
//     _startAIAnalysis(isPersonalized: false);
//   } else if (action == 'personalize') {
//     // 2. Go to the form and WAIT for the result
//     final dynamic result = await Navigator.push(
//       context, 
//       MaterialPageRoute(builder: (context) => CropTypeScreen(pendingImage: _imageBytes))
//     );

//     // 3. Check what we got back from the form
//     String? profileId;
//     if (result is String) {
//       profileId = result;
//     } else if (result is Map) {
//       profileId = result['id']?.toString() ?? result['ProfileID']?.toString();
//     }

//     // 4. Run the AI Analysis with the ID we just got
//     if (profileId != null) {
//       _startAIAnalysis(isPersonalized: true, forcedProfileId: profileId);
//     } else if (!isGuest) {
//       // If they are logged in but didn't create a NEW profile, 
//       // maybe they just selected an existing one.
//        _startAIAnalysis(isPersonalized: true);
//     }
//   }
// }

//   Future<void> _startAIAnalysis({required bool isPersonalized, String? forcedProfileId}) async {
//     if (_imageBytes == null || _selectedImage == null) return;
//     showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)));

//     try {
//       final aiResult = await AIService.runInference(_imageBytes!);
//       if (aiResult['isRejected'] == true) {
//         if (mounted) Navigator.pop(context);
//         _showErrorSnackBar(aiResult['label']);
//         return;
//       }
//       final String? publicUrl = await _scannerService.uploadCropImage(_selectedImage!);
//       if (publicUrl == null) throw Exception("Upload failed");

//       final backendResponse = await _scannerService.saveScanToBackend(
//         imageUrl: publicUrl,
//         diseaseName: aiResult['label'] ?? "Healthy",
//         confidence: aiResult['confidence'] ?? 0.0,
//         profileId: forcedProfileId, 
//       );

//       if (mounted) {
//         Navigator.pop(context); 
//         if (backendResponse != null) {
//           final Map<String, dynamic> res = backendResponse['results'] ?? {};
//           List<String> advice = (backendResponse['personalized_rules'] as List?)?.map((r) => r['ExpertAdvice']?.toString() ?? "").toList() ?? [];
//           _showResultDialog(diagnosis: res['disease'] ?? aiResult['label'], pesticide: res['pesticide'] ?? "N/A", dosage: res['dosage'] ?? "N/A", steps: res['steps'] ?? "Monitor plant.", confidence: "${((aiResult['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%", personalizedRules: advice);
//           setState(() { _imageBytes = null; _selectedImage = null; });
//         } else {
//           _showErrorSnackBar("Sync Failed.");
//         }
//       }
//     } catch (e) {
//       if (mounted) Navigator.pop(context);
//       _showErrorSnackBar("Error: $e");
//     }
//   }

//   void _showResultDialog({required String diagnosis, required String pesticide, required String dosage, required String steps, required String confidence, List<String> personalizedRules = const []}) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(diagnosis.replaceAll('_', ' '), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
//           Text("Confidence: $confidence", style: const TextStyle(fontSize: 12, color: Colors.grey)),
//         ]),
//         content: SingleChildScrollView(
//           child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
//             const Divider(),
//             _buildInfoRow(Icons.medication_liquid, t("treatment"), pesticide),
//             _buildInfoRow(Icons.straighten, t("dosage"), dosage),
//             _buildInfoRow(Icons.list_alt_rounded, t("steps"), steps),
//             if (personalizedRules.isNotEmpty) ...[
//               const SizedBox(height: 10),
//               Text(t("expert_advice"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
//               const Divider(color: Colors.blue),
//               ...personalizedRules.map((rule) => Text("• $rule", style: const TextStyle(fontSize: 13))),
//             ]
//           ]),
//         ),
//         actions: [ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text(t("done"), style: const TextStyle(color: Colors.white)))],
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(children: [
//         Icon(icon, size: 20, color: Colors.green),
//         const SizedBox(width: 10),
//         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
//           Text(value, style: const TextStyle(fontSize: 14)),
//         ])),
//       ]),
//     );
//   }

//   Future<void> _handleImageAction(ImageSource source) async {
//     final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
//     if (pickedFile != null) {
//       final Uint8List bytes = await pickedFile.readAsBytes();
//       setState(() { _imageBytes = bytes; if (!kIsWeb) _selectedImage = File(pickedFile.path); });
//     }
//   }

//   void _showSignInRequiredDialog(BuildContext context, String featureName) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text("${t("unlock")}$featureName"),
//         content: Text(t("auth_required")),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: Text(t("later"))),
//           ElevatedButton(onPressed: () async { Navigator.pop(context); final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())); if (result == true) _syncAuthStatus(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844)), child: Text(t("signin"), style: const TextStyle(color: Colors.white))),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(children: [
//             const SizedBox(height: 10),
//             _buildHeader(),
//             const SizedBox(height: 15),
//             _buildGuestBanner(), 
//             Expanded(child: Column(children: [
//               Expanded(child: _buildScannerCard()),
//               const SizedBox(height: 25),
//               Row(children: [
//                 Expanded(child: _buildMainActionButton(label: t("upload"), icon: Icons.file_upload_outlined, isPrimary: false, onTap: () => _handleImageAction(ImageSource.gallery))),
//                 const SizedBox(width: 12),
//                 Expanded(child: _buildMainActionButton(label: t("take_photo"), icon: Icons.camera_alt_rounded, isPrimary: true, onTap: () => _handleImageAction(ImageSource.camera))),
//               ]),
//               const SizedBox(height: 20),
//             ])),
//           ]),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         selectedItemColor: Colors.green,
//         unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
//         onTap: (i) => _onNavTap([t("weather"), t("crops"), t("history"), t("settings")][i]),
//         items: [
//           BottomNavigationBarItem(icon: const Icon(Icons.wb_sunny_outlined), label: t("weather")),
//           BottomNavigationBarItem(icon: const Icon(Icons.grass_rounded), label: t("crops")),
//           BottomNavigationBarItem(icon: const Icon(Icons.history_rounded), label: t("history")),
//           BottomNavigationBarItem(icon: const Icon(Icons.settings_suggest_outlined), label: t("settings")),
//         ],
//       ),
//     );
//   }

//   void _onNavTap(String text) {
//     if (text == t("weather")) _openWeather();
//     else if (isGuest) _showSignInRequiredDialog(context, text);
//     else {
//       if (text == t("history")) _openHistory();
//       else if (text == t("crops")) _openCropType();
//       else if (text == t("settings")) _openSettings();
//     }
//   }

//   void _openWeather() => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherServicePage()));
//   void _openHistory() => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
//   void _openAlerts() => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
//   void _openCropType() => Navigator.push(context, MaterialPageRoute(builder: (context) => const CropTypeScreen()));
//   void _openSettings() => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));

//   Widget _buildHeader() {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//       Row(children: [
//         const CircleAvatar(backgroundColor: Color(0xFF00A844), child: Icon(Icons.eco, color: Colors.white)),
//         const SizedBox(width: 12),
//         Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text("FarmAid", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
//           Text(t("subtitle"), style: TextStyle(fontSize: 12, color: isDark ? Colors.greenAccent.withOpacity(0.7) : Colors.green))
//         ])
//       ]),
//       Row(children: [
//         IconButton(onPressed: isGuest ? () => _showSignInRequiredDialog(context, "Alerts") : _openAlerts, icon: Badge(label: Text("$_alertCount"), isLabelVisible: _alertCount > 0, child: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.greenAccent : Colors.green))),
//         IconButton(onPressed: () { if (isGuest) _showSignInRequiredDialog(context, "Profile"); else { _auth.signOut(); _syncAuthStatus(); } }, icon: Icon(isGuest ? Icons.account_circle_outlined : Icons.logout, color: isDark ? Colors.greenAccent : Colors.green))
//       ])
//     ]);
//   }

//   Widget _buildMainActionButton({required String label, required IconData icon, required bool isPrimary, required VoidCallback onTap}) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     final style = isPrimary 
//       ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
//       : OutlinedButton.styleFrom(side: BorderSide(color: isDark ? Colors.green.shade800 : Colors.green.shade200), foregroundColor: isDark ? Colors.greenAccent : Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
//     return SizedBox(height: 55, child: isPrimary ? ElevatedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label), style: style) : OutlinedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label), style: style));
//   }

//   Widget _buildScannerCard() {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)]),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: _imageBytes != null
//           ? Stack(fit: StackFit.expand, children: [
//               Image.memory(_imageBytes!, fit: BoxFit.cover),
//               Positioned(top: 10, right: 10, child: IconButton(onPressed: () => setState(() { _imageBytes = null; }), icon: const CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.close, color: Colors.red)))),
//               Positioned(bottom: 20, left: 50, right: 50, child: ElevatedButton(onPressed: _handleAnalyzePrompt, child: Text(t("analyze"))))
//             ])
//           : Center(child: Text(t("placeholder"), style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green))),
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
//   }
// }


import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Correct Imports
import '../../weather/presentation/weather_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../scanner/data/ai_service.dart';
import '../../scanner/data/scanner_service.dart'; 
import '../../history/presentation/history_screen.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../crops/presentation/crop_type_screen.dart';
import './settings_screen.dart'; 
import '../../../core/constants.dart'; 
import '../../../core/app_localizations.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final AuthService _auth = AuthService();
  final ScannerService _scannerService = ScannerService(); 
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  File? _selectedImage;
  Uint8List? _imageBytes;

  bool isGuest = true;
  int _alertCount = 0;
  Timer? _alertTimer;

  // Localization Helper with Null Safety
  String t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _syncAuthStatus();
    AIService.loadModel();
    _startAlertPolling();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncAuthStatus() async {
    bool loggedIn = await _auth.isLoggedIn();
    if (mounted) {
      setState(() { isGuest = !loggedIn; });
      if (loggedIn) _fetchAlertCount();
    }
  }

  void _startAlertPolling() {
    _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isGuest) _fetchAlertCount();
    });
  }

  Future<void> _fetchAlertCount() async {
    try {
      final String? token = await _auth.getToken();
      final response = await http.get(
        Uri.parse(AppConstants.alertsUrl),
        headers: {"Authorization": "Token $token"},
      );

      if (response.statusCode == 200) {
        final List alerts = jsonDecode(response.body);
        final unreadAlerts = alerts.where((a) => a['IsRead'] == false).toList();
        final int newCount = unreadAlerts.length;

        if (newCount > _alertCount && mounted) {
          final newest = unreadAlerts.first;
          _notifyFarmerOfNewAlert(
            newest['Title'] ?? t("new_alert"), 
            newest['Message'] ?? t("check_updates")
          );
        }

        if (mounted) setState(() { _alertCount = newCount; });
      }
    } catch (e) {
      debugPrint("Alert Polling Error: $e");
    }
  }

  void _notifyFarmerOfNewAlert(String title, String message) {
    HapticFeedback.vibrate(); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
        backgroundColor: Colors.orange.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.notification_important, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  Text(message, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _openAlerts();
              },
              child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestBanner() {
    if (!isGuest) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.green.shade800 : Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: isDark ? Colors.greenAccent : const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t("guest_title"), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
                Text(t("guest_subtitle"), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.green.shade900)),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              if (result == true) _syncAuthStatus();
            },
            child: Text(t("signin"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A844))),
          )
        ],
      ),
    );
  }

  Future<void> _handleAnalyzePrompt() async {
    if (_imageBytes == null) return;

    // BLOCK GUESTS: Backend requires IsAuthenticated for results and translations
    if (isGuest) {
      _showSignInRequiredDialog(context, t("analyze"));
      return;
    }

    final String? action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(t("analysis_title")),
        content: Text(t("analysis_question")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'general'), 
            child: Text(t("general_tips"))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'personalize'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(t("personalize"), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (action == null) return;

    if (action == 'general') {
      _startAIAnalysis(isPersonalized: false);
    } else if (action == 'personalize') {
      final dynamic result = await Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => CropTypeScreen(pendingImage: _imageBytes))
      );

      String? profileId;
      if (result is String) {
        profileId = result;
      } else if (result is Map) {
        profileId = result['id']?.toString() ?? result['ProfileID']?.toString();
      }

      if (profileId != null) {
        _startAIAnalysis(isPersonalized: true, forcedProfileId: profileId);
      } else {
         _startAIAnalysis(isPersonalized: true);
      }
    }
  }

  Future<void> _startAIAnalysis({required bool isPersonalized, String? forcedProfileId}) async {
    if (_imageBytes == null || _selectedImage == null) return;
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)));

    try {
      final aiResult = await AIService.runInference(_imageBytes!);
      if (aiResult['isRejected'] == true) {
        if (mounted) Navigator.pop(context);
        _showErrorSnackBar(aiResult['label']);
        return;
      }
      final String? publicUrl = await _scannerService.uploadCropImage(_selectedImage!);
      if (publicUrl == null) throw Exception("Upload failed");

      final backendResponse = await _scannerService.saveScanToBackend(
        imageUrl: publicUrl,
        diseaseName: aiResult['label'] ?? "Healthy",
        confidence: aiResult['confidence'] ?? 0.0,
        profileId: forcedProfileId, 
      );

      if (mounted) {
        Navigator.pop(context); 
        if (backendResponse != null) {
          final Map<String, dynamic> res = backendResponse['results'] ?? {};
          List<String> advice = (backendResponse['personalized_rules'] as List?)?.map((r) => r['ExpertAdvice']?.toString() ?? "").toList() ?? [];
          
          // Use backend provided (translated) values, fallback to AI labels if missing
          _showResultDialog(
            diagnosis: res['disease'] ?? aiResult['label'], 
            pesticide: res['pesticide'] ?? "N/A", 
            dosage: res['dosage'] ?? "N/A", 
            steps: res['steps'] ?? "Monitor plant.", 
            confidence: "${((aiResult['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%", 
            personalizedRules: advice
          );
          setState(() { _imageBytes = null; _selectedImage = null; });
        } else {
          _showErrorSnackBar("Sync Failed.");
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Error: $e");
    }
  }

  void _showResultDialog({required String diagnosis, required String pesticide, required String dosage, required String steps, required String confidence, List<String> personalizedRules = const []}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(diagnosis.replaceAll('_', ' '), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
          Text("Confidence: $confidence", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Divider(),
            _buildInfoRow(Icons.medication_liquid, t("treatment"), pesticide),
            _buildInfoRow(Icons.straighten, t("dosage"), dosage),
            _buildInfoRow(Icons.list_alt_rounded, t("steps"), steps),
            if (personalizedRules.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(t("expert_advice"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
              const Divider(color: Colors.blue),
              ...personalizedRules.map((rule) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text("• $rule", style: const TextStyle(fontSize: 13)),
              )),
            ]
          ]),
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text(t("done"), style: const TextStyle(color: Colors.white)))],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ])),
      ]),
    );
  }

  Future<void> _handleImageAction(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      final Uint8List bytes = await pickedFile.readAsBytes();
      setState(() { _imageBytes = bytes; if (!kIsWeb) _selectedImage = File(pickedFile.path); });
    }
  }

  void _showSignInRequiredDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("${t("unlock")} $featureName"),
        content: Text(t("auth_required")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t("later"))),
          ElevatedButton(
            onPressed: () async { 
              Navigator.pop(context); 
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())); 
              if (result == true) _syncAuthStatus(); 
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844)), 
            child: Text(t("signin"), style: const TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(children: [
            const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 15),
            _buildGuestBanner(), 
            Expanded(child: Column(children: [
              Expanded(child: _buildScannerCard()),
              const SizedBox(height: 25),
              Row(children: [
                Expanded(child: _buildMainActionButton(label: t("upload"), icon: Icons.file_upload_outlined, isPrimary: false, onTap: () => _handleImageAction(ImageSource.gallery))),
                const SizedBox(width: 12),
                Expanded(child: _buildMainActionButton(label: t("take_photo"), icon: Icons.camera_alt_rounded, isPrimary: true, onTap: () => _handleImageAction(ImageSource.camera))),
              ]),
              const SizedBox(height: 20),
            ])),
          ]),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        onTap: (i) {
          final labels = ["weather", "crops", "history", "settings"];
          _onNavTap(labels[i]);
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.wb_sunny_outlined), label: t("weather")),
          BottomNavigationBarItem(icon: const Icon(Icons.grass_rounded), label: t("crops")),
          BottomNavigationBarItem(icon: const Icon(Icons.history_rounded), label: t("history")),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_suggest_outlined), label: t("settings")),
        ],
      ),
    );
  }

  void _onNavTap(String key) {
    if (key == "weather") _openWeather();
    else if (isGuest) _showSignInRequiredDialog(context, t(key));
    else {
      if (key == "history") _openHistory();
      else if (key == "crops") _openCropType();
      else if (key == "settings") _openSettings();
    }
  }

  void _openWeather() => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherServicePage()));
  void _openHistory() => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
  void _openAlerts() => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
  void _openCropType() => Navigator.push(context, MaterialPageRoute(builder: (context) => const CropTypeScreen()));
  void _openSettings() => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));

  Widget _buildHeader() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        const CircleAvatar(backgroundColor: Color(0xFF00A844), child: Icon(Icons.eco, color: Colors.white)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("FarmAid", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
          Text(t("subtitle"), style: TextStyle(fontSize: 12, color: isDark ? Colors.greenAccent.withOpacity(0.7) : Colors.green))
        ])
      ]),
      Row(children: [
        IconButton(onPressed: isGuest ? () => _showSignInRequiredDialog(context, t("alerts")) : _openAlerts, icon: Badge(label: Text("$_alertCount"), isLabelVisible: _alertCount > 0, child: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.greenAccent : Colors.green))),
        IconButton(onPressed: () { if (isGuest) _showSignInRequiredDialog(context, t("profile")); else { _auth.signOut(); _syncAuthStatus(); } }, icon: Icon(isGuest ? Icons.account_circle_outlined : Icons.logout, color: isDark ? Colors.greenAccent : Colors.green))
      ])
    ]);
  }

  Widget _buildMainActionButton({required String label, required IconData icon, required bool isPrimary, required VoidCallback onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final style = isPrimary 
      ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
      : OutlinedButton.styleFrom(side: BorderSide(color: isDark ? Colors.green.shade800 : Colors.green.shade200), foregroundColor: isDark ? Colors.greenAccent : Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
    return SizedBox(height: 55, child: isPrimary ? ElevatedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label), style: style) : OutlinedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label), style: style));
  }

  Widget _buildScannerCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _imageBytes != null
          ? Stack(fit: StackFit.expand, children: [
              Image.memory(_imageBytes!, fit: BoxFit.cover),
              Positioned(top: 10, right: 10, child: IconButton(onPressed: () => setState(() { _imageBytes = null; }), icon: const CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.close, color: Colors.red)))),
              Positioned(bottom: 20, left: 50, right: 50, child: ElevatedButton(onPressed: _handleAnalyzePrompt, child: Text(t("analyze"))))
            ])
          : Center(child: Text(t("placeholder"), style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green))),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}