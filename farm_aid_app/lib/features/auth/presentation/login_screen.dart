import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIN LOGIC ---
  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter both email and password");
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _auth.signIn(email, password);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      bool isAdmin = await _auth.isAdmin();
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context, 
        isAdmin ? '/admin_dashboard' : '/dashboard'
      );
    } else {
      if (result['error'] == 'unverified') {
        _showResendActivationDialog(email);
      } else {
        _showError(result['message'] ?? "Login failed. Please try again.");
      }
    }
  }

  // --- RESEND ACTIVATION DIALOG ---
  void _showResendActivationDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Verify Your Email"),
        content: Text("Account found for $email, but it hasn't been activated yet. Check your inbox for the link."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              bool resent = await _auth.resendActivationEmail(email);
              setState(() => _isLoading = false);
              
              if (resent) {
                _showSuccess("A new activation link has been sent!");
              } else {
                _showError("Could not resend link. Please try again later.");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("RESEND EMAIL", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Icon(Icons.eco, size: 80, color: Color(0xFF00A844)),
                const SizedBox(height: 16),
                Text(
                  "FarmAid Lesotho", 
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20)
                  )
                ),
                const Text("Grow Smarter. Feed the Nation.", style: TextStyle(color: Colors.green, fontSize: 14)),
                const SizedBox(height: 40),
                
                _buildInputField("Email Address", _emailController, Icons.email_outlined),
                const SizedBox(height: 16),
                
                _buildInputField(
                  "Password", 
                  _passwordController, 
                  Icons.lock_outline, 
                  isPasswordField: true,
                ),

                const SizedBox(height: 30),
                _buildPrimaryButton("Sign In", _handleLogin),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("New farmer?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (c) => const RegisterScreen())
                      ),
                      child: const Text("Register here", style: TextStyle(color: Color(0xFF00A844), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller, IconData icon, {bool isPasswordField = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPasswordField ? _obscurePassword : false,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          suffixIcon: isPasswordField 
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
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
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}