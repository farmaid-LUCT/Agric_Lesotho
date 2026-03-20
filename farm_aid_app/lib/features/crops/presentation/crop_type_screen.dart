import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants.dart';
import '../../../services/theme_provider.dart';
import '../../../core/app_localizations.dart';

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
  String? selectedSoil;       // stores model value e.g. 'loam'
  String? selectedDistrict;
  String? selectedIrrigation; // stores model value e.g. 'drip'
  DateTime? plantingDate;
  DateTime? expectedHarvestDate;
  final _seedVarietyController = TextEditingController();
  final _notesController       = TextEditingController();
  final _plotSizeController    = TextEditingController();

  final List<Map<String, String>> vegetableTypes = [
    {'name': 'Cabbage',      'icon': '🥬'},
    {'name': 'Tomato',       'icon': '🍅'},
    {'name': 'Potato',       'icon': '🥔'},
    {'name': 'Onion',        'icon': '🧅'},
    {'name': 'Spinach',      'icon': '🌿'},
    {'name': 'Swiss Chard',  'icon': '🥬'},
    {'name': 'Green Pepper', 'icon': '🫑'},
    {'name': 'Carrot',       'icon': '🥕'},
    {'name': 'Beetroot',     'icon': '🟣'},
    {'name': 'Pumpkin',      'icon': '🎃'},
    {'name': 'Green Beans',  'icon': '🫘'},
    {'name': 'Broccoli',     'icon': '🥦'},
    {'name': 'Cauliflower',  'icon': '🥦'},
  ];

  // ── Soil types ────────────────────────────────────────────────────────────
  // value = exact Django model choice  |  label = what the farmer sees
  // CropProfile.SoilEnvironment choices: sandy, clay, loam, silt, sandy_loam, clay_loam
  final List<Map<String, String>> soilTypes = [
    {'value': 'loam',       'label': 'Loamy (Rich)'},
    {'value': 'sandy',      'label': 'Sandy'},
    {'value': 'clay',       'label': 'Clayey'},
    {'value': 'sandy_loam', 'label': 'Sandy Loam'},
    {'value': 'clay_loam',  'label': 'Clay Loam'},
    {'value': 'silt',       'label': 'Silt (Duplex / Lesotho Special)'},
  ];

  final List<String> districts = [
    'Maseru', 'Leribe', 'Berea', 'Mafeteng', "Mohale's Hoek",
    'Quthing', "Qacha's Nek", 'Mokhotlong', 'Butha-Buthe', 'Thaba-Tseka',
  ];

  // ── Irrigation methods ────────────────────────────────────────────────────
  // value = exact Django model choice  |  label / desc = what the farmer sees
  // CropProfile.irrigation_method choices: rain, drip, flood, sprinkler
  final List<Map<String, String>> irrigationMethods = [
    {'value': 'drip',       'label': '💧 Drip Irrigation',     'desc': 'Water delivered directly to roots'},
    {'value': 'sprinkler',  'label': '🚿 Sprinkler Irrigation', 'desc': 'Overhead spray — raises fungal risk'},
    {'value': 'flood',      'label': '🌊 Flood / Furrow',       'desc': 'Water flows along channels between rows'},
    {'value': 'rain',       'label': '🌧️ Rain-fed Only',        'desc': 'Relies entirely on rainfall'},
  ];

  @override
  void dispose() {
    _seedVarietyController.dispose();
    _notesController.dispose();
    _plotSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final appLoc = AppLocalizations.of(context);

    if (selectedCrop      == null ||
        selectedSoil      == null ||
        selectedDistrict  == null ||
        selectedIrrigation == null ||
        plantingDate      == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(appLoc?.translate("Please complete all details") ??
            "Please complete all required fields"),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _auth.getToken();

      // ── Field names must match CropProfile model exactly ─────────────────
      // CropProfile fields: VegetableType, SoilEnvironment, PlantingDate,
      //   IsActive, plot_size_hectares, expected_harvest_date,
      //   irrigation_method, seed_variety, notes
      //
      // The serializer uses the model field names as keys.
      // soil and irrigation values must match the model's choice values.
      final Map<String, dynamic> profileData = {
        'VegetableType':       selectedCrop,
        'SoilEnvironment':     selectedSoil,        // model value: loam/sandy/clay etc.
        'PlantingDate':        DateFormat('yyyy-MM-dd').format(plantingDate!),
        'IsActive':            true,
        'irrigation_method':   selectedIrrigation,  // model value: rain/drip/flood/sprinkler
        'expected_harvest_date': expectedHarvestDate != null
            ? DateFormat('yyyy-MM-dd').format(expectedHarvestDate!)
            : null,
        'seed_variety': _seedVarietyController.text.trim().isEmpty
            ? null
            : _seedVarietyController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'plot_size_hectares': double.tryParse(_plotSizeController.text.trim()),
      };

      // Remove null values so Django doesn't reject optional fields
      profileData.removeWhere((k, v) => v == null);

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/crop-profiles/'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Return the new profile ID so scanner_section can pass it to SaveScanView
        final profileId = body['ProfileID']?.toString() ?? body['id']?.toString();
        _showSuccessDialog(profileId);
      } else {
        // Surface the actual Django validation error for easier debugging
        throw Exception('Server ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String? profileId) {
    final bool isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final appLoc = AppLocalizations.of(context);

    String desc = appLoc?.translate(
            'Your {} profile is ready. We will now analyze your leaf image for personalized advice.') ??
        'Your $selectedCrop profile is ready. We will now analyze your leaf image for personalized advice.';
    if (desc.contains('{}')) desc = desc.replaceAll('{}', selectedCrop ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.verified_user_rounded,
            color: Colors.green, size: 50),
        title: Text(
          appLoc?.translate('Profile Saved') ?? 'Profile Saved',
          style:
              TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(desc,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Pass profileId back to scanner_section for the AI scan call
                Navigator.pop(context, profileId);
              },
              child: Text(
                appLoc?.translate('Start Analysis') ?? 'Start Analysis',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ),
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
        title: Text(
          appLoc?.translate('Vegetable Setup') ?? 'Vegetable Setup',
          style: TextStyle(
              color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20),
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDark ? Colors.white : Colors.green),
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
                  color: isDark
                      ? Colors.green.withOpacity(0.1)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? Colors.greenAccent.withOpacity(0.3)
                          : Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color:
                            isDark ? Colors.greenAccent : Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        appLoc?.translate(
                                'Almost there! Complete your profile to get personalized AI tips for your scan.') ??
                            'Almost there! Complete your profile to get personalized AI tips for your scan.',
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.greenAccent
                                : Colors.green,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              appLoc?.translate('Personalize your Vegetable Expert') ??
                  'Personalize your Vegetable Expert',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              appLoc?.translate(
                      'Our AI will use these details to provide rule-based recommendations specific to your farm.') ??
                  'Our AI will use these details to provide rule-based recommendations specific to your farm.',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54),
            ),

            const SizedBox(height: 35),

            // 1. Vegetable Type
            _sectionTitle(
                appLoc?.translate('1. Vegetable Type') ?? '1. Vegetable Type',
                isDark),
            const SizedBox(height: 12),
            _buildVegetableDropdown(isDark, appLoc),

            const SizedBox(height: 25),

            // 2. Soil Environment
            _sectionTitle(
                appLoc?.translate('2. Soil Environment') ?? '2. Soil Environment',
                isDark),
            const SizedBox(height: 12),
            _buildSoilDropdown(isDark, appLoc),

            const SizedBox(height: 25),

            // 3. Farm Location
            _sectionTitle(
                appLoc?.translate('3. Farm Location') ?? '3. Farm Location',
                isDark),
            const SizedBox(height: 12),
            _buildSimpleDropdown(
              hint: appLoc?.translate('Select District') ?? 'Select District',
              value: selectedDistrict,
              items: districts,
              icon: Icons.location_on_outlined,
              isDark: isDark,
              onChanged: (val) => setState(() => selectedDistrict = val),
            ),

            const SizedBox(height: 25),

            // 4. Irrigation Method
            _sectionTitle(
                appLoc?.translate('4. Irrigation Method') ?? '4. Irrigation Method',
                isDark),
            const SizedBox(height: 4),
            Text('Affects which treatments are safe to apply',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white38
                        : Colors.grey.shade600)),
            const SizedBox(height: 12),
            _buildIrrigationSelector(isDark),

            const SizedBox(height: 25),

            // 5. Planting Date
            _sectionTitle(
                appLoc?.translate('5. Planting Date') ?? '5. Planting Date',
                isDark),
            const SizedBox(height: 12),
            _buildDatePicker(isDark, appLoc),

            const SizedBox(height: 25),

            // 6. Expected Harvest Date
            _sectionTitle(
                appLoc?.translate('6. Expected Harvest Date') ??
                    '6. Expected Harvest Date',
                isDark),
            const SizedBox(height: 4),
            Text('Prevents unsafe treatments near harvest time',
                style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? Colors.white38 : Colors.grey.shade600)),
            const SizedBox(height: 12),
            _buildHarvestDatePicker(isDark, appLoc),

            const SizedBox(height: 25),

            // 7. Seed Variety (optional)
            _sectionTitle(
                appLoc?.translate('7. Seed Variety (Optional)') ??
                    '7. Seed Variety (Optional)',
                isDark),
            const SizedBox(height: 4),
            Text('e.g. Roma VF, Money Maker, Star 9006',
                style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? Colors.white38 : Colors.grey.shade600)),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _seedVarietyController,
              hint: 'Enter seed variety name',
              icon: Icons.grass_outlined,
              isDark: isDark,
            ),

            const SizedBox(height: 25),

            // 8. Farm Notes (optional)
            _sectionTitle(
                appLoc?.translate('8. Farm Notes (Optional)') ??
                    '8. Farm Notes (Optional)',
                isDark),
            const SizedBox(height: 4),
            Text('Observations, inputs applied, or anything useful',
                style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? Colors.white38 : Colors.grey.shade600)),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              hint: 'e.g. Applied compost 2 weeks ago, noticed yellowing on outer leaves',
              icon: Icons.notes_outlined,
              isDark: isDark,
              maxLines: 4,
            ),

            const SizedBox(height: 25),

            // 9. Plot Size
            _sectionTitle(
                appLoc?.translate('9. Plot Size *') ??
                    '9. Plot Size (hectares) *',
                isDark),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber.withOpacity(0.08)
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isDark
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Text('⚖️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We use this to calculate your exact treatment dose — e.g. "Apply 12.5g" instead of "25g per hectare".',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.amber.shade200
                              : Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _plotSizeController,
              hint: 'e.g.  0.5  (half a hectare)  or  1.0  or  0.25',
              icon: Icons.straighten_outlined,
              isDark: isDark,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _sizeHintChip('0.1 ha', '10×10m', isDark),
                _sizeHintChip('0.25 ha', 'Quarter acre', isDark),
                _sizeHintChip('0.5 ha', 'Half acre', isDark),
                _sizeHintChip('1.0 ha', 'Full acre', isDark),
              ],
            ),

            const SizedBox(height: 50),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        appLoc?.translate('Save & Get Recommendations') ??
                            'Save & Get Recommendations',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Soil dropdown — shows friendly label, sends model value ──────────────
  Widget _buildSoilDropdown(bool isDark, AppLocalizations? appLoc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
            width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          value: selectedSoil,
          hint: Text(
            appLoc?.translate('Select Soil Type') ?? 'Select Soil Type',
            style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white38 : Colors.grey),
          ),
          isExpanded: true,
          // value = model choice (e.g. 'loam'), displayed text = friendly label
          items: soilTypes
              .map((s) => DropdownMenuItem<String>(
                    value: s['value'],
                    child: Text(s['label']!,
                        style: TextStyle(
                            fontSize: 15,
                            color:
                                isDark ? Colors.white : Colors.black)),
                  ))
              .toList(),
          onChanged: (val) => setState(() => selectedSoil = val),
        ),
      ),
    );
  }

  // ── Irrigation card selector ──────────────────────────────────────────────
  Widget _buildIrrigationSelector(bool isDark) {
    return Column(
      children: irrigationMethods.map((method) {
        final bool selected = selectedIrrigation == method['value'];
        return GestureDetector(
          onTap: () =>
              setState(() => selectedIrrigation = method['value']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? (isDark
                      ? Colors.green.withOpacity(0.2)
                      : Colors.green.shade50)
                  : (isDark ? Colors.white10 : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Colors.green
                    : (isDark ? Colors.white24 : Colors.grey.shade200),
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(method['label']!.split(' ').first,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['label']!.split(' ').skip(1).join(' '),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? Colors.green
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      Text(
                        method['desc']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white38
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title, bool isDark) => Text(
        title,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.greenAccent : Colors.green,
            letterSpacing: 0.5),
      );

  Widget _buildDatePicker(bool isDark, AppLocalizations? appLoc) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: isDark
                ? ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: Colors.green,
                        onPrimary: Colors.white,
                        surface: Color(0xFF1E1E1E),
                        onSurface: Colors.white))
                : ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: Colors.green)),
            child: child!,
          ),
        );
        if (picked != null) setState(() => plantingDate = picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade200,
              width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: Colors.green, size: 22),
            const SizedBox(width: 12),
            Text(
              plantingDate == null
                  ? (appLoc?.translate('When did you plant?') ??
                      'When did you plant?')
                  : DateFormat('dd MMMM yyyy').format(plantingDate!),
              style: TextStyle(
                fontSize: 15,
                color: plantingDate == null
                    ? (isDark ? Colors.white38 : Colors.grey.shade600)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHarvestDatePicker(bool isDark, AppLocalizations? appLoc) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: plantingDate != null
              ? plantingDate!.add(const Duration(days: 60))
              : DateTime.now().add(const Duration(days: 60)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: isDark
                ? ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: Colors.green,
                        onPrimary: Colors.white,
                        surface: Color(0xFF1E1E1E),
                        onSurface: Colors.white))
                : ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: Colors.green)),
            child: child!,
          ),
        );
        if (picked != null) setState(() => expectedHarvestDate = picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade200,
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_available_outlined,
              color:
                  expectedHarvestDate != null ? Colors.green : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expectedHarvestDate == null
                        ? (appLoc?.translate(
                                'When do you expect to harvest?') ??
                            'When do you expect to harvest?')
                        : DateFormat('dd MMMM yyyy')
                            .format(expectedHarvestDate!),
                    style: TextStyle(
                      fontSize: 15,
                      color: expectedHarvestDate == null
                          ? (isDark
                              ? Colors.white38
                              : Colors.grey.shade600)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (expectedHarvestDate != null)
                    Text(
                      '${expectedHarvestDate!.difference(DateTime.now()).inDays} days from today',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.green),
                    ),
                ],
              ),
            ),
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
        border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
            width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          value: selectedCrop,
          hint: Text(
            appLoc?.translate('Select Vegetable') ?? 'Select Vegetable',
            style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white38 : Colors.grey),
          ),
          isExpanded: true,
          items: vegetableTypes
              .map((item) => DropdownMenuItem(
                    value: item['name'],
                    child: Row(
                      children: [
                        Text(item['icon']!,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Text(item['name']!,
                            style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black)),
                      ],
                    ),
                  ))
              .toList(),
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
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
            width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white38 : Colors.grey)),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: TextStyle(
                            fontSize: 15,
                            color:
                                isDark ? Colors.white : Colors.black)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
            width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Icon(icon, color: Colors.green, size: 20),
          ),
          prefixIconConstraints: maxLines > 1
              ? const BoxConstraints(minWidth: 48, minHeight: 48)
              : null,
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white30 : Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              vertical: maxLines > 1 ? 16 : 18, horizontal: 4),
        ),
      ),
    );
  }

  Widget _sizeHintChip(String size, String label, bool isDark) {
    return GestureDetector(
      onTap: () => setState(
          () => _plotSizeController.text = size.split(' ').first),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white10
              : Colors.green.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white24
                  : Colors.green.withOpacity(0.25)),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: size,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.greenAccent
                        : const Color(0xFF2E7D32)),
              ),
              TextSpan(
                text: '  $label',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white38
                        : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
