import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants.dart'; 
import '../../../services/theme_provider.dart';
import '../../../core/app_localizations.dart'; 
import 'insights_screen.dart'; 
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
  
  List _allHistory = [];      
  List _filteredHistory = []; 
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // Locally removes a record from the list view
  void _deleteLocalRecord(dynamic item) {
    final appLoc = AppLocalizations.of(context);
    setState(() {
      _allHistory.removeWhere((element) => element == item);
      _filteredHistory.removeWhere((element) => element == item);
    });
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appLoc?.translate("Removed from local view") ?? "Removed from local view")),
    );
  }

  void _navigateToInsights() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const InsightsScreen())
    );
  }

  // Fetches diagnostic history from the Neon database via the API
  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final token = await _auth.getToken();
      final response = await http.get(
        Uri.parse(AppConstants.farmerReports), 
        headers: {"Authorization": "Token $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allHistory = data;
          _filteredHistory = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("History Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // Displays the bottom sheet with scan details and treatment plan
  void _showScanDetail(Map<String, dynamic> item) {
    final bool isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final appLoc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, 
                  height: 4, 
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300], 
                    borderRadius: BorderRadius.circular(10)
                  )
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  item['ImageURL'] ?? '',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['DiagnosisSummary'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20)
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteLocalRecord(item),
                  )
                ],
              ),
              Text(
                "${appLoc?.translate("Date") ?? "Date"}: ${item['ReportDate'].toString().split('T')[0]}", 
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600])
              ),
              const Divider(height: 30),
              Text(
                appLoc?.translate("Recommended Treatment Plan:") ?? "Recommended Treatment Plan:", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)
              ),
              const SizedBox(height: 8),
              Text(
                item['TreatmentSummary'] ?? appLoc?.translate("No treatment steps available.") ?? "No treatment steps available.", 
                style: TextStyle(fontSize: 15, height: 1.4, color: isDark ? Colors.white70 : Colors.black87)
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportSingleReport(item),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text(appLoc?.translate("Export This Report") ?? "Export This Report", style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Exports all history to a single PDF table
  Future<void> _exportReport() async {
    if (_allHistory.isEmpty) return;
    final appLoc = AppLocalizations.of(context);
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("FarmAid: Health Report", style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.green900)),
                pw.Text("${appLoc?.translate("Farmer ID") ?? "Farmer ID"}: ${_allHistory[0]['FarmerID_id']}", style: pw.TextStyle(font: font, fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              appLoc?.translate("Date") ?? 'Date', 
              appLoc?.translate("Diagnosis") ?? 'Diagnosis', 
              appLoc?.translate("Treatment") ?? 'Treatment'
            ],
            data: _allHistory.map((item) => [
              item['ReportDate'].toString().split('T')[0],
              item['DiagnosisSummary'].toString().toUpperCase(),
              item['TreatmentSummary'].toString(),
            ]).toList(),
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'FarmAid_Complete_Report.pdf');
  }

  // Exports a specific scan result to PDF
  Future<void> _exportSingleReport(Map<String, dynamic> item) async {
    final appLoc = AppLocalizations.of(context);
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, 
        children: [
          pw.Text(appLoc?.translate("FarmAid Individual Diagnosis Report") ?? "FarmAid Individual Diagnosis Report", style: pw.TextStyle(fontSize: 20, color: PdfColors.green900)),
          pw.Divider(color: PdfColors.green),
          pw.SizedBox(height: 10),
          pw.Text("${appLoc?.translate("Date") ?? "Date"}: ${item['ReportDate'].toString().split('T')[0]}"),
          pw.Text("${appLoc?.translate("Diagnosis") ?? "Diagnosis"}: ${item['DiagnosisSummary'].toString().toUpperCase()}", style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 20),
          pw.Text("${appLoc?.translate("Treatment Instructions") ?? "Treatment Instructions"}:"),
          pw.Text(item['TreatmentSummary'] ?? appLoc?.translate("Contact local expert.") ?? "Contact local expert."),
        ]
      ),
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'FarmAid_Single_Report.pdf');
  }

  // Local filtering logic for the search bar
  void _runFilter(String enteredKeyword) {
    List results = [];
    if (enteredKeyword.isEmpty) {
      results = _allHistory;
    } else {
      results = _allHistory.where((item) =>
          item["DiagnosisSummary"].toLowerCase().contains(enteredKeyword.toLowerCase())).toList();
    }
    setState(() => _filteredHistory = results);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final appLoc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          appLoc?.translate("Scan History") ?? "Scan History", 
          style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20), fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? (isDark ? const Color(0xFF121212) : Colors.white),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.green),
        actions: [
          IconButton(onPressed: _exportReport, icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent)),
          IconButton(onPressed: _navigateToInsights, icon: const Icon(Icons.auto_graph_rounded)),
          IconButton(onPressed: _fetchHistory, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToInsights,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.insights_rounded, color: Colors.white),
        label: Text(appLoc?.translate("Insights") ?? "Insights", style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: appLoc?.translate("Search vegetable scans...") ?? "Search vegetable scans...",
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.greenAccent : Colors.green),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
              : _filteredHistory.isEmpty 
                ? Center(child: Text(appLoc?.translate("No scan history found.") ?? "No scan history found.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = _filteredHistory[index];
                      return Card(
                        color: Theme.of(context).cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['ImageURL'] ?? '', 
                              width: 50, 
                              height: 50, 
                              fit: BoxFit.cover, 
                              errorBuilder: (c, e, s) => Icon(Icons.eco, color: isDark ? Colors.greenAccent : Colors.green)
                            ),
                          ),
                          title: Text(
                            item['DiagnosisSummary'].toString().toUpperCase(), 
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
                          ),
                          subtitle: Text(
                            item['ReportDate'].toString().split('T')[0],
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.green),
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
}