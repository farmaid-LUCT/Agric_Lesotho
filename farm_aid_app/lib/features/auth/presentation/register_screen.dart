import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();

  // Controllers matching your Database Columns
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the registration logic and shows verification instructions
  void _handleRegister() async {
    // 1. Basic Validation
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstNameController.text.isEmpty) {
      _showError("Please fill in all required fields (*)");
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() => _isLoading = true);

    // 2. Call Service
    bool success = await _auth.signUp(
      _firstNameController.text.trim(),
      _emailController.text.trim(),
      _lastNameController.text.trim(),
      _phoneController.text.trim(),
      _locationController.text.trim(),
      _passwordController.text.trim(),
      "en", // Default language
      _usernameController.text.trim().isEmpty 
          ? _emailController.text.trim() 
          : _usernameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 3. Handle Result
    if (success) {
      _showVerificationDialog();
    } else {
      _showError("Registration failed. Email/Username may already be taken.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  /// Displays a dialog instructing the farmer to check their email
  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.mark_email_read, color: Color(0xFF00A844), size: 50),
            SizedBox(height: 10),
            Text("Verify Your Email", textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          "Dumela, ${_firstNameController.text.trim()}! \n\n"
          "We sent a verification link to ${_emailController.text.trim()}. \n\n"
          "Please check your inbox (and spam folder) to activate your account before logging in.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); 
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A844),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "PROCEED TO LOGIN",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.greenAccent : Colors.green),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            children: [
              const Icon(Icons.eco, size: 60, color: Color(0xFF00A844)),
              const SizedBox(height: 10),
              Text(
                "Farmer Registration",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20)),
              ),
              const Text("Grow smarter with FarmAid Lesotho",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              _buildInputField("First Name *", _firstNameController, Icons.person_outline),
              const SizedBox(height: 12),
              _buildInputField("Last Name", _lastNameController, Icons.person_outline),
              const SizedBox(height: 12),
              _buildInputField("Username (Optional)", _usernameController, Icons.alternate_email),
              const SizedBox(height: 12),
              _buildInputField("Email Address *", _emailController, Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildInputField("Phone Number", _phoneController, Icons.phone,
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              _buildInputField("Farm Location", _locationController, Icons.map_outlined),
              const SizedBox(height: 12),
              _buildInputField("Password *", _passwordController, Icons.lock_outline,
                  isObscure: true),

              const SizedBox(height: 40),

              _buildPrimaryButton("CREATE ACCOUNT", _handleRegister),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Reusable Components ---

  Widget _buildInputField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isObscure = false,
    TextInputType type = TextInputType.text,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: type,
        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF00A844), size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A844),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1),
              ),
      ),
    );
  }
}