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

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
  // LOGIN FUNCTION
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
      // Login through AuthService
      final Map<String, dynamic>? userData =
          await authService.loginUser(
        email,
        password,
      );

      if (!mounted) return;

      if (userData == null) {
        setState(() {
          isLoading = false;
        });

        _showMessage(
          'User profile not found.',
        );

        return;
      }

      // Get user role from Firestore
      final String role =
          userData['role']?.toString() ?? '';

      if (role.isEmpty) {
        setState(() {
          isLoading = false;
        });

        _showMessage(
          'User role is missing.',
        );

        return;
      }

      // Stop loading before navigation
      setState(() {
        isLoading = false;
      });

      // ===========================
      // ADMIN
      // ===========================

      if (role == 'Admin') {
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

      if (role == 'Exporter') {
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

      if (role == 'Buyer') {
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
        'Invalid user role.',
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
  // BUILD UI
  // ===========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),

      // ===========================
      // APP BAR
      // ===========================

      appBar: AppBar(
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'MaarinLink Login',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ===========================
      // BODY
      // ===========================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
              const SizedBox(height: 20),

              // ===========================
              // LOGO
              // ===========================

              const CircleAvatar(
                radius: 55,
                backgroundColor: Color(0xff0A4D68),
                child: Icon(
                  Icons.anchor,
                  color: Colors.white,
                  size: 55,
                ),
              ),

              const SizedBox(height: 20),

              // ===========================
              // APP NAME
              // ===========================

              const Text(
                'MaarinLink',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0A4D68),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Fish Export Management System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // ===========================
              // EMAIL
              // ===========================

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,

                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',

                  prefixIcon: const Icon(
                    Icons.email_outlined,
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xff0A4D68),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ===========================
              // PASSWORD
              // ===========================

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction:
                    TextInputAction.done,

                onSubmitted: (_) {
                  if (!isLoading) {
                    login();
                  }
                },

                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',

                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),

                    onPressed: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xff0A4D68),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // ===========================
              // FORGOT PASSWORD
              // ===========================

              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : forgotPassword,

                  child: const Text(
                    'Forgot Password?',
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ===========================
              // LOGIN BUTTON
              // ===========================

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff0A4D68),

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        Colors.grey,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  onPressed:
                      isLoading ? null : login,

                  child: isLoading
                      ? const SizedBox(
                          width: 25,
                          height: 25,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // ===========================
              // REGISTER
              // ===========================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  const Text(
                    "Don't have an account?",
                  ),

                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterScreen(),
                              ),
                            );
                          },

                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ===========================
              // ROLE INFORMATION
              // ===========================

              const Text(
                'Login as Buyer, Exporter or Admin',
                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}