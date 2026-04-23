
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

  // ── Brand colors — same as home page ──────────────────────────
  static const Color _deepForest = Color(0xFF1B5E20);
  static const Color _midForest  = Color(0xFF2D6A4F);
  static const Color _accent     = Color(0xFF2E7D32);

  bool _isLoading        = false;
  bool _isFetching       = true;
  bool _isUploadingPhoto = false;
  bool _saved            = false;

  late TextEditingController _nameController;

  String  _selectedDistrict   = 'Maseru';
  String  _selectedExperience = 'beginner';
  String? _profilePhotoUrl;

  late AnimationController _checkCtrl;
  late Animation<double>   _checkAnim;

  // ── Theme helpers — read locally like home page ────────────────
  bool  get _isDark       => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg       => _isDark ? const Color(0xFF0D1B14) : const Color(0xFFF0F7F0);
  Color get _cardBg       => _isDark ? const Color(0xFF1A2E22) : Colors.white;
  Color get _textPrimary  => _isDark ? Colors.white           : const Color(0xFF1A1A1A);
  Color get _textMuted    => _isDark ? Colors.white38         : Colors.black38;
  Color get _brandColor   => _isDark ? Colors.greenAccent     : _deepForest;
  Color get _dividerColor => _isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100;

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

  // ── All logic methods IDENTICAL to original ───────────────────

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _pageBg,
      body: _isFetching
          ? Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: _accent))
          : isWide
              ? Column(children: [
                  _buildHeader(),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child:   _buildContent(),
                        ),
                      ),
                    ),
                  ),
                ])
              : Column(children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child:   _buildContent(),
                    ),
                  ),
                ]),
    );
  }

  // ── HEADER — same gradient as home + settings ─────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0B2E18), const Color(0xFF1B4332)]
              : [_deepForest, _midForest],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:    const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('edit_profile'),
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Update your farm details',
                    style: TextStyle(
                      color:    Colors.white.withOpacity(0.65),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Save shortcut in header
            if (!_isFetching)
              GestureDetector(
                onTap: (_isLoading || _saved) ? null : _saveProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: (_isLoading || _saved)
                        ? Colors.white.withOpacity(0.10)
                        : Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Text(
                    _saved ? 'Saved ✓' : 'Save',
                    style: TextStyle(
                      color: (_isLoading || _saved)
                          ? Colors.white54
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:   13,
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  // ── CONTENT ───────────────────────────────────────────────────
  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(),
          const SizedBox(height: 28),

          _sectionLabel('Personal Information'),
          const SizedBox(height: 8),
          _buildCard([
            _fieldTile(
              ctrl:      _nameController,
              label:     t('farmer_name_label'),
              hint:      t('enter_name_hint'),
              icon:      Icons.person_outline_rounded,
              validator: (v) =>
                  v!.trim().isEmpty ? t('name_required') : null,
            ),
          ]),

          const SizedBox(height: 20),

          _sectionLabel('Farm Details'),
          const SizedBox(height: 8),
          _buildCard([_dropdownTile()]),

          const SizedBox(height: 20),

          _sectionLabel('Experience Level'),
          const SizedBox(height: 8),
          ..._experienceLevels.map((e) => _experienceTile(e)),

          const SizedBox(height: 28),
          _buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── AVATAR ────────────────────────────────────────────────────
  Widget _buildAvatar() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Photo ring
          Container(
            width: 104, height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cardBg,
              border: Border.all(
                  color: _accent.withOpacity(0.35), width: 3),
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
                      color: _isDark ? Colors.greenAccent : _accent),
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
                  color:  _accent,
                  shape:  BoxShape.circle,
                  border: Border.all(
                    color: _pageBg,
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

  // ── SECTION LABEL — left-bar accent style ─────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(children: [
        Container(
          width:  3,
          height: 14,
          decoration: BoxDecoration(
            color:        _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize:      11,
            fontWeight:    FontWeight.bold,
            letterSpacing: 1.1,
            color:         _textMuted,
          ),
        ),
      ]),
    );
  }

  // ── CARD ──────────────────────────────────────────────────────
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color:        _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(_isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ── TEXT FIELD TILE ───────────────────────────────────────────
  Widget _fieldTile({
    required TextEditingController ctrl,
    required String    label,
    required String    hint,
    required IconData  icon,
    String? Function(String?)? validator,
    TextInputType?     keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller:   ctrl,
        keyboardType: keyboard,
        validator:    validator,
        style: TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText:  label,
          hintText:   hint,
          labelStyle: TextStyle(color: _textMuted, fontSize: 13),
          hintStyle:  TextStyle(color: _textMuted),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        _accent.withOpacity(_isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _accent, size: 16),
          ),
          border:             InputBorder.none,
          focusedBorder:      InputBorder.none,
          enabledBorder:      InputBorder.none,
          errorBorder:        InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: const TextStyle(
              fontSize: 11, color: Colors.redAccent),
        ),
      ),
    );
  }

  // ── DISTRICT DROPDOWN ─────────────────────────────────────────
  Widget _dropdownTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        value:         _selectedDistrict,
        dropdownColor: _isDark ? const Color(0xFF1A2E22) : Colors.white,
        style: TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText:  t('district_label'),
          helperText: t('district_helper'),
          labelStyle:  TextStyle(color: _textMuted, fontSize: 13),
          helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          prefixIcon: Container(
            margin:  const EdgeInsets.all(10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        _accent.withOpacity(_isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on_outlined,
                color: _accent, size: 16),
          ),
          border:        InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        items: _districts
            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
            .toList(),
        onChanged: (v) => setState(() => _selectedDistrict = v!),
      ),
    );
  }

  // ── EXPERIENCE TILE ───────────────────────────────────────────
  Widget _experienceTile(Map<String, String> e) {
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
              ? _accent.withOpacity(_isDark ? 0.15 : 0.07)
              : _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? _accent.withOpacity(_isDark ? 0.55 : 0.4)
                : _isDark ? Colors.white12 : Colors.grey.shade200,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _accent.withOpacity(0.10)
                  : Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Row(children: [
          Text(e['emoji']!, style: const TextStyle(fontSize: 24)),
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
                          ? (_isDark ? Colors.greenAccent : _deepForest)
                          : _textPrimary,
                    )),
                Text(e['desc']!,
                    style: TextStyle(fontSize: 12, color: _textMuted)),
              ],
            ),
          ),
          // Selection ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:  selected ? _accent : Colors.transparent,
              border: Border.all(
                color: selected
                    ? _accent
                    : (_isDark ? Colors.white24 : Colors.grey.shade300),
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

  // ── SAVE BUTTON ───────────────────────────────────────────────
  Widget _buildSaveButton() {
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
                ? (_isDark ? Colors.white12 : Colors.grey.shade300)
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
                      color:         Colors.white,
                      fontWeight:    FontWeight.bold,
                      fontSize:      15,
                      letterSpacing: 0.5,
                    ),
                  ),
      ),
    );
  }
}
