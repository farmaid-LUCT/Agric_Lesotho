// farm_aid_app/lib/features/history/presentation/growth_journal_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/auth_service.dart';
import '../../../services/journal_service.dart';
import '../../../core/constants.dart';
import '../../../core/app_localizations.dart';

class GrowthJournalScreen extends StatefulWidget {
  /// Optional — if provided, screen shows only entries for this crop profile
  /// and auto-populates the "new entry" form with the profile's notes field.
  final int? cropProfileId;
  final String? cropProfileName;

  const GrowthJournalScreen({
    super.key,
    this.cropProfileId,
    this.cropProfileName,
  });

  @override
  State<GrowthJournalScreen> createState() => _GrowthJournalScreenState();
}

class _GrowthJournalScreenState extends State<GrowthJournalScreen>
    with SingleTickerProviderStateMixin {

  final JournalService _journal = JournalService();
  final AuthService    _auth    = AuthService();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen  = Color(0xFF00A844);

  bool _isLoading  = true;
  bool _isSaving   = false;
  String? _error;

  List<Map<String, dynamic>> _entries     = [];
  List<Map<String, dynamic>> _cropProfiles = [];
  Map<String, dynamic>?      _activeProfile;

  // Selected crop profile filter
  int? _selectedProfileId;

  // For the new entry sheet
  final _titleController = TextEditingController();
  final _bodyController  = TextEditingController();
  String _selectedMood   = 'ok';

  // Mood filter on list
  String _moodFilter = 'all';

  late final AnimationController _fabAnimCtrl;

  String t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  // ── LIFECYCLE ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectedProfileId = widget.cropProfileId;
    _loadAll();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  // ── DATA LOADING ─────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    await Future.wait([
      _loadCropProfiles(),
      _loadEntries(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadCropProfiles() async {
    try {
      final token = await _auth.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(AppConstants.cropProfileUrl),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        final profiles  = data.cast<Map<String, dynamic>>();
        setState(() {
          _cropProfiles  = profiles;
          _activeProfile = profiles.firstWhere(
            (p) => p['IsActive'] == true,
            orElse: () => profiles.isNotEmpty ? profiles.first : {},
          );

          // Auto-seed body with farm notes on first open if no entries yet
          if (_bodyController.text.isEmpty &&
              _activeProfile != null &&
              (_activeProfile!['notes'] ?? '').toString().isNotEmpty) {
            _bodyController.text = _activeProfile!['notes'] ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await _journal.getEntries(
        profileId: _selectedProfileId,
      );
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  // ── CREATE ENTRY ─────────────────────────────────────────────

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please enter a title for your entry', isError: true);
      return;
    }
    if (_bodyController.text.trim().isEmpty) {
      _showSnack('Please write something in your entry', isError: true);
      return;
    }

    // Determine which crop profile to attach to
    final profileId = _selectedProfileId
        ?? _activeProfile?['ProfileID'] as int?
        ?? (_cropProfiles.isNotEmpty ? _cropProfiles.first['id'] as int? : null);

    if (profileId == null) {
      _showSnack('Please create a crop profile first', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final entry = await _journal.createEntry(
      cropProfileId: profileId,
      title:         _titleController.text.trim(),
      body:          _bodyController.text.trim(),
      mood:          _selectedMood,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (entry != null) {
      _titleController.clear();
      _bodyController.clear();
      setState(() => _selectedMood = 'ok');
      Navigator.pop(context); // close bottom sheet
      _loadEntries();          // refresh list
      _showSnack('Journal entry saved! 📝', isError: false);
    } else {
      _showSnack('Failed to save entry. Check your connection.', isError: true);
    }
  }

  // ── DELETE ENTRY ─────────────────────────────────────────────

  Future<void> _confirmDelete(int entryId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await _journal.deleteEntry(entryId);
      if (ok && mounted) {
        _loadEntries();
        _showSnack('Entry deleted', isError: false);
      }
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : primaryGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  List<Map<String, dynamic>> get _filteredEntries {
    if (_moodFilter == 'all') return _entries;
    return _entries.where((e) => e['mood'] == _moodFilter).toList();
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case 'great':     return Colors.green;
      case 'ok':        return Colors.blue;
      case 'concerned': return Colors.orange;
      case 'bad':       return Colors.red;
      default:          return Colors.grey;
    }
  }

  String _cropLabel(int? profileId) {
    if (profileId == null || _cropProfiles.isEmpty) return 'All Crops';
    final profile = _cropProfiles.firstWhere(
      (p) => p['ProfileID'] == profileId,
      orElse: () => {},
    );
    return profile.isNotEmpty
        ? '${profile['VegetableType'] ?? 'Crop'} — ${profile['SoilEnvironment'] ?? profile['irrigation_method'] ?? 'Profile'}'
        : 'All Crops';
  }

  // ── NEW ENTRY BOTTOM SHEET ────────────────────────────────────

  void _openNewEntrySheet() {
    // Seed body with farm notes if first entry and notes exist
    if (_entries.isEmpty &&
        _bodyController.text.isEmpty &&
        (_activeProfile?['notes'] ?? '').toString().isNotEmpty) {
      _bodyController.text = _activeProfile!['notes'] ?? '';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [

                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded,
                          color: primaryGreen, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'New Journal Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Form
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    children: [

                      // Crop selector (if multiple profiles)
                      if (_cropProfiles.length > 1) ...[
                        _sheetLabel('Crop Profile', isDark),
                        const SizedBox(height: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: _selectedProfileId,
                              dropdownColor: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              isExpanded: true,
                              hint: Text('Select crop',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey)),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'All crops',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ),
                                ..._cropProfiles.map((p) =>
                                    DropdownMenuItem(
                                      value: p['ProfileID'] as int?,
                                      child: Text(
                                        '${p['VegetableType']} — ${p['SoilEnvironment'] ?? p['irrigation_method'] ?? 'Profile'}',
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    )),
                              ],
                              onChanged: (v) {
                                setState(() => _selectedProfileId = v);
                                setSheetState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // How are your crops feeling today
                      _sheetLabel('How are your crops today?', isDark),
                      const SizedBox(height: 10),
                      Row(
                        children: JournalService.moodOptions.map((m) {
                          final selected = _selectedMood == m['value'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => _selectedMood = m['value']!),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 150),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _moodColor(m['value']!)
                                          .withOpacity(0.15)
                                      : (isDark
                                          ? Colors.white10
                                          : Colors.grey.shade50),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? _moodColor(m['value']!)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      m['label']!.split(' ').first,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      m['label']!.split(' ').last,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selected
                                            ? _moodColor(m['value']!)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      _sheetLabel('Entry Title *', isDark),
                      const SizedBox(height: 8),
                      _sheetTextField(
                        controller: _titleController,
                        hint: 'e.g. Week 3 check — tomatoes looking strong',
                        isDark: isDark,
                        maxLines: 1,
                      ),

                      const SizedBox(height: 16),

                      // Body
                      _sheetLabel('Observations *', isDark),
                      const SizedBox(height: 8),
                      _sheetTextField(
                        controller: _bodyController,
                        hint:
                            'Describe what you observed — leaf colour, new growth, any concerns, treatments applied...',
                        isDark: isDark,
                        maxLines: 7,
                      ),

                      const SizedBox(height: 8),

                      // Farm notes hint
                      if ((_activeProfile?['notes'] ?? '').toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: primaryGreen.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.sticky_note_2_outlined,
                                  size: 16, color: primaryGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Farm note: ${_activeProfile!['notes']}',
                                  style: const TextStyle(
                                      fontSize: 12, color: primaryGreen),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 30),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isSaving ? null : _saveEntry,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'SAVE ENTRY',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      appBar: AppBar(
        title: Text(
          widget.cropProfileName != null
              ? '${widget.cropProfileName} Journal'
              : 'Growth Journal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black),
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewEntrySheet,
        backgroundColor: accentGreen,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('New Entry',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    // Profile summary card
                    SliverToBoxAdapter(
                      child: _buildProfileCard(isDark),
                    ),

                    // Mood filter chips
                    SliverToBoxAdapter(
                      child: _buildMoodFilterRow(isDark),
                    ),

                    // Crop profile filter (if multiple)
                    if (_cropProfiles.length > 1)
                      SliverToBoxAdapter(
                        child: _buildCropFilterRow(isDark),
                      ),

                    // Stats row
                    SliverToBoxAdapter(
                      child: _buildStatsRow(isDark),
                    ),

                    // Empty state
                    if (_filteredEntries.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(isDark),
                      )
                    else
                      // Entries list
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildEntryCard(
                              _filteredEntries[i], isDark),
                          childCount: _filteredEntries.length,
                        ),
                      ),

                    // Bottom padding for FAB
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
    );
  }

  // ── PROFILE SUMMARY CARD ─────────────────────────────────────

  Widget _buildProfileCard(bool isDark) {
    if (_activeProfile == null || _activeProfile!.isEmpty) {
      return const SizedBox.shrink();
    }

    final p          = _activeProfile!;
    final cropType   = p['VegetableType']  ?? 'Crop';
    final district   = p['growth_stage'] ?? '';
    final soilType   = p['SoilEnvironment']  ?? '';
    final irrigation = p['irrigation_method'] ?? '';
    final notes      = p['notes']      ?? '';
    final seedVar    = p['seed_variety'] ?? '';
    final plantDate  = p['PlantingDate'] ?? '';
    final harvestDate = p['expected_harvest_date'] ?? '';

    // Days until harvest
    String harvestLabel = '';
    if (harvestDate.isNotEmpty) {
      try {
        final hDate = DateTime.parse(harvestDate);
        final days  = hDate.difference(DateTime.now()).inDays;
        harvestLabel = days > 0
            ? '$days days to harvest'
            : 'Harvest overdue';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B3A1F), const Color(0xFF0D2210)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1FAF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.green.withOpacity(0.3)
                : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop name + harvest countdown
          Row(
            children: [
              Text(
                _cropEmoji(cropType),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1B5E20),
                      ),
                    ),
                    if (district.isNotEmpty)
                      Text(district,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (harvestLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: harvestLabel.contains('overdue')
                        ? Colors.red.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: harvestLabel.contains('overdue')
                            ? Colors.red
                            : Colors.green),
                  ),
                  child: Text(
                    harvestLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: harvestLabel.contains('overdue')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Profile detail chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (soilType.isNotEmpty)
                _infoChip('🌱 $soilType', isDark),
              if (irrigation.isNotEmpty)
                _infoChip('💧 $irrigation', isDark),
              if (seedVar.isNotEmpty)
                _infoChip('🌾 $seedVar', isDark),
              if (plantDate.isNotEmpty)
                _infoChip('📅 Planted $plantDate', isDark),
            ],
          ),

          // Farm notes
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 15, color: primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(
                          fontSize: 12, color: primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── STATS ROW ────────────────────────────────────────────────

  Widget _buildStatsRow(bool isDark) {
    final total     = _entries.length;
    final greatOk   = _entries
        .where((e) => e['mood'] == 'great' || e['mood'] == 'ok')
        .length;
    final concerned = _entries
        .where((e) => e['mood'] == 'concerned' || e['mood'] == 'bad')
        .length;
    final healthPct = total > 0 ? (greatOk / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _statBox('$total', 'Entries', Icons.book_outlined, Colors.blue, isDark),
          const SizedBox(width: 10),
          _statBox('$healthPct%', 'Healthy', Icons.sentiment_satisfied_outlined,
              Colors.green, isDark),
          const SizedBox(width: 10),
          _statBox('$concerned', 'Concerns',
              Icons.warning_amber_outlined, Colors.orange, isDark),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color,
      bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ── MOOD FILTER ROW ──────────────────────────────────────────

  Widget _buildMoodFilterRow(bool isDark) {
    final filters = [
      {'value': 'all',       'label': '🌿 All'},
      {'value': 'great',     'label': '😊 Great'},
      {'value': 'ok',        'label': '🙂 OK'},
      {'value': 'concerned', 'label': '😟 Concerned'},
      {'value': 'bad',       'label': '😞 Bad'},
    ];

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: filters.map((f) {
          final selected = _moodFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!,
                  style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87))),
              selected: selected,
              selectedColor: f['value'] == 'all'
                  ? primaryGreen
                  : _moodColor(f['value']!),
              backgroundColor:
                  isDark ? const Color(0xFF2A2A2A) : Colors.white,
              checkmarkColor: Colors.white,
              onSelected: (_) =>
                  setState(() => _moodFilter = f['value']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── CROP FILTER ROW ──────────────────────────────────────────

  Widget _buildCropFilterRow(bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('All Crops',
                  style: TextStyle(
                      fontSize: 12,
                      color: _selectedProfileId == null
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87))),
              selected: _selectedProfileId == null,
              selectedColor: primaryGreen,
              backgroundColor:
                  isDark ? const Color(0xFF2A2A2A) : Colors.white,
              onSelected: (_) {
                setState(() => _selectedProfileId = null);
                _loadEntries();
              },
            ),
          ),
          ..._cropProfiles.map((p) {
            final id       = p['ProfileID'] as int?;
            final selected = _selectedProfileId == id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                    '${_cropEmoji(p['VegetableType'] ?? '')} ${p['VegetableType']}',
                    style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87))),
                selected: selected,
                selectedColor: accentGreen,
                backgroundColor:
                    isDark ? const Color(0xFF2A2A2A) : Colors.white,
                onSelected: (_) {
                  setState(() => _selectedProfileId = id);
                  _loadEntries();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── ENTRY CARD ───────────────────────────────────────────────

  Widget _buildEntryCard(Map<String, dynamic> entry, bool isDark) {
    final mood      = entry['mood'] as String? ?? 'ok';
    final title     = entry['title'] as String? ?? '';
    final body      = entry['body']  as String? ?? '';
    final dateStr   = entry['date']  as String? ?? '';
    final entryId   = entry['id']    as int? ?? 0;
    final photoUrl  = entry['photo_url'] as String?;
    final cropType  = entry['crop_profile_name'] as String? ?? '';

    // Parse and format date
    String formattedDate = dateStr;
    try {
      final parsed = DateTime.parse(dateStr);
      formattedDate = DateFormat('EEE, dd MMM yyyy').format(parsed);
    } catch (_) {}

    final moodColor = _moodColor(mood);

    return Dismissible(
      key: Key('entry_$entryId'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmDelete(entryId, title);
        return false; // we handle deletion manually
      },
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
          border: Border(
            left: BorderSide(color: moodColor, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood emoji
                      Text(JournalService.moodEmoji(mood),
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 11, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(formattedDate,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                                if (cropType.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text('·', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  Text(cropType,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Mood badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: moodColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          JournalService.moodLabel(mood),
                          style: TextStyle(
                              fontSize: 11,
                              color: moodColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Body text
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  // Photo thumbnail
                  if (photoUrl != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        photoUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Footer — swipe hint
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swipe_left_outlined,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('Swipe left to delete',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📔', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              _moodFilter == 'all'
                  ? 'No journal entries yet'
                  : 'No ${JournalService.moodLabel(_moodFilter).toLowerCase()} entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _moodFilter == 'all'
                  ? 'Start tracking your crop\'s growth journey.\nTap the button below to write your first entry.'
                  : 'Try a different mood filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            if (_moodFilter == 'all') ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _openNewEntrySheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.edit_note_rounded,
                    color: Colors.white),
                label: const Text('Write First Entry',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── ERROR STATE ──────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Could not load journal',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAll,
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── SMALL HELPERS ────────────────────────────────────────────

  Widget _sheetLabel(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
          letterSpacing: 0.3,
        ),
      );

  Widget _sheetTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: isDark ? Colors.white30 : Colors.grey.shade500,
                fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      );

  Widget _infoChip(String label, bool isDark) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white10
              : Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white12
                  : Colors.green.withOpacity(0.2)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : primaryGreen)),
      );

  String _cropEmoji(String cropType) {
    const map = {
      'Tomato':       '🍅',
      'Cabbage':      '🥬',
      'Potato':       '🥔',
      'Onion':        '🧅',
      'Spinach':      '🌿',
      'Green Pepper': '🫑',
      'Carrot':       '🥕',
      'Beetroot':     '🟣',
      'Pumpkin':      '🎃',
      'Green Beans':  '🫘',
      'Broccoli':     '🥦',
      'Cauliflower':  '🥦',
      'Swiss Chard':  '🥬',
    };
    return map[cropType] ?? '🌱';
  }
}


