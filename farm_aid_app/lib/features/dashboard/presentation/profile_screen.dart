// import 'package:flutter/material.dart';
// import '../../../services/auth_service.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final AuthService _auth = AuthService();
  
//   // State variables
//   bool _isLoading = false;
//   bool _isFetching = true;

//   // Controllers
//   late TextEditingController _nameController;
//   String _selectedDistrict = "Maseru";

//   // Lesotho Districts List for Disease Mapping
//   final List<String> _districts = [
//     "Maseru", "Berea", "Leribe", "Butha-Buthe", "Mokhotlong", 
//     "Thaba-Tseka", "Qacha's Nek", "Quthing", "Mohale's Hoek", "Mafeteng"
//   ];

//   static const Color primaryGreen = Color(0xFF2E7D32);

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController();
//     _loadFarmerData();
//   }

//   // Load existing data from AuthService/Database
//   Future<void> _loadFarmerData() async {
//     try {
//       // Logic to fetch current profile from Neon DB via Django
//       final userData = await _auth.getCurrentUser(); 
//       if (userData != null) {
//         setState(() {
//           _nameController.text = userData['full_name'] ?? "";
//           if (_districts.contains(userData['district'])) {
//             _selectedDistrict = userData['district'];
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading profile: $e");
//     } finally {
//       setState(() => _isFetching = false);
//     }
//   }

//   // Save updated data to Neon Database
//   Future<void> _saveProfile() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
      
//       try {
//         // Send to Django API to update Neon DB
//         bool success = await _auth.updateProfile(
//           fullName: _nameController.text.trim(),
//           district: _selectedDistrict,
//         );

//         if (success && mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Profile Updated in Neon DB"),
//               backgroundColor: primaryGreen,
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//           Navigator.pop(context, true); // Return true to refresh Settings header
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Update failed. Check connection.")),
//         );
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
//       appBar: AppBar(
//         title: Text(
//           "Edit Profile", 
//           style: TextStyle(
//             color: isDark ? Colors.white : Colors.black, 
//             fontWeight: FontWeight.bold
//           )
//         ),
//         backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
//       ),
//       body: _isFetching 
//         ? const Center(child: CircularProgressIndicator(color: primaryGreen))
//         : SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   _buildAvatarPicker(isDark),
//                   const SizedBox(height: 40),
                  
//                   // Full Name Input
//                   TextFormField(
//                     controller: _nameController,
//                     style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                     decoration: InputDecoration(
//                       labelText: "Farmer Full Name",
//                       labelStyle: TextStyle(color: isDark ? Colors.greenAccent : primaryGreen),
//                       hintText: "Enter your name",
//                       hintStyle: const TextStyle(color: Colors.grey),
//                       filled: true,
//                       fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade400),
//                       ),
//                       prefixIcon: const Icon(Icons.person, color: primaryGreen),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: primaryGreen, width: 2),
//                       ),
//                     ),
//                     validator: (val) => val!.isEmpty ? "Name is required" : null,
//                   ),
                  
//                   const SizedBox(height: 25),

//                   // District Dropdown (Crucial for regional alerts)
//                   DropdownButtonFormField<String>(
//                     value: _selectedDistrict,
//                     dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//                     style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                     decoration: InputDecoration(
//                       labelText: "District (Lesotho)",
//                       labelStyle: TextStyle(color: isDark ? Colors.greenAccent : primaryGreen),
//                       helperText: "Used for regional vegetable disease alerts",
//                       helperStyle: const TextStyle(color: Colors.grey),
//                       filled: true,
//                       fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade400),
//                       ),
//                       prefixIcon: const Icon(Icons.location_on, color: primaryGreen),
//                     ),
//                     items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
//                     onChanged: (val) => setState(() => _selectedDistrict = val!),
//                   ),

//                   const SizedBox(height: 50),

//                   // Save Button with Loading State
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryGreen,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 2,
//                       ),
//                       onPressed: _isLoading ? null : _saveProfile,
//                       child: _isLoading 
//                         ? const SizedBox(
//                             height: 20, 
//                             width: 20, 
//                             child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
//                           )
//                         : const Text(
//                             "SAVE CHANGES", 
//                             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
//                           ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );
//   }

//   Widget _buildAvatarPicker(bool isDark) {
//     return Center(
//       child: Stack(
//         children: [
//           CircleAvatar(
//             radius: 65,
//             backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F8E9),
//             child: Icon(Icons.person, size: 85, color: isDark ? Colors.greenAccent : primaryGreen),
//           ),
//           Positioned(
//             bottom: 5,
//             right: 5,
//             child: GestureDetector(
//               onTap: () {
//                 // Future: Implement image_picker for Supabase upload
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
//                 child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../core/app_localizations.dart'; // IMPORTED

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  
  bool _isLoading = false;
  bool _isFetching = true;

  late TextEditingController _nameController;
  String _selectedDistrict = "Maseru";

  final List<String> _districts = [
    "Maseru", "Berea", "Leribe", "Butha-Buthe", "Mokhotlong", 
    "Thaba-Tseka", "Qacha's Nek", "Quthing", "Mohale's Hoek", "Mafeteng"
  ];

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    try {
      final userData = await _auth.getCurrentUser(); 
      if (userData != null) {
        setState(() {
          _nameController.text = userData['full_name'] ?? "";
          if (_districts.contains(userData['district'])) {
            _selectedDistrict = userData['district'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _saveProfile() async {
    final appLoc = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        bool success = await _auth.updateProfile(
          fullName: _nameController.text.trim(),
          district: _selectedDistrict,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appLoc?.translate("profile_updated_msg") ?? "Profile Updated"),
              backgroundColor: primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); 
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLoc?.translate("update_failed_msg") ?? "Update failed")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final appLoc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          appLoc?.translate("edit_profile") ?? "Edit Profile", 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: _isFetching 
        ? const Center(child: CircularProgressIndicator(color: primaryGreen))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildAvatarPicker(isDark),
                  const SizedBox(height: 40),
                  
                  // Full Name Input
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: appLoc?.translate("farmer_name_label") ?? "Farmer Full Name",
                      labelStyle: TextStyle(color: isDark ? Colors.greenAccent : primaryGreen),
                      hintText: appLoc?.translate("enter_name_hint") ?? "Enter your name",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade400),
                      ),
                      prefixIcon: const Icon(Icons.person, color: primaryGreen),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryGreen, width: 2),
                      ),
                    ),
                    validator: (val) => val!.isEmpty ? (appLoc?.translate("name_required") ?? "Required") : null,
                  ),
                  
                  const SizedBox(height: 25),

                  // District Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: appLoc?.translate("district_label") ?? "District (Lesotho)",
                      labelStyle: TextStyle(color: isDark ? Colors.greenAccent : primaryGreen),
                      helperText: appLoc?.translate("district_helper") ?? "Used for regional alerts",
                      helperStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade400),
                      ),
                      prefixIcon: const Icon(Icons.location_on, color: primaryGreen),
                    ),
                    items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) => setState(() => _selectedDistrict = val!),
                  ),

                  const SizedBox(height: 50),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading 
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : Text(
                            (appLoc?.translate("save_changes") ?? "SAVE CHANGES").toUpperCase(), 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAvatarPicker(bool isDark) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F8E9),
            child: Icon(Icons.person, size: 85, color: isDark ? Colors.greenAccent : primaryGreen),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                // Future implementation for image_picker
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}