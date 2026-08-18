import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette copied 1:1 from the original tailwind.config.js "brand"
/// color scale so the Flutter app matches the web design exactly.
class AppColors {
  AppColors._();

  static const brand50 = Color(0xFFEEFDFB);
  static const brand100 = Color(0xFFD5F8F3);
  static const brand200 = Color(0xFFAEF0E9);
  static const brand300 = Color(0xFF77E2D9);
  static const brand400 = Color(0xFF3CCBC2);
  static const brand500 = Color(0xFF17B0A8);
  static const brand600 = Color(0xFF0D8F8A);
  static const brand700 = Color(0xFF0F7370);
  static const brand800 = Color(0xFF115B5A);
  static const brand900 = Color(0xFF134C4B);

  static const bg = Color(0xFFF6F8FA);
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  static const red = Color(0xFFDC2626);
  static const red600 = Color(0xFFDC2626);
  static const redBg = Color(0xFFFEF2F2);
  static const redBorder = Color(0xFFFECACA);
  static const amber = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFFFBEB);
  static const amberBorder = Color(0xFFFDE68A);
  static const lime = Color(0xFF84CC16);
  static const limeBg = Color(0xFFF7FEE7);
  static const limeBorder = Color(0xFFD9F99D);
  static const green = Color(0xFF16A34A);
  static const green50 = Color(0xFFF0FDF4);
  static const green200 = Color(0xFFBBF7D0);
  static const green600 = Color(0xFF16A34A);
  static const green700 = Color(0xFF15803D);
  static const greenBg = Color(0xFFF0FDF4);
  static const greenBorder = Color(0xFFBBF7D0);
}


class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final textTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand600,
        primary: AppColors.brand600,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gray200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gray700,
          side: const BorderSide(color: AppColors.gray300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand500, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.gray200),
    );
  }
}

/// Responsive breakpoints used across the app: a permanent sidebar + wide
/// "premium website" layout on web/desktop/tablet-landscape, and a compact
/// bottom-nav mobile layout on phones.
class Responsive {
  Responsive._();

  static const double mobileMax = 720;
  static const double tabletMax = 1080;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  static double contentMaxWidth(BuildContext context, {double base = 1100}) {
    final w = MediaQuery.of(context).size.width;
    return w < base ? w : base;
  }
}
