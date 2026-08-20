import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Ocean Color Palette
  static const Color primary = Color(0xFF0A4D68);       // Deep Oceanic Navy
  static const Color primaryDark = Color(0xFF082032);   // Midnight Sea
  static const Color secondary = Color(0xFF088395);     // Oceanic Teal
  static const Color accent = Color(0xFF05BFDB);        // Bright Cyan
  static const Color background = Color(0xFFF4F9FD);    // Soft Sea Foam / Mist
  static const Color surface = Colors.white;            // Card Surface
  static const Color surfaceLight = Color(0xFFE8F4F8);  // Ice Blue

  // Accents & Indicators
  static const Color coral = Color(0xFFFF6B6B);         // Fresh Coral / Danger
  static const Color emerald = Color(0xFF10B981);       // Paid / In Stock / Success
  static const Color amber = Color(0xFFF59E0B);         // Pending / Rating / Warning
  static const Color violet = Color(0xFF8B5CF6);        // Special Badge

  // Typography Colors
  static const Color textPrimary = Color(0xFF1E293B);   // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400
  static const Color border = Color(0xFFE2E8F0);        // Slate 200

  // Gradients
  static const LinearGradient marineGradient = LinearGradient(
    colors: [primary, secondary, Color(0xFF0EA5B5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanDepthGradient = LinearGradient(
    colors: [primaryDark, primary, secondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFF0A4D68), Color(0xFF088395)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        error: coral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.outfit(
          color: textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: secondary,
        suffixIconColor: textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: coral, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.transparent),
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
