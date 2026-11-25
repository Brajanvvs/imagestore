import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF3F0EA);
  static const ink = Color(0xFF1C1915);
  static const copper = Color(0xFFC4622D);
  static const muted = Color(0xFF746E66);
  static const line = Color(0xFFE4DDD2);
  static const field = Color(0xFFF8F5F0);
  static const danger = Color(0xFFB42318);
  static const success = Color(0xFF2F6B4F);
}

ThemeData buildAppTheme() {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: AppColors.line),
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.copper,
      primary: AppColors.ink,
      surface: Colors.white,
      error: AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.muted),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB9B3AA),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.ink,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    dividerColor: AppColors.line,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
