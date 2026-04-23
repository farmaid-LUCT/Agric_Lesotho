import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';
import '../../../core/constants.dart';

// ── Entry point ─────────────────────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {

  final AuthService _auth = AuthService();

  bool _loading = true;
  String? _error;

  // ── Raw data from backend ──────────────────────────────────────
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>       _insight = {};

  // ── Derived analytics ──────────────────────────────────────────
  int    _totalScans    = 0;
  int    _totalDiseased = 0;
  int    _totalHealthy  = 0;
  int    _streakDays    = 0;
  String _topDisease    = '—';
  String _topCrop       = '—';

  // Monthly scan counts for bar chart (last 6 months)
  List<_MonthBar> _monthlyBars = [];

  // Top 5 diseases for horizontal bar chart
  List<_DiseaseBar> _diseaseBars = [];

  // Crop distribution for donut
  Map<String, int> _cropCounts = {};

  static const _green  = Color(0xFF1B5E20);
  static const _accent = Color(0xFF2E7D32);

  late AnimationController _animCtrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _auth.getToken();
      final headers = {'Authorization': 'Token $token'};

      // Fetch history + insight in parallel
      final results = await Future.wait([
        http.get(Uri.parse(AppConstants.farmerHistory), headers: headers)
            .timeout(const Duration(seconds: 15)),
        http.get(
          Uri.parse(AppConstants.farmerInsightUrl),
          headers: headers,
        ).timeout(const Duration(seconds: 15)),
      ]);

      final histRes    = results[0];
      final insightRes = results[1];

      List<Map<String, dynamic>> history = [];
      Map<String, dynamic>       insight = {};

      if (histRes.statusCode == 200) {
        history = List<Map<String, dynamic>>.from(
            jsonDecode(histRes.body));
      }
      if (insightRes.statusCode == 200) {
        insight = Map<String, dynamic>.from(
            jsonDecode(insightRes.body));
      }

      _processData(history, insight);
      _animCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _processData(List<Map<String, dynamic>> history,
      Map<String, dynamic> insight) {
    _history = history;
    _insight = insight;

    // ── Summary stats ──────────────────────────────────────────
    _totalScans    = insight['total_scans']             as int? ?? history.length;
    _totalDiseased = insight['total_diseases_detected'] as int? ?? 0;
    _totalHealthy  = insight['total_healthy_scans']     as int? ?? 0;
    _streakDays    = insight['streak_healthy_days']     as int? ?? 0;
    _topDisease    = (insight['most_common_disease']    as String? ?? '—')
        .replaceAll('_', ' ');
    _topCrop       = insight['most_scanned_crop']       as String? ?? '—';

    // ── Monthly bars — last 6 months ──────────────────────────
    final now   = DateTime.now();
    final bars  = <_MonthBar>[];
    for (int m = 5; m >= 0; m--) {
      final target = DateTime(now.year, now.month - m, 1);
      final label  = _monthShort(target.month);
      int diseased = 0, healthy = 0;
      for (final h in history) {
        final raw = h['date'] as String? ?? '';
        DateTime? d;
        try { d = _parseDate(raw); } catch (_) {}
        if (d != null &&
            d.year  == target.year &&
            d.month == target.month) {
          final dis = (h['disease'] as String? ?? '').toLowerCase();
          if (dis.contains('healthy')) { healthy++; } else { diseased++; }
        }
      }
      bars.add(_MonthBar(label, diseased, healthy));
    }
    _monthlyBars = bars;

    // ── Disease frequency ──────────────────────────────────────
    final freq = <String, int>{};
    for (final h in history) {
      final d = (h['disease'] as String? ?? '').replaceAll('_', ' ');
      if (!d.toLowerCase().contains('healthy')) {
        freq[d] = (freq[d] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _diseaseBars = sorted
        .take(5)
        .map((e) => _DiseaseBar(e.key, e.value))
        .toList();

    // ── Crop distribution ──────────────────────────────────────
    final crops = <String, int>{};
    for (final h in history) {
      final c = h['crop'] as String? ?? 'Unknown';
      crops[c] = (crops[c] ?? 0) + 1;
    }
    _cropCounts = crops;
  }

  String _monthShort(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[(m - 1).clamp(0, 11)];
  }

  DateTime _parseDate(String raw) {
    // Handle "15 Mar, 2025" or ISO formats
    if (raw.contains(' ') && raw.contains(',')) {
      final parts = raw.replaceAll(',', '').split(' ');
      const ms = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      final day   = int.tryParse(parts[0]) ?? 1;
      final month = ms.indexOf(parts[1]) + 1;
      final year  = int.tryParse(parts[2]) ?? DateTime.now().year;
      return DateTime(year, month, day);
    }
    return DateTime.parse(raw);
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF0FBF0),
      appBar: AppBar(
        title: const Text('Crop Health Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _accent))
          : _error != null
              ? _buildError(isDark)
              : _totalScans == 0
                  ? _buildEmpty(isDark)
                  : _buildContent(isDark),
    );
  }

  // ── ERROR ──────────────────────────────────────────────────────
  Widget _buildError(bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 48,
                  color: isDark ? Colors.white30 : Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text('Could not load data',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(_error ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );

  // ── EMPTY ──────────────────────────────────────────────────────
  Widget _buildEmpty(bool isDark) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📊',
                style: TextStyle(
                    fontSize: 52,
                    color: isDark ? Colors.white30 : Colors.grey.shade300)),
            const SizedBox(height: 14),
            const Text('No scans yet',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Scan your first crop to see\nyour health analytics here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45)),
          ],
        ),
      );

  // ── MAIN CONTENT ───────────────────────────────────────────────
  Widget _buildContent(bool isDark) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [

          // ── Summary stat cards ───────────────────────────────
          _buildSummaryRow(isDark),
          const SizedBox(height: 20),

          // ── Monthly activity bar chart ───────────────────────
          _sectionTitle('Monthly Scan Activity', isDark),
          const SizedBox(height: 10),
          _buildMonthlyChart(isDark),
          const SizedBox(height: 20),

          // ── Top diseases ─────────────────────────────────────
          if (_diseaseBars.isNotEmpty) ...[
            _sectionTitle('Most Detected Diseases', isDark),
            const SizedBox(height: 10),
            _buildDiseaseChart(isDark),
            const SizedBox(height: 20),
          ],

          // ── Crop breakdown ───────────────────────────────────
          if (_cropCounts.isNotEmpty) ...[
            _sectionTitle('Crop Breakdown', isDark),
            const SizedBox(height: 10),
            _buildCropDonut(isDark),
            const SizedBox(height: 20),
          ],

          // ── Health score card ────────────────────────────────
          _buildHealthScoreCard(isDark),
          const SizedBox(height: 20),

          // ── Streak + top crop insights ───────────────────────
          _buildInsightRow(isDark),
        ],
      ),
    );
  }

  // ── SECTION TITLE ──────────────────────────────────────────────
  Widget _sectionTitle(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize:   15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      );

  // ── SUMMARY STAT CARDS ─────────────────────────────────────────
  Widget _buildSummaryRow(bool isDark) {
    final healthRate = _totalScans > 0
        ? (_totalHealthy / _totalScans * 100).round()
        : 0;

    return Row(children: [
      Expanded(child: _statCard('Total Scans', '$_totalScans',
          Icons.biotech_outlined, const Color(0xFF1565C0), isDark)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Diseased', '$_totalDiseased',
          Icons.coronavirus_outlined, const Color(0xFFB71C1C), isDark)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Healthy', '$_totalHealthy',
          Icons.check_circle_outline, const Color(0xFF2E7D32), isDark)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Health %', '$healthRate%',
          Icons.favorite_outline, const Color(0xFF6A1B9A), isDark)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon,
      Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: color.withOpacity(isDark ? 0.3 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
              fontSize:   18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            )),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
      ]),
    );
  }

  // ── MONTHLY BAR CHART ──────────────────────────────────────────
  Widget _buildMonthlyChart(bool isDark) {
    final maxVal = _monthlyBars
        .map((b) => b.diseased + b.healthy)
        .fold(0, max)
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _cardDeco(isDark),
      child: Column(children: [
        // Legend
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _legendDot(const Color(0xFFB71C1C), 'Diseased', isDark),
          const SizedBox(width: 14),
          _legendDot(const Color(0xFF2E7D32), 'Healthy', isDark),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _monthlyBars.map((bar) {
              final total = bar.diseased + bar.healthy;
              final frac  = maxVal > 0 ? total / maxVal : 0.0;
              final dFrac = total > 0 ? bar.diseased / total : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value label
                      if (total > 0)
                        Text('$total',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black45,
                            )),
                      const SizedBox(height: 3),
                      // Stacked bar
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SizedBox(
                            height: 120 * frac * _anim.value,
                            child: Column(children: [
                              // Diseased portion (top)
                              Flexible(
                                flex: (dFrac * 100).round(),
                                child: Container(
                                    color: const Color(0xFFB71C1C)),
                              ),
                              // Healthy portion (bottom)
                              Flexible(
                                flex: ((1 - dFrac) * 100).round(),
                                child: Container(
                                    color: const Color(0xFF2E7D32)),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(bar.month,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white54
                                : Colors.black45,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ── DISEASE HORIZONTAL BARS ────────────────────────────────────
  Widget _buildDiseaseChart(bool isDark) {
    final maxCount = _diseaseBars
        .map((d) => d.count)
        .fold(0, max)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Column(
        children: _diseaseBars.asMap().entries.map((entry) {
          final i   = entry.key;
          final bar = entry.value;
          final frac = maxCount > 0 ? bar.count / maxCount : 0.0;

          // Color gradient: most common = darkest red
          final colors = [
            const Color(0xFFB71C1C),
            const Color(0xFFD32F2F),
            const Color(0xFFEF5350),
            const Color(0xFFE57373),
            const Color(0xFFFFCDD2),
          ];
          final color = colors[i.clamp(0, colors.length - 1)];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        bar.disease,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    Text('${bar.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        )),
                  ],
                ),
                const SizedBox(height: 5),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.06),
                      ),
                      FractionallySizedBox(
                        widthFactor: frac * _anim.value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── CROP DONUT ─────────────────────────────────────────────────
  Widget _buildCropDonut(bool isDark) {
    final entries = _cropCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _cropCounts.values.fold(0, (a, b) => a + b);

    final cropColors = [
      const Color(0xFF1B5E20), const Color(0xFF1565C0),
      const Color(0xFF6A1B9A), const Color(0xFFE65100),
      const Color(0xFF00838F), const Color(0xFFB71C1C),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Row(children: [
        // Donut
        SizedBox(
          width:  120,
          height: 120,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _DonutPainter(
                entries.take(6).toList(),
                total,
                cropColors,
                _anim.value,
                isDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Legend
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.take(6).toList().asMap().entries.map((e) {
              final pct = total > 0
                  ? (e.value.value / total * 100).round()
                  : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: cropColors[e.key % cropColors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.value.key,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        )),
                  ),
                  Text('$pct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cropColors[e.key % cropColors.length],
                      )),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ── HEALTH SCORE CARD ──────────────────────────────────────────
  Widget _buildHealthScoreCard(bool isDark) {
    final score = _totalScans > 0
        ? (_totalHealthy / _totalScans * 100).round()
        : 0;
    final color = score >= 70
        ? const Color(0xFF2E7D32)
        : score >= 40
            ? const Color(0xFFE65100)
            : const Color(0xFFB71C1C);
    final label = score >= 70
        ? 'Good'
        : score >= 40
            ? 'Moderate'
            : 'Needs attention';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A2E0A), const Color(0xFF1A3A1B)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF0FBF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withOpacity(isDark ? 0.35 : 0.2)),
      ),
      child: Row(children: [
        // Arc gauge
        SizedBox(
          width: 80, height: 80,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _GaugePainter(
                  score / 100.0, color, isDark, _anim.value),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$score',
                        style: TextStyle(
                          fontSize:   20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        )),
                    Text('%',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.bold,
                        color:      color,
                      )),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Crop Health Score',
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : _green,
                  )),
              Text(
                '$_totalHealthy healthy out of $_totalScans total scans',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── INSIGHT ROW (streak + top crop + top disease) ──────────────
  Widget _buildInsightRow(bool isDark) {
    return Row(children: [
      Expanded(child: _insightTile(
        '🔥', 'Healthy streak', '$_streakDays days', isDark)),
      const SizedBox(width: 10),
      Expanded(child: _insightTile(
        '🌱', 'Most scanned', _topCrop, isDark)),
      const SizedBox(width: 10),
      Expanded(child: _insightTile(
        '⚠️', 'Top disease', _topDisease, isDark,
        color: const Color(0xFFB71C1C))),
    ]);
  }

  Widget _insightTile(String emoji, String label, String value,
      bool isDark, {Color? color}) {
    final c = color ??
        (isDark ? Colors.greenAccent : const Color(0xFF2E7D32));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(isDark,
          borderColor: c.withOpacity(isDark ? 0.3 : 0.15)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
        const SizedBox(height: 3),
        Text(value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            )),
      ]),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────
  BoxDecoration _cardDeco(bool isDark, {Color? borderColor}) =>
      BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ??
              (isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );

  Widget _legendDot(Color color, String label, bool isDark) =>
      Row(children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            )),
      ]);
}

// ── Data models ────────────────────────────────────────────────────────────
class _MonthBar {
  final String month;
  final int    diseased;
  final int    healthy;
  const _MonthBar(this.month, this.diseased, this.healthy);
}

class _DiseaseBar {
  final String disease;
  final int    count;
  const _DiseaseBar(this.disease, this.count);
}

// ── Donut painter ──────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int    total;
  final List<Color> colors;
  final double progress;
  final bool   isDark;

  _DonutPainter(this.entries, this.total, this.colors,
      this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.42;
    final paint = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16
      ..strokeCap   = StrokeCap.butt;

    double startAngle = -pi / 2;
    const gap = 0.05;

    for (int i = 0; i < entries.length; i++) {
      final sweep =
          (entries[i].value / total * 2 * pi * progress) - gap;
      if (sweep <= 0) continue;
      paint.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          startAngle, sweep, false, paint);
      startAngle += entries[i].value / total * 2 * pi + gap;
    }

    // Track ring
    paint
      ..color      = isDark ? Colors.white10 : Colors.black.withOpacity(0.06)
      ..strokeWidth = size.width * 0.02;
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ── Gauge painter ──────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double value;    // 0.0..1.0
  final Color  color;
  final bool   isDark;
  final double progress;

  _GaugePainter(this.value, this.color, this.isDark, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.38;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      pi * 0.75,
      pi * 1.5,
      false,
      Paint()
        ..color      = isDark ? Colors.white12 : Colors.black.withOpacity(0.08)
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap   = StrokeCap.round,
    );

    // Value arc
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        pi * 0.75,
        pi * 1.5 * value * progress,
        false,
        Paint()
          ..color      = color
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}
