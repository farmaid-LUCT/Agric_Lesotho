// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../../history/presentation/feedback_screen.dart';

// // ---------------------------------------------------------------------------
// // 1. TYPEWRITER ENGINE
// // ---------------------------------------------------------------------------
// class TypewriterText extends StatelessWidget {
//   final String text;
//   final TextStyle? style;
//   final Duration speed;
//   final Duration startDelay;

//   const TypewriterText({
//     super.key,
//     required this.text,
//     this.style,
//     this.speed      = const Duration(milliseconds: 40),
//     this.startDelay = const Duration(milliseconds: 600),
//   });

//   Stream<String> _typewriterStream() async* {
//     await Future.delayed(startDelay);
//     for (int i = 1; i <= text.length; i++) {
//       await Future.delayed(speed);
//       yield text.substring(0, i);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<String>(
//       stream: _typewriterStream(),
//       initialData: '',
//       builder: (context, snapshot) =>
//           Text(snapshot.data ?? '', style: style),
//     );
//   }
// }

// // ---------------------------------------------------------------------------
// // 2. RESULT POPUP SERVICE
// // ---------------------------------------------------------------------------
// class ScannerResultService {
//   static void showResult(
//     BuildContext context,
//     Map<String, dynamic> result, {
//     int? diagnosisId,
//     String? cropType,
//     DateTime? followUpDate,
//   }) {
//     // ── Field resolution ──────────────────────────────────────────────────
//     // Backend response shape:
//     // {
//     //   "status": "success",
//     //   "id": 123,
//     //   "personalized": {                   ← unified block, null = general scan
//     //     "advice":  "In Maseru, your clay soil...",  ← PersonalizedRule text
//     //     "dosage":  {                                ← Treatment.calculate_for_plot()
//     //       "amount": "12.5g",
//     //       "water":  "100L (10 × 10L buckets)",
//     //     },
//     //     "matched_on": { district, soil, altitude... }
//     //   },
//     //   "results": {
//     //     "disease": "Early Blight",
//     //     "pesticide": "Mancozeb",
//     //     "dosage": "25g per 10L",     ← free-text fallback
//     //     "steps": "1. Remove ...",
//     //     "treatment_dose_display": "12.5g",   ← mirrors personalized.dosage.amount
//     //     "water_volume_display":   "100L ..."
//     //   }
//     // }
//     final Map<String, dynamic> r = result['results'] as Map<String, dynamic>? ?? result;

//     // Unified personalized block — null when farmer has no CropProfile
//     final Map<String, dynamic>? personalized =
//         result['personalized'] as Map<String, dynamic>?;
//     final Map<String, dynamic>? personalizedDosage =
//         personalized?['dosage'] as Map<String, dynamic>?;

//     // Disease label
//     final String disease = (
//       r['disease_name'] ?? r['disease'] ?? 'Healthy'
//     ).toString().replaceAll('_', ' ');

//     // Confidence
//     final double confidence = (
//       r['confidence'] ?? result['confidence'] ?? result['model_confidence'] ?? 0.0
//     ).toDouble();

//     // Treatment fields — from results block
//     final String pesticide = (
//       r['pesticide'] ?? result['treatment_product'] ?? 'None required.'
//     ).toString();

//     final String dosage = (
//       r['dosage'] ?? 'Follow label instructions.'
//     ).toString();

//     final String steps = (
//       r['steps'] ?? 'Isolate plant and monitor health.'
//     ).toString();

//     // ── Personalized advice text — from PersonalizedRule table
//     // Reads new unified block first, falls back to old top-level field
//     final String? personalizedAdvice =
//         (personalized?['advice'] as String?)?.trim().isNotEmpty == true
//             ? personalized!['advice'] as String
//             : result['personalized_advice']?.toString();
//     final bool isPersonalized = personalizedAdvice != null &&
//         personalizedAdvice.trim().isNotEmpty;

//     // ── Calculated dosage — from Treatment.calculate_for_plot()
//     // Only present when farmer has CropProfile with plot_size_hectares set.
//     // Only read from personalized block — never from general results block.
//     final String? treatmentDose = personalizedDosage?['amount']?.toString();
//     final String? waterVolume   = personalizedDosage?['water']?.toString();
//     final String? phiWarning    = r['phi_warning']?.toString();

//     // Dosage card only meaningful when scan is personalized
//     final bool hasDosage = isPersonalized &&
//         (treatmentDose != null || waterVolume != null);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.88,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft:  Radius.circular(30),
//             topRight: Radius.circular(30),
//           ),
//         ),
//         child: Column(
//           children: [
//             // drag handle
//             Container(
//               margin: const EdgeInsets.only(top: 12),
//               height: 5,
//               width: 50,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),

//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 24, vertical: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [

//                     // ── Header ──────────────────────────────────────────
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   const Text(
//                                     'DIAGNOSIS REPORT',
//                                     style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.green),
//                                   ),
//                                   // Badge shows whether advice is personalized
//                                   const SizedBox(width: 8),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 8, vertical: 3),
//                                     decoration: BoxDecoration(
//                                       color: isPersonalized
//                                           ? Colors.green.withOpacity(0.12)
//                                           : Colors.grey.withOpacity(0.12),
//                                       borderRadius: BorderRadius.circular(20),
//                                       border: Border.all(
//                                         color: isPersonalized
//                                             ? Colors.green.withOpacity(0.4)
//                                             : Colors.grey.withOpacity(0.3),
//                                       ),
//                                     ),
//                                     child: Text(
//                                       isPersonalized
//                                           ? '✦ PERSONALIZED'
//                                           : 'GENERAL',
//                                       style: TextStyle(
//                                         fontSize: 9,
//                                         fontWeight: FontWeight.bold,
//                                         color: isPersonalized
//                                             ? Colors.green[700]
//                                             : Colors.grey[600],
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 disease.toUpperCase(),
//                                 style: const TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black),
//                                 overflow: TextOverflow.ellipsis,
//                                 maxLines: 2,
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         _buildConfidenceCircle(confidence),
//                       ],
//                     ),

//                     // ── PHI warning ─────────────────────────────────────
//                     if (phiWarning != null) ...[
//                       const SizedBox(height: 10),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: phiWarning.contains('⚠️') ||
//                                   phiWarning.contains('🚨')
//                               ? Colors.orange.withOpacity(0.12)
//                               : Colors.green.withOpacity(0.10),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: phiWarning.contains('⚠️') ||
//                                     phiWarning.contains('🚨')
//                                 ? Colors.orange.withOpacity(0.4)
//                                 : Colors.green.withOpacity(0.3),
//                           ),
//                         ),
//                         child: Text(phiWarning,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: phiWarning.contains('⚠️') ||
//                                       phiWarning.contains('🚨')
//                                   ? Colors.orange[800]
//                                   : Colors.green[800],
//                               fontWeight: FontWeight.w500,
//                             )),
//                       ),
//                     ],

//                     const SizedBox(height: 15),
//                     const Divider(),
//                     const SizedBox(height: 20),

//                     // ── PERSONALIZED SECTION ──────────────────────────────
//                     // Only shown when farmer tapped "Personalized" AND a
//                     // PersonalizedRule matched their farm context (district,
//                     // altitude, soil, irrigation, growth stage, variety,
//                     // season, rainfall). Advice text is adjusted for farmer
//                     // experience level (beginner vs expert).
//                     if (isPersonalized) ...[
//                       _buildPersonalizedCard(personalizedAdvice!),
//                       const SizedBox(height: 16),
//                     ],

//                     // ── Dosage card ───────────────────────────────────────
//                     // Calculated exact amounts for farmer's plot size.
//                     // Only shown for personalized scans when Treatment table
//                     // has structured dosage fields populated.
//                     if (hasDosage) ...[
//                       _buildDosageCard(
//                         product: pesticide,
//                         dose:    treatmentDose,
//                         water:   waterVolume,
//                       ),
//                       const SizedBox(height: 4),
//                     ],

//                     // ── GENERAL SECTION ───────────────────────────────────
//                     // Always shown for all scans.
//                     // General scan  → this is the only content shown.
//                     // Personalized  → shown below the personalized card
//                     //                 as supporting reference information.
//                     if (isPersonalized)
//                       const Padding(
//                         padding: EdgeInsets.only(bottom: 12),
//                         child: Row(
//                           children: [
//                             Icon(Icons.info_outline, size: 14, color: Colors.grey),
//                             SizedBox(width: 6),
//                             Text(
//                               'GENERAL TREATMENT REFERENCE',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.grey,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                     _buildSection(
//                       title:   'RECOMMENDED TREATMENT',
//                       content: pesticide,
//                       icon:    Icons.science_outlined,
//                       color:   Colors.blue[700]!,
//                       delay:   const Duration(milliseconds: 500),
//                     ),

//                     _buildSection(
//                       title:   'DOSAGE',
//                       content: dosage,
//                       icon:    Icons.opacity,
//                       color:   Colors.purple[700]!,
//                       delay:   const Duration(milliseconds: 1800),
//                     ),

//                     _buildSection(
//                       title:   'APPLICATION STEPS',
//                       content: steps,
//                       icon:    Icons.format_list_numbered,
//                       color:   Colors.orange[800]!,
//                       delay:   const Duration(milliseconds: 3200),
//                     ),

//                     const SizedBox(height: 30),

//                     // ── Feedback nudge ────────────────────────────────────
//                     if (diagnosisId != null) ...[
//                       _buildFeedbackNudge(
//                           context, diagnosisId, disease,
//                           cropType, followUpDate, pesticide),
//                       const SizedBox(height: 12),
//                     ],

//                     // ── Close button ──────────────────────────────────────
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green[700],
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15)),
//                         ),
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text(
//                           'FINISH REPORT',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── PERSONALIZED ADVICE CARD ─────────────────────────────────────────────
//   // This card only appears when the 8-factor rule engine matched a rule.
//   // It is visually distinct from the general treatment sections so the
//   // farmer immediately knows this advice is specific to their farm.
//   static Widget _buildPersonalizedCard(String advice) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.3),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: const [
//               Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 18),
//               SizedBox(width: 8),
//               Text(
//                 'ADVICE FOR YOUR FARM',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.greenAccent,
//                   letterSpacing: 0.8,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           TypewriterText(
//             text:       advice,
//             startDelay: const Duration(milliseconds: 400),
//             style: const TextStyle(
//               fontSize: 15,
//               color: Colors.white,
//               height: 1.55,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── DOSAGE CARD ──────────────────────────────────────────────────────────
//   static Widget _buildDosageCard({
//     required String product,
//     String? dose,
//     String? water,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green.shade50, Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.green.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.calculate_outlined,
//                   color: Color(0xFF2E7D32), size: 18),
//               const SizedBox(width: 6),
//               Text('For YOUR farm',
//                   style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green[800])),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               if (dose  != null)
//                 Expanded(child: _dosageStat('📦', 'Amount', dose,  Colors.blue)),
//               if (water != null)
//                 Expanded(child: _dosageStat('💧', 'Water',  water, Colors.cyan)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   static Widget _dosageStat(
//       String emoji, String label, String value, Color color) {
//     return Column(
//       children: [
//         Text(emoji, style: const TextStyle(fontSize: 20)),
//         const SizedBox(height: 4),
//         Text(value,
//             style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: color)),
//         Text(label,
//             style: const TextStyle(fontSize: 10, color: Colors.grey)),
//       ],
//     );
//   }

//   // ── FEEDBACK NUDGE ───────────────────────────────────────────────────────
//   static Widget _buildFeedbackNudge(
//     BuildContext context,
//     int diagnosisId,
//     String diseaseName,
//     String? cropType,
//     DateTime? followUpDate,
//     String? treatmentProduct,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFF00A844).withOpacity(0.07),
//         borderRadius: BorderRadius.circular(14),
//         border:
//             Border.all(color: const Color(0xFF00A844).withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.schedule_rounded,
//               color: Color(0xFF00A844), size: 22),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Track your treatment',
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                       color: Color(0xFF00A844)),
//                 ),
//                 Text(
//                   followUpDate != null
//                       ? 'We\'ll remind you on '
//                         '${followUpDate.day}/${followUpDate.month}/${followUpDate.year} '
//                         'to report how it went'
//                       : 'Come back after treatment to report the outcome',
//                   style:
//                       TextStyle(fontSize: 12, color: Colors.grey[700]),
//                 ),
//               ],
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => FeedbackScreen(
//                     diagnosisId:      diagnosisId,
//                     diseaseName:      diseaseName,
//                     cropType:         cropType ?? 'Crop',
//                     treatmentProduct: treatmentProduct,
//                     followUpDate:     followUpDate,
//                   ),
//                 ),
//               );
//             },
//             child: const Text(
//               'Review\nnow',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                   fontSize: 11,
//                   color: Color(0xFF00A844),
//                   fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── HELPERS ──────────────────────────────────────────────────────────────
//   static Widget _buildConfidenceCircle(double value) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         SizedBox(
//           width: 48,
//           height: 48,
//           child: CircularProgressIndicator(
//             value: value,
//             backgroundColor: Colors.green[50],
//             color: Colors.green[700],
//             strokeWidth: 5,
//           ),
//         ),
//         Text(
//           '${(value * 100).toInt()}%',
//           style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               color: Colors.green[900]),
//         ),
//       ],
//     );
//   }

//   static Widget _buildSection({
//     required String title,
//     required String content,
//     required IconData icon,
//     required Color color,
//     required Duration delay,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 25),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 20, color: color),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                     letterSpacing: 0.5),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           TypewriterText(
//             text:       content,
//             startDelay: delay,
//             style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[800],
//                 height: 1.5),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../history/presentation/feedback_screen.dart';

// ---------------------------------------------------------------------------
// 1. TYPEWRITER ENGINE
// ---------------------------------------------------------------------------
class TypewriterText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final Duration startDelay;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.speed      = const Duration(milliseconds: 40),
    this.startDelay = const Duration(milliseconds: 300),
  });

  Stream<String> _typewriterStream() async* {
    await Future.delayed(startDelay);
    for (int i = 1; i <= text.length; i++) {
      await Future.delayed(speed);
      yield text.substring(0, i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _typewriterStream(),
      initialData: '',
      builder: (context, snapshot) =>
          Text(snapshot.data ?? '', style: style),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. RESULT POPUP SERVICE  — 2-step flow
//    Step 1: Disease name + possible causes + Yes/No button
//    Step 2: Full treatment details (personalized + general)
// ---------------------------------------------------------------------------
class ScannerResultService {
  static void showResult(
    BuildContext context,
    Map<String, dynamic> result, {
    int? diagnosisId,
    String? cropType,
    DateTime? followUpDate,
  }) {
    // ── Field resolution ───────────────────────────────────────────────────
    final Map<String, dynamic> r =
        result['results'] as Map<String, dynamic>? ?? result;

    final Map<String, dynamic>? personalized =
        result['personalized'] as Map<String, dynamic>?;
    final Map<String, dynamic>? personalizedDosage =
        personalized?['dosage'] as Map<String, dynamic>?;

    final String disease = (r['disease_name'] ?? r['disease'] ?? 'Healthy')
        .toString()
        .replaceAll('_', ' ');

    final double confidence =
        (r['confidence'] ?? result['confidence'] ??
                result['model_confidence'] ?? 0.0)
            .toDouble();

    final String pesticide =
        (r['pesticide'] ?? result['treatment_product'] ?? 'None required.')
            .toString();

    final String dosage =
        (r['dosage'] ?? 'Follow label instructions.').toString();

    final String steps =
        (r['steps'] ?? 'Isolate plant and monitor health.').toString();

    // Possible causes — backend may return list or string
    final dynamic rawCauses = r['possible_causes'] ?? r['causes'];
    final List<String> causes = rawCauses is List
        ? rawCauses.map((e) => e.toString()).toList()
        : rawCauses != null
            ? _splitCauses(rawCauses.toString())
            : _defaultCauses(disease);

    final String? personalizedAdvice =
        (personalized?['advice'] as String?)?.trim().isNotEmpty == true
            ? personalized!['advice'] as String
            : result['personalized_advice']?.toString();
    final bool isPersonalized =
        personalizedAdvice != null && personalizedAdvice.trim().isNotEmpty;

    final String? treatmentDose = personalizedDosage?['amount']?.toString();
    final String? waterVolume   = personalizedDosage?['water']?.toString();
    final String? phiWarning    = r['phi_warning']?.toString();

    final bool hasDosage =
        isPersonalized && (treatmentDose != null || waterVolume != null);

    // ── STEP 1: Disease + Causes dialog ───────────────────────────────────
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _Step1Sheet(
        disease:        disease,
        confidence:     confidence,
        causes:         causes,
        isPersonalized: isPersonalized,
        onYes: () {
          Navigator.pop(ctx);
          // ── STEP 2: Full details ───────────────────────────────────────
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx2) => _Step2Sheet(
              disease:           disease,
              confidence:        confidence,
              isPersonalized:    isPersonalized,
              personalizedAdvice: personalizedAdvice,
              hasDosage:         hasDosage,
              pesticide:         pesticide,
              dosage:            dosage,
              steps:             steps,
              treatmentDose:     treatmentDose,
              waterVolume:       waterVolume,
              phiWarning:        phiWarning,
              diagnosisId:       diagnosisId,
              cropType:          cropType,
              followUpDate:      followUpDate,
            ),
          );
        },
        onNo: () => Navigator.pop(ctx),
      ),
    );
  }

  // ── Cause helpers ────────────────────────────────────────────────────────
  static List<String> _splitCauses(String raw) {
    // Try newline split first, then period, then comma
    if (raw.contains('\n')) return raw.split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (raw.contains('. ')) return raw.split('. ').where((s) => s.trim().isNotEmpty).toList();
    if (raw.contains(', ')) return raw.split(', ').where((s) => s.trim().isNotEmpty).toList();
    return [raw];
  }

  static List<String> _defaultCauses(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('blight'))
      return ['Fungal infection (Alternaria/Phytophthora)', 'High humidity & poor air circulation', 'Infected plant debris in soil', 'Overhead irrigation keeping leaves wet'];
    if (d.contains('mildew'))
      return ['Powdery/downy mildew fungal spores', 'Warm days and cool nights', 'Overcrowded plants with low airflow', 'Excessive nitrogen fertilisation'];
    if (d.contains('rust'))
      return ['Puccinia fungal spores spread by wind', 'Extended leaf wetness', 'Cool temperatures (15–20°C)', 'Infected volunteer plants nearby'];
    if (d.contains('mosaic') || d.contains('virus'))
      return ['Aphid or whitefly virus transmission', 'Infected seeds or transplants', 'Handling plants without washing hands', 'Contaminated tools'];
    if (d.contains('wilt'))
      return ['Fusarium/Verticillium soil fungi', 'Waterlogged or poorly drained soil', 'Root damage from pests or cultivation', 'Infected transplant material'];
    if (d.contains('healthy'))
      return ['No disease detected', 'Plant appears healthy', 'Continue regular monitoring'];
    return ['Fungal, bacterial or viral pathogen', 'Environmental stress (heat, drought, waterlogging)', 'Poor soil nutrition or pH imbalance', 'Pest damage opening entry points for disease'];
  }
}

// ---------------------------------------------------------------------------
// 3. STEP 1 SHEET — Disease name + possible causes
// ---------------------------------------------------------------------------
class _Step1Sheet extends StatelessWidget {
  final String       disease;
  final double       confidence;
  final List<String> causes;
  final bool         isPersonalized;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _Step1Sheet({
    required this.disease,
    required this.confidence,
    required this.causes,
    required this.isPersonalized,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = disease.toLowerCase().contains('healthy');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 5, width: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Text('DIAGNOSIS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  letterSpacing: 1,
                                )),
                              const SizedBox(width: 8),
                              _badge(isPersonalized),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              disease.toUpperCase(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isHealthy
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _confidenceCircle(confidence),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Status banner ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isHealthy
                          ? Colors.green.withOpacity(0.08)
                          : Colors.red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isHealthy
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.25),
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        isHealthy
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: isHealthy ? Colors.green[700] : Colors.red[700],
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isHealthy
                              ? 'Your crop looks healthy. Keep monitoring regularly.'
                              : 'Disease detected. View treatment details below.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isHealthy
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // ── Possible causes ──────────────────────────────
                  Row(children: [
                    Icon(Icons.pest_control_outlined,
                        color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isHealthy ? 'HEALTH FACTORS' : 'POSSIBLE CAUSES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        letterSpacing: 0.6,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  ...causes.asMap().entries.map((e) =>
                    _causeRow(e.key, e.value, isHealthy)),

                  const SizedBox(height: 28),

                  // ── Yes/No prompt ────────────────────────────────
                  if (!isHealthy) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Would you like to view the full treatment details?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Includes recommended treatment, dosage and application steps.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),

                    Row(children: [
                      // No button
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: onNo,
                          child: const Text('No, close',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Yes button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: onYes,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Yes, view treatment',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ] else ...[
                    // Healthy — just a close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: onNo,
                        child: const Text('Great, close',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _causeRow(int index, String cause, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isHealthy
                  ? Colors.green.withOpacity(0.12)
                  : Colors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isHealthy ? Colors.green[700] : Colors.orange[700],
                )),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(cause.trim(),
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[800], height: 1.45)),
          ),
        ],
      ),
    );
  }

  Widget _badge(bool isPersonalized) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPersonalized
            ? Colors.green.withOpacity(0.12)
            : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPersonalized
              ? Colors.green.withOpacity(0.4)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        isPersonalized ? '✦ PERSONALIZED' : 'GENERAL',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isPersonalized ? Colors.green[700] : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _confidenceCircle(double value) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 52, height: 52,
          child: CircularProgressIndicator(
            value: value,
            backgroundColor: Colors.green[50],
            color: Colors.green[700],
            strokeWidth: 5,
          ),
        ),
        Text('${(value * 100).toInt()}%',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green[900])),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. STEP 2 SHEET — Full treatment details
// ---------------------------------------------------------------------------
class _Step2Sheet extends StatelessWidget {
  final String  disease;
  final double  confidence;
  final bool    isPersonalized;
  final String? personalizedAdvice;
  final bool    hasDosage;
  final String  pesticide;
  final String  dosage;
  final String  steps;
  final String? treatmentDose;
  final String? waterVolume;
  final String? phiWarning;
  final int?    diagnosisId;
  final String? cropType;
  final DateTime? followUpDate;

  const _Step2Sheet({
    required this.disease,
    required this.confidence,
    required this.isPersonalized,
    this.personalizedAdvice,
    required this.hasDosage,
    required this.pesticide,
    required this.dosage,
    required this.steps,
    this.treatmentDose,
    this.waterVolume,
    this.phiWarning,
    this.diagnosisId,
    this.cropType,
    this.followUpDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 5, width: 50,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),
          // Back button row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    size: 14, color: Colors.grey),
                label: const Text('Back to diagnosis',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TREATMENT REPORT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              letterSpacing: 1,
                            )),
                          const SizedBox(height: 4),
                          Text(disease.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            )),
                        ],
                      ),
                      _buildConfidenceCircle(confidence),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // PHI warning
                  if (phiWarning != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: phiWarning!.contains('⚠️') || phiWarning!.contains('🚨')
                            ? Colors.orange.withOpacity(0.12)
                            : Colors.green.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: phiWarning!.contains('⚠️') || phiWarning!.contains('🚨')
                              ? Colors.orange.withOpacity(0.4)
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(phiWarning!,
                          style: TextStyle(
                            fontSize: 13,
                            color: phiWarning!.contains('⚠️') || phiWarning!.contains('🚨')
                                ? Colors.orange[800]
                                : Colors.green[800],
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  // Personalized advice card
                  if (isPersonalized && personalizedAdvice != null) ...[
                    _buildPersonalizedCard(personalizedAdvice!),
                    const SizedBox(height: 16),
                  ],

                  // Dosage card
                  if (hasDosage) ...[
                    _buildDosageCard(
                      product: pesticide,
                      dose:    treatmentDose,
                      water:   waterVolume,
                    ),
                    const SizedBox(height: 4),
                  ],

                  // General reference label
                  if (isPersonalized)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('GENERAL TREATMENT REFERENCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          )),
                      ]),
                    ),

                  _buildSection(
                    title:   'RECOMMENDED TREATMENT',
                    content: pesticide,
                    icon:    Icons.science_outlined,
                    color:   Colors.blue[700]!,
                    delay:   const Duration(milliseconds: 300),
                  ),
                  _buildSection(
                    title:   'DOSAGE',
                    content: dosage,
                    icon:    Icons.opacity,
                    color:   Colors.purple[700]!,
                    delay:   const Duration(milliseconds: 1200),
                  ),
                  _buildSection(
                    title:   'APPLICATION STEPS',
                    content: steps,
                    icon:    Icons.format_list_numbered,
                    color:   Colors.orange[800]!,
                    delay:   const Duration(milliseconds: 2400),
                  ),

                  const SizedBox(height: 24),

                  // Feedback nudge
                  if (diagnosisId != null) ...[
                    _buildFeedbackNudge(
                        context, diagnosisId!, disease,
                        cropType, followUpDate, pesticide),
                    const SizedBox(height: 16),
                  ],

                  // Finish button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('FINISH REPORT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPersonalizedCard(String advice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 18),
            SizedBox(width: 8),
            Text('ADVICE FOR YOUR FARM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
                letterSpacing: 0.8,
              )),
          ]),
          const SizedBox(height: 10),
          TypewriterText(
            text:       advice,
            startDelay: const Duration(milliseconds: 400),
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDosageCard({
    required String product,
    String? dose,
    String? water,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calculate_outlined,
                color: Color(0xFF2E7D32), size: 18),
            const SizedBox(width: 6),
            Text('For YOUR farm',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            if (dose  != null)
              Expanded(child: _dosageStat('📦', 'Amount', dose,  Colors.blue)),
            if (water != null)
              Expanded(child: _dosageStat('💧', 'Water',  water, Colors.cyan)),
          ]),
        ],
      ),
    );
  }

  static Widget _dosageStat(
      String emoji, String label, String value, Color color) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }

  static Widget _buildFeedbackNudge(
    BuildContext context,
    int diagnosisId,
    String diseaseName,
    String? cropType,
    DateTime? followUpDate,
    String? treatmentProduct,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00A844).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00A844).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.schedule_rounded, color: Color(0xFF00A844), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Track your treatment',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF00A844))),
              Text(
                followUpDate != null
                    ? 'We\'ll remind you on '
                      '${followUpDate.day}/${followUpDate.month}/${followUpDate.year} '
                      'to report how it went'
                    : 'Come back after treatment to report the outcome',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context,
              MaterialPageRoute(
                builder: (_) => FeedbackScreen(
                  diagnosisId:      diagnosisId,
                  diseaseName:      diseaseName,
                  cropType:         cropType ?? 'Crop',
                  treatmentProduct: treatmentProduct,
                  followUpDate:     followUpDate,
                ),
              ),
            );
          },
          child: const Text('Review\nnow',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFF00A844),
                fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  static Widget _buildConfidenceCircle(double value) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(
            value: value,
            backgroundColor: Colors.green[50],
            color: Colors.green[700],
            strokeWidth: 5,
          ),
        ),
        Text('${(value * 100).toInt()}%',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green[900])),
      ],
    );
  }

  static Widget _buildSection({
    required String   title,
    required String   content,
    required IconData icon,
    required Color    color,
    required Duration delay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 10),
          TypewriterText(
            text:       content,
            startDelay: delay,
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5),
          ),
        ],
      ),
    );
  }
}