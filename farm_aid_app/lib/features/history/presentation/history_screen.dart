import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants.dart';
import '../../../services/theme_provider.dart';
import '../../../core/app_localizations.dart';
import 'insights_screen.dart';
import 'feedback_screen.dart';           // ← NEW
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AuthService _auth = AuthService();

  List _allHistory      = [];
  List _filteredHistory = [];
  bool _isLoading       = true;

  final TextEditingController _searchController = TextEditingController();

  // ── FIELD NAME HELPERS ───────────────────────────────────────
  // Backend now returns snake_case fields from the new API.
  // We support both old PascalCase and new snake_case so the
  // screen works regardless of which API version is live.

  String _disease(Map<String, dynamic> item) =>
      (item['disease_name']      ?? item['DiagnosisSummary'] ?? 'Unknown')
          .toString();

  String _date(Map<String, dynamic> item) =>
      (item['date']              ?? item['ReportDate']       ?? '')
          .toString()
          .split('T')[0];

  String _treatment(Map<String, dynamic> item) =>
      (item['treatment_advice']  ?? item['TreatmentSummary'] ?? 'No treatment recorded')
          .toString();

  String _imageUrl(Map<String, dynamic> item) =>
      (item['image_url']         ?? item['ImageURL']         ?? '')
          .toString();

  int? _diagnosisId(Map<String, dynamic> item) =>
      item['id'] as int?;

  String? _treatmentProduct(Map<String, dynamic> item) =>
      item['treatment_product']?.toString();

  DateTime? _scanDate(Map<String, dynamic> item) {
    try { return DateTime.parse(item['date'] ?? item['ReportDate'] ?? ''); }
    catch (_) { return null; }
  }

  DateTime? _followUpDate(Map<String, dynamic> item) {
    try { return DateTime.parse(item['follow_up_date'] ?? ''); }
    catch (_) { return null; }
  }

  /// true if farmer hasn't submitted feedback for this diagnosis yet
  bool _needsFeedback(Map<String, dynamic> item) =>
      item['treatment_outcome'] == null &&
      item['id'] != null;

  // ── LIFECYCLE ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── DATA ──────────────────────────────────────────────────────

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final token = await _auth.getToken();
      final response = await http.get(
        Uri.parse(AppConstants.farmerReports),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _allHistory      = data;
          _filteredHistory = data;
        });
      }
    } catch (e) {
      debugPrint('History fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteLocalRecord(dynamic item) {
    final appLoc = AppLocalizations.of(context);
    setState(() {
      _allHistory.removeWhere((e) => e == item);
      _filteredHistory.removeWhere((e) => e == item);
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(appLoc?.translate('Removed from local view') ??
          'Removed from local view'),
    ));
  }

  void _runFilter(String keyword) {
    setState(() {
      _filteredHistory = keyword.isEmpty
          ? _allHistory
          : _allHistory
              .where((item) => _disease(item)
                  .toLowerCase()
                  .contains(keyword.toLowerCase()))
              .toList();
    });
  }

  // ── NAVIGATION ────────────────────────────────────────────────

  void _navigateToInsights() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InsightsScreen()),
      );

  void _openFeedback(Map<String, dynamic> item) {
    final id = _diagnosisId(item);
    if (id == null) return;
    Navigator.pop(context); // close bottom sheet first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          diagnosisId:      id,
          diseaseName:      _disease(item),
          cropType:         item['crop_type']?.toString() ?? 'Crop',
          treatmentProduct: _treatmentProduct(item),
          scanDate:         _scanDate(item),
          followUpDate:     _followUpDate(item),
          initialSeverity:  item['severity']?.toString(),
        ),
      ),
    ).then((_) => _fetchHistory()); // refresh after feedback submitted
  }

  // ── DETAIL BOTTOM SHEET ───────────────────────────────────────

  void _showScanDetail(Map<String, dynamic> item) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final appLoc = AppLocalizations.of(context);
    final needsFeedback = _needsFeedback(item);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Scan image
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  _imageUrl(item),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        size: 50, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _disease(item).toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.greenAccent
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _deleteLocalRecord(item),
                  ),
                ],
              ),

              Text(
                '${appLoc?.translate("Date") ?? "Date"}: ${_date(item)}',
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600]),
              ),

              // Crop type + severity chips
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (item['crop_type'] != null)
                    _chip('🌱 ${item['crop_type']}', Colors.green, isDark),
                  if (item['severity'] != null)
                    _chip(
                      '⚠️ ${item['severity']}',
                      _severityColor(item['severity']),
                      isDark,
                    ),
                  if (item['follow_up_date'] != null)
                    _chip(
                      '🔔 Follow-up ${item['follow_up_date'].toString().split('T')[0]}',
                      Colors.orange,
                      isDark,
                    ),
                  // Feedback status chip
                  _needsFeedback(item)
                      ? _chip('📝 Awaiting feedback', Colors.blue, isDark)
                      : _chip('✅ Feedback given', Colors.grey, isDark),
                ],
              ),

              const Divider(height: 30),

              // Treatment plan
              Text(
                appLoc?.translate('Recommended Treatment Plan:') ??
                    'Recommended Treatment Plan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _treatment(item),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),

              // Personalized advice (new field)
              if (item['personalized_advice'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Personalized Advice',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['personalized_advice'].toString(),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color:
                              isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── FEEDBACK BUTTON ─────────────────────────────
              if (needsFeedback)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openFeedback(item),
                    icon: const Icon(Icons.rate_review_outlined,
                        color: Colors.white, size: 18),
                    label: const Text(
                      'Give Treatment Feedback',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A844),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              if (needsFeedback) const SizedBox(height: 10),

              // Export button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportSingleReport(item),
                  icon: const Icon(Icons.picture_as_pdf,
                      color: Colors.white),
                  label: Text(
                    appLoc?.translate('Export This Report') ??
                        'Export This Report',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ── PDF EXPORTS (unchanged logic) ────────────────────────────

  Future<void> _exportReport() async {
    if (_allHistory.isEmpty) return;
    final appLoc = AppLocalizations.of(context);
    final pdf      = pw.Document();
    final font     = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FarmAid: Health Report',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.green900)),
                pw.Text(
                    '${appLoc?.translate("Farmer ID") ?? "Farmer ID"}: '
                    '${_allHistory[0]['FarmerID_id'] ?? ''}',
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              appLoc?.translate('Date')      ?? 'Date',
              appLoc?.translate('Diagnosis') ?? 'Diagnosis',
              appLoc?.translate('Treatment') ?? 'Treatment',
            ],
            data: _allHistory
                .map((item) => [
                      _date(item),
                      _disease(item).toUpperCase(),
                      _treatment(item),
                    ])
                .toList(),
            headerStyle:
                pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.green800),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'FarmAid_Complete_Report.pdf');
  }

  Future<void> _exportSingleReport(Map<String, dynamic> item) async {
    final appLoc = AppLocalizations.of(context);
    final pdf    = pw.Document();
    pdf.addPage(pw.Page(
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            appLoc?.translate(
                    'FarmAid Individual Diagnosis Report') ??
                'FarmAid Individual Diagnosis Report',
            style: pw.TextStyle(
                fontSize: 20, color: PdfColors.green900),
          ),
          pw.Divider(color: PdfColors.green),
          pw.SizedBox(height: 10),
          pw.Text(
              '${appLoc?.translate("Date") ?? "Date"}: ${_date(item)}'),
          pw.Text(
            '${appLoc?.translate("Diagnosis") ?? "Diagnosis"}: '
            '${_disease(item).toUpperCase()}',
            style: pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
              '${appLoc?.translate("Treatment Instructions") ?? "Treatment Instructions"}:'),
          pw.Text(_treatment(item)),
        ],
      ),
    ));
    await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'FarmAid_Single_Report.pdf');
  }

  // ── BUILD ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final appLoc = AppLocalizations.of(context);

    // Count pending feedbacks for badge
    final pendingFeedback =
        _allHistory.where((e) => _needsFeedback(e)).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          appLoc?.translate('Scan History') ?? 'Scan History',
          style: TextStyle(
            color: isDark
                ? Colors.greenAccent
                : const Color(0xFF1B5E20),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            (isDark ? const Color(0xFF121212) : Colors.white),
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDark ? Colors.white : Colors.green),
        actions: [
          // Pending feedback badge
          if (pendingFeedback > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.rate_review_outlined),
                  tooltip: 'Pending feedback',
                  onPressed: () {
                    // Scroll to first item needing feedback
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          '$pendingFeedback scan${pendingFeedback > 1 ? "s" : ""} '
                          'awaiting feedback — tap a scan to review'),
                      backgroundColor: const Color(0xFF00A844),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '$pendingFeedback',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            onPressed: _exportReport,
            icon: const Icon(Icons.picture_as_pdf,
                color: Colors.redAccent),
          ),
          IconButton(
            onPressed: _navigateToInsights,
            icon: const Icon(Icons.auto_graph_rounded),
          ),
          IconButton(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToInsights,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.insights_rounded, color: Colors.white),
        label: Text(
          appLoc?.translate('Insights') ?? 'Insights',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              style:
                  TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText:
                    appLoc?.translate('Search vegetable scans...') ??
                        'Search vegetable scans...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey),
                prefixIcon: Icon(Icons.search,
                    color: isDark ? Colors.greenAccent : Colors.green),
                filled: true,
                fillColor:
                    isDark ? Colors.white10 : Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32)))
                : _filteredHistory.isEmpty
                    ? Center(
                        child: Text(
                          appLoc?.translate('No scan history found.') ??
                              'No scan history found.',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = _filteredHistory[index]
                              as Map<String, dynamic>;
                          final hasFeedback =
                              !_needsFeedback(item);

                          return Card(
                            color: Theme.of(context).cardColor,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15)),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: Image.network(
                                      _imageUrl(item),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.eco,
                                              color: isDark
                                                  ? Colors.greenAccent
                                                  : Colors.green),
                                    ),
                                  ),
                                  // Feedback pending dot
                                  if (!hasFeedback)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00A844),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                _disease(item).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _date(item),
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                        fontSize: 12),
                                  ),
                                  // Feedback nudge
                                  if (!hasFeedback)
                                    const Text(
                                      'Tap to give feedback',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF00A844),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: !hasFeedback,
                              trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.green),
                              onTap: () => _showScanDetail(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── SMALL HELPERS ────────────────────────────────────────────

  Widget _chip(String label, Color color, bool isDark) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500)),
      );

  Color _severityColor(dynamic severity) {
    switch (severity?.toString()) {
      case 'healthy':  return Colors.green;
      case 'mild':     return Colors.yellow.shade700;
      case 'moderate': return Colors.orange;
      case 'severe':   return Colors.red;
      case 'critical': return Colors.red.shade900;
      default:         return Colors.grey;
    }
  }
}
