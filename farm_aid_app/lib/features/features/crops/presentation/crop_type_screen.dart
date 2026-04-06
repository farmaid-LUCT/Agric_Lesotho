// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:provider/provider.dart';
// import '../../../services/auth_service.dart';
// import '../../../core/constants.dart';
// import '../../../services/theme_provider.dart';
// import '../../../core/app_localizations.dart';

// class CropTypeScreen extends StatefulWidget {
//   final Uint8List? pendingImage;
//   const CropTypeScreen({super.key, this.pendingImage});

//   @override
//   State<CropTypeScreen> createState() => _CropTypeScreenState();
// }

// class _CropTypeScreenState extends State<CropTypeScreen>
//     with TickerProviderStateMixin {

//   final AuthService _auth = AuthService();
//   bool _isLoading = false;

//   // ── Wizard step ────────────────────────────────────────────────
//   int _step = 0;  // 0..3
//   static const _totalSteps = 4;

//   // Step labels shown in the header indicator
//   static const _stepLabels = ['Crop', 'Location', 'Dates', 'Details'];

//   // ── Form state ─────────────────────────────────────────────────
//   String?   selectedCrop;
//   String?   selectedSoil;
//   String?   selectedDistrict;
//   String?   selectedIrrigation;
//   DateTime? plantingDate;
//   DateTime? expectedHarvestDate;
//   final _seedCtrl     = TextEditingController();
//   final _notesCtrl    = TextEditingController();
//   final _plotSizeCtrl = TextEditingController();

//   // ── Animation ──────────────────────────────────────────────────
//   late AnimationController _slideCtrl;
//   late Animation<Offset>   _slideIn;

//   static const _green  = Color(0xFF1B5E20);
//   static const _accent = Color(0xFF2E7D32);

//   // ── Data ───────────────────────────────────────────────────────
//   final _vegetables = const [
//     {'name': 'Cabbage',      'icon': '🥬'},
//     {'name': 'Tomato',       'icon': '🍅'},
//     {'name': 'Potato',       'icon': '🥔'},
//     {'name': 'Onion',        'icon': '🧅'},
//     {'name': 'Spinach',      'icon': '🌿'},
//     {'name': 'Swiss Chard',  'icon': '🥬'},
//     {'name': 'Green Pepper', 'icon': '🫑'},
//     {'name': 'Carrot',       'icon': '🥕'},
//     {'name': 'Beetroot',     'icon': '🟣'},
//     {'name': 'Pumpkin',      'icon': '🎃'},
//     {'name': 'Green Beans',  'icon': '🫘'},
//     {'name': 'Broccoli',     'icon': '🥦'},
//     {'name': 'Cauliflower',  'icon': '🥦'},
//   ];

//   final _soilTypes = const [
//     {'value': 'loam',       'emoji': '🌱', 'label': 'Loamy',      'desc': 'Rich, well-draining'},
//     {'value': 'sandy',      'emoji': '🏜️', 'label': 'Sandy',       'desc': 'Fast-draining, low nutrients'},
//     {'value': 'clay',       'emoji': '🧱', 'label': 'Clayey',      'desc': 'Heavy, good nutrient retention'},
//     {'value': 'sandy_loam', 'emoji': '⚖️', 'label': 'Sandy Loam',  'desc': 'Good balance of drainage'},
//     {'value': 'clay_loam',  'emoji': '💧', 'label': 'Clay Loam',   'desc': 'Moderate water retention'},
//     {'value': 'silt',       'emoji': '🇱🇸', 'label': 'Silt',        'desc': 'Duplex / Lesotho Special'},
//   ];

//   final _districts = const [
//     'Maseru', 'Leribe', 'Berea', 'Mafeteng', "Mohale's Hoek",
//     'Quthing', "Qacha's Nek", 'Mokhotlong', 'Butha-Buthe', 'Thaba-Tseka',
//   ];

//   final _irrigationMethods = const [
//     {'value': 'drip',      'emoji': '💧', 'label': 'Drip',       'desc': 'Lowest disease risk'},
//     {'value': 'sprinkler', 'emoji': '🚿', 'label': 'Sprinkler',  'desc': 'Raises fungal risk'},
//     {'value': 'flood',     'emoji': '🌊', 'label': 'Flood',      'desc': 'Flow between rows'},
//     {'value': 'rain',      'emoji': '🌧',  'label': 'Rain-fed',   'desc': 'Relies on rainfall'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _slideCtrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 320));
//     _slideIn = Tween<Offset>(
//       begin: const Offset(0.08, 0), end: Offset.zero,
//     ).animate(CurvedAnimation(
//         parent: _slideCtrl, curve: Curves.easeOutCubic));
//     _slideCtrl.forward();
//   }

//   @override
//   void dispose() {
//     _slideCtrl.dispose();
//     _seedCtrl.dispose();
//     _notesCtrl.dispose();
//     _plotSizeCtrl.dispose();
//     super.dispose();
//   }

//   // ── Step validation ────────────────────────────────────────────
//   bool get _stepValid {
//     switch (_step) {
//       case 0: return selectedCrop != null && selectedSoil != null;
//       case 1: return selectedDistrict != null && selectedIrrigation != null;
//       case 2: return plantingDate != null;
//       case 3: return true; // all optional
//       default: return false;
//     }
//   }

//   void _goNext() {
//     if (!_stepValid) {
//       _showSnack(_step == 2
//           ? 'Please select a planting date'
//           : 'Please complete all fields on this step');
//       return;
//     }
//     if (_step < _totalSteps - 1) {
//       HapticFeedback.selectionClick();
//       setState(() => _step++);
//       _slideCtrl.forward(from: 0);
//     } else {
//       _saveProfile();
//     }
//   }

//   void _goBack() {
//     if (_step > 0) {
//       HapticFeedback.selectionClick();
//       setState(() => _step--);
//       _slideCtrl.forward(from: 0);
//     } else {
//       Navigator.pop(context);
//     }
//   }

//   // ── Save ───────────────────────────────────────────────────────
//   Future<void> _saveProfile() async {
//     setState(() => _isLoading = true);
//     try {
//       final token = await _auth.getToken();
//       final body  = <String, dynamic>{
//         'VegetableType':     selectedCrop,
//         'SoilEnvironment':   selectedSoil,
//         'PlantingDate':      DateFormat('yyyy-MM-dd').format(plantingDate!),
//         'IsActive':          true,
//         'irrigation_method': selectedIrrigation,
//         if (expectedHarvestDate != null)
//           'expected_harvest_date':
//               DateFormat('yyyy-MM-dd').format(expectedHarvestDate!),
//         if (_seedCtrl.text.trim().isNotEmpty)
//           'seed_variety': _seedCtrl.text.trim(),
//         if (_notesCtrl.text.trim().isNotEmpty)
//           'notes': _notesCtrl.text.trim(),
//         if (double.tryParse(_plotSizeCtrl.text.trim()) != null)
//           'plot_size_hectares': double.parse(_plotSizeCtrl.text.trim()),
//       };

//       final res = await http.post(
//         Uri.parse('${AppConstants.apiBaseUrl}/crop-profiles/'),
//         headers: {
//           'Content-Type':  'application/json',
//           'Authorization': 'Token $token',
//         },
//         body: jsonEncode(body),
//       );

//       if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
//         final json = jsonDecode(res.body);
//         final id   = json['ProfileID']?.toString() ?? json['id']?.toString();
//         _showSuccessSheet(id);
//       } else {
//         throw Exception('${res.statusCode}: ${res.body}');
//       }
//     } catch (e) {
//       _showSnack('Failed to save: $e', isError: true);
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void _showSnack(String msg, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg),
//       backgroundColor: isError ? Colors.redAccent : _accent,
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     ));
//   }

//   void _showSuccessSheet(String? profileId) {
//     final isDark =
//         Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
//     showModalBottomSheet(
//       context: context,
//       isDismissible: false,
//       enableDrag: false,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Container(
//         decoration: BoxDecoration(
//           color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//           borderRadius:
//               const BorderRadius.vertical(top: Radius.circular(28)),
//         ),
//         padding: EdgeInsets.fromLTRB(
//             28, 28, 28, MediaQuery.of(context).padding.bottom + 28),
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           Container(
//             width: 72, height: 72,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
//                 begin: Alignment.topLeft,
//                 end:   Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(color: _accent.withOpacity(0.3),
//                     blurRadius: 16, offset: const Offset(0, 6)),
//               ],
//             ),
//             child: const Icon(Icons.check_rounded,
//                 color: Colors.white, size: 38),
//           ),
//           const SizedBox(height: 16),
//           Text('Profile Saved!',
//               style: TextStyle(
//                 fontSize:   22,
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white : Colors.black87,
//               )),
//           const SizedBox(height: 8),
//           Text(
//             'Your $selectedCrop profile is ready.\nThe AI will now give personalised advice for your farm.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 14, height: 1.55,
//               color: isDark ? Colors.white60 : Colors.black54,
//             ),
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _accent,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16)),
//                 elevation: 0,
//               ),
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pop(context, profileId);
//               },
//               child: const Text('Start AI Analysis',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16)),
//             ),
//           ),
//         ]),
//       ),
//     );
//   }

//   // ══════════════════════════════════════════════════════════════
//   // BUILD
//   // ══════════════════════════════════════════════════════════════
//   @override
//   Widget build(BuildContext context) {
//     final isDark =
//         Provider.of<ThemeProvider>(context).isDarkMode;
//     final isWide = MediaQuery.of(context).size.width > 600;
//     final bottom = MediaQuery.of(context).padding.bottom;

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF121212) : const Color(0xFFF0FBF0),
//       body: SafeArea(
//         child: isWide
//             ? Center(
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 560),
//                   child: _buildWizard(isDark, bottom),
//                 ),
//               )
//             : _buildWizard(isDark, bottom),
//       ),
//     );
//   }

//   Widget _buildWizard(bool isDark, double bottom) {
//     return Column(children: [
//       // ── Top bar ──────────────────────────────────────────────
//       _buildTopBar(isDark),

//       // ── Step indicator ────────────────────────────────────────
//       _buildStepIndicator(isDark),

//       // ── Step content (scrollable) ─────────────────────────────
//       Expanded(
//         child: SlideTransition(
//           position: _slideIn,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
//             child: _buildStepContent(isDark),
//           ),
//         ),
//       ),

//       // ── Bottom nav buttons ────────────────────────────────────
//       _buildBottomNav(isDark, bottom),
//     ]);
//   }

//   // ── TOP BAR ────────────────────────────────────────────────────
//   Widget _buildTopBar(bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
//       child: Row(children: [
//         GestureDetector(
//           onTap: _goBack,
//           child: Container(
//             width: 38, height: 38,
//             decoration: BoxDecoration(
//               color: isDark
//                   ? Colors.white.withOpacity(0.10)
//                   : Colors.black.withOpacity(0.07),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(Icons.arrow_back_ios_new_rounded,
//                 size:  16,
//                 color: isDark ? Colors.white : Colors.black87),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Farm Profile Setup',
//                   style: TextStyle(
//                     fontSize:   18,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: -0.3,
//                     color: isDark ? Colors.greenAccent : _green,
//                   )),
//               Text('Personalise your AI recommendations',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: isDark ? Colors.white38 : Colors.black38,
//                   )),
//             ],
//           ),
//         ),
//         // Step counter pill
//         Container(
//           padding: const EdgeInsets.symmetric(
//               horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: _accent.withOpacity(isDark ? 0.2 : 0.1),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             '${_step + 1} / $_totalSteps',
//             style: TextStyle(
//               fontSize:   12,
//               fontWeight: FontWeight.bold,
//               color: isDark ? Colors.greenAccent : _accent,
//             ),
//           ),
//         ),
//       ]),
//     );
//   }

//   // ── STEP INDICATOR (dot + label) ───────────────────────────────
//   Widget _buildStepIndicator(bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
//       child: Row(children: List.generate(_totalSteps, (i) {
//         final done    = i < _step;
//         final current = i == _step;
//         return Expanded(
//           child: Row(children: [
//             Expanded(
//               child: Column(children: [
//                 // Dot
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 250),
//                   height: 6,
//                   decoration: BoxDecoration(
//                     color: done
//                         ? _accent
//                         : current
//                             ? _accent.withOpacity(0.5)
//                             : isDark
//                                 ? Colors.white12
//                                 : Colors.black.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   _stepLabels[i],
//                   style: TextStyle(
//                     fontSize:   10,
//                     fontWeight: current
//                         ? FontWeight.bold
//                         : FontWeight.normal,
//                     color: done || current
//                         ? (isDark ? Colors.greenAccent : _accent)
//                         : (isDark ? Colors.white30 : Colors.black38),
//                   ),
//                 ),
//               ]),
//             ),
//             if (i < _totalSteps - 1) const SizedBox(width: 6),
//           ]),
//         );
//       })),
//     );
//   }

//   // ── STEP CONTENT ───────────────────────────────────────────────
//   Widget _buildStepContent(bool isDark) {
//     switch (_step) {
//       case 0: return _buildStep0(isDark);
//       case 1: return _buildStep1(isDark);
//       case 2: return _buildStep2(isDark);
//       case 3: return _buildStep3(isDark);
//       default: return const SizedBox.shrink();
//     }
//   }

//   // ── STEP 0 — Crop + Soil ──────────────────────────────────────
//   Widget _buildStep0(bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (widget.pendingImage != null) ...[
//           _pendingBanner(isDark),
//           const SizedBox(height: 16),
//         ],
//         _stepHeading('Which crop are you growing?', isDark),
//         const SizedBox(height: 12),
//         // Vegetable grid
//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount:   4,
//             mainAxisSpacing:  8,
//             crossAxisSpacing: 8,
//             childAspectRatio: 0.95,
//           ),
//           itemCount: _vegetables.length,
//           itemBuilder: (_, i) {
//             final v = _vegetables[i];
//             final sel = selectedCrop == v['name'];
//             return _selectTile(
//               emoji:    v['icon']!,
//               label:    v['name']!,
//               selected: sel,
//               isDark:   isDark,
//               onTap: () => setState(() => selectedCrop = v['name']),
//             );
//           },
//         ),
//         const SizedBox(height: 22),
//         _stepHeading('What type of soil do you have?', isDark),
//         const SizedBox(height: 12),
//         // Soil grid
//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount:   2,
//             mainAxisSpacing:  8,
//             crossAxisSpacing: 8,
//             childAspectRatio: 2.8,
//           ),
//           itemCount: _soilTypes.length,
//           itemBuilder: (_, i) {
//             final s   = _soilTypes[i];
//             final sel = selectedSoil == s['value'];
//             return GestureDetector(
//               onTap: () {
//                 HapticFeedback.selectionClick();
//                 setState(() => selectedSoil = s['value']);
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 180),
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 10, vertical: 8),
//                 decoration: _selectionDecoration(sel, isDark),
//                 child: Row(children: [
//                   Text(s['emoji']!,
//                       style: const TextStyle(fontSize: 18)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(s['label']!,
//                             style: TextStyle(
//                               fontSize:   12,
//                               fontWeight: FontWeight.bold,
//                               color: sel
//                                   ? (isDark ? Colors.greenAccent : _green)
//                                   : (isDark ? Colors.white : Colors.black87),
//                             )),
//                         Text(s['desc']!,
//                             style: TextStyle(
//                               fontSize: 9,
//                               color: isDark ? Colors.white38 : Colors.black38,
//                             )),
//                       ],
//                     ),
//                   ),
//                   if (sel)
//                     Icon(Icons.check_circle_rounded,
//                         color: _accent, size: 14),
//                 ]),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   // ── STEP 1 — District + Irrigation ───────────────────────────
//   Widget _buildStep1(bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _stepHeading('Which district is your farm in?', isDark),
//         const SizedBox(height: 12),
//         Wrap(
//           spacing: 8, runSpacing: 8,
//           children: _districts.map((d) {
//             final sel = selectedDistrict == d;
//             return GestureDetector(
//               onTap: () {
//                 HapticFeedback.selectionClick();
//                 setState(() => selectedDistrict = d);
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 180),
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 14, vertical: 9),
//                 decoration: BoxDecoration(
//                   color: sel
//                       ? _accent.withOpacity(isDark ? 0.2 : 0.1)
//                       : isDark
//                           ? Colors.white.withOpacity(0.06)
//                           : Colors.white,
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(
//                     color: sel
//                         ? _accent.withOpacity(0.55)
//                         : isDark ? Colors.white12 : Colors.grey.shade200,
//                     width: sel ? 1.5 : 1.0,
//                   ),
//                   boxShadow: sel ? [] : [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
//                       blurRadius: 4, offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Text(d,
//                     style: TextStyle(
//                       fontSize:   13,
//                       fontWeight: sel ? FontWeight.bold : FontWeight.normal,
//                       color: sel
//                           ? (isDark ? Colors.greenAccent : _green)
//                           : (isDark ? Colors.white70 : Colors.black54),
//                     )),
//               ),
//             );
//           }).toList(),
//         ),
//         const SizedBox(height: 22),
//         _stepHeading('How do you water your crops?', isDark),
//         const SizedBox(height: 4),
//         Text('Affects which treatments are safe to apply',
//             style: TextStyle(
//               fontSize: 11,
//               color: isDark ? Colors.white38 : Colors.black38,
//             )),
//         const SizedBox(height: 12),
//         // 2×2 irrigation grid
//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount:   2,
//             mainAxisSpacing:  8,
//             crossAxisSpacing: 8,
//             childAspectRatio: 2.2,
//           ),
//           itemCount: _irrigationMethods.length,
//           itemBuilder: (_, i) {
//             final m   = _irrigationMethods[i];
//             final sel = selectedIrrigation == m['value'];
//             return GestureDetector(
//               onTap: () {
//                 HapticFeedback.selectionClick();
//                 setState(() => selectedIrrigation = m['value']);
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 180),
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 12, vertical: 10),
//                 decoration: _selectionDecoration(sel, isDark),
//                 child: Row(children: [
//                   Text(m['emoji']!,
//                       style: const TextStyle(fontSize: 22)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(m['label']!,
//                             style: TextStyle(
//                               fontSize:   12,
//                               fontWeight: FontWeight.bold,
//                               color: sel
//                                   ? (isDark ? Colors.greenAccent : _green)
//                                   : (isDark ? Colors.white : Colors.black87),
//                             )),
//                         Text(m['desc']!,
//                             style: TextStyle(
//                               fontSize: 9,
//                               color: isDark ? Colors.white38 : Colors.black38,
//                             )),
//                       ],
//                     ),
//                   ),
//                 ]),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   // ── STEP 2 — Dates ────────────────────────────────────────────
//   Widget _buildStep2(bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _stepHeading('When did you plant?', isDark),
//         Text('Determines your current growth stage for accurate advice.',
//             style: TextStyle(
//               fontSize: 12, height: 1.4,
//               color: isDark ? Colors.white38 : Colors.black38,
//             )),
//         const SizedBox(height: 14),
//         _dateTile(
//           value:       plantingDate,
//           placeholder: 'Select planting date',
//           icon:        Icons.calendar_today_outlined,
//           isDark:      isDark,
//           required:    true,
//           onTap: () async {
//             final p = await showDatePicker(
//               context:     context,
//               initialDate: DateTime.now(),
//               firstDate:   DateTime(2020),
//               lastDate:    DateTime.now(),
//               builder:     (c, child) => _dpTheme(c, child, isDark),
//             );
//             if (p != null) setState(() => plantingDate = p);
//           },
//         ),
//         const SizedBox(height: 22),
//         Row(children: [
//           _stepHeading('Expected harvest date', isDark),
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(
//                 horizontal: 8, vertical: 2),
//             decoration: BoxDecoration(
//               color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text('Optional',
//                 style: TextStyle(
//                   fontSize: 9,
//                   color: isDark ? Colors.white38 : Colors.black38,
//                 )),
//           ),
//         ]),
//         const SizedBox(height: 4),
//         Text('Prevents unsafe treatments near harvest time.',
//             style: TextStyle(
//               fontSize: 12, height: 1.4,
//               color: isDark ? Colors.white38 : Colors.black38,
//             )),
//         const SizedBox(height: 14),
//         _dateTile(
//           value:       expectedHarvestDate,
//           placeholder: 'Select expected harvest date',
//           icon:        Icons.event_available_outlined,
//           isDark:      isDark,
//           required:    false,
//           onTap: () async {
//             final p = await showDatePicker(
//               context: context,
//               initialDate: plantingDate?.add(const Duration(days: 60)) ??
//                   DateTime.now().add(const Duration(days: 60)),
//               firstDate: DateTime.now(),
//               lastDate:  DateTime.now().add(const Duration(days: 365)),
//               builder:   (c, child) => _dpTheme(c, child, isDark),
//             );
//             if (p != null) setState(() => expectedHarvestDate = p);
//           },
//         ),
//       ],
//     );
//   }

//   // ── STEP 3 — Details (all optional) ─────────────────────────
//   Widget _buildStep3(bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Plot size
//         _stepHeading('Plot size', isDark),
//         const SizedBox(height: 4),
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: isDark
//                 ? Colors.amber.withOpacity(0.08)
//                 : Colors.amber.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isDark
//                   ? Colors.amber.withOpacity(0.25)
//                   : Colors.amber.shade200,
//             ),
//           ),
//           child: Row(children: [
//             const Text('⚖️', style: TextStyle(fontSize: 18)),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 'Used to calculate exact dosage — e.g. "Apply 12.5g" instead of generic "25g per hectare".',
//                 style: TextStyle(
//                   fontSize: 12, height: 1.4,
//                   color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
//                 ),
//               ),
//             ),
//           ]),
//         ),
//         const SizedBox(height: 10),
//         _inputField(
//           ctrl:     _plotSizeCtrl,
//           hint:     'e.g. 0.5 hectares',
//           icon:     Icons.straighten_outlined,
//           isDark:   isDark,
//           keyboard: const TextInputType.numberWithOptions(decimal: true),
//         ),
//         const SizedBox(height: 8),
//         Wrap(spacing: 8, runSpacing: 6, children: [
//           _plotChip('0.1', '10×10m',      isDark),
//           _plotChip('0.25', 'Quarter ha', isDark),
//           _plotChip('0.5', 'Half ha',     isDark),
//           _plotChip('1.0', 'Full ha',     isDark),
//         ]),
//         const SizedBox(height: 22),
//         _stepHeading('Seed variety', isDark),
//         const SizedBox(height: 4),
//         Text('e.g. Roma VF, Money Maker, Star 9006',
//             style: TextStyle(
//               fontSize: 11,
//               color: isDark ? Colors.white38 : Colors.black38,
//             )),
//         const SizedBox(height: 10),
//         _inputField(
//           ctrl:   _seedCtrl,
//           hint:   'Enter seed variety name',
//           icon:   Icons.grass_outlined,
//           isDark: isDark,
//         ),
//         const SizedBox(height: 22),
//         _stepHeading('Farm notes', isDark),
//         const SizedBox(height: 4),
//         Text('Anything useful — inputs applied, observations, etc.',
//             style: TextStyle(
//               fontSize: 11,
//               color: isDark ? Colors.white38 : Colors.black38,
//             )),
//         const SizedBox(height: 10),
//         _inputField(
//           ctrl:     _notesCtrl,
//           hint:     'e.g. Applied compost 2 weeks ago, noticed yellowing on outer leaves',
//           icon:     Icons.notes_outlined,
//           isDark:   isDark,
//           maxLines: 4,
//         ),
//       ],
//     );
//   }

//   // ── BOTTOM NAV ─────────────────────────────────────────────────
//   Widget _buildBottomNav(bool isDark, double bottom) {
//     final isLast = _step == _totalSteps - 1;
//     return Container(
//       padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
//             blurRadius: 12,
//             offset: const Offset(0, -3),
//           ),
//         ],
//       ),
//       child: Row(children: [
//         // Back button
//         if (_step > 0) ...[
//           OutlinedButton(
//             onPressed: _goBack,
//             style: OutlinedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 20, vertical: 14),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14)),
//               side: BorderSide(
//                   color: isDark ? Colors.white24 : Colors.grey.shade300),
//             ),
//             child: const Icon(Icons.arrow_back_rounded),
//           ),
//           const SizedBox(width: 12),
//         ],
//         // Next / Save
//         Expanded(
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 250),
//             height: 52,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(14),
//               gradient: _stepValid && !_isLoading
//                   ? const LinearGradient(
//                       colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
//                       begin: Alignment.topLeft,
//                       end:   Alignment.bottomRight,
//                     )
//                   : null,
//               color: !_stepValid || _isLoading
//                   ? (isDark ? Colors.white12 : Colors.grey.shade300)
//                   : null,
//               boxShadow: _stepValid && !_isLoading
//                   ? [
//                       BoxShadow(
//                         color:      _accent.withOpacity(0.35),
//                         blurRadius: 12,
//                         offset:     const Offset(0, 4),
//                       ),
//                     ]
//                   : [],
//             ),
//             child: ElevatedButton(
//               onPressed: _isLoading ? null : _goNext,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 shadowColor:     Colors.transparent,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14)),
//               ),
//               child: _isLoading
//                   ? const SizedBox(
//                       width: 22, height: 22,
//                       child: CircularProgressIndicator(
//                           color: Colors.white, strokeWidth: 2.5))
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           isLast ? 'Save & Analyse' : 'Continue',
//                           style: TextStyle(
//                             fontSize:   15,
//                             fontWeight: FontWeight.bold,
//                             color: _stepValid
//                                 ? Colors.white
//                                 : (isDark ? Colors.white38 : Colors.grey),
//                           ),
//                         ),
//                         if (_stepValid) ...[
//                           const SizedBox(width: 6),
//                           Icon(
//                             isLast
//                                 ? Icons.check_rounded
//                                 : Icons.arrow_forward_rounded,
//                             color: Colors.white, size: 18,
//                           ),
//                         ],
//                       ],
//                     ),
//             ),
//           ),
//         ),
//       ]),
//     );
//   }

//   // ── SHARED WIDGETS ─────────────────────────────────────────────

//   Widget _stepHeading(String text, bool isDark) => Text(
//         text,
//         style: TextStyle(
//           fontSize:   15,
//           fontWeight: FontWeight.bold,
//           color: isDark ? Colors.white : Colors.black87,
//           letterSpacing: -0.2,
//         ),
//       );

//   BoxDecoration _selectionDecoration(bool selected, bool isDark) =>
//       BoxDecoration(
//         color: selected
//             ? _accent.withOpacity(isDark ? 0.18 : 0.08)
//             : isDark
//                 ? Colors.white.withOpacity(0.05)
//                 : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: selected
//               ? _accent.withOpacity(isDark ? 0.6 : 0.45)
//               : isDark ? Colors.white12 : Colors.grey.shade200,
//           width: selected ? 1.5 : 1.0,
//         ),
//         boxShadow: selected ? [] : [
//           BoxShadow(
//             color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
//             blurRadius: 4, offset: const Offset(0, 2),
//           ),
//         ],
//       );

//   Widget _selectTile({
//     required String       emoji,
//     required String       label,
//     required bool         selected,
//     required bool         isDark,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: () { HapticFeedback.selectionClick(); onTap(); },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         decoration: _selectionDecoration(selected, isDark),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(emoji, style: const TextStyle(fontSize: 24)),
//             const SizedBox(height: 3),
//             Text(label,
//                 textAlign: TextAlign.center,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize:   9,
//                   fontWeight: selected
//                       ? FontWeight.bold
//                       : FontWeight.normal,
//                   color: selected
//                       ? (isDark ? Colors.greenAccent : _green)
//                       : (isDark ? Colors.white60 : Colors.black45),
//                 )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _dateTile({
//     required DateTime?    value,
//     required String       placeholder,
//     required IconData     icon,
//     required bool         isDark,
//     required bool         required,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(
//             horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: value != null
//               ? _accent.withOpacity(isDark ? 0.12 : 0.06)
//               : isDark ? Colors.white.withOpacity(0.05) : Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: value != null
//                 ? _accent.withOpacity(isDark ? 0.45 : 0.3)
//                 : isDark ? Colors.white12 : Colors.grey.shade200,
//           ),
//           boxShadow: value == null ? [
//             BoxShadow(
//               color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
//               blurRadius: 6, offset: const Offset(0, 2),
//             ),
//           ] : [],
//         ),
//         child: Row(children: [
//           Icon(icon,
//               color: value != null ? _accent : Colors.grey,
//               size: 20),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   value == null
//                       ? placeholder
//                       : DateFormat('dd MMMM yyyy').format(value),
//                   style: TextStyle(
//                     fontSize:   14,
//                     fontWeight: value != null
//                         ? FontWeight.w600
//                         : FontWeight.normal,
//                     color: value == null
//                         ? (isDark ? Colors.white38 : Colors.black38)
//                         : (isDark ? Colors.white : Colors.black87),
//                   ),
//                 ),
//                 if (value != null && value.isAfter(DateTime.now()))
//                   Text(
//                     '${value.difference(DateTime.now()).inDays} days from today',
//                     style: const TextStyle(
//                         fontSize: 11, color: Colors.green),
//                   ),
//               ],
//             ),
//           ),
//           Icon(
//             value != null
//                 ? Icons.edit_calendar_outlined
//                 : Icons.chevron_right_rounded,
//             color: Colors.grey.shade400, size: 18,
//           ),
//         ]),
//       ),
//     );
//   }

//   Widget _inputField({
//     required TextEditingController ctrl,
//     required String   hint,
//     required IconData icon,
//     required bool     isDark,
//     int maxLines = 1,
//     TextInputType keyboard = TextInputType.text,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: isDark
//             ? Colors.white.withOpacity(0.05)
//             : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//             color: isDark ? Colors.white12 : Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
//             blurRadius: 6, offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller:   ctrl,
//         maxLines:     maxLines,
//         keyboardType: keyboard,
//         onChanged:    (_) => setState(() {}),
//         style: TextStyle(
//             fontSize: 14,
//             color: isDark ? Colors.white : Colors.black87),
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: _accent, size: 20),
//           prefixIconConstraints: maxLines > 1
//               ? const BoxConstraints(minWidth: 48, minHeight: 48) : null,
//           hintText:  hint,
//           hintStyle: TextStyle(
//               fontSize: 13,
//               color: isDark ? Colors.white30 : Colors.grey.shade400),
//           border:         InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(
//               vertical: maxLines > 1 ? 14 : 16, horizontal: 4),
//         ),
//       ),
//     );
//   }

//   Widget _plotChip(String size, String label, bool isDark) {
//     return GestureDetector(
//       onTap: () {
//         HapticFeedback.selectionClick();
//         setState(() => _plotSizeCtrl.text = size);
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: isDark
//               ? Colors.white.withOpacity(0.07)
//               : Colors.green.withOpacity(0.06),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//               color: isDark
//                   ? Colors.white24
//                   : Colors.green.withOpacity(0.22)),
//         ),
//         child: RichText(
//           text: TextSpan(children: [
//             TextSpan(text: '$size ha',
//                 style: TextStyle(
//                   fontSize:   12,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.greenAccent : _green,
//                 )),
//             TextSpan(text: '  $label',
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: isDark ? Colors.white38 : Colors.grey.shade500,
//                 )),
//           ]),
//         ),
//       ),
//     );
//   }

//   Widget _pendingBanner(bool isDark) => Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isDark
//                 ? [Colors.green.withOpacity(0.12),
//                    Colors.green.withOpacity(0.06)]
//                 : [Colors.green.shade50, const Color(0xFFF0FBF0)],
//           ),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//               color: isDark
//                   ? Colors.greenAccent.withOpacity(0.25)
//                   : Colors.green.shade200),
//         ),
//         child: Row(children: [
//           const Text('🔍', style: TextStyle(fontSize: 20)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               'Complete your profile to get personalised AI advice for your scan.',
//               style: TextStyle(
//                 fontSize:   13,
//                 height:     1.4,
//                 fontWeight: FontWeight.w600,
//                 color: isDark ? Colors.greenAccent : Colors.green,
//               ),
//             ),
//           ),
//         ]),
//       );

//   Widget _dpTheme(BuildContext ctx, Widget? child, bool isDark) =>
//       Theme(
//         data: isDark
//             ? ThemeData.dark().copyWith(
//                 colorScheme: const ColorScheme.dark(
//                   primary: Colors.green, onPrimary: Colors.white,
//                   surface: Color(0xFF1E1E1E), onSurface: Colors.white,
//                 ))
//             : ThemeData.light().copyWith(
//                 colorScheme: const ColorScheme.light(primary: Colors.green)),
//         child: child!,
//       );
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _CropTypeScreenState extends State<CropTypeScreen>
    with TickerProviderStateMixin {

  final AuthService _auth = AuthService();
  bool _isLoading = false;

  // ── Wizard step ────────────────────────────────────────────────
  int _step = 0;  // 0..3
  static const _totalSteps = 4;

  // Step labels shown in the header indicator
  static const _stepLabels = ['Crop', 'Location', 'Dates', 'Details'];

  // ── Form state ─────────────────────────────────────────────────
  String?   selectedCrop;
  String?   selectedSoil;
  String?   selectedDistrict;
  String?   selectedIrrigation;
  DateTime? plantingDate;
  DateTime? expectedHarvestDate;
  final _seedCtrl     = TextEditingController();
  final _notesCtrl    = TextEditingController();
  final _plotSizeCtrl = TextEditingController();

  // ── Animation ──────────────────────────────────────────────────
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideIn;

  static const _green  = Color(0xFF1B5E20);
  static const _accent = Color(0xFF2E7D32);

  // ── Data ───────────────────────────────────────────────────────
  final _vegetables = const [
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

  final _soilTypes = const [
    {'value': 'loam',       'emoji': '🌱', 'label': 'Loamy',      'desc': 'Rich, well-draining'},
    {'value': 'sandy',      'emoji': '🏜️', 'label': 'Sandy',       'desc': 'Fast-draining, low nutrients'},
    {'value': 'clay',       'emoji': '🧱', 'label': 'Clayey',      'desc': 'Heavy, good nutrient retention'},
    {'value': 'sandy_loam', 'emoji': '⚖️', 'label': 'Sandy Loam',  'desc': 'Good balance of drainage'},
    {'value': 'clay_loam',  'emoji': '💧', 'label': 'Clay Loam',   'desc': 'Moderate water retention'},
    {'value': 'silt',       'emoji': '🇱🇸', 'label': 'Silt',        'desc': 'Duplex / Lesotho Special'},
  ];

  final _districts = const [
    'Maseru', 'Leribe', 'Berea', 'Mafeteng', "Mohale's Hoek",
    'Quthing', "Qacha's Nek", 'Mokhotlong', 'Butha-Buthe', 'Thaba-Tseka',
  ];

  final _irrigationMethods = const [
    {'value': 'drip',      'emoji': '💧', 'label': 'Drip',       'desc': 'Lowest disease risk'},
    {'value': 'sprinkler', 'emoji': '🚿', 'label': 'Sprinkler',  'desc': 'Raises fungal risk'},
    {'value': 'flood',     'emoji': '🌊', 'label': 'Flood',      'desc': 'Flow between rows'},
    {'value': 'rain',      'emoji': '🌧',  'label': 'Rain-fed',   'desc': 'Relies on rainfall'},
  ];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slideIn = Tween<Offset>(
      begin: const Offset(0.08, 0), end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _seedCtrl.dispose();
    _notesCtrl.dispose();
    _plotSizeCtrl.dispose();
    super.dispose();
  }

  // ── Step validation ────────────────────────────────────────────
  bool get _stepValid {
    switch (_step) {
      case 0: return selectedCrop != null && selectedSoil != null;
      case 1: return selectedDistrict != null && selectedIrrigation != null;
      case 2: return plantingDate != null;
      case 3: return true; // all optional
      default: return false;
    }
  }

  void _goNext() {
    if (!_stepValid) {
      _showSnack(_step == 2
          ? 'Please select a planting date'
          : 'Please complete all fields on this step');
      return;
    }
    if (_step < _totalSteps - 1) {
      HapticFeedback.selectionClick();
      setState(() => _step++);
      _slideCtrl.forward(from: 0);
    } else {
      _saveProfile();
    }
  }

  void _goBack() {
    if (_step > 0) {
      HapticFeedback.selectionClick();
      setState(() => _step--);
      _slideCtrl.forward(from: 0);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Save ───────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final token = await _auth.getToken();
      final body  = <String, dynamic>{
        'VegetableType':     selectedCrop,
        'SoilEnvironment':   selectedSoil,
        'PlantingDate':      DateFormat('yyyy-MM-dd').format(plantingDate!),
        'IsActive':          true,
        'irrigation_method': selectedIrrigation,
        if (expectedHarvestDate != null)
          'expected_harvest_date':
              DateFormat('yyyy-MM-dd').format(expectedHarvestDate!),
        if (_seedCtrl.text.trim().isNotEmpty)
          'seed_variety': _seedCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty)
          'notes': _notesCtrl.text.trim(),
        if (double.tryParse(_plotSizeCtrl.text.trim()) != null)
          'plot_size_hectares': double.parse(_plotSizeCtrl.text.trim()),
      };

      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/crop-profiles/'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(body),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        final json = jsonDecode(res.body);
        final id   = json['ProfileID']?.toString() ?? json['id']?.toString();
        _showSuccessSheet(id);
      } else {
        throw Exception('${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : _accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccessSheet(String? profileId) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            28, 28, 28, MediaQuery.of(context).padding.bottom + 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: _accent.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
          Text('Profile Saved!',
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              )),
          const SizedBox(height: 8),
          Text(
            'Your $selectedCrop profile is ready.\nThe AI will now give personalised advice for your farm.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, height: 1.55,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, profileId);
              },
              child: const Text('Start AI Analysis',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).isDarkMode;
    final isWide = MediaQuery.of(context).size.width > 600;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF0FBF0),
      body: SafeArea(
        child: isWide
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _buildWizard(isDark, bottom),
                ),
              )
            : _buildWizard(isDark, bottom),
      ),
    );
  }

  Widget _buildWizard(bool isDark, double bottom) {
    return Column(children: [
      // ── Top bar ──────────────────────────────────────────────
      _buildTopBar(isDark),

      // ── Step indicator ────────────────────────────────────────
      _buildStepIndicator(isDark),

      // ── Step content (scrollable) ─────────────────────────────
      Expanded(
        child: SlideTransition(
          position: _slideIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _buildStepContent(isDark),
          ),
        ),
      ),

      // ── Bottom nav buttons ────────────────────────────────────
      _buildBottomNav(isDark, bottom),
    ]);
  }

  // ── TOP BAR ────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: _goBack,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size:  16,
                color: isDark ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Farm Profile Setup',
                  style: TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.greenAccent : _green,
                  )),
              Text('Personalise your AI recommendations',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  )),
            ],
          ),
        ),
        // Step counter pill
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_step + 1} / $_totalSteps',
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.greenAccent : _accent,
            ),
          ),
        ),
      ]),
    );
  }

  // ── STEP INDICATOR (dot + label) ───────────────────────────────
  Widget _buildStepIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(children: List.generate(_totalSteps, (i) {
        final done    = i < _step;
        final current = i == _step;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                // Dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: done
                        ? _accent
                        : current
                            ? _accent.withOpacity(0.5)
                            : isDark
                                ? Colors.white12
                                : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _stepLabels[i],
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: current
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: done || current
                        ? (isDark ? Colors.greenAccent : _accent)
                        : (isDark ? Colors.white30 : Colors.black38),
                  ),
                ),
              ]),
            ),
            if (i < _totalSteps - 1) const SizedBox(width: 6),
          ]),
        );
      })),
    );
  }

  // ── STEP CONTENT ───────────────────────────────────────────────
  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case 0: return _buildStep0(isDark);
      case 1: return _buildStep1(isDark);
      case 2: return _buildStep2(isDark);
      case 3: return _buildStep3(isDark);
      default: return const SizedBox.shrink();
    }
  }

  // ── STEP 0 — Crop + Soil ──────────────────────────────────────
  Widget _buildStep0(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.pendingImage != null) ...[
          _pendingBanner(isDark),
          const SizedBox(height: 16),
        ],
        _stepHeading('Which crop are you growing?', isDark),
        const SizedBox(height: 12),
        // Vegetable grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   4,
            mainAxisSpacing:  8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemCount: _vegetables.length,
          itemBuilder: (_, i) {
            final v = _vegetables[i];
            final sel = selectedCrop == v['name'];
            return _selectTile(
              emoji:    v['icon']!,
              label:    v['name']!,
              selected: sel,
              isDark:   isDark,
              onTap: () => setState(() => selectedCrop = v['name']),
            );
          },
        ),
        const SizedBox(height: 22),
        _stepHeading('What type of soil do you have?', isDark),
        const SizedBox(height: 12),
        // Soil grid — FIX: increased childAspectRatio to give tiles more height
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   2,
            mainAxisSpacing:  8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2, // was 2.8 — extra height prevents 1px overflow
          ),
          itemCount: _soilTypes.length,
          itemBuilder: (_, i) {
            final s   = _soilTypes[i];
            final sel = selectedSoil == s['value'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => selectedSoil = s['value']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: _selectionDecoration(sel, isDark),
                child: Row(children: [
                  Text(s['emoji']!,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  // FIX: wrap Column in Flexible so it can't overflow its parent Row
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // FIX: don't expand beyond needed height
                      children: [
                        Text(
                          s['label']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.bold,
                            color: sel
                                ? (isDark ? Colors.greenAccent : _green)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        Text(
                          s['desc']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sel)
                    Icon(Icons.check_circle_rounded,
                        color: _accent, size: 14),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── STEP 1 — District + Irrigation ───────────────────────────
  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading('Which district is your farm in?', isDark),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _districts.map((d) {
            final sel = selectedDistrict == d;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => selectedDistrict = d);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel
                      ? _accent.withOpacity(isDark ? 0.2 : 0.1)
                      : isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sel
                        ? _accent.withOpacity(0.55)
                        : isDark ? Colors.white12 : Colors.grey.shade200,
                    width: sel ? 1.5 : 1.0,
                  ),
                  boxShadow: sel ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
                      blurRadius: 4, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(d,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      color: sel
                          ? (isDark ? Colors.greenAccent : _green)
                          : (isDark ? Colors.white70 : Colors.black54),
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        _stepHeading('How do you water your crops?', isDark),
        const SizedBox(height: 4),
        Text('Affects which treatments are safe to apply',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
        const SizedBox(height: 12),
        // Irrigation grid — FIX: increased childAspectRatio to give tiles more height
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   2,
            mainAxisSpacing:  8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6, // was 2.2 — extra height prevents 1px overflow
          ),
          itemCount: _irrigationMethods.length,
          itemBuilder: (_, i) {
            final m   = _irrigationMethods[i];
            final sel = selectedIrrigation == m['value'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => selectedIrrigation = m['value']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: _selectionDecoration(sel, isDark),
                child: Row(children: [
                  Text(m['emoji']!,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  // FIX: wrap Column in Flexible so it can't overflow its parent Row
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // FIX: don't expand beyond needed height
                      children: [
                        Text(
                          m['label']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.bold,
                            color: sel
                                ? (isDark ? Colors.greenAccent : _green)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        Text(
                          m['desc']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── STEP 2 — Dates ────────────────────────────────────────────
  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading('When did you plant?', isDark),
        Text('Determines your current growth stage for accurate advice.',
            style: TextStyle(
              fontSize: 12, height: 1.4,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
        const SizedBox(height: 14),
        _dateTile(
          value:       plantingDate,
          placeholder: 'Select planting date',
          icon:        Icons.calendar_today_outlined,
          isDark:      isDark,
          required:    true,
          onTap: () async {
            final p = await showDatePicker(
              context:     context,
              initialDate: DateTime.now(),
              firstDate:   DateTime(2020),
              lastDate:    DateTime.now(),
              builder:     (c, child) => _dpTheme(c, child, isDark),
            );
            if (p != null) setState(() => plantingDate = p);
          },
        ),
        const SizedBox(height: 22),
        Row(children: [
          _stepHeading('Expected harvest date', isDark),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Optional',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white38 : Colors.black38,
                )),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Prevents unsafe treatments near harvest time.',
            style: TextStyle(
              fontSize: 12, height: 1.4,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
        const SizedBox(height: 14),
        _dateTile(
          value:       expectedHarvestDate,
          placeholder: 'Select expected harvest date',
          icon:        Icons.event_available_outlined,
          isDark:      isDark,
          required:    false,
          onTap: () async {
            final p = await showDatePicker(
              context: context,
              initialDate: plantingDate?.add(const Duration(days: 60)) ??
                  DateTime.now().add(const Duration(days: 60)),
              firstDate: DateTime.now(),
              lastDate:  DateTime.now().add(const Duration(days: 365)),
              builder:   (c, child) => _dpTheme(c, child, isDark),
            );
            if (p != null) setState(() => expectedHarvestDate = p);
          },
        ),
      ],
    );
  }

  // ── STEP 3 — Details (all optional) ─────────────────────────
  Widget _buildStep3(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plot size
        _stepHeading('Plot size', isDark),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.amber.withOpacity(0.08)
                : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.amber.withOpacity(0.25)
                  : Colors.amber.shade200,
            ),
          ),
          child: Row(children: [
            const Text('⚖️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Used to calculate exact dosage — e.g. "Apply 12.5g" instead of generic "25g per hectare".',
                style: TextStyle(
                  fontSize: 12, height: 1.4,
                  color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        _inputField(
          ctrl:     _plotSizeCtrl,
          hint:     'e.g. 0.5 hectares',
          icon:     Icons.straighten_outlined,
          isDark:   isDark,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _plotChip('0.1', '10×10m',      isDark),
          _plotChip('0.25', 'Quarter ha', isDark),
          _plotChip('0.5', 'Half ha',     isDark),
          _plotChip('1.0', 'Full ha',     isDark),
        ]),
        const SizedBox(height: 22),
        _stepHeading('Seed variety', isDark),
        const SizedBox(height: 4),
        Text('e.g. Roma VF, Money Maker, Star 9006',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
        const SizedBox(height: 10),
        _inputField(
          ctrl:   _seedCtrl,
          hint:   'Enter seed variety name',
          icon:   Icons.grass_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 22),
        _stepHeading('Farm notes', isDark),
        const SizedBox(height: 4),
        Text('Anything useful — inputs applied, observations, etc.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
        const SizedBox(height: 10),
        _inputField(
          ctrl:     _notesCtrl,
          hint:     'e.g. Applied compost 2 weeks ago, noticed yellowing on outer leaves',
          icon:     Icons.notes_outlined,
          isDark:   isDark,
          maxLines: 4,
        ),
      ],
    );
  }

  // ── BOTTOM NAV ─────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark, double bottom) {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(children: [
        // Back button
        if (_step > 0) ...[
          OutlinedButton(
            onPressed: _goBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
        ],
        // Next / Save
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: _stepValid && !_isLoading
                  ? const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    )
                  : null,
              color: !_stepValid || _isLoading
                  ? (isDark ? Colors.white12 : Colors.grey.shade300)
                  : null,
              boxShadow: _stepValid && !_isLoading
                  ? [
                      BoxShadow(
                        color:      _accent.withOpacity(0.35),
                        blurRadius: 12,
                        offset:     const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor:     Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Save & Analyse' : 'Continue',
                          style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.bold,
                            color: _stepValid
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.grey),
                          ),
                        ),
                        if (_stepValid) ...[
                          const SizedBox(width: 6),
                          Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── SHARED WIDGETS ─────────────────────────────────────────────

  Widget _stepHeading(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize:   15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
          letterSpacing: -0.2,
        ),
      );

  BoxDecoration _selectionDecoration(bool selected, bool isDark) =>
      BoxDecoration(
        color: selected
            ? _accent.withOpacity(isDark ? 0.18 : 0.08)
            : isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? _accent.withOpacity(isDark ? 0.6 : 0.45)
              : isDark ? Colors.white12 : Colors.grey.shade200,
          width: selected ? 1.5 : 1.0,
        ),
        boxShadow: selected ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 4, offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _selectTile({
    required String       emoji,
    required String       label,
    required bool         selected,
    required bool         isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: _selectionDecoration(selected, isDark),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // FIX: prevent vertical expansion
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:   9,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected
                        ? (isDark ? Colors.greenAccent : _green)
                        : (isDark ? Colors.white60 : Colors.black45),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile({
    required DateTime?    value,
    required String       placeholder,
    required IconData     icon,
    required bool         isDark,
    required bool         required,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value != null
              ? _accent.withOpacity(isDark ? 0.12 : 0.06)
              : isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value != null
                ? _accent.withOpacity(isDark ? 0.45 : 0.3)
                : isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: value == null ? [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Row(children: [
          Icon(icon,
              color: value != null ? _accent : Colors.grey,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // FIX: prevent vertical expansion
              children: [
                Text(
                  value == null
                      ? placeholder
                      : DateFormat('dd MMMM yyyy').format(value),
                  style: TextStyle(
                    fontSize:   14,
                    fontWeight: value != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: value == null
                        ? (isDark ? Colors.white38 : Colors.black38)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                if (value != null && value.isAfter(DateTime.now()))
                  Text(
                    '${value.difference(DateTime.now()).inDays} days from today',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.green),
                  ),
              ],
            ),
          ),
          Icon(
            value != null
                ? Icons.edit_calendar_outlined
                : Icons.chevron_right_rounded,
            color: Colors.grey.shade400, size: 18,
          ),
        ]),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController ctrl,
    required String   hint,
    required IconData icon,
    required bool     isDark,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller:   ctrl,
        maxLines:     maxLines,
        keyboardType: keyboard,
        onChanged:    (_) => setState(() {}),
        style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _accent, size: 20),
          prefixIconConstraints: maxLines > 1
              ? const BoxConstraints(minWidth: 48, minHeight: 48) : null,
          hintText:  hint,
          hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.grey.shade400),
          border:         InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              vertical: maxLines > 1 ? 14 : 16, horizontal: 4),
        ),
      ),
    );
  }

  Widget _plotChip(String size, String label, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _plotSizeCtrl.text = size);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.green.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white24
                  : Colors.green.withOpacity(0.22)),
        ),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(text: '$size ha',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.greenAccent : _green,
                )),
            TextSpan(text: '  $label',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                )),
          ]),
        ),
      ),
    );
  }

  Widget _pendingBanner(bool isDark) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.green.withOpacity(0.12),
                   Colors.green.withOpacity(0.06)]
                : [Colors.green.shade50, const Color(0xFFF0FBF0)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.greenAccent.withOpacity(0.25)
                  : Colors.green.shade200),
        ),
        child: Row(children: [
          const Text('🔍', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Complete your profile to get personalised AI advice for your scan.',
              style: TextStyle(
                fontSize:   13,
                height:     1.4,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.greenAccent : Colors.green,
              ),
            ),
          ),
        ]),
      );

  Widget _dpTheme(BuildContext ctx, Widget? child, bool isDark) =>
      Theme(
        data: isDark
            ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.green, onPrimary: Colors.white,
                  surface: Color(0xFF1E1E1E), onSurface: Colors.white,
                ))
            : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: Colors.green)),
        child: child!,
      );
}