// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; 
// import 'package:share_plus/share_plus.dart';
// import 'dart:io'; 
// import 'package:path_provider/path_provider.dart'; 
// import 'package:provider/provider.dart';

// // REAL APP IMPORTS
// import 'package:farm_aid_app/services/auth_service.dart';
// import 'package:farm_aid_app/features/scanner/data/ai_service.dart';
// import 'package:farm_aid_app/features/dashboard/presentation/profile_screen.dart';
// import 'package:farm_aid_app/services/theme_provider.dart';
// import 'package:farm_aid_app/services/language_provider.dart'; // IMPORTED: Language Provider

// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({super.key});

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   final AuthService _authService = AuthService();
//   final AIService _aiService = AIService(); 

//   static const Color primaryGreen = Color(0xFF2E7D32);

//   bool _isSyncing = false;
//   bool _syncSuccess = false; 

//   // --- UI HELPERS USING SYSTEM THEME ---
//   Color get textColor => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
//   Color get subTextColor => Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
//   Color get cardColor => Theme.of(context).cardColor;

//   void _showPasswordDialog() {
//     final TextEditingController oldPassController = TextEditingController();
//     final TextEditingController newPassController = TextEditingController();
//     bool isLoading = false;
//     bool obscureOld = true;
//     bool obscureNew = true;

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           backgroundColor: cardColor,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           title: const Text("Change Password", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: oldPassController,
//                 obscureText: obscureOld,
//                 style: TextStyle(color: textColor),
//                 decoration: InputDecoration(
//                   labelText: "Current Password",
//                   labelStyle: TextStyle(color: subTextColor),
//                   suffixIcon: IconButton(
//                     icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, color: primaryGreen),
//                     onPressed: () => setDialogState(() => obscureOld = !obscureOld),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: newPassController,
//                 obscureText: obscureNew,
//                 style: TextStyle(color: textColor),
//                 decoration: InputDecoration(
//                   labelText: "New Password",
//                   labelStyle: TextStyle(color: subTextColor),
//                   suffixIcon: IconButton(
//                     icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: primaryGreen),
//                     onPressed: () => setDialogState(() => obscureNew = !obscureNew),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
//               onPressed: isLoading ? null : () async {
//                 if (oldPassController.text.isEmpty || newPassController.text.isEmpty) {
//                   _showSnackBar("Please fill in both fields.");
//                   return;
//                 }
//                 setDialogState(() => isLoading = true);
//                 final result = await _authService.changePassword(oldPassController.text, newPassController.text);
//                 setDialogState(() => isLoading = false);

//                 if (result['success']) {
//                   Navigator.pop(context);
//                   _showSnackBar("Password updated successfully!");
//                 } else {
//                   _showSnackBar(result['message'] ?? "Update failed");
//                 }
//               },
//               child: isLoading 
//                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                 : const Text("UPDATE", style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _handleNeonSync() async {
//     setState(() {
//       _isSyncing = true;
//       _syncSuccess = false; 
//     });
//     try {
//       await _aiService.syncScanHistory();
//       setState(() => _syncSuccess = true); 
//       _showSnackBar("Vegetable history synced with Neon DB successfully!");
//     } catch (e) {
//       _showSnackBar("Sync failed. Check your internet connection.");
//     } finally {
//       setState(() => _isSyncing = false);
//     }
//   }

//   Future<void> _handleClearCache() async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       if (tempDir.existsSync()) {
//         tempDir.deleteSync(recursive: true); 
//         _showSnackBar("Image cache cleared! Storage space freed.");
//       }
//     } catch (e) {
//       _showSnackBar("Failed to clear cache.");
//     }
//   }

//   Future<void> _handleLogout() async {
//     final bool? confirm = await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: cardColor,
//         title: Text("Logout", style: TextStyle(color: textColor)),
//         content: Text("Are you sure you want to sign out?", style: TextStyle(color: subTextColor)),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true), 
//             child: const Text("Logout", style: TextStyle(color: Colors.red))
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       await _authService.signOut();
//       if (mounted) Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   // --- NEW: LANGUAGE PICKER LOGIC ---
//   Future<void> _showLanguagePicker() async {
//     final langProv = Provider.of<LanguageProvider>(context, listen: false);
    
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (context) => Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 15),
//           Text("Select Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
//           const Divider(),
//           _buildLanguageOption("English", "en", langProv.appLocale.languageCode == "en", langProv),
//           _buildLanguageOption("Sesotho", "st", langProv.appLocale.languageCode == "st", langProv),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildLanguageOption(String label, String code, bool isSelected, LanguageProvider langProv) {
//     return ListTile(
//       leading: Icon(Icons.language, color: isSelected ? primaryGreen : Colors.grey),
//       title: Text(label, style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
//       trailing: isSelected ? const Icon(Icons.check_circle, color: primaryGreen) : null,
//       onTap: () async {
//         Navigator.pop(context);
//         await langProv.changeLanguage(Locale(code)); // Update Global State
//         _showSnackBar("Language changed to $label");
//       },
//     );
//   }

//   Future<void> _contactSupport() async {
//     final Uri telUri = Uri(scheme: 'tel', path: '+26658575277'); 
//     if (await canLaunchUrl(telUri)) {
//       await launchUrl(telUri);
//     } else {
//       _showSnackBar("Could not open dialer. Call +266 5837 4842");
//     }
//   }

//   void _shareApp() {
//     Share.share(
//       'Protect your vegetables with FarmAid Lesotho! Identify diseases like Blight instantly. Download: [PlayStore Link]',
//       subject: 'Check out FarmAid Lesotho',
//     );
//   }

//   void _showTerms() {
//     _showInfoModal(
//       "Terms and Conditions",
//       "1. AI Accuracy: Supportive guide for Vegetables only. Non-vegetable scans are rejected.\n\n"
//       "2. Professional Advice: Verify results with a local extension officer.\n\n"
//       "3. Data Usage: Images are stored in Supabase; results in Neon DB to help map outbreaks in Lesotho districts."
//     );
//   }

//   void _showFAQ() {
//     _showInfoModal(
//       "Help / FAQ",
//       "• Why was my photo rejected?\nThe AI rejects non-vegetable images for accuracy.\n\n"
//       "• Do I need internet?\nYes, to sync results with the Neon Database.\n\n"
//       "• Supported Crops:\nTomato, Cabbage, Pepper, Onion, and Potato."
//     );
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
//   }

//   void _showInfoModal(String title, String content) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.6,
//         maxChildSize: 0.9,
//         minChildSize: 0.4,
//         builder: (context, scrollController) => Container(
//           decoration: BoxDecoration(
//             color: cardColor,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
//           ),
//           padding: const EdgeInsets.all(24.0),
//           child: ListView(
//             controller: scrollController,
//             children: [
//               Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
//               const SizedBox(height: 20),
//               Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen)),
//               const Divider(height: 30),
//               Text(content, style: TextStyle(fontSize: 16, height: 1.6, color: subTextColor)),
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryGreen,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                 ),
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("I UNDERSTAND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProv = Provider.of<ThemeProvider>(context);
//     final langProv = Provider.of<LanguageProvider>(context); // Watching language provider

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: Text('Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: textColor),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           children: [
//             const SizedBox(height: 10),
//             _buildProfileHeader(),
//             const SizedBox(height: 25),
            
//             _buildSettingsCard([
//               _buildListTile(
//                 Icons.person_outline, 
//                 "Profile details",
//                 onTap: () async {
//                   final result = await Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const ProfileScreen()),
//                   );
//                   if (result == true) setState(() {}); 
//                 },
//               ),
//               _buildListTile(
//                 Icons.lock_outline, 
//                 "Password",
//                 onTap: _showPasswordDialog,
//               ),
//               _buildSwitchTile(
//                 Icons.dark_mode_outlined, 
//                 "Dark Mode", 
//                 themeProv.isDarkMode, 
//                 (val) => themeProv.toggleTheme(val),
//               ),
//             ]),

//             const SizedBox(height: 20),

//             _buildSettingsCard([
//               _buildListTile(
//                 Icons.translate, 
//                 "Language Preference", 
//                 subtitle: langProv.appLocale.languageCode == "en" ? "English" : "Sesotho",
//                 onTap: _showLanguagePicker, // TRIGGER: Show picker
//               ),
//               _buildListTile(
//                 Icons.cloud_sync_outlined, 
//                 "Sync with Neon DB", 
//                 subtitle: _isSyncing 
//                   ? "Syncing..." 
//                   : (_syncSuccess ? "Updated" : "Update vegetable scan history"),
//                 onTap: _isSyncing ? null : _handleNeonSync,
//                 trailing: _isSyncing 
//                   ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) 
//                   : (_syncSuccess ? const Icon(Icons.check_circle, color: primaryGreen, size: 20) : null),
//               ),
//             ]),

//             const SizedBox(height: 20),

//             _buildSettingsCard([
//               _buildListTile(Icons.description_outlined, "Terms and Conditions", onTap: _showTerms),
//               _buildListTile(Icons.contact_support, "Contact Support", onTap: _contactSupport), 
//               _buildListTile(Icons.help_outline, "Help / FAQ", onTap: _showFAQ),
//               _buildListTile(Icons.share_outlined, "Share application", onTap: _shareApp),
//             ]),

//             const SizedBox(height: 20),

//             _buildSettingsCard([
//               _buildListTile(Icons.logout, "Logout", textColor: Colors.red, onTap: _handleLogout),
//               _buildListTile(
//                 Icons.delete_sweep_outlined, 
//                 "Clear Image Cache", 
//                 textColor: Colors.red, 
//                 subtitle: "Delete local photos only",
//                 onTap: () async {
//                   bool? confirm = await showDialog(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       backgroundColor: cardColor,
//                       title: Text("Clear Cache?", style: TextStyle(color: textColor)),
//                       content: Text("This removes temporary scan photos to save space. Your cloud history is safe.", style: TextStyle(color: subTextColor)),
//                       actions: [
//                         TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
//                         TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("CLEAR", style: TextStyle(color: Colors.red))),
//                       ],
//                     ),
//                   );
//                   if (confirm == true) _handleClearCache();
//                 },
//               ),
//             ]),
            
//             const SizedBox(height: 40),
//             Text("FarmAid Lesotho v1.0.2", style: TextStyle(color: subTextColor, fontSize: 12)),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileHeader() {
//     return FutureBuilder<Map<String, dynamic>?>(
//       future: _authService.getCurrentUser(),
//       builder: (context, snapshot) {
//         final name = snapshot.data?['full_name'] ?? "Farmer Name";
//         final district = snapshot.data?['district'] ?? "Maseru District, LS";

//         return Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
//           child: Row(
//             children: [
//               const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.person, size: 40, color: primaryGreen)),
//               const SizedBox(width: 15),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
//                   Text(district.contains("District") ? district : "$district District, LS", style: const TextStyle(color: Colors.grey)),
//                 ],
//               ),
//               const Spacer(),
//               const Icon(Icons.verified_user, size: 20, color: primaryGreen),
//             ],
//           ),
//         );
//       }
//     );
//   }

//   Widget _buildSettingsCard(List<Widget> children) {
//     return Container(
//       decoration: BoxDecoration(
//         color: cardColor, 
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03), 
//             blurRadius: 10, 
//             offset: const Offset(0, 5)
//           )
//         ],
//       ),
//       child: Column(children: children),
//     );
//   }

//   Widget _buildListTile(IconData icon, String title, {String? subtitle, Color? textColor, VoidCallback? onTap, Widget? trailing}) {
//     return ListTile(
//       leading: Icon(icon, color: textColor ?? primaryGreen),
//       title: Text(title, style: TextStyle(color: textColor ?? this.textColor, fontWeight: FontWeight.w500, fontSize: 15)),
//       subtitle: subtitle != null 
//           ? Text(subtitle, style: TextStyle(fontSize: 12, color: subtitle == "Updated" ? primaryGreen : Colors.grey)) 
//           : null,
//       trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
//       onTap: onTap,
//     );
//   }

//   Widget _buildSwitchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
//     return SwitchListTile(
//       secondary: Icon(icon, color: primaryGreen),
//       title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15)),
//       value: value,
//       onChanged: onChanged,
//       activeColor: primaryGreen,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:share_plus/share_plus.dart';
import 'dart:io'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:provider/provider.dart';

// REAL APP IMPORTS
import 'package:farm_aid_app/services/auth_service.dart';
import 'package:farm_aid_app/features/scanner/data/ai_service.dart';
import 'package:farm_aid_app/features/dashboard/presentation/profile_screen.dart';
import 'package:farm_aid_app/services/theme_provider.dart';
import 'package:farm_aid_app/services/language_provider.dart';
import 'package:farm_aid_app/core/app_localizations.dart'; // IMPORTED

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final AIService _aiService = AIService(); 

  static const Color primaryGreen = Color(0xFF2E7D32);

  bool _isSyncing = false;
  bool _syncSuccess = false; 

  // --- UI HELPERS ---
  Color get textColor => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  Color get subTextColor => Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
  Color get cardColor => Theme.of(context).cardColor;

  void _showPasswordDialog() {
    final appLoc = AppLocalizations.of(context);
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    bool isLoading = false;
    bool obscureOld = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(appLoc?.translate("password") ?? "Password", style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassController,
                obscureText: obscureOld,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: appLoc?.translate("current_password") ?? "Current Password",
                  labelStyle: TextStyle(color: subTextColor),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, color: primaryGreen),
                    onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPassController,
                obscureText: obscureNew,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: appLoc?.translate("new_password") ?? "New Password",
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
              child: Text(appLoc?.translate("cancel") ?? "CANCEL", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: isLoading ? null : () async {
                if (oldPassController.text.isEmpty || newPassController.text.isEmpty) return;
                setDialogState(() => isLoading = true);
                final result = await _authService.changePassword(oldPassController.text, newPassController.text);
                setDialogState(() => isLoading = false);

                if (result['success']) {
                  Navigator.pop(context);
                  _showSnackBar(appLoc?.translate("synced") ?? "Updated");
                }
              },
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(appLoc?.translate("update") ?? "UPDATE", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNeonSync() async {
    final appLoc = AppLocalizations.of(context);
    setState(() {
      _isSyncing = true;
      _syncSuccess = false; 
    });
    try {
      await _aiService.syncScanHistory();
      setState(() => _syncSuccess = true); 
      _showSnackBar(appLoc?.translate("sync_success_msg") ?? "Synced");
    } catch (e) {
      _showSnackBar("Sync failed");
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleClearCache() async {
    final appLoc = AppLocalizations.of(context);
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true); 
        _showSnackBar(appLoc?.translate("cache_cleared_msg") ?? "Cleared");
      }
    } catch (e) {
      _showSnackBar("Failed to clear cache.");
    }
  }

  Future<void> _handleLogout() async {
    final appLoc = AppLocalizations.of(context);
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(appLoc?.translate("logout") ?? "Logout", style: TextStyle(color: textColor)),
        content: Text(appLoc?.translate("logout_confirm") ?? "Confirm?", style: TextStyle(color: subTextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(appLoc?.translate("cancel") ?? "Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(appLoc?.translate("logout") ?? "Logout", style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _showLanguagePicker() async {
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    final appLoc = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          Text(appLoc?.translate("select_lang") ?? "Select Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const Divider(),
          _buildLanguageOption("English", "en", langProv.appLocale.languageCode == "en", langProv),
          _buildLanguageOption("Sesotho", "st", langProv.appLocale.languageCode == "st", langProv),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code, bool isSelected, LanguageProvider langProv) {
    return ListTile(
      leading: Icon(Icons.language, color: isSelected ? primaryGreen : Colors.grey),
      title: Text(label, style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: primaryGreen) : null,
      onTap: () async {
        Navigator.pop(context);
        await langProv.changeLanguage(Locale(code));
      },
    );
  }

  Future<void> _contactSupport() async {
    final Uri telUri = Uri(scheme: 'tel', path: '+26658575277'); 
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  void _shareApp() {
    Share.share('Protect your vegetables with FarmAid Lesotho!', subject: 'Check out FarmAid Lesotho');
  }

  void _showTerms() {
    final appLoc = AppLocalizations.of(context);
    _showInfoModal(
      appLoc?.translate("terms_cond") ?? "Terms",
      "1. AI Accuracy: Supportive guide for Vegetables only.\n\n2. Data: Results saved in Neon DB."
    );
  }

  void _showFAQ() {
    final appLoc = AppLocalizations.of(context);
    _showInfoModal(
      appLoc?.translate("help_faq") ?? "Help",
      "• Vegetables: Tomato, Cabbage, Pepper, Onion, Potato."
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  void _showInfoModal(String title, String content) {
    final appLoc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen)),
              const Divider(height: 30),
              Text(content, style: TextStyle(fontSize: 16, height: 1.6, color: subTextColor)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context),
                child: Text(appLoc?.translate("i_understand") ?? "I UNDERSTAND", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final langProv = Provider.of<LanguageProvider>(context);
    final appLoc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(appLoc?.translate("settings_title") ?? 'Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileHeader(),
            const SizedBox(height: 25),
            
            _buildSettingsCard([
              _buildListTile(Icons.person_outline, appLoc?.translate("profile_details") ?? "Profile details", onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                if (result == true) setState(() {}); 
              }),
              _buildListTile(Icons.lock_outline, appLoc?.translate("password") ?? "Password", onTap: _showPasswordDialog),
              _buildSwitchTile(Icons.dark_mode_outlined, appLoc?.translate("dark_mode") ?? "Dark Mode", themeProv.isDarkMode, (val) => themeProv.toggleTheme(val)),
            ]),

            const SizedBox(height: 20),

            _buildSettingsCard([
              _buildListTile(
                Icons.translate, 
                appLoc?.translate("lang_pref") ?? "Language Preference", 
                subtitle: langProv.appLocale.languageCode == "en" ? "English" : "Sesotho",
                onTap: _showLanguagePicker,
              ),
              _buildListTile(
                Icons.cloud_sync_outlined, 
                appLoc?.translate("sync_neon") ?? "Sync", 
                subtitle: _isSyncing ? appLoc?.translate("syncing") : (_syncSuccess ? appLoc?.translate("synced") : appLoc?.translate("sync_desc")),
                onTap: _isSyncing ? null : _handleNeonSync,
                trailing: _isSyncing 
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : (_syncSuccess ? const Icon(Icons.check_circle, color: primaryGreen, size: 20) : null),
              ),
            ]),

            const SizedBox(height: 20),

            _buildSettingsCard([
              _buildListTile(Icons.description_outlined, appLoc?.translate("terms_cond") ?? "Terms", onTap: _showTerms),
              _buildListTile(Icons.contact_support, appLoc?.translate("contact_support") ?? "Contact", onTap: _contactSupport), 
              _buildListTile(Icons.help_outline, appLoc?.translate("help_faq") ?? "FAQ", onTap: _showFAQ),
              _buildListTile(Icons.share_outlined, appLoc?.translate("share_app") ?? "Share", onTap: _shareApp),
            ]),

            const SizedBox(height: 20),

            _buildSettingsCard([
              _buildListTile(Icons.logout, appLoc?.translate("logout") ?? "Logout", textColor: Colors.red, onTap: _handleLogout),
              _buildListTile(Icons.delete_sweep_outlined, appLoc?.translate("clear_cache") ?? "Clear Cache", textColor: Colors.red, subtitle: appLoc?.translate("clear_cache_desc"), onTap: () async {
                _handleClearCache();
              }),
            ]),
            
            const SizedBox(height: 40),
            Text("FarmAid Lesotho v1.0.2", style: TextStyle(color: subTextColor, fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final appLoc = AppLocalizations.of(context);
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getCurrentUser(),
      builder: (context, snapshot) {
        final name = snapshot.data?['full_name'] ?? "Farmer Name";
        final district = snapshot.data?['district'] ?? "Maseru";
        final districtLabel = appLoc?.translate("district_suffix") ?? "District, LS";

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.person, size: 40, color: primaryGreen)),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  Text("$district $districtLabel", style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.verified_user, size: 20, color: primaryGreen),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSettingsCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
    child: Column(children: children),
  );

  Widget _buildListTile(IconData icon, String title, {String? subtitle, Color? textColor, VoidCallback? onTap, Widget? trailing}) => ListTile(
    leading: Icon(icon, color: textColor ?? primaryGreen),
    title: Text(title, style: TextStyle(color: textColor ?? this.textColor, fontWeight: FontWeight.w500, fontSize: 15)),
    subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
    trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    onTap: onTap,
  );

  Widget _buildSwitchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
    secondary: Icon(icon, color: primaryGreen),
    title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15)),
    value: value,
    onChanged: onChanged,
    activeColor: primaryGreen,
  );
}