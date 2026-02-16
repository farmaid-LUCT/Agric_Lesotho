// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'dart:typed_data'; // Added for Uint8List
// // import '../../../services/auth_service.dart';
// // import '../../../core/constants.dart'; // Import constants for the URL

// // class CropTypeScreen extends StatefulWidget {
// //   // Added pendingImage to receive the scan from HomeDashboard
// //   final Uint8List? pendingImage; 

// //   const CropTypeScreen({super.key, this.pendingImage});

// //   @override
// //   State<CropTypeScreen> createState() => _CropTypeScreenState();
// // }

// // class _CropTypeScreenState extends State<CropTypeScreen> {
// //   final AuthService _auth = AuthService();
// //   bool _isLoading = false;

// //   // Form State
// //   String? selectedCrop; 
// //   String? selectedSoil;
// //   String? selectedDistrict;
// //   DateTime? plantingDate;

// //   final List<Map<String, String>> vegetableTypes = [
// //     {'name': 'Cabbage', 'icon': '🥬'},
// //     {'name': 'Tomato', 'icon': '🍅'},
// //     {'name': 'Potato', 'icon': '🥔'},
// //     {'name': 'Onion', 'icon': '🧅'},
// //     {'name': 'Spinach', 'icon': '🌿'},
// //     {'name': 'Swiss Chard', 'icon': '🥬'},
// //     {'name': 'Green Pepper', 'icon': '🫑'},
// //     {'name': 'Carrot', 'icon': '🥕'},
// //     {'name': 'Beetroot', 'icon': '🟣'},
// //     {'name': 'Pumpkin', 'icon': '🎃'},
// //     {'name': 'Green Beans', 'icon': '🫘'},
// //     {'name': 'Broccoli', 'icon': '🥦'},
// //     {'name': 'Cauliflower', 'icon': '🥦'},
// //   ];

// //   final List<String> soilTypes = [
// //     'Loamy (Rich)', 
// //     'Sandy', 
// //     'Clayey', 
// //     'Duplex (Lesotho Special)'
// //   ];

// //   final List<String> districts = [
// //     'Maseru', 'Leribe', 'Berea', 'Mafeteng', 'Mohale\'s Hoek', 
// //     'Quthing', 'Qacha\'s Nek', 'Mokhotlong', 'Butha-Buthe', 'Thaba-Tseka'
// //   ];

// //   Future<void> _saveProfile() async {
// //     if (selectedCrop == null || selectedSoil == null || plantingDate == null || selectedDistrict == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Please complete all details"), backgroundColor: Colors.orange),
// //       );
// //       return;
// //     }

// //     setState(() => _isLoading = true);

// //     try {
// //       final token = await _auth.getToken();
      
// //       final Map<String, dynamic> profileData = {
// //         "VegetableType": selectedCrop,
// //         "SoilEnvironment": selectedSoil,
// //         "FarmLocation": selectedDistrict,
// //         "PlantingDate": DateFormat('yyyy-MM-dd').format(plantingDate!),
// //         "IsActive": true
// //       };

// //       // Using AppConstants for the URL to maintain consistency
// //       final response = await http.post(
// //         Uri.parse("${AppConstants.apiBaseUrl}/crop-profiles/"),
// //         headers: {
// //           "Content-Type": "application/json",
// //           "Authorization": "Token $token",
// //         },
// //         body: jsonEncode(profileData),
// //       );

// //       if (response.statusCode == 201 || response.statusCode == 200) {
// //         _showSuccessDialog();
// //       } else {
// //         debugPrint("Response Error: ${response.body}");
// //         throw Exception("Server Error: ${response.statusCode}");
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red),
// //       );
// //     } finally {
// //       setState(() => _isLoading = false);
// //     }
// //   }

// //   void _showSuccessDialog() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => AlertDialog(
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //         icon: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 50),
// //         title: const Text("Profile Saved"),
// //         content: Text("Your $selectedCrop profile is ready. We will now analyze your leaf image for personalized advice."),
// //         actions: [
// //           Center(
// //             child: TextButton(
// //               onPressed: () {
// //                 Navigator.pop(context); // Close dialog
// //                 // IMPORTANT: Pass 'true' back to HomeDashboard to start the AI analysis
// //                 Navigator.pop(context, true); 
// //               }, 
// //               child: const Text("Start Analysis", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
// //             ),
// //           )
// //         ],
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF8FAF8),
// //       appBar: AppBar(
// //         title: const Text("Vegetable Setup", 
// //           style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         iconTheme: const IconThemeData(color: Colors.green),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(24),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Visual feedback if we are in the middle of a scan
// //             if (widget.pendingImage != null)
// //               Container(
// //                 margin: const EdgeInsets.only(bottom: 20),
// //                 padding: const EdgeInsets.all(12),
// //                 decoration: BoxDecoration(
// //                   color: Colors.green.shade50,
// //                   borderRadius: BorderRadius.circular(12),
// //                   border: Border.all(color: Colors.green.shade200)
// //                 ),
// //                 child: const Row(
// //                   children: [
// //                     Icon(Icons.auto_awesome, color: Colors.green),
// //                     SizedBox(width: 10),
// //                     Expanded(child: Text("Almost there! Complete your profile to get personalized AI tips for your scan.", 
// //                       style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600))),
// //                   ],
// //                 ),
// //               ),

// //             const Text("Personalize your Vegetable Expert", 
// //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
// //             const SizedBox(height: 10),
// //             const Text("Our AI will use these details to provide rule-based recommendations specific to your farm.",
// //               style: TextStyle(fontSize: 14, color: Colors.black54)),
            
// //             const SizedBox(height: 35),
// //             _sectionTitle("1. Vegetable Type"),
// //             const SizedBox(height: 12),
// //             _buildVegetableDropdown(),

// //             const SizedBox(height: 25),
// //             _sectionTitle("2. Soil Environment"),
// //             const SizedBox(height: 12),
// //             _buildSimpleDropdown(
// //               hint: "Select Soil Type", 
// //               value: selectedSoil, 
// //               items: soilTypes, 
// //               icon: Icons.layers_outlined,
// //               onChanged: (val) => setState(() => selectedSoil = val)
// //             ),

// //             const SizedBox(height: 25),
// //             _sectionTitle("3. Farm Location"),
// //             const SizedBox(height: 12),
// //             _buildSimpleDropdown(
// //               hint: "Select District", 
// //               value: selectedDistrict, 
// //               items: districts, 
// //               icon: Icons.location_on_outlined,
// //               onChanged: (val) => setState(() => selectedDistrict = val)
// //             ),

// //             const SizedBox(height: 25),
// //             _sectionTitle("4. Planting Date"),
// //             const SizedBox(height: 12),
// //             _buildDatePicker(),

// //             const SizedBox(height: 50),
// //             SizedBox(
// //               width: double.infinity,
// //               height: 60,
// //               child: ElevatedButton(
// //                 onPressed: _isLoading ? null : _saveProfile,
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: const Color(0xFF1B5E20),
// //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
// //                 ),
// //                 child: _isLoading 
// //                   ? const CircularProgressIndicator(color: Colors.white)
// //                   : const Text("Save & Get Recommendations", 
// //                       style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
// //               ),
// //             ),
// //             const SizedBox(height: 40),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _sectionTitle(String title) {
// //     return Text(title, 
// //       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 0.5));
// //   }

// //   Widget _buildDatePicker() {
// //     return InkWell(
// //       onTap: () async {
// //         DateTime? picked = await showDatePicker(
// //           context: context, 
// //           initialDate: DateTime.now(),
// //           firstDate: DateTime(2025), 
// //           lastDate: DateTime.now(),
// //         );
// //         if (picked != null) setState(() => plantingDate = picked);
// //       },
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //         decoration: BoxDecoration(
// //           color: Colors.white, 
// //           borderRadius: BorderRadius.circular(15), 
// //           border: Border.all(color: Colors.grey.shade200, width: 1.5)
// //         ),
// //         child: Row(
// //           children: [
// //             const Icon(Icons.calendar_month_outlined, color: Colors.green, size: 22),
// //             const SizedBox(width: 12),
// //             Text(
// //               plantingDate == null 
// //                 ? "When did you plant?" 
// //                 : DateFormat('dd MMMM yyyy').format(plantingDate!),
// //               style: TextStyle(
// //                 fontSize: 15, 
// //                 color: plantingDate == null ? Colors.grey.shade600 : Colors.black87
// //               ),
// //             ),
// //             const Spacer(),
// //             const Icon(Icons.arrow_drop_down, color: Colors.grey),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildVegetableDropdown() {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 16),
// //       decoration: BoxDecoration(
// //         color: Colors.white, 
// //         borderRadius: BorderRadius.circular(15), 
// //         border: Border.all(color: Colors.grey.shade200, width: 1.5)
// //       ),
// //       child: DropdownButtonHideUnderline(
// //         child: DropdownButton<String>(
// //           value: selectedCrop,
// //           hint: const Text("Select Vegetable", style: TextStyle(fontSize: 15, color: Colors.grey)),
// //           isExpanded: true,
// //           items: vegetableTypes.map((item) => DropdownMenuItem(
// //             value: item['name'], 
// //             child: Row(
// //               children: [
// //                 Text(item['icon']!, style: const TextStyle(fontSize: 22)),
// //                 const SizedBox(width: 12),
// //                 Text(item['name']!, style: const TextStyle(fontSize: 15)),
// //               ],
// //             )
// //           )).toList(),
// //           onChanged: (val) => setState(() => selectedCrop = val),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSimpleDropdown({
// //     required String hint, 
// //     required String? value, 
// //     required List<String> items, 
// //     required IconData icon,
// //     required Function(String?) onChanged
// //   }) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 16),
// //       decoration: BoxDecoration(
// //         color: Colors.white, 
// //         borderRadius: BorderRadius.circular(15), 
// //         border: Border.all(color: Colors.grey.shade200, width: 1.5)
// //       ),
// //       child: DropdownButtonHideUnderline(
// //         child: DropdownButton<String>(
// //           value: value,
// //           hint: Text(hint, style: const TextStyle(fontSize: 15, color: Colors.grey)),
// //           isExpanded: true,
// //           items: items.map((e) => DropdownMenuItem(
// //             value: e, 
// //             child: Text(e, style: const TextStyle(fontSize: 15))
// //           )).toList(),
// //           onChanged: onChanged,
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:typed_data'; 
// import 'package:provider/provider.dart';
// import '../../../services/auth_service.dart';
// import '../../../core/constants.dart';
// import '../../../services/theme_provider.dart'; // ✅ Added for Dark Mode

// class CropTypeScreen extends StatefulWidget {
//   final Uint8List? pendingImage; 

//   const CropTypeScreen({super.key, this.pendingImage});

//   @override
//   State<CropTypeScreen> createState() => _CropTypeScreenState();
// }

// class _CropTypeScreenState extends State<CropTypeScreen> {
//   final AuthService _auth = AuthService();
//   bool _isLoading = false;

//   String? selectedCrop; 
//   String? selectedSoil;
//   String? selectedDistrict;
//   DateTime? plantingDate;

//   final List<Map<String, String>> vegetableTypes = [
//     {'name': 'Cabbage', 'icon': '🥬'},
//     {'name': 'Tomato', 'icon': '🍅'},
//     {'name': 'Potato', 'icon': '🥔'},
//     {'name': 'Onion', 'icon': '🧅'},
//     {'name': 'Spinach', 'icon': '🌿'},
//     {'name': 'Swiss Chard', 'icon': '🥬'},
//     {'name': 'Green Pepper', 'icon': '🫑'},
//     {'name': 'Carrot', 'icon': '🥕'},
//     {'name': 'Beetroot', 'icon': '🟣'},
//     {'name': 'Pumpkin', 'icon': '🎃'},
//     {'name': 'Green Beans', 'icon': '🫘'},
//     {'name': 'Broccoli', 'icon': '🥦'},
//     {'name': 'Cauliflower', 'icon': '🥦'},
//   ];

//   final List<String> soilTypes = ['Loamy (Rich)', 'Sandy', 'Clayey', 'Duplex (Lesotho Special)'];

//   final List<String> districts = [
//     'Maseru', 'Leribe', 'Berea', 'Mafeteng', 'Mohale\'s Hoek', 
//     'Quthing', 'Qacha\'s Nek', 'Mokhotlong', 'Butha-Buthe', 'Thaba-Tseka'
//   ];

//   Future<void> _saveProfile() async {
//     if (selectedCrop == null || selectedSoil == null || plantingDate == null || selectedDistrict == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please complete all details"), backgroundColor: Colors.orange),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final token = await _auth.getToken();
//       final Map<String, dynamic> profileData = {
//         "VegetableType": selectedCrop,
//         "SoilEnvironment": selectedSoil,
//         "FarmLocation": selectedDistrict,
//         "PlantingDate": DateFormat('yyyy-MM-dd').format(plantingDate!),
//         "IsActive": true
//       };

//       final response = await http.post(
//         Uri.parse("${AppConstants.apiBaseUrl}/crop-profiles/"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Token $token",
//         },
//         body: jsonEncode(profileData),
//       );

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         _showSuccessDialog();
//       } else {
//         throw Exception("Server Error: ${response.statusCode}");
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showSuccessDialog() {
//     final bool isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         icon: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 50),
//         title: Text("Profile Saved", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
//         content: Text(
//           "Your $selectedCrop profile is ready. We will now analyze your leaf image for personalized advice.",
//           style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
//         ),
//         actions: [
//           Center(
//             child: TextButton(
//               onPressed: () {
//                 Navigator.pop(context); 
//                 Navigator.pop(context, true); 
//               }, 
//               child: const Text("Start Analysis", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: Text("Vegetable Setup", 
//           style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
//         backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
//         elevation: 0,
//         iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.green),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (widget.pendingImage != null)
//               Container(
//                 margin: const EdgeInsets.only(bottom: 20),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: isDark ? Colors.greenAccent.withOpacity(0.3) : Colors.green.shade200)
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.auto_awesome, color: isDark ? Colors.greenAccent : Colors.green),
//                     const SizedBox(width: 10),
//                     Expanded(child: Text("Almost there! Complete your profile to get personalized AI tips for your scan.", 
//                       style: TextStyle(fontSize: 13, color: isDark ? Colors.greenAccent : Colors.green, fontWeight: FontWeight.w600))),
//                   ],
//                 ),
//               ),

//             Text("Personalize your Vegetable Expert", 
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
//             const SizedBox(height: 10),
//             Text("Our AI will use these details to provide rule-based recommendations specific to your farm.",
//               style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54)),
            
//             const SizedBox(height: 35),
//             _sectionTitle("1. Vegetable Type", isDark),
//             const SizedBox(height: 12),
//             _buildVegetableDropdown(isDark),

//             const SizedBox(height: 25),
//             _sectionTitle("2. Soil Environment", isDark),
//             const SizedBox(height: 12),
//             _buildSimpleDropdown(
//               hint: "Select Soil Type", 
//               value: selectedSoil, 
//               items: soilTypes, 
//               icon: Icons.layers_outlined,
//               isDark: isDark,
//               onChanged: (val) => setState(() => selectedSoil = val)
//             ),

//             const SizedBox(height: 25),
//             _sectionTitle("3. Farm Location", isDark),
//             const SizedBox(height: 12),
//             _buildSimpleDropdown(
//               hint: "Select District", 
//               value: selectedDistrict, 
//               items: districts, 
//               icon: Icons.location_on_outlined,
//               isDark: isDark,
//               onChanged: (val) => setState(() => selectedDistrict = val)
//             ),

//             const SizedBox(height: 25),
//             _sectionTitle("4. Planting Date", isDark),
//             const SizedBox(height: 12),
//             _buildDatePicker(isDark),

//             const SizedBox(height: 50),
//             SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _saveProfile,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF2E7D32),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//                 ),
//                 child: _isLoading 
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text("Save & Get Recommendations", 
//                       style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//               ),
//             ),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String title, bool isDark) {
//     return Text(title, 
//       style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : Colors.green, letterSpacing: 0.5));
//   }

//   Widget _buildDatePicker(bool isDark) {
//     return InkWell(
//       onTap: () async {
//         DateTime? picked = await showDatePicker(
//           context: context, 
//           initialDate: DateTime.now(),
//           firstDate: DateTime(2025), 
//           lastDate: DateTime.now(),
//           builder: (context, child) {
//             return Theme(
//               data: isDark ? ThemeData.dark().copyWith(
//                 colorScheme: const ColorScheme.dark(primary: Colors.green, onPrimary: Colors.white, surface: Color(0xFF1E1E1E), onSurface: Colors.white),
//               ) : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.green)),
//               child: child!,
//             );
//           },
//         );
//         if (picked != null) setState(() => plantingDate = picked);
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         decoration: BoxDecoration(
//           color: isDark ? Colors.white10 : Colors.white, 
//           borderRadius: BorderRadius.circular(15), 
//           border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200, width: 1.5)
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.calendar_month_outlined, color: Colors.green, size: 22),
//             const SizedBox(width: 12),
//             Text(
//               plantingDate == null 
//                 ? "When did you plant?" 
//                 : DateFormat('dd MMMM yyyy').format(plantingDate!),
//               style: TextStyle(
//                 fontSize: 15, 
//                 color: plantingDate == null ? (isDark ? Colors.white38 : Colors.grey.shade600) : (isDark ? Colors.white : Colors.black87)
//               ),
//             ),
//             const Spacer(),
//             const Icon(Icons.arrow_drop_down, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVegetableDropdown(bool isDark) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.white10 : Colors.white, 
//         borderRadius: BorderRadius.circular(15), 
//         border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200, width: 1.5)
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//           value: selectedCrop,
//           hint: Text("Select Vegetable", style: TextStyle(fontSize: 15, color: isDark ? Colors.white38 : Colors.grey)),
//           isExpanded: true,
//           items: vegetableTypes.map((item) => DropdownMenuItem(
//             value: item['name'], 
//             child: Row(
//               children: [
//                 Text(item['icon']!, style: const TextStyle(fontSize: 22)),
//                 const SizedBox(width: 12),
//                 Text(item['name']!, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
//               ],
//             )
//           )).toList(),
//           onChanged: (val) => setState(() => selectedCrop = val),
//         ),
//       ),
//     );
//   }

//   Widget _buildSimpleDropdown({
//     required String hint, 
//     required String? value, 
//     required List<String> items, 
//     required IconData icon,
//     required bool isDark,
//     required Function(String?) onChanged
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.white10 : Colors.white, 
//         borderRadius: BorderRadius.circular(15), 
//         border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200, width: 1.5)
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//           value: value,
//           hint: Text(hint, style: TextStyle(fontSize: 15, color: isDark ? Colors.white38 : Colors.grey)),
//           isExpanded: true,
//           items: items.map((e) => DropdownMenuItem(
//             value: e, 
//             child: Text(e, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black))
//           )).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; 
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants.dart';
import '../../../services/theme_provider.dart';
import '../../../core/app_localizations.dart'; // ✅ Added for localization

class CropTypeScreen extends StatefulWidget {
  final Uint8List? pendingImage; 

  const CropTypeScreen({super.key, this.pendingImage});

  @override
  State<CropTypeScreen> createState() => _CropTypeScreenState();
}

class _CropTypeScreenState extends State<CropTypeScreen> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  String? selectedCrop; 
  String? selectedSoil;
  String? selectedDistrict;
  DateTime? plantingDate;

  final List<Map<String, String>> vegetableTypes = [
    {'name': 'Cabbage', 'icon': '🥬'},
    {'name': 'Tomato', 'icon': '🍅'},
    {'name': 'Potato', 'icon': '🥔'},
    {'name': 'Onion', 'icon': '🧅'},
    {'name': 'Spinach', 'icon': '🌿'},
    {'name': 'Swiss Chard', 'icon': '🥬'},
    {'name': 'Green Pepper', 'icon': '🫑'},
    {'name': 'Carrot', 'icon': '🥕'},
    {'name': 'Beetroot', 'icon': '🟣'},
    {'name': 'Pumpkin', 'icon': '🎃'},
    {'name': 'Green Beans', 'icon': '🫘'},
    {'name': 'Broccoli', 'icon': '🥦'},
    {'name': 'Cauliflower', 'icon': '🥦'},
  ];

  final List<String> soilTypes = ['Loamy (Rich)', 'Sandy', 'Clayey', 'Duplex (Lesotho Special)'];

  final List<String> districts = [
    'Maseru', 'Leribe', 'Berea', 'Mafeteng', 'Mohale\'s Hoek', 
    'Quthing', 'Qacha\'s Nek', 'Mokhotlong', 'Butha-Buthe', 'Thaba-Tseka'
  ];

  Future<void> _saveProfile() async {
    final appLoc = AppLocalizations.of(context);
    if (selectedCrop == null || selectedSoil == null || plantingDate == null || selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLoc?.translate("Please complete all details") ?? "Please complete all details"), 
          backgroundColor: Colors.orange
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _auth.getToken();
      final Map<String, dynamic> profileData = {
        "VegetableType": selectedCrop,
        "SoilEnvironment": selectedSoil,
        "FarmLocation": selectedDistrict,
        "PlantingDate": DateFormat('yyyy-MM-dd').format(plantingDate!),
        "IsActive": true
      };

      final response = await http.post(
        Uri.parse("${AppConstants.apiBaseUrl}/crop-profiles/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token $token",
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final bool isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final appLoc = AppLocalizations.of(context);
    
    String desc = appLoc?.translate("Your {} profile is ready. We will now analyze your leaf image for personalized advice.") 
        ?? "Your $selectedCrop profile is ready. We will now analyze your leaf image for personalized advice.";
    
    if (desc.contains("{}")) {
      desc = desc.replaceAll("{}", selectedCrop ?? "");
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 50),
        title: Text(appLoc?.translate("Profile Saved") ?? "Profile Saved", 
          style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(
          desc,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context, true); 
              }, 
              child: Text(appLoc?.translate("Start Analysis") ?? "Start Analysis", 
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final appLoc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(appLoc?.translate("Vegetable Setup") ?? "Vegetable Setup", 
          style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.green),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.pendingImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.greenAccent.withOpacity(0.3) : Colors.green.shade200)
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: isDark ? Colors.greenAccent : Colors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text(appLoc?.translate("Almost there! Complete your profile to get personalized AI tips for your scan.") 
                      ?? "Almost there! Complete your profile to get personalized AI tips for your scan.", 
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.greenAccent : Colors.green, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),

            Text(appLoc?.translate("Personalize your Vegetable Expert") ?? "Personalize your Vegetable Expert", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 10),
            Text(appLoc?.translate("Our AI will use these details to provide rule-based recommendations specific to your farm.") 
              ?? "Our AI will use these details to provide rule-based recommendations specific to your farm.",
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54)),
            
            const SizedBox(height: 35),
            _sectionTitle(appLoc?.translate("1. Vegetable Type") ?? "1. Vegetable Type", isDark),
            const SizedBox(height: 12),
            _buildVegetableDropdown(isDark, appLoc),

            const SizedBox(height: 25),
            _sectionTitle(appLoc?.translate("2. Soil Environment") ?? "2. Soil Environment", isDark),
            const SizedBox(height: 12),
            _buildSimpleDropdown(
              hint: appLoc?.translate("Select Soil Type") ?? "Select Soil Type", 
              value: selectedSoil, 
              items: soilTypes, 
              icon: Icons.layers_outlined,
              isDark: isDark,
              onChanged: (val) => setState(() => selectedSoil = val)
            ),

            const SizedBox(height: 25),
            _sectionTitle(appLoc?.translate("3. Farm Location") ?? "3. Farm Location", isDark),
            const SizedBox(height: 12),
            _buildSimpleDropdown(
              hint: appLoc?.translate("Select District") ?? "Select District", 
              value: selectedDistrict, 
              items: districts, 
              icon: Icons.location_on_outlined,
              isDark: isDark,
              onChanged: (val) => setState(() => selectedDistrict = val)
            ),

            const SizedBox(height: 25),
            _sectionTitle(appLoc?.translate("4. Planting Date") ?? "4. Planting Date", isDark),
            const SizedBox(height: 12),
            _buildDatePicker(isDark, appLoc),

            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(appLoc?.translate("Save & Get Recommendations") ?? "Save & Get Recommendations", 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(title, 
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : Colors.green, letterSpacing: 0.5));
  }

  Widget _buildDatePicker(bool isDark, AppLocalizations? appLoc) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context, 
          initialDate: DateTime.now(),
          firstDate: DateTime(2025), 
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: isDark ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(primary: Colors.green, onPrimary: Colors.white, surface: Color(0xFF1E1E1E), onSurface: Colors.white),
              ) : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.green)),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => plantingDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white, 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200, width: 1.5)
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Colors.green, size: 22),
            const SizedBox(width: 12),
            Text(
              plantingDate == null 
                ? (appLoc?.translate("When did you plant?") ?? "When did you plant?") 
                : DateFormat('dd MMMM yyyy').format(plantingDate!),
              style: TextStyle(
                fontSize: 15, 
                color: plantingDate == null ? (isDark ? Colors.white38 : Colors.grey.shade600) : (isDark ? Colors.white : Colors.black87)
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildVegetableDropdown(bool isDark, AppLocalizations? appLoc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200, width: 1.5)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          value: selectedCrop,
          hint: Text(appLoc?.translate("Select Vegetable") ?? "Select Vegetable", 
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white38 : Colors.grey)),
          isExpanded: true,
          items: vegetableTypes.map((item) => DropdownMenuItem(
            value: item['name'], 
            child: Row(
              children: [
                Text(item['icon']!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Text(item['name']!, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
              ],
            )
          )).toList(),
          onChanged: (val) => setState(() => selectedCrop = val),
        ),
      ),
    );
  }

  Widget _buildSimpleDropdown({
    required String hint, 
    required String? value, 
    required List<String> items, 
    required IconData icon,
    required bool isDark,
    required Function(String?) onChanged
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200, width: 1.5)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 15, color: isDark ? Colors.white38 : Colors.grey)),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(
            value: e, 
            child: Text(e, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black))
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}