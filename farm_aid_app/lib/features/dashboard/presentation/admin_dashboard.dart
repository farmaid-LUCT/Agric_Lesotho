import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  final String adminUrl = 'http://10.245.104.167:8000/admin/';

  Future<void> _launchAdminPortal(BuildContext context) async {
    final Uri url = Uri.parse(adminUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Admin Portal")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();
    // Get screen width to handle padding dynamically
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF5),
      appBar: AppBar(
        title: const Text("Admin Control Center", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "System Management",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF1B5E20)
                ),
              ),
              const Text(
                "Here You Can Manage All Administrative Funtions",
                style: TextStyle(color: Colors.green, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              // Use Expanded with GridView.builder for better performance and fitting
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns
                    crossAxisSpacing: 16, // Space between columns
                    mainAxisSpacing: 16, // Space between rows
                    childAspectRatio: 0.95, // Adjust this to fit height nicely (Width / Height)
                  ),
                  children: [
                    _buildAdminMenuCard(context, "Knowledge Base", Icons.menu_book_rounded, "Manage Diseases"),
                    _buildAdminMenuCard(context, "AI Models", Icons.psychology_rounded, "Validate Versions"),
                    _buildAdminMenuCard(context, "Monitor System", Icons.analytics_rounded, "View Statistics"),
                    _buildAdminMenuCard(context, "User Profiles", Icons.people_alt_rounded, "Manage Farmers"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMenuCard(BuildContext context, String title, IconData icon, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded for modern feel
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 12, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchAdminPortal(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFF1FAF5),
                  child: Icon(icon, size: 32, color: const Color(0xFF00A844)),
                ),
                const SizedBox(height: 12),
                Text(
                  title, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





