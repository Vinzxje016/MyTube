import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette
  static const Color background = Color(0xFF090A0F);
  static const Color surface = Color(0xFF131622);
  static const Color surfaceLight = Color(0xFF1F2438);
  static const Color surfaceBorder = Color(0x1FFFFFFF);

  static const Color primary = Color(0xFF7C3AED); // Electric Purple
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color accent = Color(0xFFEC4899); // Neon Pink
  static const Color cyan = Color(0xFF06B6D4); // Neon Cyan
  static const Color emerald = Color(0xFF10B981); // Spotify-like Emerald

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanPurpleGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF181B2A), Color(0xFF11131E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [Color(0x337C3AED), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: ThemeData.dark(useMaterial3: true).textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryLight,
        unselectedItemColor: textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryLight,
        inactiveTrackColor: surfaceLight,
        thumbColor: Colors.white,
        overlayColor: primary.withAlpha(50),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 3,
      ),
    );
  }

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF3F5F8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6D28D9),
      secondary: Color(0xFFDB2777),
      surface: Colors.white,
      onSurface: Color(0xFF151821),
    ),
    textTheme: ThemeData.light(useMaterial3: true).textTheme.apply(
      bodyColor: const Color(0xFF151821),
      displayColor: const Color(0xFF151821),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF151821),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      selectedItemColor: Color(0xFF6D28D9),
      unselectedItemColor: Color(0xFF64748B),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

extension AppThemeColors on BuildContext {
  bool get usesLightTheme => Theme.of(this).brightness == Brightness.light;
  Color get pageColor =>
      usesLightTheme ? const Color(0xFFF4F6FA) : AppTheme.background;
  Color get surfaceColor => usesLightTheme ? Colors.white : AppTheme.surface;
  Color get raisedSurfaceColor =>
      usesLightTheme ? const Color(0xFFEAEDF4) : AppTheme.surfaceLight;
  Color get borderColor =>
      usesLightTheme ? const Color(0xFFDDE2EA) : AppTheme.surfaceBorder;
  Color get primaryTextColor =>
      usesLightTheme ? const Color(0xFF171923) : AppTheme.textPrimary;
  Color get secondaryTextColor =>
      usesLightTheme ? const Color(0xFF51596A) : AppTheme.textSecondary;
  Color get mutedTextColor =>
      usesLightTheme ? const Color(0xFF737D90) : AppTheme.textMuted;
  Color get iconTextColor =>
      usesLightTheme ? const Color(0xFF3F4859) : AppTheme.textSecondary;
  Color get accentColor =>
      usesLightTheme ? const Color(0xFF6D28D9) : AppTheme.primaryLight;
}
