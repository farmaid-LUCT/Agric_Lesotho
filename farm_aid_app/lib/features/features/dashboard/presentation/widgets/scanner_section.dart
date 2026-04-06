// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// import '../../../scanner/data/ai_service.dart';
// import '../../../scanner/data/scanner_service.dart';
// import '../../../crops/presentation/crop_type_screen.dart';
// import '../../../../core/app_localizations.dart';
// import '../../../../services/gps_state.dart';

// import '../../../scanner/presentation/scanner_result_service.dart';

// class ScannerSection extends StatefulWidget {
//   final bool isGuest;

//   // GPS params — kept so existing callers don't break.
//   // Values are ALSO written to GpsState singleton by HomeDashboard,
//   // so ScannerSection reads from both sources (widget props first,
//   // singleton as fallback).
//   final double? gpsLatitude;
//   final double? gpsLongitude;
//   final double? gpsAltitude;
//   final String  gpsDistrict;

//   final Function(String) onAuthRequired;
//   final VoidCallback      onLoginSuccess;

//   const ScannerSection({
//     super.key,
//     required this.isGuest,
//     this.gpsLatitude,
//     this.gpsLongitude,
//     this.gpsAltitude,
//     this.gpsDistrict = '',
//     required this.onAuthRequired,
//     required this.onLoginSuccess,
//   });

//   @override
//   State<ScannerSection> createState() => _ScannerSectionState();
// }

// class _ScannerSectionState extends State<ScannerSection> {
//   final ScannerService _scannerService = ScannerService();
//   final ImagePicker    _picker         = ImagePicker();

//   File?      _selectedImage;
//   Uint8List? _imageBytes;

//   String t(String key) =>
//       AppLocalizations.of(context)?.translate(key) ?? key;

//   // ── GPS resolution ────────────────────────────────────────────
//   // Use widget props if provided, fall back to GpsState singleton.
//   double? get _lat      => widget.gpsLatitude  ?? GpsState.instance.latitude;
//   double? get _lon      => widget.gpsLongitude ?? GpsState.instance.longitude;
//   double? get _alt      => widget.gpsAltitude  ?? GpsState.instance.altitude;
//   String  get _district =>
//       widget.gpsDistrict.isNotEmpty
//           ? widget.gpsDistrict
//           : GpsState.instance.district;

//   // ── LIFECYCLE ─────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     AIService.loadModel();
//   }

//   // ── IMAGE SELECTION ───────────────────────────────────────────

//   Future<void> _handleImageAction(ImageSource source) async {
//     final XFile? pickedFile = await _picker.pickImage(
//         source: source, imageQuality: 70);
//     if (pickedFile != null) {
//       final Uint8List bytes = await pickedFile.readAsBytes();
//       setState(() {
//         _imageBytes    = bytes;
//         if (!kIsWeb) _selectedImage = File(pickedFile.path);
//       });
//     }
//   }

//   // ── ANALYSIS PROMPT ───────────────────────────────────────────

//   Future<void> _handleAnalyzePrompt() async {
//     if (_imageBytes == null) return;
//     if (widget.isGuest) {
//       widget.onAuthRequired(t('analyze'));
//       return;
//     }

//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color green =
//         isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

//     final String? action = await showDialog<String>(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15)),
//         title:   Text(t('analysis_title')),
//         content: Text(t('analysis_question')),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, 'general'),
//             child: Text(t('general_tips'),
//                 style: TextStyle(color: green)),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, 'personalize'),
//             style: ElevatedButton.styleFrom(backgroundColor: green),
//             child: Text(t('personalize'),
//                 style: const TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );

//     if (action == null) return;

//     if (action == 'general') {
//       _startAIAnalysis(isPersonalized: false);
//     } else {
//       // ── Personalized flow ────────────────────────────────────
//       // Always push CropTypeScreen so farmer fills in their farm
//       // details (soil, irrigation, plot size, planting date etc).
//       // CropTypeScreen POSTs to /crop-profiles/ and returns the
//       // new ProfileID via Navigator.pop(context, profileId).
//       // That ProfileID is then sent to SaveScanView which:
//       //   1. Matches the AI disease output against PersonalizedRule
//       //      table using all 9 factors (district, altitude, soil,
//       //      irrigation, growth stage, variety, season, rainfall)
//       //   2. Calculates exact dosage from Treatment table using
//       //      farmer's plot_size_hectares
//       //   3. Returns advice text adjusted for farmer experience
//       //      level (beginner gets simpler language)
//       final dynamic result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => CropTypeScreen(pendingImage: _imageBytes),
//         ),
//       );

//       if (!mounted) return;

//       // CropTypeScreen returns profileId as a plain String
//       String? profileId;
//       if (result is String && result.isNotEmpty) {
//         profileId = result;
//       } else if (result is Map) {
//         profileId = result['ProfileID']?.toString()
//             ?? result['id']?.toString();
//       }

//       if (profileId == null) {
//         // Farmer cancelled — do nothing, stay on scanner
//         return;
//       }

//       _startAIAnalysis(isPersonalized: true, forcedProfileId: profileId);
//     }
//   }

//   // ── CORE ANALYSIS FLOW ────────────────────────────────────────

//   Future<void> _startAIAnalysis({
//     required bool isPersonalized,
//     String? forcedProfileId,
//   }) async {
//     if (_imageBytes == null) return;

//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color green =
//         isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

//     // Show loading spinner
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) =>
//           Center(child: CircularProgressIndicator(color: green)),
//     );

//     try {
//       // ── 1. Local TFLite inference ───────────────────────────
//       final aiResult = await AIService.runInference(_imageBytes!);

//       if (aiResult['isRejected'] == true) {
//         if (mounted) Navigator.pop(context);
//         _showErrorSnackBar(aiResult['label']);
//         return;
//       }

//       // ── 2. Upload image to Supabase ─────────────────────────
//       String? publicUrl;
//       if (kIsWeb) {
//         publicUrl =
//             await _scannerService.uploadCropImageWeb(_imageBytes!);
//       } else {
//         if (_selectedImage == null) {
//           throw Exception('No image file found');
//         }
//         publicUrl =
//             await _scannerService.uploadCropImage(_selectedImage!);
//       }
//       if (publicUrl == null) throw Exception('Upload failed');

//       // ── 3. Save to Django backend ───────────────────────────
//       final backendResponse = await _scannerService.saveScanToBackend(
//         imageUrl:    publicUrl,
//         diseaseName: aiResult['label']      ?? 'Healthy',
//         confidence:  aiResult['confidence'] ?? 0.0,
//         profileId:   isPersonalized ? forcedProfileId : null,
//         latitude:    _lat,
//         longitude:   _lon,
//         altitude:    _alt,
//         district:    _district,
//         scanMode:    isPersonalized ? 'personalized' : 'general',
//       );

//       if (!mounted) return;
//       Navigator.pop(context); // close spinner

//       if (backendResponse == null) {
//         _showErrorSnackBar('Sync failed. Check your connection.');
//         return;
//       }

//       // ── DEBUG — print full backend response to Flutter console ──
//       print('🔍 [ScanDebug] full response: ${jsonEncode(backendResponse)}');
//       print('🔍 [ScanDebug] scan_mode sent: ${isPersonalized ? 'personalized' : 'general'}');
//       print('🔍 [ScanDebug] profileId sent: $forcedProfileId');
//       print('🔍 [ScanDebug] _debug block: ${backendResponse['_debug']}');

//       // ── 4. Extract diagnosis ID + follow-up date ────────────
//       // These are returned by the new save-scan endpoint and are
//       // needed to wire the feedback flow.
//       final int?      diagnosisId  = backendResponse['id'] as int?;
//       final DateTime? followUpDate = backendResponse['follow_up_date'] != null
//           ? DateTime.tryParse(
//               backendResponse['follow_up_date'].toString())
//           : null;
//       final String?   cropType =
//           backendResponse['crop_type']?.toString()
//           ?? forcedProfileId; // fallback

//       // ── 5. Show result using ScannerResultService ───────────
//       // Replaces old _showResultDialog AlertDialog.
//       // Passes diagnosisId so feedback nudge card is shown.
//       ScannerResultService.showResult(
//         context,
//         backendResponse,                // full response — service
//                                         // resolves all field names
//         diagnosisId:  diagnosisId,      // ← enables feedback card
//         cropType:     cropType,         // ← shown in feedback screen
//         followUpDate: followUpDate,     // ← shown in feedback nudge
//       );

//       // Clear image after successful scan
//       setState(() {
//         _imageBytes    = null;
//         _selectedImage = null;
//       });

//     } catch (e) {
//       if (mounted) Navigator.pop(context);
//       _showErrorSnackBar('Error: $e');
//     }
//   }

//   // ── BUILD ─────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(child: _buildScannerCard()),
//         const SizedBox(height: 25),
//         Row(
//           children: [
//             Expanded(
//               child: _buildActionButton(
//                 label:     t('upload'),
//                 icon:      Icons.file_upload_outlined,
//                 isPrimary: false,
//                 onTap: () => _handleImageAction(ImageSource.gallery),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildActionButton(
//                 label:     t('take_photo'),
//                 icon:      Icons.camera_alt_rounded,
//                 isPrimary: true,
//                 onTap: () => _handleImageAction(ImageSource.camera),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   // ── SCANNER CARD ─────────────────────────────────────────────

//   Widget _buildScannerCard() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color green =
//         isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black
//                   .withOpacity(isDark ? 0.3 : 0.05),
//               blurRadius: 10)
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: _imageBytes != null
//             ? Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   InteractiveViewer(
//                     child: Image.memory(_imageBytes!,
//                         fit: BoxFit.cover),
//                   ),
//                   // Clear button
//                   Positioned(
//                     top: 10,
//                     right: 10,
//                     child: IconButton(
//                       onPressed: () =>
//                           setState(() => _imageBytes = null),
//                       icon: const CircleAvatar(
//                         backgroundColor: Colors.white70,
//                         child: Icon(Icons.close,
//                             color: Colors.red),
//                       ),
//                     ),
//                   ),
//                   // Analyze button overlay
//                   Positioned(
//                     bottom: 20,
//                     left: 50,
//                     right: 50,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: isDark
//                             ? Colors.black54
//                             : Colors.white.withOpacity(0.95),
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: TextButton(
//                         onPressed: _handleAnalyzePrompt,
//                         child: Text(
//                           t('analyze'),
//                           style: TextStyle(
//                             color: green,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//             // Empty state
//             : Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.document_scanner_outlined,
//                         size: 64,
//                         color: green.withOpacity(0.4)),
//                     const SizedBox(height: 16),
//                     Text(
//                       t('placeholder'),
//                       style: TextStyle(color: green),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }

//   // ── BUTTONS ───────────────────────────────────────────────────

//   Widget _buildActionButton({
//     required String   label,
//     required IconData icon,
//     required bool     isPrimary,
//     required VoidCallback onTap,
//   }) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     final style = isPrimary
//         ? ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF00A844),
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12)),
//           )
//         : OutlinedButton.styleFrom(
//             side: BorderSide(
//                 color: isDark
//                     ? Colors.green.shade800
//                     : Colors.green.shade200),
//             foregroundColor:
//                 isDark ? Colors.greenAccent : Colors.green,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12)),
//           );

//     return SizedBox(
//       height: 55,
//       child: isPrimary
//           ? ElevatedButton.icon(
//               onPressed: onTap,
//               icon:  Icon(icon),
//               label: Text(label),
//               style: style,
//             )
//           : OutlinedButton.icon(
//               onPressed: onTap,
//               icon:  Icon(icon),
//               label: Text(label),
//               style: style,
//             ),
//     );
//   }

//   // ── ERROR ─────────────────────────────────────────────────────

//   void _showErrorSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(message),
//       backgroundColor: Colors.red,
//       behavior: SnackBarBehavior.floating,
//     ));
//   }
// }

// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// import '../../../scanner/data/ai_service.dart';
// import '../../../scanner/data/scanner_service.dart';
// import '../../../crops/presentation/crop_type_screen.dart';
// import '../../../../core/app_localizations.dart';
// import '../../../../services/gps_state.dart';

// import '../../../scanner/presentation/scanner_result_service.dart';
// import '../../../scanner/presentation/image_viewer.dart';

// class ScannerSection extends StatefulWidget {
//   final bool isGuest;

//   // GPS params — kept so existing callers don't break.
//   // Values are ALSO written to GpsState singleton by HomeDashboard,
//   // so ScannerSection reads from both sources (widget props first,
//   // singleton as fallback).
//   final double? gpsLatitude;
//   final double? gpsLongitude;
//   final double? gpsAltitude;
//   final String  gpsDistrict;

//   final Function(String) onAuthRequired;
//   final VoidCallback      onLoginSuccess;

//   const ScannerSection({
//     super.key,
//     required this.isGuest,
//     this.gpsLatitude,
//     this.gpsLongitude,
//     this.gpsAltitude,
//     this.gpsDistrict = '',
//     required this.onAuthRequired,
//     required this.onLoginSuccess,
//   });

//   @override
//   State<ScannerSection> createState() => _ScannerSectionState();
// }

// class _ScannerSectionState extends State<ScannerSection> {
//   final ScannerService _scannerService = ScannerService();
//   final ImagePicker    _picker         = ImagePicker();

//   File?      _selectedImage;
//   Uint8List? _imageBytes;
//   ImageTransform _imageTransform = ImageTransform.identity; // viewer state

//   String t(String key) =>
//       AppLocalizations.of(context)?.translate(key) ?? key;

//   // ── GPS resolution ────────────────────────────────────────────
//   // Use widget props if provided, fall back to GpsState singleton.
//   double? get _lat      => widget.gpsLatitude  ?? GpsState.instance.latitude;
//   double? get _lon      => widget.gpsLongitude ?? GpsState.instance.longitude;
//   double? get _alt      => widget.gpsAltitude  ?? GpsState.instance.altitude;
//   String  get _district =>
//       widget.gpsDistrict.isNotEmpty
//           ? widget.gpsDistrict
//           : GpsState.instance.district;

//   // ── LIFECYCLE ─────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     AIService.loadModel();
//   }

//   // ── IMAGE SELECTION ───────────────────────────────────────────

//   Future<void> _handleImageAction(ImageSource source) async {
//     final XFile? pickedFile = await _picker.pickImage(
//         source: source, imageQuality: 70);
//     if (pickedFile != null) {
//       final Uint8List bytes = await pickedFile.readAsBytes();
//       setState(() {
//         _imageBytes    = bytes;
//         if (!kIsWeb) _selectedImage = File(pickedFile.path);
//       });
//     }
//   }

//   // ── ANALYSIS PROMPT ───────────────────────────────────────────

//   Future<void> _handleAnalyzePrompt() async {
//     if (_imageBytes == null) return;
//     if (widget.isGuest) {
//       widget.onAuthRequired(t('analyze'));
//       return;
//     }

//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color green =
//         isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

//     final String? action = await showDialog<String>(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15)),
//         title:   Text(t('analysis_title')),
//         content: Text(t('analysis_question')),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, 'general'),
//             child: Text(t('general_tips'),
//                 style: TextStyle(color: green)),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, 'personalize'),
//             style: ElevatedButton.styleFrom(backgroundColor: green),
//             child: Text(t('personalize'),
//                 style: const TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );

//     if (action == null) return;

//     if (action == 'general') {
//       _startAIAnalysis(isPersonalized: false);
//     } else {
//       // ── Personalized flow ────────────────────────────────────
//       // Always push CropTypeScreen so farmer fills in their farm
//       // details (soil, irrigation, plot size, planting date etc).
//       // CropTypeScreen POSTs to /crop-profiles/ and returns the
//       // new ProfileID via Navigator.pop(context, profileId).
//       // That ProfileID is then sent to SaveScanView which:
//       //   1. Matches the AI disease output against PersonalizedRule
//       //      table using all 9 factors (district, altitude, soil,
//       //      irrigation, growth stage, variety, season, rainfall)
//       //   2. Calculates exact dosage from Treatment table using
//       //      farmer's plot_size_hectares
//       //   3. Returns advice text adjusted for farmer experience
//       //      level (beginner gets simpler language)
//       final dynamic result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => CropTypeScreen(pendingImage: _imageBytes),
//         ),
//       );

//       if (!mounted) return;

//       // CropTypeScreen returns profileId as a plain String
//       String? profileId;
//       if (result is String && result.isNotEmpty) {
//         profileId = result;
//       } else if (result is Map) {
//         profileId = result['ProfileID']?.toString()
//             ?? result['id']?.toString();
//       }

//       if (profileId == null) {
//         // Farmer cancelled — do nothing, stay on scanner
//         return;
//       }

//       _startAIAnalysis(isPersonalized: true, forcedProfileId: profileId);
//     }
//   }

//   // ── CORE ANALYSIS FLOW ────────────────────────────────────────

//   Future<void> _startAIAnalysis({
//     required bool isPersonalized,
//     String? forcedProfileId,
//   }) async {
//     if (_imageBytes == null) return;

//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color green =
//         isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

//     // Show loading spinner
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) =>
//           Center(child: CircularProgressIndicator(color: green)),
//     );

//     try {
//       // ── 1. Local TFLite inference ───────────────────────────
//       final aiResult = await AIService.runInference(_imageBytes!);

//       if (aiResult['isRejected'] == true) {
//         if (mounted) Navigator.pop(context);
//         _showErrorSnackBar(aiResult['label']);
//         return;
//       }

//       // ── 2. Upload image to Supabase ─────────────────────────
//       String? publicUrl;
//       if (kIsWeb) {
//         publicUrl =
//             await _scannerService.uploadCropImageWeb(_imageBytes!);
//       } else {
//         if (_selectedImage == null) {
//           throw Exception('No image file found');
//         }
//         publicUrl =
//             await _scannerService.uploadCropImage(_selectedImage!);
//       }
//       if (publicUrl == null) throw Exception('Upload failed');

//       // ── 3. Save to Django backend ───────────────────────────
//       final backendResponse = await _scannerService.saveScanToBackend(
//         imageUrl:    publicUrl,
//         diseaseName: aiResult['label']      ?? 'Healthy',
//         confidence:  aiResult['confidence'] ?? 0.0,
//         profileId:   isPersonalized ? forcedProfileId : null,
//         latitude:    _lat,
//         longitude:   _lon,
//         altitude:    _alt,
//         district:    _district,
//         scanMode:    isPersonalized ? 'personalized' : 'general',
//       );

//       if (!mounted) return;
//       Navigator.pop(context); // close spinner

//       if (backendResponse == null) {
//         _showErrorSnackBar('Sync failed. Check your connection.');
//         return;
//       }

//       // ── DEBUG — print full backend response to Flutter console ──
//       print('🔍 [ScanDebug] full response: ${jsonEncode(backendResponse)}');
//       print('🔍 [ScanDebug] scan_mode sent: ${isPersonalized ? 'personalized' : 'general'}');
//       print('🔍 [ScanDebug] profileId sent: $forcedProfileId');
//       print('🔍 [ScanDebug] _debug block: ${backendResponse['_debug']}');

//       // ── 4. Extract diagnosis ID + follow-up date ────────────
//       // These are returned by the new save-scan endpoint and are
//       // needed to wire the feedback flow.
//       final int?      diagnosisId  = backendResponse['id'] as int?;
//       final DateTime? followUpDate = backendResponse['follow_up_date'] != null
//           ? DateTime.tryParse(
//               backendResponse['follow_up_date'].toString())
//           : null;
//       final String?   cropType =
//           backendResponse['crop_type']?.toString()
//           ?? forcedProfileId; // fallback

//       // ── 5. Show result using ScannerResultService ───────────
//       // Replaces old _showResultDialog AlertDialog.
//       // Passes diagnosisId so feedback nudge card is shown.
//       ScannerResultService.showResult(
//         context,
//         backendResponse,                // full response — service
//                                         // resolves all field names
//         diagnosisId:  diagnosisId,      // ← enables feedback card
//         cropType:     cropType,         // ← shown in feedback screen
//         followUpDate: followUpDate,     // ← shown in feedback nudge
//       );

//       // Clear image after successful scan
//       setState(() {
//         _imageBytes    = null;
//         _selectedImage = null;
//       });

//     } catch (e) {
//       if (mounted) Navigator.pop(context);
//       _showErrorSnackBar('Error: $e');
//     }
//   }

//   // ── BUILD ─────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(child: _buildScannerCard()),
//         const SizedBox(height: 25),
//         Row(
//           children: [
//             Expanded(
//               child: _buildActionButton(
//                 label:     t('upload'),
//                 icon:      Icons.file_upload_outlined,
//                 isPrimary: false,
//                 onTap: () => _handleImageAction(ImageSource.gallery),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildActionButton(
//                 label:     t('take_photo'),
//                 icon:      Icons.camera_alt_rounded,
//                 isPrimary: true,
//                 onTap: () => _handleImageAction(ImageSource.camera),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   // ── SCANNER CARD ─────────────────────────────────────────────

//   Widget _buildScannerCard() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color green =
//         isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black
//                   .withOpacity(isDark ? 0.3 : 0.05),
//               blurRadius: 10)
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: _imageBytes != null
//             ? Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   // Image preview — tap to open rotate/zoom/pan viewer
//                   GestureDetector(
//                     onTap: () async {
//                       final t = await ImageViewerSheet.show(
//                         context, _imageBytes!,
//                         initial: _imageTransform,
//                       );
//                       if (t != null && mounted) {
//                         setState(() => _imageTransform = t);
//                       }
//                     },
//                     child: Transform(
//                       alignment: Alignment.center,
//                       transform: Matrix4.identity()
//                         ..translate(_imageTransform.offset.dx, _imageTransform.offset.dy)
//                         ..rotateZ(_imageTransform.rotation)
//                         ..scale(_imageTransform.scale),
//                       child: Image.memory(_imageBytes!, fit: BoxFit.cover),
//                     ),
//                   ),
//                   // Expand / rotate hint badge (top-left)
//                   Positioned(
//                     top: 10,
//                     left: 10,
//                     child: GestureDetector(
//                       onTap: () async {
//                     final t = await ImageViewerSheet.show(
//                       context, _imageBytes!,
//                       initial: _imageTransform,
//                     );
//                     if (t != null && mounted) {
//                       setState(() => _imageTransform = t);
//                     }
//                   },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: Colors.black54,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.open_with_rounded,
//                                 color: Colors.white, size: 14),
//                             SizedBox(width: 5),
//                             Text('Adjust image',
//                                 style: TextStyle(
//                                     color: Colors.white, fontSize: 11)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   // Clear button (top-right)
//                   Positioned(
//                     top: 10,
//                     right: 10,
//                     child: IconButton(
//                       onPressed: () =>
//                           setState(() { _imageBytes = null; _imageTransform = ImageTransform.identity; }),
//                       icon: const CircleAvatar(
//                         backgroundColor: Colors.white70,
//                         child: Icon(Icons.close, color: Colors.red),
//                       ),
//                     ),
//                   ),
//                   // Analyze button overlay (bottom)
//                   Positioned(
//                     bottom: 20,
//                     left: 50,
//                     right: 50,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: isDark
//                             ? Colors.black54
//                             : Colors.white.withOpacity(0.95),
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: TextButton(
//                         onPressed: _handleAnalyzePrompt,
//                         child: Text(
//                           t('analyze'),
//                           style: TextStyle(
//                             color: green,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//             // Empty state
//             : Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.document_scanner_outlined,
//                         size: 64,
//                         color: green.withOpacity(0.4)),
//                     const SizedBox(height: 16),
//                     Text(
//                       t('placeholder'),
//                       style: TextStyle(color: green),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }

//   // ── BUTTONS ───────────────────────────────────────────────────

//   Widget _buildActionButton({
//     required String   label,
//     required IconData icon,
//     required bool     isPrimary,
//     required VoidCallback onTap,
//   }) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     final style = isPrimary
//         ? ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF00A844),
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12)),
//           )
//         : OutlinedButton.styleFrom(
//             side: BorderSide(
//                 color: isDark
//                     ? Colors.green.shade800
//                     : Colors.green.shade200),
//             foregroundColor:
//                 isDark ? Colors.greenAccent : Colors.green,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12)),
//           );

//     return SizedBox(
//       height: 55,
//       child: isPrimary
//           ? ElevatedButton.icon(
//               onPressed: onTap,
//               icon:  Icon(icon),
//               label: Text(label),
//               style: style,
//             )
//           : OutlinedButton.icon(
//               onPressed: onTap,
//               icon:  Icon(icon),
//               label: Text(label),
//               style: style,
//             ),
//     );
//   }

//   // ── ERROR ─────────────────────────────────────────────────────

//   void _showErrorSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(message),
//       backgroundColor: Colors.red,
//       behavior: SnackBarBehavior.floating,
//     ));
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../scanner/data/ai_service.dart';
import '../../../scanner/data/scanner_service.dart';
import '../../../crops/presentation/crop_type_screen.dart';
import '../../../../core/app_localizations.dart';
import '../../../../services/gps_state.dart';

import '../../../scanner/presentation/scanner_result_service.dart';
import '../../../scanner/presentation/image_viewer.dart';

class ScannerSection extends StatefulWidget {
  final bool isGuest;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final double? gpsAltitude;
  final String  gpsDistrict;
  final Function(String) onAuthRequired;
  final VoidCallback      onLoginSuccess;

  const ScannerSection({
    super.key,
    required this.isGuest,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsAltitude,
    this.gpsDistrict = '',
    required this.onAuthRequired,
    required this.onLoginSuccess,
  });

  @override
  State<ScannerSection> createState() => _ScannerSectionState();
}

class _ScannerSectionState extends State<ScannerSection> {
  final ScannerService _scannerService = ScannerService();
  final ImagePicker    _picker         = ImagePicker();

  File?      _selectedImage;
  Uint8List? _imageBytes;
  ImageTransform _imageTransform = ImageTransform.identity;

  String t(String key) =>
      AppLocalizations.of(context)?.translate(key) ?? key;

  double? get _lat      => widget.gpsLatitude  ?? GpsState.instance.latitude;
  double? get _lon      => widget.gpsLongitude ?? GpsState.instance.longitude;
  double? get _alt      => widget.gpsAltitude  ?? GpsState.instance.altitude;
  String  get _district =>
      widget.gpsDistrict.isNotEmpty
          ? widget.gpsDistrict
          : GpsState.instance.district;

  @override
  void initState() {
    super.initState();
    AIService.loadModel();
  }

  Future<void> _handleImageAction(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
        source: source, imageQuality: 70);
    if (pickedFile != null) {
      final Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes   = bytes;
        _imageTransform = ImageTransform.identity;
        if (!kIsWeb) _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleAnalyzePrompt() async {
    if (_imageBytes == null) return;
    if (widget.isGuest) {
      widget.onAuthRequired(t('analyze'));
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color green =
        isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

    final String? action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        title:   Text(t('analysis_title')),
        content: Text(t('analysis_question')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'general'),
            child: Text(t('general_tips'),
                style: TextStyle(color: green)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'personalize'),
            style: ElevatedButton.styleFrom(backgroundColor: green),
            child: Text(t('personalize'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (action == null) return;

    if (action == 'general') {
      _startAIAnalysis(isPersonalized: false);
    } else {
      final dynamic result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CropTypeScreen(pendingImage: _imageBytes),
        ),
      );

      if (!mounted) return;

      String? profileId;
      if (result is String && result.isNotEmpty) {
        profileId = result;
      } else if (result is Map) {
        profileId = result['ProfileID']?.toString()
            ?? result['id']?.toString();
      }

      if (profileId == null) return;

      _startAIAnalysis(isPersonalized: true, forcedProfileId: profileId);
    }
  }

  Future<void> _startAIAnalysis({
    required bool isPersonalized,
    String? forcedProfileId,
  }) async {
    if (_imageBytes == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color green =
        isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: green)),
    );

    try {
      final aiResult = await AIService.runInference(_imageBytes!);

      if (aiResult['isRejected'] == true) {
        if (mounted) Navigator.pop(context);
        _showErrorSnackBar(aiResult['label']);
        return;
      }

      String? publicUrl;
      if (kIsWeb) {
        publicUrl =
            await _scannerService.uploadCropImageWeb(_imageBytes!);
      } else {
        if (_selectedImage == null) {
          throw Exception('No image file found');
        }
        publicUrl =
            await _scannerService.uploadCropImage(_selectedImage!);
      }
      if (publicUrl == null) throw Exception('Upload failed');

      final backendResponse = await _scannerService.saveScanToBackend(
        imageUrl:    publicUrl,
        diseaseName: aiResult['label']      ?? 'Healthy',
        confidence:  aiResult['confidence'] ?? 0.0,
        profileId:   isPersonalized ? forcedProfileId : null,
        latitude:    _lat,
        longitude:   _lon,
        altitude:    _alt,
        district:    _district,
        scanMode:    isPersonalized ? 'personalized' : 'general',
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (backendResponse == null) {
        _showErrorSnackBar('Sync failed. Check your connection.');
        return;
      }

      print('🔍 [ScanDebug] full response: ${jsonEncode(backendResponse)}');
      print('🔍 [ScanDebug] scan_mode sent: ${isPersonalized ? 'personalized' : 'general'}');
      print('🔍 [ScanDebug] profileId sent: $forcedProfileId');
      print('🔍 [ScanDebug] _debug block: ${backendResponse['_debug']}');

      final int?      diagnosisId  = backendResponse['id'] as int?;
      final DateTime? followUpDate = backendResponse['follow_up_date'] != null
          ? DateTime.tryParse(backendResponse['follow_up_date'].toString())
          : null;
      final String?   cropType =
          backendResponse['crop_type']?.toString() ?? forcedProfileId;

      ScannerResultService.showResult(
        context,
        backendResponse,
        diagnosisId:  diagnosisId,
        cropType:     cropType,
        followUpDate: followUpDate,
      );

      setState(() {
        _imageBytes     = null;
        _selectedImage  = null;
        _imageTransform = ImageTransform.identity;
      });

    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar('Error: $e');
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildScannerCard()),
        const SizedBox(height: 16),
        // Bottom buttons only shown when image IS selected
        if (_imageBytes != null) ...[
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label:     t('upload'),
                  icon:      Icons.file_upload_outlined,
                  isPrimary: false,
                  onTap: () => _handleImageAction(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label:     t('take_photo'),
                  icon:      Icons.camera_alt_rounded,
                  isPrimary: true,
                  onTap: () => _handleImageAction(ImageSource.camera),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ── SCANNER CARD ─────────────────────────────────────────────

  Widget _buildScannerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color green =
        isDark ? Colors.greenAccent : const Color(0xFF1B5E20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _imageBytes != null
            ? _buildImagePreview(green, isDark)
            : _buildDropZone(green, isDark),
      ),
    );
  }

  // ── IMAGE PREVIEW STATE ───────────────────────────────────────

  Widget _buildImagePreview(Color green, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image with transform applied
        GestureDetector(
          onTap: () async {
            final result = await ImageViewerSheet.show(
              context, _imageBytes!,
              initial: _imageTransform,
            );
            if (result != null && mounted) {
              setState(() => _imageTransform = result);
            }
          },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(_imageTransform.offset.dx, _imageTransform.offset.dy)
              ..rotateZ(_imageTransform.rotation)
              ..scale(_imageTransform.scale),
            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
          ),
        ),
        // Adjust image badge (top-left)
        Positioned(
          top: 10,
          left: 10,
          child: GestureDetector(
            onTap: () async {
              final result = await ImageViewerSheet.show(
                context, _imageBytes!,
                initial: _imageTransform,
              );
              if (result != null && mounted) {
                setState(() => _imageTransform = result);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_with_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text('Adjust image',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        // Clear button (top-right)
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            onPressed: () => setState(() {
              _imageBytes     = null;
              _selectedImage  = null;
              _imageTransform = ImageTransform.identity;
            }),
            icon: const CircleAvatar(
              backgroundColor: Colors.white70,
              child: Icon(Icons.close, color: Colors.red),
            ),
          ),
        ),
        // Analyze button (bottom)
        Positioned(
          bottom: 20,
          left: 50,
          right: 50,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black54
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextButton(
              onPressed: _handleAnalyzePrompt,
              child: Text(
                t('analyze'),
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── DROP ZONE (empty state) ───────────────────────────────────

  Widget _buildDropZone(Color green, bool isDark) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color:       green.withOpacity(0.30),
        radius:      20,
        dashWidth:   9,
        dashGap:     5,
        strokeWidth: 1.8,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Compact layout when height is tight (< 200px)
          final compact = constraints.maxHeight < 200;
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: compact ? 10 : 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ── Icon cluster ─────────────────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width:  compact ? 70 : 100,
                          height: compact ? 70 : 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: green.withOpacity(0.06),
                          ),
                        ),
                        Container(
                          width:  compact ? 52 : 72,
                          height: compact ? 52 : 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: green.withOpacity(0.10),
                            border: Border.all(
                              color: green.withOpacity(0.22),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: compact ? 24 : 32,
                            color: green.withOpacity(0.75),
                          ),
                        ),
                        Positioned(
                          bottom: compact ? 2 : 5,
                          right:  compact ? 2 : 5,
                          child: Container(
                            padding: EdgeInsets.all(compact ? 4 : 5),
                            decoration: BoxDecoration(
                              color: green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: green.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: compact ? 10 : 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: compact ? 8 : 14),

                    // ── Headline ─────────────────────────
                    Text(
                      'Select a crop photo to diagnose',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1B5E20),
                        letterSpacing: -0.2,
                      ),
                    ),

                    if (!compact) ...[
                      const SizedBox(height: 5),
                      Text(
                        'AI detects diseases & gives personalised advice',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: green.withOpacity(0.55),
                          height: 1.4,
                        ),
                      ),
                    ],

                    SizedBox(height: compact ? 10 : 18),

                    // ── Action chips ─────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chip(
                          icon:   Icons.file_upload_outlined,
                          label:  t('upload'),
                          green:  green,
                          isDark: isDark,
                          onTap:  () => _handleImageAction(
                              ImageSource.gallery),
                        ),
                        const SizedBox(width: 10),
                        _chip(
                          icon:   Icons.camera_alt_rounded,
                          label:  t('take_photo'),
                          green:  green,
                          isDark: isDark,
                          onTap:  () => _handleImageAction(
                              ImageSource.camera),
                          filled: true,
                        ),
                      ],
                    ),

                    if (!compact) ...[
                      const SizedBox(height: 14),
                      // Format info tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: green.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: green.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_outlined,
                                size: 11,
                                color: green.withOpacity(0.5)),
                            const SizedBox(width: 5),
                            Text(
                              'JPG · PNG · HEIC  •  AI-powered',
                              style: TextStyle(
                                fontSize: 10,
                                color: green.withOpacity(0.55),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Chip button ───────────────────────────────────────────────

  Widget _chip({
    required IconData     icon,
    required String       label,
    required Color        green,
    required bool         isDark,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? green
              : green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: filled
              ? null
              : Border.all(color: green.withOpacity(0.22)),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: filled
                    ? Colors.white
                    : green.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled
                    ? Colors.white
                    : green.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action button (shown when image is loaded) ────────────────

  Widget _buildActionButton({
    required String       label,
    required IconData     icon,
    required bool         isPrimary,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final style = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A844),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          )
        : OutlinedButton.styleFrom(
            side: BorderSide(
                color: isDark
                    ? Colors.green.shade800
                    : Colors.green.shade200),
            foregroundColor:
                isDark ? Colors.greenAccent : Colors.green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          );

    return SizedBox(
      height: 55,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon:  Icon(icon),
              label: Text(label),
              style: style,
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon:  Icon(icon),
              label: Text(label),
              style: style,
            ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Dashed border painter ──────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color  color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          strokeWidth / 2,
          strokeWidth / 2,
          size.width  - strokeWidth,
          size.height - strokeWidth,
        ),
        Radius.circular(radius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.dashWidth != dashWidth;
}