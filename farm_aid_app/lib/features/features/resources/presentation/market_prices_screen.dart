import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/market_service.dart';
import '../../../services/theme_provider.dart';
import '../../../core/app_localizations.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final MarketService _service = MarketService();

  List<Map<String, dynamic>> _prices   = [];
  bool   _isLoading   = true;
  bool   _isRefreshing = false;
  String? _error;

  // Filter state
  String  _selectedDistrict = 'All';
  String  _selectedCrop     = 'All';
  String  _sortBy           = 'name'; // 'name' | 'price_asc' | 'price_desc' | 'trend'

  static const List<String> _lesothoDistricts = [
    'All', 'Maseru', 'Leribe', 'Berea', 'Mafeteng',
    'Mohale\'s Hoek', 'Qacha\'s Nek', 'Quthing', 'Thaba-Tseka',
    'Butha-Buthe', 'Mokhotlong',
  ];

  String t(String key) =>
      AppLocalizations.of(context)?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  // ── DATA ──────────────────────────────────────────────────

  Future<void> _loadPrices() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final district = _selectedDistrict == 'All' ? null : _selectedDistrict;
      final data = await _service.getPrices(district: district);
      if (mounted) setState(() { _prices = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      final district = _selectedDistrict == 'All' ? null : _selectedDistrict;
      final data = await _service.refreshPrices(district: district);
      if (mounted) setState(() { _prices = data; _isRefreshing = false; });
    } catch (e) {
      if (mounted) setState(() { _isRefreshing = false; });
    }
  }

  // ── COMPUTED ──────────────────────────────────────────────

  List<String> get _cropOptions {
    final crops = _prices
        .map((p) => p['vegetable_name']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...crops];
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    // Filter
    var filtered = _prices.where((p) {
      final cropMatch = _selectedCrop == 'All' ||
          (p['vegetable_name']?.toString() ?? '') == _selectedCrop;
      final districtMatch = _selectedDistrict == 'All' ||
          (p['district']?.toString() ?? '') == _selectedDistrict;
      return cropMatch && districtMatch;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'price_asc':
        filtered.sort((a, b) =>
            ((a['price_per_kg'] as num?) ?? 0)
                .compareTo((b['price_per_kg'] as num?) ?? 0));
        break;
      case 'price_desc':
        filtered.sort((a, b) =>
            ((b['price_per_kg'] as num?) ?? 0)
                .compareTo((a['price_per_kg'] as num?) ?? 0));
        break;
      case 'trend':
        const order = {'rising': 0, 'stable': 1, 'falling': 2};
        filtered.sort((a, b) =>
            (order[a['price_trend']] ?? 1)
                .compareTo(order[b['price_trend']] ?? 1));
        break;
      default: // 'name'
        filtered.sort((a, b) =>
            (a['vegetable_name']?.toString() ?? '')
                .compareTo(b['vegetable_name']?.toString() ?? ''));
    }

    return MarketService.groupByCrop(filtered);
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bg     = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4);
    final card   = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF2E7D32),
        child: CustomScrollView(
          slivers: [

            // ── App Bar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 130,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF1B1B1B) : const Color(0xFF2E7D32),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Market Prices',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Lesotho • LSL per kg',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1B5E20), const Color(0xFF1B1B1B)]
                          : [const Color(0xFF1B5E20), const Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 72,
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (_isRefreshing)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _refresh,
                    tooltip: 'Refresh prices',
                  ),
              ],
            ),

            // ── Summary bar ──────────────────────────────────
            if (!_isLoading && _prices.isNotEmpty)
              SliverToBoxAdapter(child: _buildSummaryBar(isDark)),

            // ── Filters ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildFilters(isDark, card),
            ),

            // ── Content ──────────────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildError(isDark))
            else if (_grouped.isEmpty)
              SliverFillRemaining(child: _buildEmpty(isDark))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final crop  = _grouped.keys.elementAt(index);
                      final items = _grouped[crop]!;
                      return _buildCropCard(crop, items, isDark, card);
                    },
                    childCount: _grouped.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY BAR ───────────────────────────────────────────

  Widget _buildSummaryBar(bool isDark) {
    final rising  = _prices.where((p) => p['price_trend'] == 'rising').length;
    final falling = _prices.where((p) => p['price_trend'] == 'falling').length;
    final stable  = _prices.where((p) =>
        p['price_trend'] == 'stable' || p['price_trend'] == null).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryChip('↑ $rising Rising',  const Color(0xFF43A047)),
          const SizedBox(width: 8),
          _summaryChip('→ $stable Stable',  const Color(0xFFFB8C00)),
          const SizedBox(width: 8),
          _summaryChip('↓ $falling Falling', const Color(0xFFE53935)),
          const Spacer(),
          Text(
            '${_prices.length} listings',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold),
        ),
      );

  // ── FILTERS ───────────────────────────────────────────────

  Widget _buildFilters(bool isDark, Color card) {
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white54 : Colors.black45,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: District + Crop filters
          Row(
            children: [
              Expanded(
                child: _filterDropdown(
                  label: 'District',
                  value: _selectedDistrict,
                  items: _lesothoDistricts,
                  isDark: isDark,
                  card: card,
                  onChanged: (v) {
                    setState(() => _selectedDistrict = v!);
                    _loadPrices();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filterDropdown(
                  label: 'Crop',
                  value: _cropOptions.contains(_selectedCrop)
                      ? _selectedCrop
                      : 'All',
                  items: _cropOptions,
                  isDark: isDark,
                  card: card,
                  onChanged: (v) => setState(() => _selectedCrop = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Sort chips
          Row(
            children: [
              Text('Sort:', style: labelStyle),
              const SizedBox(width: 8),
              ...[
                ('name',       'A–Z'),
                ('price_asc',  'Price ↑'),
                ('price_desc', 'Price ↓'),
                ('trend',      'Trend'),
              ].map((s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _sortChip(s.$1, s.$2, isDark),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required bool isDark,
    required Color card,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: card,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
          ),
          items: items
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _sortChip(String value, String label, bool isDark) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2E7D32)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  // ── CROP CARD ─────────────────────────────────────────────

  Widget _buildCropCard(
    String crop,
    List<Map<String, dynamic>> items,
    bool isDark,
    Color card,
  ) {
    final best     = MarketService.bestPrice(items);
    final topTrend = items.first['price_trend']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Crop header ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                // Crop emoji
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _trendColor(topTrend).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _cropEmoji(crop),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${items.length} market${items.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                // Best price badge
                if (best != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Best price',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      Text(
                        'M ${best.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Market rows ──
          ...items.map((item) => _buildMarketRow(item, isDark)),
        ],
      ),
    );
  }

  Widget _buildMarketRow(Map<String, dynamic> item, bool isDark) {
    final trend    = item['price_trend']?.toString();
    final price    = (item['price_per_kg'] as num?)?.toDouble() ?? 0.0;
    final market   = item['market_name']?.toString() ?? '—';
    final district = item['district']?.toString() ?? '';
    final date     = item['date_recorded']?.toString().split('T')[0] ?? '';

    final trendColor = _trendColor(trend);
    final trendIcon  = _trendIconData(trend);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          // Market info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  market,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (district.isNotEmpty || date.isNotEmpty)
                  Text(
                    [if (district.isNotEmpty) district, if (date.isNotEmpty) date]
                        .join(' • '),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          // Price + trend
          Row(
            children: [
              Text(
                'M ${price.toStringAsFixed(2)}/kg',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 12, color: trendColor),
                    const SizedBox(width: 2),
                    Text(
                      trend ?? 'stable',
                      style: TextStyle(
                        fontSize: 10,
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── EMPTY / ERROR STATES ─────────────────────────────────

  Widget _buildEmpty(bool isDark) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined,
                size: 64,
                color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(
              'No prices available',
              style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different district or pull down to refresh',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildError(bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Could not load prices',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Check your connection and try again',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPrices,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );

  // ── HELPERS ───────────────────────────────────────────────

  Color _trendColor(String? trend) {
    switch (trend) {
      case 'rising':  return const Color(0xFF43A047);
      case 'falling': return const Color(0xFFE53935);
      default:        return const Color(0xFFFB8C00);
    }
  }

  IconData _trendIconData(String? trend) {
    switch (trend) {
      case 'rising':  return Icons.trending_up;
      case 'falling': return Icons.trending_down;
      default:        return Icons.trending_flat;
    }
  }

  String _cropEmoji(String crop) {
    final c = crop.toLowerCase();
    if (c.contains('tomato'))   return '🍅';
    if (c.contains('cabbage'))  return '🥬';
    if (c.contains('potato'))   return '🥔';
    if (c.contains('spinach'))  return '🥦';
    if (c.contains('onion'))    return '🧅';
    if (c.contains('pepper'))   return '🌶️';
    if (c.contains('carrot'))   return '🥕';
    if (c.contains('bean'))     return '🫘';
    if (c.contains('maize') || c.contains('corn')) return '🌽';
    if (c.contains('lettuce'))  return '🥗';
    if (c.contains('pea'))      return '🟢';
    if (c.contains('pumpkin'))  return '🎃';
    if (c.contains('beetroot') || c.contains('beet')) return '🔴';
    if (c.contains('cucumber')) return '🥒';
    return '🌿';
  }
}