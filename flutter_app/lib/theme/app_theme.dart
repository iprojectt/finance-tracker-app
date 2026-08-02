import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep dark backgrounds
  static const background = Color(0xFF090B14);
  static const surface = Color(0xFF141824);
  static const surfaceLight = Color(0xFF1D2235);
  
  // Vibrant Accents (Dribbble style)
  static const accentPrimary = Color(0xFF7B61FF); // Vibrant Purple
  static const accentSecondary = Color(0xFF00E5FF); // Neon Cyan
  
  // Status Colors
  static const success = Color(0xFF00E676); // Bright Green
  static const error = Color(0xFFFF3B30); // Bright Red
  static const warning = Color(0xFFFFCC00); // Yellow
  
  // Text Colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8F95B2);
  
  // Borders and Dividers
  static const border = Color(0xFF2A2F45);
  
  // Legacy colors for backwards compatibility with other screens
  static const surfaceAlt = surfaceLight;
  static const accent = accentPrimary;
  static const accentGreen = success;
  static const accentRed = error;
  static const accentAmber = warning;
}

class AppGradients {
  static const primaryGradient = LinearGradient(
    colors: [AppColors.accentPrimary, AppColors.accentSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const glassGradient = LinearGradient(
    colors: [
      Color(0x22FFFFFF),
      Color(0x05FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData appTheme() {
  final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
  
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentPrimary,
      secondary: AppColors.accentSecondary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    
    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800, letterSpacing: -1.5),
      displayMedium: baseTextTheme.displayMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -1.0),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleLarge: baseTextTheme.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium: baseTextTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      labelSmall: baseTextTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    ),
    
    // Cards & Surfaces
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // App Bar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    
    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accentPrimary, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        elevation: 0,
      ),
    ),
    
    // Navigation
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.background,
      selectedIconTheme: IconThemeData(color: AppColors.accentSecondary),
      unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
      selectedLabelTextStyle: TextStyle(color: AppColors.accentSecondary, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.accentSecondary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
