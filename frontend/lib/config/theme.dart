import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Scanalyze design system — dark-first, premium aesthetic
class AppTheme {
  AppTheme._();

  // ─── Colors ───
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF131829);
  static const Color bgCardLight = Color(0xFF1A2035);
  static const Color bgSurface = Color(0xFF0F1425);

  static const Color primary = Color(0xFF00E5A0);       // Emerald green
  static const Color primaryDark = Color(0xFF00B87D);
  static const Color secondary = Color(0xFF6C63FF);      // Soft violet
  static const Color accent = Color(0xFF00D4FF);          // Cyan

  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF8A93A6);
  static const Color textMuted = Color(0xFF5A6378);

  static const Color safe = Color(0xFF00E5A0);
  static const Color moderate = Color(0xFFFFA726);
  static const Color unsafe = Color(0xFFFF5252);

  static const Color dangerBg = Color(0x20FF5252);
  static const Color warningBg = Color(0x20FFA726);
  static const Color successBg = Color(0x2000E5A0);
  static const Color infoBg = Color(0x2000D4FF);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2035), Color(0xFF131829)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00B87D)],
  );

  static const LinearGradient moderateGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
  );

  static const LinearGradient unsafeGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
  );

  // ─── Border Radius ───
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ─── ThemeData ───
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: bgCard,
        error: unsafe,
        onPrimary: bgDark,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: bgDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCardLight,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: const Color(0xFF1E2538),
    );
  }

  // ─── Helpers ───
  static Color scoreColor(double score) {
    if (score >= 70) return safe;
    if (score >= 40) return moderate;
    return unsafe;
  }

  static LinearGradient scoreGradient(double score) {
    if (score >= 70) return safeGradient;
    if (score >= 40) return moderateGradient;
    return unsafeGradient;
  }

  static String safetyLabel(String safetyClass) {
    switch (safetyClass.toUpperCase()) {
      case 'SAFE':
        return 'Safe';
      case 'MODERATE':
        return 'Moderate';
      case 'UNSAFE':
        return 'Unsafe';
      default:
        return safetyClass;
    }
  }

  static IconData safetyIcon(String safetyClass) {
    switch (safetyClass.toUpperCase()) {
      case 'SAFE':
        return Icons.check_circle_rounded;
      case 'MODERATE':
        return Icons.warning_rounded;
      case 'UNSAFE':
        return Icons.dangerous_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}
