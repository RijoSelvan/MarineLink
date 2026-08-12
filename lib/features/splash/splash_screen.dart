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
      backgroundColor: const Color(0xff0A4D68),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            // ===========================
            // LOGO
            // ===========================

            const Icon(
              Icons.anchor,
              size: 120,
              color: Colors.white,
            ),

            const SizedBox(height: 20),

            // ===========================
            // APP NAME
            // ===========================

            const Text(
              'MaarinLink',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ===========================
            // TAGLINE
            // ===========================

            const Text(
              'Connecting Marine Businesses',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 50),

            // ===========================
            // LOADING
            // ===========================

            const SizedBox(
              width: 35,
              height: 35,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}