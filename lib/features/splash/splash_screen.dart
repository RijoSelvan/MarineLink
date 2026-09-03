import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_dashboard.dart';
import '../auth/login_screen.dart';
import '../buyer/buyer_dashboard.dart';
import '../exporter/exporter_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(
      const Duration(seconds: 3),
      _checkUser,
    );
  }

  // ===========================
  // CHECK CURRENT USER
  // ===========================

  Future<void> _checkUser() async {
    if (!mounted) return;

    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      // ===========================
      // NO USER LOGGED IN
      // ===========================

      if (user == null) {
        _goToLogin();
        return;
      }

      // ===========================
      // GET USER DATA
      // ===========================

      final DocumentSnapshot<Map<String, dynamic>>
          document =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      // ===========================
      // USER DOCUMENT NOT FOUND
      // ===========================

      if (!document.exists ||
          document.data() == null) {
        await FirebaseAuth.instance.signOut();

        _goToLogin();
        return;
      }

      final Map<String, dynamic> userData =
          document.data()!;

      final String role =
          userData['role']?.toString() ?? '';

      // ===========================
      // REDIRECT BASED ON ROLE
      // ===========================

      if (role == 'Admin') {
        _goToAdmin();
      } else if (role == 'Exporter') {
        _goToExporter();
      } else if (role == 'Buyer') {
        _goToBuyer();
      } else {
        // Invalid role
        await FirebaseAuth.instance.signOut();

        _goToLogin();
      }
    } catch (e) {
      // If something goes wrong,
      // send user back to login.

      if (!mounted) return;

      _goToLogin();
    }
  }

  // ===========================
  // GO TO LOGIN
  // ===========================

  void _goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ===========================
  // GO TO ADMIN DASHBOARD
  // ===========================

  void _goToAdmin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminDashboard(),
      ),
    );
  }

  // ===========================
  // GO TO EXPORTER DASHBOARD
  // ===========================

  void _goToExporter() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ExporterDashboard(),
      ),
    );
  }

  // ===========================
  // GO TO BUYER DASHBOARD
  // ===========================

  void _goToBuyer() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const BuyerDashboard(),
      ),
    );
  }

  // ===========================
  // DISPOSE
  // ===========================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ===========================
  // BUILD
  // ===========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF061A28),
              Color(0xFF0A4D68),
              Color(0xFF088395),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Emblem
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF05BFDB).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.anchor_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // App Name
              const Text(
                'MarineLink',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 10),

              // Tagline Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Global Seafood Export Platform',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Loading Indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: Color(0xFF05BFDB),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Connecting Marine Markets...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}