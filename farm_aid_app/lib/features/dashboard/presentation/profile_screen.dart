import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../core/app_localizations.dart';
import '../../../core/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _auth      = AuthService();
  final _picker    = ImagePicker();
  final _supabase  = Supabase.instance.client;

  static const Color primaryGreen = Color(0xFF2E7D32);

  bool _isLoading   = false;
  bool _isFetching  = true;
  bool _isUploadingPhoto = false;

  // Controllers
  late TextEditingController _nameController;

  // Profile state
  String  _selectedDistrict     = 'Maseru';
  String  _selectedExperience   = 'beginner';
  String? _profilePhotoUrl;

  final List<String> _districts = [
    'Maseru', 'Berea', 'Leribe', 'Butha-Buthe', 'Mokhotlong',
    'Thaba-Tseka', "Qacha's Nek", 'Quthing', "Mohale's Hoek", 'Mafeteng',
  ];

  final Map<String, String> _experienceLabels = {
    'beginner':     '🌱 Beginner',
    'intermediate': '🌿 Intermediate',
    'expert':       '🌾 Expert',
  };

  String t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _nameController     = TextEditingController();
    _loadFarmerData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------
  // Load profile from backend (with local cache fallback)
  // --------------------------------------------------------
  Future<void> _loadFarmerData() async {
    try {
      final data = await _auth.getCurrentUser();
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _profilePhotoUrl = data['profile_photo_url'];

          if (_districts.contains(data['district'])) {
            _selectedDistrict = data['district'];
          }
          if (_experienceLabels.containsKey(data['experience_level'])) {
            _selectedExperience = data['experience_level'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // --------------------------------------------------------
  // Profile photo upload to Supabase Storage
  // --------------------------------------------------------
  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes    = await picked.readAsBytes();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path     = 'profiles/$fileName';

      await _supabase.storage.from('farmaid-media').uploadBinary(
        path, bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = _supabase.storage
          .from('farmaid-media')
          .getPublicUrl(path);

      // Save URL to backend immediately
      await _auth.updateProfile(profilePhotoUrl: publicUrl);

      if (mounted) setState(() => _profilePhotoUrl = publicUrl);

      _showSnack(t('photo_updated') ?? 'Photo updated!', isError: false);
    } catch (e) {
      _showSnack('Photo upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // --------------------------------------------------------
  // Save profile
  // --------------------------------------------------------
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final success  = await _auth.updateProfile(
        fullName:         _nameController.text.trim(),
        district:         _selectedDistrict,
        experienceLevel:  _selectedExperience,
      );

      if (success && mounted) {
        _showSnack(t('profile_updated_msg') ?? 'Profile updated!', isError: false);
        Navigator.pop(context, true);
      } else {
        _showSnack(t('update_failed_msg') ?? 'Update failed', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : primaryGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          t('edit_profile') ?? 'Edit Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // --- Avatar ---
                    _buildAvatarSection(isDark),
                    const SizedBox(height: 36),

                    // --- Full Name ---
                    _buildLabel(t('farmer_name_label') ?? 'Full Name', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: _inputDecoration(
                        hint: t('enter_name_hint') ?? 'Enter your name',
                        icon: Icons.person,
                        isDark: isDark,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? (t('name_required') ?? 'Required') : null,
                    ),
                    const SizedBox(height: 20),

                    // --- District ---
                    _buildLabel(t('district_label') ?? 'District', isDark),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: _inputDecoration(
                        hint: 'Select district',
                        icon: Icons.location_on,
                        isDark: isDark,
                        helperText: t('district_helper') ?? 'Used for regional alerts',
                      ),
                      items: _districts
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDistrict = v!),
                    ),
                    const SizedBox(height: 20),

                    // --- Experience Level ---
                    _buildLabel(t('experience_label') ?? 'Farming Experience', isDark),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade400,
                        ),
                      ),
                      child: Column(
                        children: _experienceLabels.entries.map((entry) {
                          final selected = _selectedExperience == entry.key;
                          return RadioListTile<String>(
                            value: entry.key,
                            groupValue: _selectedExperience,
                            title: Text(
                              entry.value,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              _experienceSubtitle(entry.key),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            activeColor: primaryGreen,
                            onChanged: (v) =>
                                setState(() => _selectedExperience = v!),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 40),

                    // --- Save Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                (t('save_changes') ?? 'SAVE CHANGES').toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // --------------------------------------------------------
  // WIDGETS
  // --------------------------------------------------------

  Widget _buildAvatarSection(bool isDark) {
    return Center(
      child: Stack(
        children: [
          // Photo or placeholder
          CircleAvatar(
            radius: 65,
            backgroundColor:
                isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F8E9),
            backgroundImage: _profilePhotoUrl != null
                ? NetworkImage(_profilePhotoUrl!)
                : null,
            child: _profilePhotoUrl == null
                ? Icon(Icons.person,
                    size: 85,
                    color: isDark ? Colors.greenAccent : primaryGreen)
                : null,
          ),

          // Upload indicator or camera button
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: primaryGreen, shape: BoxShape.circle),
                child: _isUploadingPhoto
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
          letterSpacing: 0.3,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    String? helperText,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
        prefixIcon: Icon(icon, color: primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
      );

  String _experienceSubtitle(String level) {
    switch (level) {
      case 'beginner':
        return 'Plain-language advice, step-by-step guidance';
      case 'intermediate':
        return 'Balanced advice with some technical detail';
      case 'expert':
        return 'Full technical protocols and agronomic data';
      default:
        return '';
    }
  }
}


