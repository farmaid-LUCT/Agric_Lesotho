// import 'package:flutter/material.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/google_auth_service.dart';
// import '../widgets/password_strength_indicator.dart';
// import '../../../core/widgets/responsive_auth_wrapper.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final AuthService _auth = AuthService();
//   final GoogleAuthService _googleAuth = GoogleAuthService();

//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _locationController = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool _isLoading = false;
//   bool _isGoogleLoading = false;
//   bool _obscurePassword = true;
//   bool _isPasswordStrongEnough = false;

//   @override
//   void initState() {
//     super.initState();
//     // Listen to password changes safely
//     _passwordController.addListener(_onPasswordChanged);
//   }

//   // This prevents the "setState() during build" error by ensuring 
//   // updates happen outside the immediate build pipeline.
//   void _onPasswordChanged() {
//     if (!mounted) return;
//     setState(() {}); 
//   }

//   @override
//   void dispose() {
//     _passwordController.removeListener(_onPasswordChanged);
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _usernameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _locationController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // ... [Keep _handleRegister, _handleGoogleSignUp, _showVerificationDialog, and _showError exactly as they were] ...
  
//   void _handleRegister() async {
//     if (_emailController.text.isEmpty ||
//         _passwordController.text.isEmpty ||
//         _firstNameController.text.isEmpty) {
//       _showError('Please fill in all required fields (*)');
//       return;
//     }
//     if (!_emailController.text.contains('@')) {
//       _showError('Please enter a valid email address');
//       return;
//     }
//     if (!_isPasswordStrongEnough) {
//       _showError('Please choose a stronger password before continuing.');
//       return;
//     }

//     setState(() => _isLoading = true);
//     try {
//       final bool success = await _auth.signUp(
//         _firstNameController.text.trim(),
//         _emailController.text.trim(),
//         _lastNameController.text.trim(),
//         _phoneController.text.trim(),
//         _locationController.text.trim(),
//         _passwordController.text.trim(),
//         Localizations.localeOf(context).languageCode,
//         _usernameController.text.trim().isEmpty
//             ? _emailController.text.trim()
//             : _usernameController.text.trim(),
//       );

//       if (!mounted) return;
//       setState(() => _isLoading = false);

//       if (success) {
//         _showVerificationDialog();
//       } else {
//         _showError('Registration failed. Email taken or password too weak.');
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       _showError('Registration failed. Please try again.');
//     }
//   }

//   void _handleGoogleSignUp() async {
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
//       _showError(result['message'] ?? 'Google sign-up failed.');
//     }
//   }

//   void _showVerificationDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Column(
//           children: [
//             Icon(Icons.mark_email_read, color: Color(0xFF00A844), size: 50),
//             SizedBox(height: 10),
//             Text('Verify Your Email', textAlign: TextAlign.center),
//           ],
//         ),
//         content: Text(
//           'Dumela, ${_firstNameController.text.trim()}! \n\n'
//           'Check your inbox for ${_emailController.text.trim()} to activate your account.',
//           textAlign: TextAlign.center,
//         ),
//         actionsAlignment: MainAxisAlignment.center,
//         actions: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844)),
//             child: const Text('PROCEED TO LOGIN', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(message),
//       backgroundColor: Colors.redAccent,
//       behavior: SnackBarBehavior.floating,
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     final bool isWide = MediaQuery.of(context).size.width > 600;

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         iconTheme: IconThemeData(color: isDark ? Colors.greenAccent : Colors.green),
//       ),
//       body: isWide
//           ? ResponsiveAuthWrapper(maxWidth: 520, child: _buildFormContent(isDark))
//           : SafeArea(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//                 child: _buildFormContent(isDark),
//               ),
//             ),
//     );
//   }

//   Widget _buildFormContent(bool isDark) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Icon(Icons.eco, size: 56, color: Color(0xFF00A844)),
//         const SizedBox(height: 8),
//         Text('Farmer Registration',
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20))),
//         const SizedBox(height: 24),
//         _buildGoogleButton(isDark),
//         const SizedBox(height: 20),
//         _buildDivider(isDark),
//         const SizedBox(height: 20),
//         _buildInputField('First Name *', _firstNameController, Icons.person_outline, isDark: isDark),
//         const SizedBox(height: 12),
//         _buildInputField('Last Name', _lastNameController, Icons.person_outline, isDark: isDark),
//         const SizedBox(height: 12),
//         _buildInputField('Username (Optional)', _usernameController, Icons.alternate_email, isDark: isDark),
//         const SizedBox(height: 12),
//         _buildInputField('Email Address *', _emailController, Icons.email_outlined, isDark: isDark, type: TextInputType.emailAddress),
//         const SizedBox(height: 12),
//         _buildInputField('Phone Number', _phoneController, Icons.phone, isDark: isDark, type: TextInputType.phone),
//         const SizedBox(height: 12),
//         _buildInputField('Farm Location', _locationController, Icons.map_outlined, isDark: isDark),
//         const SizedBox(height: 12),
//         _buildPasswordField(isDark),
        
//         // Use postFrameCallback here to prevent the crash during typing
//         PasswordStrengthIndicator(
//           password: _passwordController.text,
//           onStrengthChanged: (strength) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) {
//                 final isStrong = strength.index >= PasswordStrength.strong.index;
//                 if (_isPasswordStrongEnough != isStrong) {
//                   setState(() => _isPasswordStrongEnough = isStrong);
//                 }
//               }
//             });
//           },
//         ),

//         const SizedBox(height: 28),
//         _buildPrimaryButton('CREATE ACCOUNT', _handleRegister, isDark),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   // ... [The helper widgets stay mostly the same, but notice the onChanged is removed from _buildPasswordField] ...

//   Widget _buildPasswordField(bool isDark) {
//     return Container(
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: isDark ? Border.all(color: Colors.white10) : null,
//       ),
//       child: TextField(
//         controller: _passwordController,
//         obscureText: _obscurePassword,
//         // REMOVED onChanged: (_) => setState(() {}), 
//         // Logic is now handled by the listener in initState
//         style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black),
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00A844), size: 20),
//           hintText: 'Password *',
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//           suffixIcon: IconButton(
//             icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
//             onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//           ),
//         ),
//       ),
//     );
//   }

//   // [Remaining helper methods: _buildGoogleButton, _buildDivider, _buildInputField, _buildPrimaryButton remain the same]
//   Widget _buildGoogleButton(bool isDark) {
//     return SizedBox(
//       width: double.infinity,
//       height: 52,
//       child: OutlinedButton(
//         onPressed: _isGoogleLoading ? null : _handleGoogleSignUp,
//         style: OutlinedButton.styleFrom(
//           side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
//         ),
//         child: _isGoogleLoading
//             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
//             : const Text('Sign up with Google', style: TextStyle(fontWeight: FontWeight.w600)),
//       ),
//     );
//   }

//   Widget _buildDivider(bool isDark) {
//     return Row(children: [
//       Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
//       const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or register with email', style: TextStyle(fontSize: 12, color: Colors.grey))),
//       Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
//     ]);
//   }

//   Widget _buildInputField(String hint, TextEditingController controller, IconData icon, {required bool isDark, TextInputType type = TextInputType.text}) {
//     return Container(
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: isDark ? Border.all(color: Colors.white10) : null,
//       ),
//       child: TextField(
//         controller: controller,
//         keyboardType: type,
//         style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black),
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: const Color(0xFF00A844), size: 20),
//           hintText: hint,
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//         ),
//       ),
//     );
//   }

//   Widget _buildPrimaryButton(String text, VoidCallback onPressed, bool isDark) {
//     final bool canSubmit = !_isLoading && _isPasswordStrongEnough;
//     return SizedBox(
//       width: double.infinity,
//       height: 52,
//       child: ElevatedButton(
//         onPressed: canSubmit ? onPressed : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: canSubmit ? const Color(0xFF00A844) : Colors.grey.shade400,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         child: _isLoading
//             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//             : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this to pubspec.yaml
import '../../../services/auth_service.dart';
import '../../../services/google_auth_service.dart';
import '../widgets/password_strength_indicator.dart';
import '../../../core/widgets/responsive_auth_wrapper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final GoogleAuthService _googleAuth = GoogleAuthService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _isPasswordStrongEnough = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (!mounted) return;
    setState(() {}); 
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    // Basic Validation
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstNameController.text.isEmpty) {
      _showError('Please fill in all required fields (*)');
      return;
    }
    if (!_emailController.text.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }
    if (!_isPasswordStrongEnough) {
      _showError('Please choose a stronger password before continuing.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bool success = await _auth.signUp(
        _firstNameController.text.trim(),
        _emailController.text.trim(),
        _lastNameController.text.trim(),
        _phoneController.text.trim(),
        _locationController.text.trim(),
        _passwordController.text.trim(),
        Localizations.localeOf(context).languageCode,
        _usernameController.text.trim().isEmpty
            ? _emailController.text.trim()
            : _usernameController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        _showVerificationDialog();
      } else {
        _showError('Registration failed. Email taken or server error.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Connection error. Is the backend waking up?');
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.mark_email_unread_rounded, color: Color(0xFF00A844), size: 64),
            SizedBox(height: 16),
            Text('Check Your Email', 
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dumela, ${_firstNameController.text.trim()}!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent an activation link to:\n${_emailController.text.trim()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please click the link in the email to activate your FarmAid account.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsOverflowButtonSpacing: 10,
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // Option to open email app directly
          TextButton(
            onPressed: () async {
              final Uri emailLaunchUri = Uri(scheme: 'mailto');
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              }
            },
            child: const Text('OPEN EMAIL APP', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close Dialog
              Navigator.pushReplacementNamed(context, '/login'); // Go to Sign In
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A844),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('PROCEED TO LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDER METHODS ---

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1FAF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.greenAccent : Colors.green),
      ),
      body: isWide
          ? ResponsiveAuthWrapper(maxWidth: 520, child: _buildFormContent(isDark))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: _buildFormContent(isDark),
              ),
            ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.eco, size: 56, color: Color(0xFF00A844)),
        const SizedBox(height: 8),
        Text('Farmer Registration',
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.greenAccent : const Color(0xFF1B5E20)
            )),
        const SizedBox(height: 24),
        _buildGoogleButton(isDark),
        const SizedBox(height: 20),
        _buildDivider(isDark),
        const SizedBox(height: 20),
        _buildInputField('First Name *', _firstNameController, Icons.person_outline, isDark: isDark),
        const SizedBox(height: 12),
        _buildInputField('Last Name', _lastNameController, Icons.person_outline, isDark: isDark),
        const SizedBox(height: 12),
        _buildInputField('Username (Optional)', _usernameController, Icons.alternate_email, isDark: isDark),
        const SizedBox(height: 12),
        _buildInputField('Email Address *', _emailController, Icons.email_outlined, isDark: isDark, type: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildInputField('Phone Number', _phoneController, Icons.phone, isDark: isDark, type: TextInputType.phone),
        const SizedBox(height: 12),
        _buildInputField('Farm Location', _locationController, Icons.map_outlined, isDark: isDark),
        const SizedBox(height: 12),
        _buildPasswordField(isDark),
        
        PasswordStrengthIndicator(
          password: _passwordController.text,
          onStrengthChanged: (strength) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final isStrong = strength.index >= PasswordStrength.strong.index;
                if (_isPasswordStrongEnough != isStrong) {
                  setState(() => _isPasswordStrongEnough = isStrong);
                }
              }
            });
          },
        ),

        const SizedBox(height: 28),
        _buildPrimaryButton('CREATE ACCOUNT', _handleRegister, isDark),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildPasswordField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00A844), size: 20),
          hintText: 'Password *',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignUp,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        ),
        child: _isGoogleLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
            : const Text('Sign up with Google', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _handleGoogleSignUp() async {
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
      _showError(result['message'] ?? 'Google sign-up failed.');
    }
  }

  Widget _buildDivider(bool isDark) {
    return Row(children: [
      Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or register with email', style: TextStyle(fontSize: 12, color: Colors.grey))),
      Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
    ]);
  }

  Widget _buildInputField(String hint, TextEditingController controller, IconData icon, {required bool isDark, TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF00A844), size: 20),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed, bool isDark) {
    final bool canSubmit = !_isLoading && _isPasswordStrongEnough;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canSubmit ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? const Color(0xFF00A844) : Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }
}