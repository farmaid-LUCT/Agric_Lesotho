// import 'package:flutter/material.dart';
// import 'package:farm_aid_app/features/auth/presentation/register_screen.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/google_auth_service.dart';
// import '../../../core/widgets/responsive_auth_wrapper.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final AuthService       _auth       = AuthService();
//   final GoogleAuthService _googleAuth = GoogleAuthService();

//   final _emailController    = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool _isLoading       = false;
//   bool _isGoogleLoading = false;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _handleLogin() async {
//     final email    = _emailController.text.trim();
//     final password = _passwordController.text.trim();

//     if (email.isEmpty || password.isEmpty) {
//       _showError('Please enter both email and password');
//       return;
//     }

//     setState(() => _isLoading = true);
//     final result = await _auth.signIn(email, password);
//     if (!mounted) return;
//     setState(() => _isLoading = false);

//     if (result['success'] == true) {
//       final bool isAdmin = await _auth.isAdmin();
//       if (!mounted) return;
//       Navigator.pushReplacementNamed(
//         context,
//         isAdmin ? '/admin_dashboard' : '/dashboard',
//       );
//     } else {
//       if (result['error'] == 'unverified') {
//         _showResendActivationDialog(email);
//       } else {
//         _showError(result['message'] ?? 'Invalid email or password.');
//       }
//     }
//   }

//   void _handleGoogleSignIn() async {
//     setState(() => _isGoogleLoading = true);
//     final result = await _googleAuth.signInWithGoogle();
//     if (!mounted) return;
//     setState(() => _isGoogleLoading = false);

//     if (result['success'] == true) {
//       final bool isAdmin = await _auth.isAdmin();
//       if (!mounted) return;
//       Navigator.pushReplacementNamed(
//         context,
//         isAdmin ? '/admin_dashboard' : '/dashboard',
//       );
//     } else {
//       _showError(result['message'] ?? 'Google sign-in failed. Please try again.');
//     }
//   }

//   void _showResendActivationDialog(String email) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15)),
//         title: const Text('Verify Your Email'),
//         content: Text(
//           'Account found for $email, but it hasn\'t been activated yet. '
//           'Check your inbox for the link.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('CANCEL',
//                 style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               setState(() => _isLoading = true);
//               final resent = await _auth.resendActivationEmail(email);
//               if (!mounted) return;
//               setState(() => _isLoading = false);
//               if (resent) {
//                 _showSuccess('A new activation link has been sent!');
//               } else {
//                 _showError('Could not resend link. Please try again later.');
//               }
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             child: const Text('RESEND EMAIL',
//                 style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content:         Text(message),
//       backgroundColor: Colors.redAccent,
//       behavior:        SnackBarBehavior.floating,
//       margin:          const EdgeInsets.all(20),
//     ));
//   }

//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content:         Text(message),
//       backgroundColor: Colors.green,
//       behavior:        SnackBarBehavior.floating,
//       margin:          const EdgeInsets.all(20),
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     final bool isWide = MediaQuery.of(context).size.width > 600;

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       body: SafeArea(
//         child: isWide
//             // ── DESKTOP / CHROME — centered card ──────────────────────
//             ? ResponsiveAuthWrapper(
//                 child: _buildFormContent(isDark, padded: false),
//               )
//             // ── MOBILE — full screen scroll ───────────────────────────
//             : Center(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: _buildFormContent(isDark, padded: true),
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _buildFormContent(bool isDark, {required bool padded}) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (padded) const SizedBox(height: 20),
//         const Icon(Icons.eco, size: 64, color: Color(0xFF00A844)),
//         const SizedBox(height: 12),
//         Text(
//           'FarmAid Lesotho',
//           style: TextStyle(
//             fontSize:   24,
//             fontWeight: FontWeight.bold,
//             color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20),
//           ),
//         ),
//         const SizedBox(height: 4),
//         const Text(
//           'Grow Smarter. Feed the Nation.',
//           style: TextStyle(color: Colors.green, fontSize: 13),
//         ),
//         const SizedBox(height: 32),

//         // Email
//         _buildInputField(
//           'Email Address',
//           _emailController,
//           Icons.email_outlined,
//           keyboardType: TextInputType.emailAddress,
//           isDark: isDark,
//         ),
//         const SizedBox(height: 14),

//         // Password
//         _buildInputField(
//           'Password',
//           _passwordController,
//           Icons.lock_outline,
//           isPasswordField: true,
//           isDark: isDark,
//         ),
//         const SizedBox(height: 28),

//         // Sign In button
//         _buildPrimaryButton('Sign In', _handleLogin, isDark),
//         const SizedBox(height: 20),

//         _buildDivider(isDark),
//         const SizedBox(height: 20),

//         _buildGoogleButton(isDark),
//         const SizedBox(height: 20),

//         // Register link
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'New farmer?',
//               style: TextStyle(
//                   color: isDark ? Colors.white70 : Colors.black87),
//             ),
//             TextButton(
//               onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const RegisterScreen()),
//               ),
//               child: const Text(
//                 'Register here',
//                 style: TextStyle(
//                   color:      Color(0xFF00A844),
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         if (padded) const SizedBox(height: 20),
//       ],
//     );
//   }

//   Widget _buildGoogleButton(bool isDark) {
//     return SizedBox(
//       width:  double.infinity,
//       height: 52,
//       child: OutlinedButton(
//         onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
//         style: OutlinedButton.styleFrom(
//           side: BorderSide(
//               color: isDark ? Colors.white24 : Colors.black12),
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12)),
//           backgroundColor:
//               isDark ? const Color(0xFF2A2A2A) : Colors.white,
//         ),
//         child: _isGoogleLoading
//             ? const SizedBox(
//                 height: 20, width: 20,
//                 child: CircularProgressIndicator(
//                     color: Colors.green, strokeWidth: 2))
//             : Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 22, height: 22,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Color(0xFF4285F4),
//                     ),
//                     child: const Center(
//                       child: Text('G',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 13,
//                               fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     'Continue with Google',
//                     style: TextStyle(
//                       fontSize:   14,
//                       fontWeight: FontWeight.w600,
//                       color: isDark ? Colors.white : Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   Widget _buildDivider(bool isDark) {
//     return Row(
//       children: [
//         Expanded(child: Divider(
//             color: isDark ? Colors.white12 : Colors.black12)),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Text('or',
//               style: TextStyle(
//                   fontSize: 12,
//                   color: isDark ? Colors.white38 : Colors.black38)),
//         ),
//         Expanded(child: Divider(
//             color: isDark ? Colors.white12 : Colors.black12)),
//       ],
//     );
//   }

//   Widget _buildInputField(
//     String hint,
//     TextEditingController controller,
//     IconData icon, {
//     required bool isDark,
//     bool isPasswordField      = false,
//     TextInputType? keyboardType,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: isDark
//             ? []
//             : [BoxShadow(
//                 color: Colors.black.withOpacity(0.03),
//                 blurRadius: 10)],
//         border: isDark ? Border.all(color: Colors.white10) : null,
//       ),
//       child: TextField(
//         controller:   controller,
//         obscureText:  isPasswordField ? _obscurePassword : false,
//         keyboardType: keyboardType,
//         style: TextStyle(color: isDark ? Colors.white : Colors.black),
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: Colors.green, size: 20),
//           hintText:   hint,
//           hintStyle:  const TextStyle(fontSize: 14, color: Colors.grey),
//           border:     InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(vertical: 16),
//           suffixIcon: isPasswordField
//               ? IconButton(
//                   icon: Icon(
//                     _obscurePassword
//                         ? Icons.visibility_off_outlined
//                         : Icons.visibility_outlined,
//                     color: Colors.grey, size: 20,
//                   ),
//                   onPressed: () => setState(
//                       () => _obscurePassword = !_obscurePassword),
//                 )
//               : null,
//         ),
//       ),
//     );
//   }

//   Widget _buildPrimaryButton(
//       String text, VoidCallback onPressed, bool isDark) {
//     return SizedBox(
//       width:  double.infinity,
//       height: 52,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF00A844),
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12)),
//           elevation: 0,
//         ),
//         child: _isLoading
//             ? const SizedBox(
//                 height: 20, width: 20,
//                 child: CircularProgressIndicator(
//                     color: Colors.white, strokeWidth: 2))
//             : Text(text,
//                 style: const TextStyle(
//                     color:      Colors.white,
//                     fontSize:   15,
//                     fontWeight: FontWeight.bold)),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:farm_aid_app/features/auth/presentation/register_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/google_auth_service.dart';
import '../../../core/widgets/responsive_auth_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final GoogleAuthService _googleAuth = GoogleAuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController(); // Controller for Forgot Password

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // --- LOGIC HANDLERS ---

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    setState(() => _isLoading = true);
    final result = await _auth.signIn(email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final bool isAdmin = await _auth.isAdmin();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        isAdmin ? '/admin_dashboard' : '/dashboard',
      );
    } else {
      if (result['error'] == 'unverified') {
        _showResendActivationDialog(email);
      } else {
        _showError(result['message'] ?? 'Invalid email or password.');
      }
    }
  }

  void _handleForgotPassword() async {
    final email = _resetEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }

    Navigator.pop(context); // Close the dialog/bottom sheet
    setState(() => _isLoading = true);
    
    // Assuming you have a requestPasswordReset method in your AuthService
    final bool success = await _auth.requestPasswordReset(email);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccess('Password reset link sent to your email!');
    } else {
      _showError('Failed to send reset link. Check your connection.');
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final result = await _googleAuth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      final bool isAdmin = await _auth.isAdmin();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        isAdmin ? '/admin_dashboard' : '/dashboard',
      );
    } else {
      _showError(result['message'] ?? 'Google sign-in failed. Please try again.');
    }
  }

  // --- DIALOGS & UI HELPERS ---

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your registered email and we will send you a link to reset your password.'),
            const SizedBox(height: 16),
            _buildInputField(
              'Email Address',
              _resetEmailController,
              Icons.email_outlined,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _handleForgotPassword,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844)),
            child: const Text('SEND LINK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResendActivationDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Verify Your Email'),
        content: Text('Account found for $email, but it hasn\'t been activated yet. Check your inbox for the link.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final resent = await _auth.resendActivationEmail(email);
              if (!mounted) return;
              setState(() => _isLoading = false);
              if (resent) {
                _showSuccess('A new activation link has been sent!');
              } else {
                _showError('Could not resend link. Please try again later.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('RESEND EMAIL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
    ));
  }

  // --- BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      body: SafeArea(
        child: isWide
            ? ResponsiveAuthWrapper(child: _buildFormContent(isDark, padded: false))
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildFormContent(isDark, padded: true),
                ),
              ),
      ),
    );
  }

  Widget _buildFormContent(bool isDark, {required bool padded}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (padded) const SizedBox(height: 20),
        const Icon(Icons.eco, size: 64, color: Color(0xFF00A844)),
        const SizedBox(height: 12),
        Text(
          'FarmAid Lesotho',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 4),
        const Text('Grow Smarter. Feed the Nation.', style: TextStyle(color: Colors.green, fontSize: 13)),
        const SizedBox(height: 32),

        _buildInputField('Email Address', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress, isDark: isDark),
        const SizedBox(height: 14),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildInputField('Password', _passwordController, Icons.lock_outline, isPasswordField: true, isDark: isDark),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF00A844), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        
        const SizedBox(height: 14),
        _buildPrimaryButton('Sign In', _handleLogin, isDark),
        const SizedBox(height: 20),
        _buildDivider(isDark),
        const SizedBox(height: 20),
        _buildGoogleButton(isDark),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New farmer?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Register here', style: TextStyle(color: Color(0xFF00A844), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (padded) const SizedBox(height: 20),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildInputField(String hint, TextEditingController controller, IconData icon, {required bool isDark, bool isPasswordField = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPasswordField ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A844),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        ),
        child: _isGoogleLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
            : const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(children: [
      Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(fontSize: 12, color: Colors.grey))),
      Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
    ]);
  }
}