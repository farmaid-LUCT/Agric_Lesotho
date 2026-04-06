// // farm_aid_app/lib/features/history/presentation/feedback_screen.dart
// //
// // Shown after a follow-up notification OR from scan history.
// // Farmer fills in severity, treatment_applied, treatment_outcome,
// // and free-text farmer_feedback for a specific diagnosis.
// //
// // Wired to: PATCH /api/diagnosis/<id>/feedback/
// // via InsightService.submitFeedback()

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../../services/insight_service.dart';
// import '../../../core/app_localizations.dart';

// class FeedbackScreen extends StatefulWidget {
//   /// ID of the Diagnosis record to update
//   final int diagnosisId;

//   /// Display info — shown in the header card
//   final String diseaseName;
//   final String cropType;
//   final String? treatmentProduct;
//   final DateTime? scanDate;
//   final DateTime? followUpDate;

//   /// Pre-fill if coming from a notification that already knows severity
//   final String? initialSeverity;

//   const FeedbackScreen({
//     super.key,
//     required this.diagnosisId,
//     required this.diseaseName,
//     required this.cropType,
//     this.treatmentProduct,
//     this.scanDate,
//     this.followUpDate,
//     this.initialSeverity,
//   });

//   @override
//   State<FeedbackScreen> createState() => _FeedbackScreenState();
// }

// class _FeedbackScreenState extends State<FeedbackScreen> {
//   final InsightService _insight = InsightService();

//   static const Color primaryGreen = Color(0xFF2E7D32);
//   static const Color accentGreen  = Color(0xFF00A844);

//   // ── FORM STATE ───────────────────────────────────────────────
//   String  _severity          = 'moderate';
//   bool?   _treatmentApplied;           // null = not yet selected
//   String? _treatmentOutcome;           // null until applied=true
//   String  _feedbackType      = 'correct'; // AI diagnosis accuracy
//   final   _notesController   = TextEditingController();

//   bool _isSubmitting = false;
//   bool _submitted    = false;

//   // ── OPTION DEFINITIONS ───────────────────────────────────────

//   final List<Map<String, dynamic>> _severityOptions = [
//     {
//       'value': 'healthy',
//       'emoji': '💚',
//       'label': 'Healthy',
//       'desc':  'No visible disease signs',
//       'color': Colors.green,
//     },
//     {
//       'value': 'mild',
//       'emoji': '🟡',
//       'label': 'Mild',
//       'desc':  'A few spots, less than 10% of plant affected',
//       'color': Colors.yellow.shade700,
//     },
//     {
//       'value': 'moderate',
//       'emoji': '🟠',
//       'label': 'Moderate',
//       'desc':  '10–40% of plant affected',
//       'color': Colors.orange,
//     },
//     {
//       'value': 'severe',
//       'emoji': '🔴',
//       'label': 'Severe',
//       'desc':  '40–70% of plant affected',
//       'color': Colors.red,
//     },
//     {
//       'value': 'critical',
//       'emoji': '💀',
//       'label': 'Critical',
//       'desc':  'Over 70% — plant may not recover',
//       'color': Colors.red.shade900,
//     },
//   ];

//   final List<Map<String, dynamic>> _outcomeOptions = [
//     {
//       'value': 'recovered',
//       'emoji': '✅',
//       'label': 'Fully Recovered',
//       'desc':  'Disease is gone, plant looks healthy',
//       'color': Colors.green,
//     },
//     {
//       'value': 'improving',
//       'emoji': '📈',
//       'label': 'Improving',
//       'desc':  'Getting better but not fully recovered yet',
//       'color': Colors.lightGreen,
//     },
//     {
//       'value': 'no_change',
//       'emoji': '➡️',
//       'label': 'No Change',
//       'desc':  'Treatment had no visible effect',
//       'color': Colors.grey,
//     },
//     {
//       'value': 'worsened',
//       'emoji': '📉',
//       'label': 'Worsened',
//       'desc':  'Disease spread further after treatment',
//       'color': Colors.red,
//     },
//   ];

//   final List<Map<String, dynamic>> _diagnosisAccuracyOptions = [
//     {
//       'value': 'correct',
//       'emoji': '👍',
//       'label': 'Correct',
//       'desc':  'The AI identified the disease correctly',
//       'color': Colors.green,
//     },
//     {
//       'value': 'incorrect',
//       'emoji': '👎',
//       'label': 'Incorrect',
//       'desc':  'The disease was different from what AI said',
//       'color': Colors.red,
//     },
//     {
//       'value': 'unsure',
//       'emoji': '🤷',
//       'label': 'Not Sure',
//       'desc':  "I can't tell if the diagnosis was right",
//       'color': Colors.orange,
//     },
//   ];

//   // ── LIFECYCLE ────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     if (widget.initialSeverity != null) {
//       _severity = widget.initialSeverity!;
//     }
//   }

//   @override
//   void dispose() {
//     _notesController.dispose();
//     super.dispose();
//   }

//   // ── SUBMIT ───────────────────────────────────────────────────

//   Future<void> _submit() async {
//     if (_treatmentApplied == null) {
//       _showSnack('Please tell us if you applied the treatment', isError: true);
//       return;
//     }
//     if (_treatmentApplied == true && _treatmentOutcome == null) {
//       _showSnack('Please select the treatment outcome', isError: true);
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     final ok = await _insight.submitFeedback(
//       diagnosisId:      widget.diagnosisId,
//       feedback:         _feedbackType,
//       severity:         _severity,
//       treatmentApplied: _treatmentApplied,
//       treatmentOutcome: _treatmentApplied == true
//           ? _treatmentOutcome
//           : 'not_applied',
//     );

//     if (!mounted) return;
//     setState(() {
//       _isSubmitting = false;
//       _submitted    = ok;
//     });

//     if (ok) {
//       _showSuccessSheet();
//     } else {
//       _showSnack('Could not save feedback. Check your connection.', isError: true);
//     }
//   }

//   // ── SUCCESS BOTTOM SHEET ─────────────────────────────────────

//   void _showSuccessSheet() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     // Determine follow-up advice based on outcome
//     String followUpMessage;
//     IconData followUpIcon;
//     Color followUpColor;

//     if (!(_treatmentApplied ?? false)) {
//       followUpMessage = 'That\'s okay. Try to apply the treatment soon — '
//           'early treatment prevents the disease from spreading to nearby plants.';
//       followUpIcon  = Icons.info_outline_rounded;
//       followUpColor = Colors.orange;
//     } else {
//       switch (_treatmentOutcome) {
//         case 'recovered':
//           followUpMessage = 'Excellent! Your crops recovered. Keep monitoring '
//               'weekly and scan again if you notice any new symptoms.';
//           followUpIcon  = Icons.celebration_rounded;
//           followUpColor = Colors.green;
//           break;
//         case 'improving':
//           followUpMessage = 'Good progress! Apply a second round of treatment '
//               'in 7 days if not fully recovered.';
//           followUpIcon  = Icons.trending_up_rounded;
//           followUpColor = Colors.lightGreen;
//           break;
//         case 'no_change':
//           followUpMessage = 'No change after treatment may mean a different '
//               'disease or resistant strain. Scan again for a fresh diagnosis.';
//           followUpIcon  = Icons.search_rounded;
//           followUpColor = Colors.blue;
//           break;
//         case 'worsened':
//           followUpMessage = 'The disease worsened — scan your crop again now '
//               'for an updated diagnosis. Consider removing severely affected '
//               'plants to protect the rest.';
//           followUpIcon  = Icons.warning_amber_rounded;
//           followUpColor = Colors.red;
//           break;
//         default:
//           followUpMessage = 'Thank you for your feedback. '
//               'This helps improve recommendations for all farmers.';
//           followUpIcon  = Icons.check_circle_outline_rounded;
//           followUpColor = primaryGreen;
//       }
//     }

//     showModalBottomSheet(
//       context: context,
//       isDismissible: false,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Container(
//         padding: const EdgeInsets.all(28),
//         decoration: BoxDecoration(
//           color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Icon
//             Container(
//               width: 72,
//               height: 72,
//               decoration: BoxDecoration(
//                 color: followUpColor.withOpacity(0.12),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(followUpIcon, color: followUpColor, size: 36),
//             ),
//             const SizedBox(height: 16),

//             Text(
//               'Feedback Saved!',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white : Colors.black,
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Follow-up advice
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: followUpColor.withOpacity(0.07),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: followUpColor.withOpacity(0.25)),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(followUpIcon, color: followUpColor, size: 18),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       followUpMessage,
//                       style: TextStyle(
//                         fontSize: 13,
//                         height: 1.5,
//                         color: isDark ? Colors.white70 : Colors.black87,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Insight update notice
//             Text(
//               'Your farm health score has been updated.',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isDark ? Colors.white38 : Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Buttons
//             Row(
//               children: [
//                 // Scan again (if worsened or no change)
//                 if (_treatmentOutcome == 'worsened' ||
//                     _treatmentOutcome == 'no_change') ...[
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () {
//                         Navigator.pop(context);  // close sheet
//                         Navigator.pop(context);  // back to history
//                         // Nav to scanner handled by caller
//                       },
//                       icon: const Icon(Icons.document_scanner_outlined,
//                           size: 18),
//                       label: const Text('Scan Again'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: accentGreen,
//                         side: const BorderSide(color: accentGreen),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12)),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                 ],

//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context); // close sheet
//                       Navigator.pop(context); // back to history
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryGreen,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                     child: const Text(
//                       'Done',
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 15),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── BUILD ─────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       appBar: AppBar(
//         title: const Text(
//           'Treatment Feedback',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor:
//             isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         foregroundColor: isDark ? Colors.white : Colors.black,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [

//             // ── Diagnosis summary card ──────────────────────────
//             _buildDiagnosisCard(isDark),
//             const SizedBox(height: 24),

//             // ── Step 1: Severity ────────────────────────────────
//             _stepHeader('1', 'How severe was the disease?',
//                 'When you first noticed it', isDark),
//             const SizedBox(height: 12),
//             ..._severityOptions.map(
//                 (o) => _buildOptionCard(
//                   value:    o['value'],
//                   selected: _severity,
//                   emoji:    o['emoji'],
//                   label:    o['label'],
//                   desc:     o['desc'],
//                   color:    o['color'],
//                   isDark:   isDark,
//                   onTap:    () => setState(() => _severity = o['value']),
//                 ),
//               ),

//             const SizedBox(height: 24),

//             // ── Step 2: Treatment applied? ──────────────────────
//             _stepHeader('2', 'Did you apply the treatment?',
//                 widget.treatmentProduct != null
//                     ? 'Recommended: ${widget.treatmentProduct}'
//                     : 'The treatment recommended after your scan',
//                 isDark),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildYesNoCard(
//                     value:    true,
//                     label:    '✅  Yes, I applied it',
//                     selected: _treatmentApplied == true,
//                     color:    Colors.green,
//                     isDark:   isDark,
//                     onTap:    () => setState(() {
//                       _treatmentApplied = true;
//                     }),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildYesNoCard(
//                     value:    false,
//                     label:    '❌  No, I didn\'t',
//                     selected: _treatmentApplied == false,
//                     color:    Colors.red,
//                     isDark:   isDark,
//                     onTap:    () => setState(() {
//                       _treatmentApplied  = false;
//                       _treatmentOutcome  = null; // reset outcome
//                     }),
//                   ),
//                 ),
//               ],
//             ),

//             // Reason if not applied
//             if (_treatmentApplied == false) ...[
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(12),
//                   border:
//                       Border.all(color: Colors.orange.withOpacity(0.3)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Row(
//                       children: [
//                         Icon(Icons.help_outline_rounded,
//                             color: Colors.orange, size: 16),
//                         SizedBox(width: 6),
//                         Text(
//                           'Why not? (Optional)',
//                           style: TextStyle(
//                             color: Colors.orange,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: _notesController,
//                       maxLines: 3,
//                       style: TextStyle(
//                           color: isDark ? Colors.white : Colors.black87,
//                           fontSize: 13),
//                       decoration: InputDecoration(
//                         hintText:
//                             'e.g. "Could not find the product in Maseru" '
//                             'or "Too expensive"',
//                         hintStyle: TextStyle(
//                             color: isDark
//                                 ? Colors.white30
//                                 : Colors.grey.shade500,
//                             fontSize: 12),
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.zero,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             // ── Step 3: Outcome (only if applied) ───────────────
//             if (_treatmentApplied == true) ...[
//               const SizedBox(height: 24),
//               _stepHeader('3', 'How did the treatment work?',
//                   'Compared to when you first scanned', isDark),
//               const SizedBox(height: 12),
//               ..._outcomeOptions.map(
//                   (o) => _buildOptionCard(
//                     value:    o['value'],
//                     selected: _treatmentOutcome ?? '',
//                     emoji:    o['emoji'],
//                     label:    o['label'],
//                     desc:     o['desc'],
//                     color:    o['color'],
//                     isDark:   isDark,
//                     onTap:    () =>
//                         setState(() => _treatmentOutcome = o['value']),
//                   ),
//                 ),
//             ],

//             const SizedBox(height: 24),

//             // ── Step 4: AI accuracy ─────────────────────────────
//             _stepHeader(
//               _treatmentApplied == true ? '4' : '3',
//               'Was the AI diagnosis accurate?',
//               'Did the disease match what you saw?',
//               isDark,
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: _diagnosisAccuracyOptions.map((o) {
//                 final selected = _feedbackType == o['value'];
//                 final color    = o['color'] as Color;
//                 return Expanded(
//                   child: GestureDetector(
//                     onTap: () =>
//                         setState(() => _feedbackType = o['value']),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 150),
//                       margin: const EdgeInsets.only(right: 8),
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 14, horizontal: 4),
//                       decoration: BoxDecoration(
//                         color: selected
//                             ? color.withOpacity(0.12)
//                             : (isDark
//                                 ? const Color(0xFF1E1E1E)
//                                 : Colors.white),
//                         borderRadius: BorderRadius.circular(14),
//                         border: Border.all(
//                           color:
//                               selected ? color : Colors.transparent,
//                           width: 2,
//                         ),
//                         boxShadow: selected
//                             ? []
//                             : [
//                                 BoxShadow(
//                                     color:
//                                         Colors.black.withOpacity(0.04),
//                                     blurRadius: 6)
//                               ],
//                       ),
//                       child: Column(
//                         children: [
//                           Text(o['emoji'],
//                               style: const TextStyle(fontSize: 24)),
//                           const SizedBox(height: 6),
//                           Text(
//                             o['label'],
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: selected
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                               color: selected
//                                   ? color
//                                   : (isDark
//                                       ? Colors.white70
//                                       : Colors.black54),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),

//             const SizedBox(height: 24),

//             // ── Step 5: Free text notes ─────────────────────────
//             _stepHeader(
//               _treatmentApplied == true ? '5' : '4',
//               'Any other observations?',
//               'Optional — helps improve future recommendations',
//               isDark,
//             ),
//             const SizedBox(height: 12),
//             Container(
//               decoration: BoxDecoration(
//                 color: isDark
//                     ? const Color(0xFF1E1E1E)
//                     : Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                     color: isDark
//                         ? Colors.white12
//                         : Colors.grey.shade300),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black.withOpacity(0.03),
//                       blurRadius: 8)
//                 ],
//               ),
//               child: TextField(
//                 controller: _treatmentApplied == false
//                     ? TextEditingController() // already captured above
//                     : _notesController,
//                 maxLines: 4,
//                 style: TextStyle(
//                     color: isDark ? Colors.white : Colors.black87,
//                     fontSize: 14),
//                 decoration: InputDecoration(
//                   hintText:
//                       'e.g. "Disease came back after rain" or '
//                       '"Could not find copper hydroxide in Butha-Buthe"',
//                   hintStyle: TextStyle(
//                       color: isDark
//                           ? Colors.white30
//                           : Colors.grey.shade500,
//                       fontSize: 13),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.all(16),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 32),

//             // ── Submit button ───────────────────────────────────
//             SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed:
//                     (_isSubmitting || _submitted) ? null : _submit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryGreen,
//                   disabledBackgroundColor:
//                       primaryGreen.withOpacity(0.5),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14)),
//                   elevation: 0,
//                 ),
//                 child: _isSubmitting
//                     ? const SizedBox(
//                         height: 22,
//                         width: 22,
//                         child: CircularProgressIndicator(
//                             color: Colors.white, strokeWidth: 2.5),
//                       )
//                     : const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.send_rounded,
//                               color: Colors.white, size: 18),
//                           SizedBox(width: 8),
//                           Text(
//                             'SUBMIT FEEDBACK',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 15,
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                         ],
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── WIDGETS ──────────────────────────────────────────────────

//   /// Diagnosis summary header card
//   Widget _buildDiagnosisCard(bool isDark) {
//     final scanDateStr = widget.scanDate != null
//         ? DateFormat('dd MMM yyyy').format(widget.scanDate!)
//         : null;
//     final followUpStr = widget.followUpDate != null
//         ? DateFormat('dd MMM yyyy').format(widget.followUpDate!)
//         : null;
//     final daysSinceScan = widget.scanDate != null
//         ? DateTime.now().difference(widget.scanDate!).inDays
//         : null;

//     return Container(
//       margin: const EdgeInsets.only(top: 16),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isDark
//               ? [const Color(0xFF1B3A1F), const Color(0xFF0D2210)]
//               : [const Color(0xFFE8F5E9), Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//             color: isDark
//                 ? Colors.green.withOpacity(0.3)
//                 : Colors.green.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Title row
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: primaryGreen.withOpacity(0.12),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.bug_report_outlined,
//                     color: primaryGreen, size: 22),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.diseaseName,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: isDark ? Colors.white : Colors.black,
//                       ),
//                     ),
//                     Text(
//                       widget.cropType,
//                       style: const TextStyle(
//                           color: Colors.grey, fontSize: 13),
//                     ),
//                   ],
//                 ),
//               ),
//               // Days since scan badge
//               if (daysSinceScan != null)
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: primaryGreen.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     '${daysSinceScan}d ago',
//                     style: const TextStyle(
//                         color: primaryGreen,
//                         fontSize: 11,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//             ],
//           ),

//           if (widget.treatmentProduct != null ||
//               scanDateStr != null ||
//               followUpStr != null) ...[
//             const SizedBox(height: 14),
//             const Divider(height: 1),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 10,
//               runSpacing: 8,
//               children: [
//                 if (widget.treatmentProduct != null)
//                   _cardChip(
//                     '💊 ${widget.treatmentProduct}',
//                     isDark,
//                     color: Colors.blue,
//                   ),
//                 if (scanDateStr != null)
//                   _cardChip('📅 Scanned $scanDateStr', isDark),
//                 if (followUpStr != null)
//                   _cardChip(
//                     '🔔 Follow-up $followUpStr',
//                     isDark,
//                     color: Colors.orange,
//                   ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   /// Numbered step header
//   Widget _stepHeader(
//       String step, String title, String subtitle, bool isDark) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 28,
//           height: 28,
//           decoration: const BoxDecoration(
//               color: primaryGreen, shape: BoxShape.circle),
//           child: Center(
//             child: Text(
//               step,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 13),
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black,
//                 ),
//               ),
//               Text(
//                 subtitle,
//                 style: const TextStyle(
//                     color: Colors.grey, fontSize: 12),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   /// Single selectable option card (severity + outcome)
//   Widget _buildOptionCard({
//     required String value,
//     required String selected,
//     required String emoji,
//     required String label,
//     required String desc,
//     required Color color,
//     required bool isDark,
//     required VoidCallback onTap,
//   }) {
//     final isSelected = value == selected;
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         margin: const EdgeInsets.only(bottom: 8),
//         padding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? color.withOpacity(0.10)
//               : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isSelected ? color : Colors.transparent,
//             width: 2,
//           ),
//           boxShadow: isSelected
//               ? []
//               : [
//                   BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: 6,
//                       offset: const Offset(0, 2))
//                 ],
//         ),
//         child: Row(
//           children: [
//             Text(emoji, style: const TextStyle(fontSize: 24)),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: isSelected
//                           ? FontWeight.bold
//                           : FontWeight.w500,
//                       color: isSelected
//                           ? color
//                           : (isDark ? Colors.white : Colors.black),
//                     ),
//                   ),
//                   Text(
//                     desc,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: isDark
//                           ? Colors.white38
//                           : Colors.grey.shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 150),
//               width: 22,
//               height: 22,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isSelected
//                     ? color
//                     : (isDark ? Colors.white12 : Colors.grey.shade200),
//               ),
//               child: isSelected
//                   ? const Icon(Icons.check,
//                       color: Colors.white, size: 14)
//                   : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Yes / No card for treatment_applied
//   Widget _buildYesNoCard({
//     required bool value,
//     required String label,
//     required bool selected,
//     required Color color,
//     required bool isDark,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         padding: const EdgeInsets.symmetric(vertical: 18),
//         decoration: BoxDecoration(
//           color: selected
//               ? color.withOpacity(0.10)
//               : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: selected ? color : Colors.transparent,
//             width: 2,
//           ),
//           boxShadow: selected
//               ? []
//               : [
//                   BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: 6)
//                 ],
//         ),
//         child: Center(
//           child: Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight:
//                   selected ? FontWeight.bold : FontWeight.normal,
//               color: selected
//                   ? color
//                   : (isDark ? Colors.white70 : Colors.black54),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _cardChip(String label, bool isDark, {Color? color}) =>
//       Container(
//         padding:
//             const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         decoration: BoxDecoration(
//           color: (color ?? primaryGreen).withOpacity(0.08),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//               color: (color ?? primaryGreen).withOpacity(0.25)),
//         ),
//         child: Text(label,
//             style: TextStyle(
//                 fontSize: 11,
//                 color: color ?? primaryGreen,
//                 fontWeight: FontWeight.w500)),
//       );

//   void _showSnack(String msg, {required bool isError}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg),
//       backgroundColor: isError ? Colors.redAccent : primaryGreen,
//       behavior: SnackBarBehavior.floating,
//     ));
//   }
// }






// farm_aid_app/lib/features/history/presentation/feedback_screen.dart
//
// Shown after a follow-up notification OR from scan history.
// Farmer fills in severity, treatment_applied, treatment_outcome,
// and free-text farmer_feedback for a specific diagnosis.
//
// Wired to: PATCH /api/diagnosis/<id>/feedback/
// via InsightService.submitFeedback()

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/insight_service.dart';
import '../../../core/app_localizations.dart';

class FeedbackScreen extends StatefulWidget {
  /// ID of the Diagnosis record to update
  final int diagnosisId;

  /// Display info — shown in the header card
  final String diseaseName;
  final String cropType;
  final String? treatmentProduct;
  final DateTime? scanDate;
  final DateTime? followUpDate;

  /// Pre-fill if coming from a notification that already knows severity
  final String? initialSeverity;

  const FeedbackScreen({
    super.key,
    required this.diagnosisId,
    required this.diseaseName,
    required this.cropType,
    this.treatmentProduct,
    this.scanDate,
    this.followUpDate,
    this.initialSeverity,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final InsightService _insight = InsightService();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen  = Color(0xFF00A844);

  // ── FORM STATE ───────────────────────────────────────────────
  String  _severity          = 'moderate';
  bool?   _treatmentApplied;           // null = not yet selected
  String? _treatmentOutcome;           // null until applied=true
  String  _feedbackType      = 'correct'; // AI diagnosis accuracy
  final   _notesController   = TextEditingController();

  bool _isSubmitting = false;
  bool _submitted    = false;

  // ── OPTION DEFINITIONS ───────────────────────────────────────

  final List<Map<String, dynamic>> _severityOptions = [
    {
      'value': 'healthy',
      'emoji': '💚',
      'label': 'Healthy',
      'desc':  'No visible disease signs',
      'color': Colors.green,
    },
    {
      'value': 'mild',
      'emoji': '🟡',
      'label': 'Mild',
      'desc':  'A few spots, less than 10% of plant affected',
      'color': Colors.yellow,
    },
    {
      'value': 'moderate',
      'emoji': '🟠',
      'label': 'Moderate',
      'desc':  '10–40% of plant affected',
      'color': Colors.orange,
    },
    {
      'value': 'severe',
      'emoji': '🔴',
      'label': 'Severe',
      'desc':  '40–70% of plant affected',
      'color': Colors.red,
    },
    {
      'value': 'critical',
      'emoji': '💀',
      'label': 'Critical',
      'desc':  'Over 70% — plant may not recover',
      'color': Colors.red,
    },
  ];

  final List<Map<String, dynamic>> _outcomeOptions = [
    {
      'value': 'recovered',
      'emoji': '✅',
      'label': 'Fully Recovered',
      'desc':  'Disease is gone, plant looks healthy',
      'color': Colors.green,
    },
    {
      'value': 'improving',
      'emoji': '📈',
      'label': 'Improving',
      'desc':  'Getting better but not fully recovered yet',
      'color': Colors.lightGreen,
    },
    {
      'value': 'no_change',
      'emoji': '➡️',
      'label': 'No Change',
      'desc':  'Treatment had no visible effect',
      'color': Colors.grey,
    },
    {
      'value': 'worsened',
      'emoji': '📉',
      'label': 'Worsened',
      'desc':  'Disease spread further after treatment',
      'color': Colors.red,
    },
  ];

  final List<Map<String, dynamic>> _diagnosisAccuracyOptions = [
    {
      'value': 'correct',
      'emoji': '👍',
      'label': 'Correct',
      'desc':  'The AI identified the disease correctly',
      'color': Colors.green,
    },
    {
      'value': 'incorrect',
      'emoji': '👎',
      'label': 'Incorrect',
      'desc':  'The disease was different from what AI said',
      'color': Colors.red,
    },
    {
      'value': 'unsure',
      'emoji': '🤷',
      'label': 'Not Sure',
      'desc':  "I can't tell if the diagnosis was right",
      'color': Colors.orange,
    },
  ];

  // ── LIFECYCLE ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.initialSeverity != null) {
      _severity = widget.initialSeverity!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ── SUBMIT ───────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_treatmentApplied == null) {
      _showSnack('Please tell us if you applied the treatment', isError: true);
      return;
    }
    if (_treatmentApplied == true && _treatmentOutcome == null) {
      _showSnack('Please select the treatment outcome', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await _insight.submitFeedback(
      diagnosisId:      widget.diagnosisId,
      feedback:         _feedbackType,
      severity:         _severity,
      treatmentApplied: _treatmentApplied,
      treatmentOutcome: _treatmentApplied == true
          ? _treatmentOutcome
          : 'not_applied',
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submitted    = ok;
    });

    if (ok) {
      _showSuccessSheet();
    } else {
      _showSnack('Could not save feedback. Check your connection.', isError: true);
    }
  }

  // ── SUCCESS BOTTOM SHEET ─────────────────────────────────────

  void _showSuccessSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine follow-up advice based on outcome
    String followUpMessage;
    IconData followUpIcon;
    Color followUpColor;

    if (!(_treatmentApplied ?? false)) {
      followUpMessage = 'That\'s okay. Try to apply the treatment soon — '
          'early treatment prevents the disease from spreading to nearby plants.';
      followUpIcon  = Icons.info_outline_rounded;
      followUpColor = Colors.orange;
    } else {
      switch (_treatmentOutcome) {
        case 'recovered':
          followUpMessage = 'Excellent! Your crops recovered. Keep monitoring '
              'weekly and scan again if you notice any new symptoms.';
          followUpIcon  = Icons.celebration_rounded;
          followUpColor = Colors.green;
          break;
        case 'improving':
          followUpMessage = 'Good progress! Apply a second round of treatment '
              'in 7 days if not fully recovered.';
          followUpIcon  = Icons.trending_up_rounded;
          followUpColor = Colors.lightGreen;
          break;
        case 'no_change':
          followUpMessage = 'No change after treatment may mean a different '
              'disease or resistant strain. Scan again for a fresh diagnosis.';
          followUpIcon  = Icons.search_rounded;
          followUpColor = Colors.blue;
          break;
        case 'worsened':
          followUpMessage = 'The disease worsened — scan your crop again now '
              'for an updated diagnosis. Consider removing severely affected '
              'plants to protect the rest.';
          followUpIcon  = Icons.warning_amber_rounded;
          followUpColor = Colors.red;
          break;
        default:
          followUpMessage = 'Thank you for your feedback. '
              'This helps improve recommendations for all farmers.';
          followUpIcon  = Icons.check_circle_outline_rounded;
          followUpColor = primaryGreen;
      }
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,         // ← allows sheet to grow beyond 50% screen height
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        // Cap at 90% of screen height so it never covers the status bar
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.fromLTRB(
          28,
          28,
          28,
          28 + MediaQuery.of(context).viewInsets.bottom, // account for keyboard
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        // ── FIX: SingleChildScrollView prevents RenderFlex overflow ──────
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: followUpColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(followUpIcon, color: followUpColor, size: 36),
              ),
              const SizedBox(height: 16),

              Text(
                'Feedback Saved!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Follow-up advice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: followUpColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: followUpColor.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(followUpIcon, color: followUpColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        followUpMessage,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Insight update notice
              Text(
                'Your farm health score has been updated.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Scan again (if worsened or no change)
                  if (_treatmentOutcome == 'worsened' ||
                      _treatmentOutcome == 'no_change') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);  // close sheet
                          Navigator.pop(context);  // back to history
                          // Nav to scanner handled by caller
                        },
                        icon: const Icon(Icons.document_scanner_outlined,
                            size: 18),
                        label: const Text('Scan Again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentGreen,
                          side: const BorderSide(color: accentGreen),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // close sheet
                        Navigator.pop(context); // back to history
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
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
        title: const Text(
          'Treatment Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Diagnosis summary card ──────────────────────────
            _buildDiagnosisCard(isDark),
            const SizedBox(height: 24),

            // ── Step 1: Severity ────────────────────────────────
            _stepHeader('1', 'How severe was the disease?',
                'When you first noticed it', isDark),
            const SizedBox(height: 12),
            ..._severityOptions.map(
                (o) => _buildOptionCard(
                  value:    o['value'],
                  selected: _severity,
                  emoji:    o['emoji'],
                  label:    o['label'],
                  desc:     o['desc'],
                  color:    o['color'],
                  isDark:   isDark,
                  onTap:    () => setState(() => _severity = o['value']),
                ),
              ),

            const SizedBox(height: 24),

            // ── Step 2: Treatment applied? ──────────────────────
            _stepHeader('2', 'Did you apply the treatment?',
                widget.treatmentProduct != null
                    ? 'Recommended: ${widget.treatmentProduct}'
                    : 'The treatment recommended after your scan',
                isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildYesNoCard(
                    value:    true,
                    label:    '✅  Yes, I applied it',
                    selected: _treatmentApplied == true,
                    color:    Colors.green,
                    isDark:   isDark,
                    onTap:    () => setState(() {
                      _treatmentApplied = true;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildYesNoCard(
                    value:    false,
                    label:    '❌  No, I didn\'t',
                    selected: _treatmentApplied == false,
                    color:    Colors.red,
                    isDark:   isDark,
                    onTap:    () => setState(() {
                      _treatmentApplied  = false;
                      _treatmentOutcome  = null; // reset outcome
                    }),
                  ),
                ),
              ],
            ),

            // Reason if not applied
            if (_treatmentApplied == false) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.help_outline_rounded,
                            color: Colors.orange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Why not? (Optional)',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. "Could not find the product in Maseru" '
                            'or "Too expensive"',
                        hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white30
                                : Colors.grey.shade500,
                            fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Step 3: Outcome (only if applied) ───────────────
            if (_treatmentApplied == true) ...[
              const SizedBox(height: 24),
              _stepHeader('3', 'How did the treatment work?',
                  'Compared to when you first scanned', isDark),
              const SizedBox(height: 12),
              ..._outcomeOptions.map(
                  (o) => _buildOptionCard(
                    value:    o['value'],
                    selected: _treatmentOutcome ?? '',
                    emoji:    o['emoji'],
                    label:    o['label'],
                    desc:     o['desc'],
                    color:    o['color'],
                    isDark:   isDark,
                    onTap:    () =>
                        setState(() => _treatmentOutcome = o['value']),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // ── Step 4: AI accuracy ─────────────────────────────
            _stepHeader(
              _treatmentApplied == true ? '4' : '3',
              'Was the AI diagnosis accurate?',
              'Did the disease match what you saw?',
              isDark,
            ),
            const SizedBox(height: 12),
            Row(
              children: _diagnosisAccuracyOptions.map((o) {
                final selected = _feedbackType == o['value'];
                final color    = o['color'] as Color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _feedbackType = o['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.12)
                            : (isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              selected ? color : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: selected
                            ? []
                            : [
                                BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.04),
                                    blurRadius: 6)
                              ],
                      ),
                      child: Column(
                        children: [
                          Text(o['emoji'],
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 6),
                          Text(
                            o['label'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? color
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Step 5: Free text notes ─────────────────────────
            _stepHeader(
              _treatmentApplied == true ? '5' : '4',
              'Any other observations?',
              'Optional — helps improve future recommendations',
              isDark,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8)
                ],
              ),
              child: TextField(
                controller: _treatmentApplied == false
                    ? TextEditingController() // already captured above
                    : _notesController,
                maxLines: 4,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'e.g. "Disease came back after rain" or '
                      '"Could not find copper hydroxide in Butha-Buthe"',
                  hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white30
                          : Colors.grey.shade500,
                      fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_isSubmitting || _submitted) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor:
                      primaryGreen.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'SUBMIT FEEDBACK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS ──────────────────────────────────────────────────

  /// Diagnosis summary header card
  Widget _buildDiagnosisCard(bool isDark) {
    final scanDateStr = widget.scanDate != null
        ? DateFormat('dd MMM yyyy').format(widget.scanDate!)
        : null;
    final followUpStr = widget.followUpDate != null
        ? DateFormat('dd MMM yyyy').format(widget.followUpDate!)
        : null;
    final daysSinceScan = widget.scanDate != null
        ? DateTime.now().difference(widget.scanDate!).inDays
        : null;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B3A1F), const Color(0xFF0D2210)]
              : [const Color(0xFFE8F5E9), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.green.withOpacity(0.3)
                : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bug_report_outlined,
                    color: primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.diseaseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      widget.cropType,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Days since scan badge
              if (daysSinceScan != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${daysSinceScan}d ago',
                    style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          if (widget.treatmentProduct != null ||
              scanDateStr != null ||
              followUpStr != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (widget.treatmentProduct != null)
                  _cardChip(
                    '💊 ${widget.treatmentProduct}',
                    isDark,
                    color: Colors.blue,
                  ),
                if (scanDateStr != null)
                  _cardChip('📅 Scanned $scanDateStr', isDark),
                if (followUpStr != null)
                  _cardChip(
                    '🔔 Follow-up $followUpStr',
                    isDark,
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Numbered step header
  Widget _stepHeader(
      String step, String title, String subtitle, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: primaryGreen, shape: BoxShape.circle),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
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
              Text(
                subtitle,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Single selectable option card (severity + outcome)
  Widget _buildOptionCard({
    required String value,
    required String selected,
    required String emoji,
    required String label,
    required String desc,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.10)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? color
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white38
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Yes / No card for treatment_applied
  Widget _buildYesNoCard({
    required bool value,
    required String label,
    required bool selected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.10)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6)
                ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? color
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardChip(String label, bool isDark, {Color? color}) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? primaryGreen).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (color ?? primaryGreen).withOpacity(0.25)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color ?? primaryGreen,
                fontWeight: FontWeight.w500)),
      );

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : primaryGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }
}