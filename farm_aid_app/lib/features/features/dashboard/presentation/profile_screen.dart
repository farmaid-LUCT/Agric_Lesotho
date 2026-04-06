// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../services/auth_service.dart';
// import '../../../core/app_localizations.dart';
// import '../../../core/constants.dart';
// import '../../../core/widgets/responsive_auth_wrapper.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final _formKey  = GlobalKey<FormState>();
//   final _auth     = AuthService();
//   final _picker   = ImagePicker();
//   final _supabase = Supabase.instance.client;

//   static const Color primaryGreen = Color(0xFF2E7D32);

//   bool _isLoading        = false;
//   bool _isFetching       = true;
//   bool _isUploadingPhoto = false;

//   late TextEditingController _nameController;

//   String  _selectedDistrict   = 'Maseru';
//   String  _selectedExperience = 'beginner';
//   String? _profilePhotoUrl;

//   final List<String> _districts = [
//     'Maseru', 'Berea', 'Leribe', 'Butha-Buthe', 'Mokhotlong',
//     'Thaba-Tseka', "Qacha's Nek", 'Quthing', "Mohale's Hoek", 'Mafeteng',
//   ];

//   final Map<String, String> _experienceLabels = {
//     'beginner':     '🌱 Beginner',
//     'intermediate': '🌿 Intermediate',
//     'expert':       '🌾 Expert',
//   };

//   String t(String key) =>
//       AppLocalizations.of(context)?.translate(key) ?? key;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController();
//     _loadFarmerData();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadFarmerData() async {
//     try {
//       final data = await _auth.getCurrentUser();
//       if (data != null && mounted) {
//         setState(() {
//           _nameController.text = data['full_name'] ?? '';
//           _profilePhotoUrl     = data['profile_photo_url'];

//           if (_districts.contains(data['district'])) {
//             _selectedDistrict = data['district'];
//           }
//           if (_experienceLabels.containsKey(data['experience_level'])) {
//             _selectedExperience = data['experience_level'];
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading profile: $e');
//     } finally {
//       if (mounted) setState(() => _isFetching = false);
//     }
//   }

//   Future<void> _pickAndUploadPhoto() async {
//     try {
//       final XFile? picked = await _picker.pickImage(
//         source:       ImageSource.gallery,
//         maxWidth:     512,
//         maxHeight:    512,
//         imageQuality: 80,
//       );
//       if (picked == null) return;

//       setState(() => _isUploadingPhoto = true);

//       final bytes    = await picked.readAsBytes();
//       final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       final path     = 'profiles/$fileName';

//       await _supabase.storage.from('farmaid-media').uploadBinary(
//         path, bytes,
//         fileOptions:
//             const FileOptions(contentType: 'image/jpeg', upsert: true),
//       );

//       final publicUrl =
//           _supabase.storage.from('farmaid-media').getPublicUrl(path);

//       await _auth.updateProfile(profilePhotoUrl: publicUrl);

//       if (mounted) setState(() => _profilePhotoUrl = publicUrl);
//       _showSnack(t('photo_updated'), isError: false);
//     } catch (e) {
//       _showSnack('Photo upload failed: $e', isError: true);
//     } finally {
//       if (mounted) setState(() => _isUploadingPhoto = false);
//     }
//   }

//   Future<void> _saveProfile() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);

//     try {
//       final success = await _auth.updateProfile(
//         fullName:        _nameController.text.trim(),
//         district:        _selectedDistrict,
//         experienceLevel: _selectedExperience,
//       );

//       if (success && mounted) {
//         _showSnack(t('profile_updated_msg'), isError: false);
//         Navigator.pop(context, true);
//       } else {
//         _showSnack(t('update_failed_msg'), isError: true);
//       }
//     } catch (e) {
//       _showSnack('Error: $e', isError: true);
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void _showSnack(String msg, {required bool isError}) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content:         Text(msg),
//       backgroundColor: isError ? Colors.redAccent : primaryGreen,
//       behavior:        SnackBarBehavior.floating,
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final isWide = MediaQuery.of(context).size.width > 600;

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF121212) : Colors.white,
//       appBar: AppBar(
//         title: Text(
//           t('edit_profile'),
//           style: TextStyle(
//               color:      isDark ? Colors.white : Colors.black,
//               fontWeight: FontWeight.bold),
//         ),
//         backgroundColor:
//             isDark ? const Color(0xFF121212) : Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(
//             color: isDark ? Colors.white : Colors.black),
//       ),
//       body: _isFetching
//           ? const Center(
//               child: CircularProgressIndicator(color: primaryGreen))
//           : isWide
//               // ── DESKTOP: centered card ───────────────────────
//               ? ResponsiveAuthWrapper(
//                   maxWidth: 520,
//                   child: _buildFormContent(isDark),
//                 )
//               // ── MOBILE: full scroll ──────────────────────────
//               : SingleChildScrollView(
//                   padding: const EdgeInsets.all(24),
//                   child: _buildFormContent(isDark),
//                 ),
//     );
//   }

//   Widget _buildFormContent(bool isDark) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [

//           // Avatar
//           _buildAvatarSection(isDark),
//           const SizedBox(height: 36),

//           // Full Name
//           _buildLabel(t('farmer_name_label'), isDark),
//           const SizedBox(height: 8),
//           TextFormField(
//             controller: _nameController,
//             style: TextStyle(
//                 color: isDark ? Colors.white : Colors.black),
//             decoration: _inputDecoration(
//               hint:   t('enter_name_hint'),
//               icon:   Icons.person,
//               isDark: isDark,
//             ),
//             validator: (v) =>
//                 v!.isEmpty ? t('name_required') : null,
//           ),
//           const SizedBox(height: 20),

//           // District
//           _buildLabel(t('district_label'), isDark),
//           const SizedBox(height: 8),
//           DropdownButtonFormField<String>(
//             value:         _selectedDistrict,
//             dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//             style: TextStyle(
//                 color: isDark ? Colors.white : Colors.black),
//             decoration: _inputDecoration(
//               hint:       'Select district',
//               icon:       Icons.location_on,
//               isDark:     isDark,
//               helperText: t('district_helper'),
//             ),
//             items: _districts
//                 .map((d) =>
//                     DropdownMenuItem(value: d, child: Text(d)))
//                 .toList(),
//             onChanged: (v) =>
//                 setState(() => _selectedDistrict = v!),
//           ),
//           const SizedBox(height: 20),

//           // Experience Level
//           _buildLabel(t('experience_label'), isDark),
//           const SizedBox(height: 8),
//           Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isDark
//                     ? Colors.white12
//                     : Colors.grey.shade400,
//               ),
//             ),
//             child: Column(
//               children: _experienceLabels.entries.map((entry) {
//                 final selected = _selectedExperience == entry.key;
//                 return RadioListTile<String>(
//                   value:      entry.key,
//                   groupValue: _selectedExperience,
//                   title: Text(
//                     entry.value,
//                     style: TextStyle(
//                       color: isDark ? Colors.white : Colors.black87,
//                       fontWeight: selected
//                           ? FontWeight.bold
//                           : FontWeight.normal,
//                     ),
//                   ),
//                   subtitle: Text(
//                     _experienceSubtitle(entry.key),
//                     style: const TextStyle(
//                         fontSize: 11, color: Colors.grey),
//                   ),
//                   activeColor: primaryGreen,
//                   onChanged: (v) =>
//                       setState(() => _selectedExperience = v!),
//                 );
//               }).toList(),
//             ),
//           ),

//           const SizedBox(height: 40),

//           // Save Button
//           SizedBox(
//             width:  double.infinity,
//             height: 55,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryGreen,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//               onPressed: _isLoading ? null : _saveProfile,
//               child: _isLoading
//                   ? const SizedBox(
//                       height: 20,
//                       width:  20,
//                       child: CircularProgressIndicator(
//                           color: Colors.white, strokeWidth: 2))
//                   : Text(
//                       (t('save_changes')).toUpperCase(),
//                       style: const TextStyle(
//                           color:      Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize:   16),
//                     ),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildAvatarSection(bool isDark) {
//     return Center(
//       child: Stack(
//         children: [
//           CircleAvatar(
//             radius:          65,
//             backgroundColor: isDark
//                 ? const Color(0xFF1E1E1E)
//                 : const Color(0xFFF1F8E9),
//             backgroundImage: _profilePhotoUrl != null
//                 ? NetworkImage(_profilePhotoUrl!)
//                 : null,
//             child: _profilePhotoUrl == null
//                 ? Icon(Icons.person,
//                     size:  85,
//                     color: isDark ? Colors.greenAccent : primaryGreen)
//                 : null,
//           ),
//           Positioned(
//             bottom: 5,
//             right:  5,
//             child: GestureDetector(
//               onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: const BoxDecoration(
//                     color: primaryGreen, shape: BoxShape.circle),
//                 child: _isUploadingPhoto
//                     ? const SizedBox(
//                         width:  18,
//                         height: 18,
//                         child: CircularProgressIndicator(
//                             color: Colors.white, strokeWidth: 2))
//                     : const Icon(Icons.camera_alt,
//                         color: Colors.white, size: 20),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLabel(String text, bool isDark) => Text(
//         text,
//         style: TextStyle(
//           fontSize:   13,
//           fontWeight: FontWeight.w600,
//           color: isDark ? Colors.white70 : Colors.black54,
//           letterSpacing: 0.3,
//         ),
//       );

//   InputDecoration _inputDecoration({
//     required String  hint,
//     required IconData icon,
//     required bool    isDark,
//     String?          helperText,
//   }) =>
//       InputDecoration(
//         hintText:    hint,
//         hintStyle:   const TextStyle(color: Colors.grey),
//         helperText:  helperText,
//         helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
//         filled:      true,
//         fillColor: isDark
//             ? const Color(0xFF1E1E1E)
//             : Colors.transparent,
//         prefixIcon: Icon(icon, color: primaryGreen),
//         border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12)),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//               color: isDark ? Colors.white12 : Colors.grey.shade400),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide:
//               const BorderSide(color: primaryGreen, width: 2),
//         ),
//       );

//   String _experienceSubtitle(String level) {
//     switch (level) {
//       case 'beginner':     return 'Plain-language advice, step-by-step guidance';
//       case 'intermediate': return 'Balanced advice with some technical detail';
//       case 'expert':       return 'Full technical protocols and agronomic data';
//       default:             return '';
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../core/app_localizations.dart';
import '../../../core/constants.dart';
import '../../../core/widgets/responsive_auth_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _auth     = AuthService();
  final _picker   = ImagePicker();
  final _supabase = Supabase.instance.client;

  static const _green  = Color(0xFF1B5E20);
  static const _accent = Color(0xFF2E7D32);

  bool _isLoading        = false;
  bool _isFetching       = true;
  bool _isUploadingPhoto = false;
  bool _saved            = false;

  late TextEditingController _nameController;

  String  _selectedDistrict   = 'Maseru';
  String  _selectedExperience = 'beginner';
  String? _profilePhotoUrl;

  // Animated checkmark after save
  late AnimationController _checkCtrl;
  late Animation<double>   _checkAnim;

  final List<String> _districts = [
    'Maseru', 'Berea', 'Leribe', 'Butha-Buthe', 'Mokhotlong',
    'Thaba-Tseka', "Qacha's Nek", 'Quthing', "Mohale's Hoek", 'Mafeteng',
  ];

  final _experienceLevels = [
    {
      'value': 'beginner',
      'emoji': '🌱',
      'label': 'Beginner',
      'desc':  'Plain-language advice, step-by-step guidance',
    },
    {
      'value': 'intermediate',
      'emoji': '🌿',
      'label': 'Intermediate',
      'desc':  'Balanced advice with some technical detail',
    },
    {
      'value': 'expert',
      'emoji': '🌾',
      'label': 'Expert',
      'desc':  'Full technical protocols and agronomic data',
    },
  ];

  String t(String key) =>
      AppLocalizations.of(context)?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _checkCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600));
    _checkAnim = CurvedAnimation(
        parent: _checkCtrl, curve: Curves.elasticOut);
    _loadFarmerData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFarmerData() async {
    try {
      final data = await _auth.getCurrentUser();
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _profilePhotoUrl     = data['profile_photo_url'];
          if (_districts.contains(data['district'])) {
            _selectedDistrict = data['district'];
          }
          final exp = data['experience_level'] ?? 'beginner';
          if (_experienceLevels.any((e) => e['value'] == exp)) {
            _selectedExperience = exp;
          }
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source:       ImageSource.gallery,
        maxWidth:     512,
        maxHeight:    512,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() => _isUploadingPhoto = true);

      final bytes    = await picked.readAsBytes();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path     = 'profiles/$fileName';

      await _supabase.storage.from('farmaid-media').uploadBinary(
        path, bytes,
        fileOptions: const FileOptions(
            contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl =
          _supabase.storage.from('farmaid-media').getPublicUrl(path);
      await _auth.updateProfile(profilePhotoUrl: publicUrl);

      if (mounted) {
        setState(() => _profilePhotoUrl = publicUrl);
        _showSnack(t('photo_updated'), isError: false);
      }
    } catch (e) {
      _showSnack('Photo upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final success = await _auth.updateProfile(
        fullName:        _nameController.text.trim(),
        district:        _selectedDistrict,
        experienceLevel: _selectedExperience,
      );

      if (success && mounted) {
        setState(() { _saved = true; _isLoading = false; });
        _checkCtrl.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnack(t('update_failed_msg'), isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: isError ? Colors.redAccent : _accent,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF0FBF0),
      appBar: AppBar(
        title: Text(
          t('edit_profile'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black87),
        // Save shortcut in AppBar
        actions: [
          if (!_isFetching)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: (_isLoading || _saved) ? null : _saveProfile,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: (_isLoading || _saved)
                        ? Colors.grey
                        : _accent,
                    fontWeight: FontWeight.bold,
                    fontSize:   15,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isFetching
          ? const Center(
              child: CircularProgressIndicator(color: _accent))
          : isWide
              ? ResponsiveAuthWrapper(
                  maxWidth: 520,
                  child:    _buildContent(isDark),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child:   _buildContent(isDark),
                ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Avatar ────────────────────────────────────────
          _buildAvatar(isDark),
          const SizedBox(height: 28),

          // ── Personal info card ────────────────────────────
          _sectionLabel('Personal Information', isDark),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _fieldTile(
              ctrl:      _nameController,
              label:     t('farmer_name_label'),
              hint:      t('enter_name_hint'),
              icon:      Icons.person_outline_rounded,
              isDark:    isDark,
              validator: (v) => v!.trim().isEmpty
                  ? t('name_required') : null,
            ),
          ]),

          const SizedBox(height: 20),

          // ── Farm details card ─────────────────────────────
          _sectionLabel('Farm Details', isDark),
          const SizedBox(height: 8),
          _buildCard(isDark, [
            _dropdownTile(isDark),
          ]),

          const SizedBox(height: 20),

          // ── Experience level ──────────────────────────────
          _sectionLabel('Experience Level', isDark),
          const SizedBox(height: 8),
          ..._experienceLevels.map((e) =>
              _experienceTile(e, isDark)),

          const SizedBox(height: 28),

          // ── Save button ───────────────────────────────────
          _buildSaveButton(isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── AVATAR ─────────────────────────────────────────────────────
  Widget _buildAvatar(bool isDark) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Photo ring
          Container(
            width: 104, height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFE8F5E9),
              border: Border.all(
                  color: _accent.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color:      _accent.withOpacity(0.15),
                  blurRadius: 16,
                  offset:     const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: _profilePhotoUrl != null
                  ? Image.network(_profilePhotoUrl!, fit: BoxFit.cover)
                  : Icon(Icons.person_rounded,
                      size:  58,
                      color: isDark ? Colors.greenAccent : _accent),
            ),
          ),
          // Camera badge
          Positioned(
            bottom: 2,
            right:  -2,
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF121212)
                        : const Color(0xFFF0FBF0),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:      _accent.withOpacity(0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: _isUploadingPhoto
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
              ),
            ),
          ),
          // Success overlay
          if (_saved)
            ScaleTransition(
              scale: _checkAnim,
              child: Container(
                width: 104, height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.92),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 50),
              ),
            ),
        ],
      ),
    );
  }

  // ── SECTION LABEL ──────────────────────────────────────────────
  Widget _sectionLabel(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      );

  // ── SETTINGS-STYLE CARD ────────────────────────────────────────
  Widget _buildCard(bool isDark, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      );

  // ── TEXT FIELD TILE (borderless inside card) ───────────────────
  Widget _fieldTile({
    required TextEditingController ctrl,
    required String    label,
    required String    hint,
    required IconData  icon,
    required bool      isDark,
    String? Function(String?)? validator,
    TextInputType?     keyboard,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        child: TextFormField(
          controller:   ctrl,
          keyboardType: keyboard,
          validator:    validator,
          style: TextStyle(
              color:    isDark ? Colors.white : Colors.black87,
              fontSize: 15),
          decoration: InputDecoration(
            labelText:  label,
            hintText:   hint,
            labelStyle: TextStyle(
                color:    isDark ? Colors.white38 : Colors.black38,
                fontSize: 13),
            hintStyle:  const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon,
                color: isDark ? Colors.white38 : _accent, size: 20),
            border:           InputBorder.none,
            focusedBorder:    InputBorder.none,
            enabledBorder:    InputBorder.none,
            errorBorder:      InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            errorStyle: const TextStyle(
                fontSize: 11, color: Colors.redAccent),
          ),
        ),
      );

  // ── DISTRICT DROPDOWN TILE ─────────────────────────────────────
  Widget _dropdownTile(bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        child: DropdownButtonFormField<String>(
          value:         _selectedDistrict,
          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15),
          decoration: InputDecoration(
            labelText:  t('district_label'),
            helperText: t('district_helper'),
            labelStyle: TextStyle(
                color:    isDark ? Colors.white38 : Colors.black38,
                fontSize: 13),
            helperStyle: const TextStyle(
                fontSize: 11, color: Colors.grey),
            prefixIcon: Icon(Icons.location_on_outlined,
                color: isDark ? Colors.white38 : _accent, size: 20),
            border:        InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
          items: _districts.map((d) =>
              DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _selectedDistrict = v!),
        ),
      );

  // ── EXPERIENCE TILE ────────────────────────────────────────────
  Widget _experienceTile(Map<String, String> e, bool isDark) {
    final selected = _selectedExperience == e['value'];

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedExperience = e['value']!);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:   const EdgeInsets.only(bottom: 8),
        padding:  const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withOpacity(isDark ? 0.15 : 0.07)
              : isDark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _accent.withOpacity(isDark ? 0.55 : 0.4)
                : isDark
                    ? Colors.white12
                    : Colors.grey.shade200,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _accent.withOpacity(0.10)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Row(children: [
          Text(e['emoji']!,
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['label']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:   14,
                      color: selected
                          ? (isDark ? Colors.greenAccent : _green)
                          : (isDark ? Colors.white : Colors.black87),
                    )),
                Text(e['desc']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white38
                          : Colors.black45,
                    )),
              ],
            ),
          ),
          // Selection ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _accent : Colors.transparent,
              border: Border.all(
                color: selected
                    ? _accent
                    : (isDark
                        ? Colors.white24
                        : Colors.grey.shade300),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }

  // ── SAVE BUTTON ────────────────────────────────────────────────
  Widget _buildSaveButton(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height:   56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: (_isLoading || _saved)
            ? null
            : const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
        color: _saved
            ? _accent
            : _isLoading
                ? Colors.grey.shade300
                : null,
        boxShadow: (!_isLoading && !_saved)
            ? [
                BoxShadow(
                  color:      _accent.withOpacity(0.35),
                  blurRadius: 14,
                  offset:     const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor:     Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: (_isLoading || _saved) ? null : _saveProfile,
        child: _isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : _saved
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Saved!',
                          style: TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize:   16,
                          )),
                    ],
                  )
                : Text(
                    t('save_changes').toUpperCase(),
                    style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:   15,
                      letterSpacing: 0.5,
                    ),
                  ),
      ),
    );
  }
}