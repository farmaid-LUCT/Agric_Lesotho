// import 'package:flutter/material.dart';
// import '../../../core/widgets/responsive_auth_wrapper.dart';

// class ResourcesScreen extends StatefulWidget {
//   const ResourcesScreen({super.key});

//   @override
//   State<ResourcesScreen> createState() => _ResourcesScreenState();
// }

// class _ResourcesScreenState extends State<ResourcesScreen> {

//   final List<Map<String, dynamic>> _allVegetables = const [
//     {
//       'name': 'Cabbage', 'emoji': '🥬', 'duration': '90-120 Days',
//       'best_way': 'Plant in cool weather (15-20°C). Needs nitrogen-rich soil and consistent watering at the base to prevent head splitting. Earthing up stems helps support growth.',
//       'spacing': '45cm between plants, 60cm between rows.',
//       'tip': 'Mulching keeps roots cool and soil moist. Apply nitrogen fertiliser 3 weeks after transplanting for best head formation.',
//     },
//     {
//       'name': 'Tomato', 'emoji': '🍅', 'duration': '60-85 Days',
//       'best_way': 'Requires full sun (6+ hours). Use stakes or cages to keep fruit off the ground. Prune lower leaves for airflow. Deep watering once a week is better than shallow daily watering.',
//       'spacing': '50cm apart, rows 75cm apart.',
//       'tip': 'Plant near Basil to improve flavour and repel pests. Remove suckers (shoots in leaf axils) on indeterminate varieties to concentrate energy into fruit.',
//     },
//     {
//       'name': 'Spinach', 'emoji': '🍃', 'duration': '35-50 Days',
//       'best_way': 'Fast grower. Harvest outer leaves first to allow the centre to keep producing. Thrives in partial shade during hot months. Keep soil consistently damp.',
//       'spacing': '10cm apart, rows 25cm apart.',
//       'tip': 'High iron content comes from soil rich in organic compost. Spinach bolts quickly in heat — harvest before flower stalks appear.',
//     },
//     {
//       'name': 'Carrot', 'emoji': '🥕', 'duration': '70-80 Days',
//       'best_way': 'Needs deep, loose sandy soil free of stones to prevent forked roots. Do not over-fertilise with nitrogen — too much causes forking and hairy roots. Thin seedlings early.',
//       'spacing': '5cm apart, rows 20cm apart.',
//       'tip': 'Thin out seedlings early to give roots space to grow straight and thick. Mulch lightly to keep soil surface from crusting.',
//     },
//     {
//       'name': 'Bitter Gourd', 'emoji': '🥒', 'duration': '55-70 Days',
//       'best_way': 'Grows best in warm weather (25-35°C). Needs a strong trellis. Water deeply twice a week at the base. Harvest fruits while still green and firm for best flavour.',
//       'spacing': '40cm apart, rows 1.5m apart.',
//       'tip': 'Pinch off growing tips after 6-8 nodes to encourage lateral branches and more fruit set. Hand-pollinate if bees are scarce.',
//     },
//     {
//       'name': 'Bottle Gourd', 'emoji': '🫙', 'duration': '60-75 Days',
//       'best_way': 'Thrives in hot climates. Train on a strong trellis or fence. Water at the base every 2-3 days. Harvest young for vegetables or leave mature for use as containers.',
//       'spacing': '50cm apart, rows 1.5m apart.',
//       'tip': 'Hand-pollinate morning flowers with a small brush if fruit set is poor — bottle gourd relies heavily on bee pollination.',
//     },
//     {
//       'name': 'Cauliflower', 'emoji': '🥦', 'duration': '80-100 Days',
//       'best_way': 'Needs consistently cool temperatures (15-18°C) for curd development. When the curd reaches 5cm wide, tie outer leaves over it loosely to blanch it white and tender.',
//       'spacing': '50cm apart, rows 60cm apart.',
//       'tip': 'Blanching prevents browning. Tie leaves loosely with soft string — tight binding traps moisture and causes rot inside the curd.',
//     },
//     {
//       'name': 'Cucumber', 'emoji': '🥒', 'duration': '50-70 Days',
//       'best_way': 'Needs warm soil (21°C+) and full sun. Train on a trellis for straighter fruit and better airflow. Water deeply but infrequently. Harvest before yellowing begins.',
//       'spacing': '30cm apart on trellis, rows 60cm apart.',
//       'tip': 'Cucumbers are 95% water — consistent moisture is critical. Irregular watering causes bitter-tasting fruit. Never let the soil dry out completely.',
//     },
//     {
//       'name': 'Eggplant', 'emoji': '🍆', 'duration': '70-90 Days',
//       'best_way': 'Needs a long warm season (24-30°C). Start seedlings 8-10 weeks before transplanting. Stake plants to support heavy fruit. Deep, consistent watering prevents blossom drop.',
//       'spacing': '60cm apart, rows 75cm apart.',
//       'tip': 'Harvest when skin is glossy and firm. Dull skin means overripe — seeds become hard and the flesh turns bitter.',
//     },
//     {
//       'name': 'Kale', 'emoji': '🥬', 'duration': '55-75 Days',
//       'best_way': 'Cold-tolerant — frost actually improves flavour by converting starches to sugars. Harvest outer leaves first, leaving the central growing point intact. Benefits from high nitrogen.',
//       'spacing': '40cm apart, rows 60cm apart.',
//       'tip': 'Pick leaves in the morning for best flavour and crispness. Kale is one of the most nutrient-dense vegetables — rich in iron, calcium and vitamin C.',
//     },
//     {
//       'name': 'Lettuce', 'emoji': '🥗', 'duration': '45-75 Days',
//       'best_way': 'Cool season crop (15-20°C). Bolts in heat — plant in partial shade during summer. Harvest the entire head or pick outer leaves. Keep soil consistently moist.',
//       'spacing': '25cm apart for heading types, 15cm apart for leaf varieties.',
//       'tip': 'Sow new seeds every 2 weeks for a continuous harvest all season. Lettuce is shallow-rooted — never let the soil surface dry out completely.',
//     },
//     {
//       'name': 'Onion', 'emoji': '🧅', 'duration': '100-175 Days',
//       'best_way': 'Plant from sets or transplants in full sun. Stop watering when tops begin to fall over — this is the harvest signal. Cure bulbs in the sun for 2 weeks before storage.',
//       'spacing': '10cm apart, rows 30cm apart.',
//       'tip': 'Never push bulbs deep into soil — they need light exposure to trigger bulb formation. The neck should always remain above soil level.',
//     },
//     {
//       'name': 'Potato', 'emoji': '🥔', 'duration': '70-120 Days',
//       'best_way': 'Plant seed potatoes in loose, well-drained soil. Hill soil around stems as they grow to prevent tuber greening. Stop watering 2 weeks before harvest to allow skins to set.',
//       'spacing': '30cm apart, rows 75cm apart.',
//       'tip': 'Green potatoes contain solanine — a toxin. Always hill soil to cover developing tubers completely. Harvest on a dry day and cure in a cool, dark place for 2 weeks.',
//     },
//     {
//       'name': 'Pumpkin', 'emoji': '🎃', 'duration': '90-120 Days',
//       'best_way': 'Needs large space — vines spread 2-4m. Plant on mounds with 3-4 seeds per mound. Water at the base. Pollination is essential — plant near flowering herbs to attract bees.',
//       'spacing': '1.5-2m between mounds.',
//       'tip': 'Slip a piece of cardboard or flat stone under developing fruit to prevent soil contact and rot. Harvest when the stem dries out and the skin is hard.',
//     },
//     {
//       'name': 'Radish', 'emoji': '🌱', 'duration': '25-35 Days',
//       'best_way': 'Fastest maturing vegetable — ready in under 5 weeks. Direct sow in cool weather. Harvest before they become woody and pithy. Loose, deep soil produces the best-shaped roots.',
//       'spacing': '5cm apart, rows 15cm apart.',
//       'tip': 'Sow every 2 weeks for a continuous harvest. Radishes bolt quickly in heat — avoid mid-summer planting. Harvest as soon as they reach full size.',
//     },
//     {
//       'name': 'Beans', 'emoji': '🫘', 'duration': '50-70 Days',
//       'best_way': 'Plant in well-drained soil with full sun after the last frost. Sow seeds 3-4cm deep. Avoid overwatering — beans hate waterlogged roots. Support climbing varieties with a trellis.',
//       'spacing': '10cm apart, rows 45cm apart.',
//       'tip': 'Inoculate seeds with Rhizobium bacteria before planting to boost nitrogen fixation and improve yields by up to 30%. Do not add extra nitrogen fertiliser — beans fix their own.',
//     },
//   ];

//   List<Map<String, dynamic>> _foundVegetables = [];
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _foundVegetables = _allVegetables;
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _runFilter(String keyword) {
//     setState(() {
//       _foundVegetables = keyword.isEmpty
//           ? _allVegetables
//           : _allVegetables
//               .where((v) => v['name']
//                   .toLowerCase()
//                   .contains(keyword.toLowerCase()))
//               .toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final isWide = MediaQuery.of(context).size.width > 600;

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       appBar: AppBar(
//         title: const Text('FARMING MANUAL',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//         backgroundColor: Colors.green[800],
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [

//           // Search bar — always full width (part of the green header)
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//             color: Colors.green[800],
//             child: TextField(
//               controller: _searchController,
//               onChanged:  _runFilter,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText:  'Search for a vegetable…',
//                 hintStyle: const TextStyle(color: Colors.white70),
//                 prefixIcon: const Icon(Icons.search, color: Colors.white70),
//                 suffixIcon: _searchController.text.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear, color: Colors.white70),
//                         onPressed: () {
//                           _searchController.clear();
//                           _runFilter('');
//                         },
//                       )
//                     : null,
//                 filled:    true,
//                 fillColor: Colors.white.withOpacity(0.18),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide:   BorderSide.none,
//                 ),
//               ),
//             ),
//           ),

//           // Crop count chip
//           Container(
//             color: isDark ? const Color(0xFF1E1E1E) : Colors.green[800],
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//             child: Row(children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   '${_foundVegetables.length} crop${_foundVegetables.length == 1 ? '' : 's'}',
//                   style: const TextStyle(
//                     color:      Colors.white,
//                     fontSize:   11,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ]),
//           ),

//           // List — constrained on desktop
//           Expanded(
//             child: _foundVegetables.isNotEmpty
//                 ? isWide
//                     // ── DESKTOP: centered constrained list ──────
//                     ? Center(
//                         child: ConstrainedBox(
//                           constraints:
//                               const BoxConstraints(maxWidth: 760),
//                           child: _buildList(isDark),
//                         ),
//                       )
//                     // ── MOBILE: full width ───────────────────────
//                     : _buildList(isDark)
//                 : Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.search_off,
//                             size:  60,
//                             color: isDark
//                                 ? Colors.white30
//                                 : Colors.grey[400]),
//                         const SizedBox(height: 10),
//                         Text('No vegetables found.',
//                             style: TextStyle(
//                                 fontSize: 16,
//                                 color: isDark
//                                     ? Colors.white54
//                                     : Colors.grey)),
//                       ],
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildList(bool isDark) {
//     return ListView.builder(
//       padding:    const EdgeInsets.all(16),
//       itemCount:  _foundVegetables.length,
//       itemBuilder: (_, i) =>
//           _buildResourceCard(_foundVegetables[i], isDark),
//     );
//   }

//   Widget _buildResourceCard(Map<String, dynamic> veg, bool isDark) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: isDark
//               ? Colors.green.withOpacity(0.2)
//               : Colors.green.shade100,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color:     Colors.black.withOpacity(isDark ? 0.3 : 0.05),
//             blurRadius: 10,
//             offset:    const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(children: [
//                   Text(veg['emoji'] ?? '🌱',
//                       style: const TextStyle(fontSize: 26)),
//                   const SizedBox(width: 10),
//                   Text(
//                     veg['name'].toString().toUpperCase(),
//                     style: TextStyle(
//                       fontSize:   20,
//                       fontWeight: FontWeight.bold,
//                       color: isDark
//                           ? Colors.greenAccent
//                           : const Color(0xFF1B5E20),
//                     ),
//                   ),
//                 ]),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color:        Colors.green[800],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     veg['duration'],
//                     style: const TextStyle(
//                         color:      Colors.white,
//                         fontSize:   11,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),

//             Divider(
//                 height: 24,
//                 color:  isDark ? Colors.white12 : Colors.grey.shade200),

//             _buildDetailRow(
//                 Icons.auto_stories_outlined, 'How to Grow',
//                 veg['best_way'], isDark),
//             const SizedBox(height: 12),
//             _buildDetailRow(
//                 Icons.straighten, 'Spacing',
//                 veg['spacing'], isDark),
//             const SizedBox(height: 15),
//             _buildTipBox(veg['tip'], isDark),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(
//       IconData icon, String title, String content, bool isDark) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon,
//             size:  18,
//             color: isDark ? Colors.greenAccent : Colors.green[700]),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize:   14,
//                     color: isDark ? Colors.white : Colors.black87,
//                   )),
//               Text(content,
//                   style: TextStyle(
//                     color:    isDark ? Colors.white60 : Colors.black54,
//                     fontSize: 14,
//                     height:   1.4,
//                   )),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTipBox(String tip, bool isDark) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: isDark
//             ? Colors.amber.withOpacity(0.12)
//             : Colors.amber[100],
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(
//             color: Colors.amber.withOpacity(isDark ? 0.3 : 0.5)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               'PRO TIP: $tip',
//               style: TextStyle(
//                 fontSize:   13,
//                 fontWeight: FontWeight.w600,
//                 color: isDark ? Colors.amber[200] : Colors.black87,
//                 height:     1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {

  final List<Map<String, dynamic>> _allVegetables = const [
    {
      'name': 'Cabbage', 'emoji': '🥬', 'duration': '90-120 Days',
      'best_way': 'Plant in cool weather (15-20°C). Needs nitrogen-rich soil and consistent watering at the base to prevent head splitting. Earthing up stems helps support growth.',
      'spacing': '45cm between plants, 60cm between rows.',
      'tip': 'Mulching keeps roots cool and soil moist. Apply nitrogen fertiliser 3 weeks after transplanting for best head formation.',
    },
    {
      'name': 'Tomato', 'emoji': '🍅', 'duration': '60-85 Days',
      'best_way': 'Requires full sun (6+ hours). Use stakes or cages to keep fruit off the ground. Prune lower leaves for airflow. Deep watering once a week is better than shallow daily watering.',
      'spacing': '50cm apart, rows 75cm apart.',
      'tip': 'Plant near Basil to improve flavour and repel pests. Remove suckers (shoots in leaf axils) on indeterminate varieties to concentrate energy into fruit.',
    },
    {
      'name': 'Spinach', 'emoji': '🍃', 'duration': '35-50 Days',
      'best_way': 'Fast grower. Harvest outer leaves first to allow the centre to keep producing. Thrives in partial shade during hot months. Keep soil consistently damp.',
      'spacing': '10cm apart, rows 25cm apart.',
      'tip': 'High iron content comes from soil rich in organic compost. Spinach bolts quickly in heat — harvest before flower stalks appear.',
    },
    {
      'name': 'Carrot', 'emoji': '🥕', 'duration': '70-80 Days',
      'best_way': 'Needs deep, loose sandy soil free of stones to prevent forked roots. Do not over-fertilise with nitrogen — too much causes forking and hairy roots. Thin seedlings early.',
      'spacing': '5cm apart, rows 20cm apart.',
      'tip': 'Thin out seedlings early to give roots space to grow straight and thick. Mulch lightly to keep soil surface from crusting.',
    },
    {
      'name': 'Bitter Gourd', 'emoji': '🥒', 'duration': '55-70 Days',
      'best_way': 'Grows best in warm weather (25-35°C). Needs a strong trellis. Water deeply twice a week at the base. Harvest fruits while still green and firm for best flavour.',
      'spacing': '40cm apart, rows 1.5m apart.',
      'tip': 'Pinch off growing tips after 6-8 nodes to encourage lateral branches and more fruit set. Hand-pollinate if bees are scarce.',
    },
    {
      'name': 'Bottle Gourd', 'emoji': '🫙', 'duration': '60-75 Days',
      'best_way': 'Thrives in hot climates. Train on a strong trellis or fence. Water at the base every 2-3 days. Harvest young for vegetables or leave mature for use as containers.',
      'spacing': '50cm apart, rows 1.5m apart.',
      'tip': 'Hand-pollinate morning flowers with a small brush if fruit set is poor — bottle gourd relies heavily on bee pollination.',
    },
    {
      'name': 'Cauliflower', 'emoji': '🥦', 'duration': '80-100 Days',
      'best_way': 'Needs consistently cool temperatures (15-18°C) for curd development. When the curd reaches 5cm wide, tie outer leaves over it loosely to blanch it white and tender.',
      'spacing': '50cm apart, rows 60cm apart.',
      'tip': 'Blanching prevents browning. Tie leaves loosely with soft string — tight binding traps moisture and causes rot inside the curd.',
    },
    {
      'name': 'Cucumber', 'emoji': '🥒', 'duration': '50-70 Days',
      'best_way': 'Needs warm soil (21°C+) and full sun. Train on a trellis for straighter fruit and better airflow. Water deeply but infrequently. Harvest before yellowing begins.',
      'spacing': '30cm apart on trellis, rows 60cm apart.',
      'tip': 'Cucumbers are 95% water — consistent moisture is critical. Irregular watering causes bitter-tasting fruit. Never let the soil dry out completely.',
    },
    {
      'name': 'Eggplant', 'emoji': '🍆', 'duration': '70-90 Days',
      'best_way': 'Needs a long warm season (24-30°C). Start seedlings 8-10 weeks before transplanting. Stake plants to support heavy fruit. Deep, consistent watering prevents blossom drop.',
      'spacing': '60cm apart, rows 75cm apart.',
      'tip': 'Harvest when skin is glossy and firm. Dull skin means overripe — seeds become hard and the flesh turns bitter.',
    },
    {
      'name': 'Kale', 'emoji': '🥬', 'duration': '55-75 Days',
      'best_way': 'Cold-tolerant — frost actually improves flavour by converting starches to sugars. Harvest outer leaves first, leaving the central growing point intact. Benefits from high nitrogen.',
      'spacing': '40cm apart, rows 60cm apart.',
      'tip': 'Pick leaves in the morning for best flavour and crispness. Kale is one of the most nutrient-dense vegetables — rich in iron, calcium and vitamin C.',
    },
    {
      'name': 'Lettuce', 'emoji': '🥗', 'duration': '45-75 Days',
      'best_way': 'Cool season crop (15-20°C). Bolts in heat — plant in partial shade during summer. Harvest the entire head or pick outer leaves. Keep soil consistently moist.',
      'spacing': '25cm apart for heading types, 15cm apart for leaf varieties.',
      'tip': 'Sow new seeds every 2 weeks for a continuous harvest all season. Lettuce is shallow-rooted — never let the soil surface dry out completely.',
    },
    {
      'name': 'Onion', 'emoji': '🧅', 'duration': '100-175 Days',
      'best_way': 'Plant from sets or transplants in full sun. Stop watering when tops begin to fall over — this is the harvest signal. Cure bulbs in the sun for 2 weeks before storage.',
      'spacing': '10cm apart, rows 30cm apart.',
      'tip': 'Never push bulbs deep into soil — they need light exposure to trigger bulb formation. The neck should always remain above soil level.',
    },
    {
      'name': 'Potato', 'emoji': '🥔', 'duration': '70-120 Days',
      'best_way': 'Plant seed potatoes in loose, well-drained soil. Hill soil around stems as they grow to prevent tuber greening. Stop watering 2 weeks before harvest to allow skins to set.',
      'spacing': '30cm apart, rows 75cm apart.',
      'tip': 'Green potatoes contain solanine — a toxin. Always hill soil to cover developing tubers completely. Harvest on a dry day and cure in a cool, dark place for 2 weeks.',
    },
    {
      'name': 'Pumpkin', 'emoji': '🎃', 'duration': '90-120 Days',
      'best_way': 'Needs large space — vines spread 2-4m. Plant on mounds with 3-4 seeds per mound. Water at the base. Pollination is essential — plant near flowering herbs to attract bees.',
      'spacing': '1.5-2m between mounds.',
      'tip': 'Slip a piece of cardboard or flat stone under developing fruit to prevent soil contact and rot. Harvest when the stem dries out and the skin is hard.',
    },
    {
      'name': 'Radish', 'emoji': '🌱', 'duration': '25-35 Days',
      'best_way': 'Fastest maturing vegetable — ready in under 5 weeks. Direct sow in cool weather. Harvest before they become woody and pithy. Loose, deep soil produces the best-shaped roots.',
      'spacing': '5cm apart, rows 15cm apart.',
      'tip': 'Sow every 2 weeks for a continuous harvest. Radishes bolt quickly in heat — avoid mid-summer planting. Harvest as soon as they reach full size.',
    },
    {
      'name': 'Beans', 'emoji': '🫘', 'duration': '50-70 Days',
      'best_way': 'Plant in well-drained soil with full sun after the last frost. Sow seeds 3-4cm deep. Avoid overwatering — beans hate waterlogged roots. Support climbing varieties with a trellis.',
      'spacing': '10cm apart, rows 45cm apart.',
      'tip': 'Inoculate seeds with Rhizobium bacteria before planting to boost nitrogen fixation and improve yields by up to 30%. Do not add extra nitrogen fertiliser — beans fix their own.',
    },
  ];

  List<Map<String, dynamic>> _foundVegetables = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _foundVegetables = _allVegetables;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runFilter(String keyword) {
    setState(() {
      _foundVegetables = keyword.isEmpty
          ? _allVegetables
          : _allVegetables
              .where((v) => v['name']
                  .toLowerCase()
                  .contains(keyword.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      body: isWide
          // ── DESKTOP: centered constrained column ──────────────
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _buildBody(isDark),
              ),
            )
          // ── MOBILE: full width ─────────────────────────────────
          : _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    return Column(
      children: [

        // ── Green header: back button + title + search + count ────
        Container(
          color: Colors.green[800],
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Back button + title row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size:  18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'FARMING MANUAL',
                        style: TextStyle(
                          color:      Colors.white,
                          fontSize:   18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged:  _runFilter,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:  'Search for a vegetable…',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white70),
                              onPressed: () {
                                _searchController.clear();
                                _runFilter('');
                              },
                            )
                          : null,
                      filled:    true,
                      fillColor: Colors.white.withOpacity(0.18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:   BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Crop count chip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_foundVegetables.length} crop${_foundVegetables.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Vegetable list ────────────────────────────────────────
        Expanded(
          child: _foundVegetables.isNotEmpty
              ? ListView.builder(
                  padding:    const EdgeInsets.all(16),
                  itemCount:  _foundVegetables.length,
                  itemBuilder: (_, i) =>
                      _buildResourceCard(_foundVegetables[i], isDark),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size:  60,
                          color: isDark ? Colors.white30 : Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text('No vegetables found.',
                          style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white54 : Colors.grey)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> veg, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.green.withOpacity(0.2)
              : Colors.green.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(veg['emoji'] ?? '🌱',
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Text(
                    veg['name'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.greenAccent
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        Colors.green[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    veg['duration'],
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            Divider(
                height: 24,
                color:  isDark ? Colors.white12 : Colors.grey.shade200),

            _buildDetailRow(Icons.auto_stories_outlined, 'How to Grow',
                veg['best_way'], isDark),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.straighten, 'Spacing',
                veg['spacing'], isDark),
            const SizedBox(height: 15),
            _buildTipBox(veg['tip'], isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String title, String content, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size:  18,
            color: isDark ? Colors.greenAccent : Colors.green[700]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:   14,
                    color: isDark ? Colors.white : Colors.black87,
                  )),
              Text(content,
                  style: TextStyle(
                    color:    isDark ? Colors.white60 : Colors.black54,
                    fontSize: 14,
                    height:   1.4,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipBox(String tip, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.withOpacity(0.12)
            : Colors.amber[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.amber.withOpacity(isDark ? 0.3 : 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'PRO TIP: $tip',
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.amber[200] : Colors.black87,
                height:     1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}