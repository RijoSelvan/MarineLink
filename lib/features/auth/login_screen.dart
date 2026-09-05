import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../buyer/buyer_dashboard.dart';
import '../exporter/exporter_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ===========================
  // CONTROLLERS
  // ===========================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // ===========================
  // SERVICES
  // ===========================

  final AuthService authService = AuthService();

  // ===========================
  // VARIABLES
  // ===========================

  bool obscurePassword = true;
  bool isLoading = false;

  // ===========================
  // DISPOSE
  // ===========================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ===========================
  // LOGIN
  // ===========================

  Future<void> login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    // Validate fields
    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter your email and password.',
      );
      return;
    }

    // Basic email validation
    if (!email.contains('@')) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Login through Firebase Auth
      final Map<String, dynamic>? userData =
          await authService.loginUser(
        email,
        password,
      );

      if (!mounted) return;

      // Check Firestore profile
      if (userData == null) {
        setState(() {
          isLoading = false;
        });

        _showMessage(
          'User profile not found.',
        );

        return;
      }

      // ===========================
      // GET ROLE
      // ===========================

      final dynamic roleValue = userData['role'];

      if (roleValue == null) {
        setState(() {
          isLoading = false;
        });

        _showMessage(
          'User role is missing from your profile.',
        );

        return;
      }

      // Convert role to lowercase.
      //
      // This allows:
      // Admin / admin / ADMIN
      // Buyer / buyer / BUYER
      // Exporter / exporter / EXPORTER
      final String role =
          roleValue.toString().trim().toLowerCase();

      debugPrint('Logged in user role: $role');

      // Stop loading before navigation
      setState(() {
        isLoading = false;
      });

      // ===========================
      // ADMIN
      // ===========================

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AdminDashboard(),
          ),
        );

        return;
      }

      // ===========================
      // EXPORTER
      // ===========================

      if (role == 'exporter') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ExporterDashboard(),
          ),
        );

        return;
      }

      // ===========================
      // BUYER
      // ===========================

      if (role == 'buyer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const BuyerDashboard(),
          ),
        );

        return;
      }

      // ===========================
      // INVALID ROLE
      // ===========================

      _showMessage(
        'Invalid user role: $role',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ===========================
  // SHOW MESSAGE
  // ===========================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===========================
  // FORGOT PASSWORD
  // ===========================

  Future<void> forgotPassword() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email address first.',
      );
      return;
    }

    if (!email.contains('@')) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    try {
      await authService.resetPassword(email);

      if (!mounted) return;

      _showMessage(
        'Password reset email has been sent.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ===========================
  // BUILD
  // ===========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Oceanic Header with Curved Wave
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF061A28),
                    Color(0xFF0A4D68),
                    Color(0xFF088395),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF05BFDB).withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.anchor_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MarineLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Global Seafood Export & Trading',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Login Card Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A4D68).withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in to access your portal',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'e.g. buyer@marinelink.com',
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF088395), size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF088395), width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!isLoading) login();
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF088395), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF088395), width: 2),
                        ),
                      ),
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : forgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF088395),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Login Button with Gradient & Shadow
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0A4D68),
                            Color(0xFF088395),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A4D68).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              color: Color(0xFF088395),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Role Pills Information
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  const Text(
                    'PORTAL ACCESS AVAILABLE FOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRoleBadge('Buyer', Icons.shopping_bag_outlined, const Color(0xFF0A4D68)),
                      const SizedBox(width: 8),
                      _buildRoleBadge('Exporter', Icons.local_shipping_outlined, const Color(0xFF088395)),
                      const SizedBox(width: 8),
                      _buildRoleBadge('Admin', Icons.admin_panel_settings_outlined, const Color(0xFF05BFDB)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}