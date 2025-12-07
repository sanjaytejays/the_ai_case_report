import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicalTheme {
  // --- COLOR PALETTE ---
  static const _tealPrimary = Color(0xFF0F766E); // Teal 700
  static const _tealAccent = Color(0xFF14B8A6); // Teal 500
  static const _navyBackground = Color(0xFF0F172A); // Slate 900
  static const _navySurface = Color(0xFF1E293B); // Slate 800

  // --- TEXT THEME GENERATOR ---
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5),
      bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.5),
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _tealPrimary,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC), // Slate 50
      onSurface: const Color(0xFF1E293B),
      primary: _tealPrimary,
      secondaryContainer: const Color(0xFFF1F5F9), // Slate 100
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    textTheme: _buildTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200 border
      ),
    ),
    inputDecorationTheme: _inputTheme(Colors.white, const Color(0xFFE2E8F0)),
  );

  // --- DARK THEME ---
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _tealAccent,
      brightness: Brightness.dark,
      surface: _navySurface,
      onSurface: const Color(0xFFF8FAFC),
      primary: _tealAccent,
      secondaryContainer: const Color(0xFF334155),
    ),
    scaffoldBackgroundColor: _navyBackground,
    textTheme: _buildTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: _navySurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    ),
    inputDecorationTheme: _inputTheme(
      const Color(0xFF020617),
      Colors.white.withOpacity(0.1),
    ),
  );

  static InputDecorationTheme _inputTheme(Color fill, Color border) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _tealAccent, width: 2),
      ),
    );
  }
}
