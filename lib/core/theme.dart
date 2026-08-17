import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1D5ED9);
  static const primaryDark = Color(0xFF1547A8);
  static const primaryLight = Color(0xFFEAF1FE);
  static const background = Color(0xFFF6F8FC);
  static const textDark = Color(0xFF202A3C);
  static const textGrey = Color(0xFF8A94A6);
  static const border = Color(0xFFE4E9F2);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background, foregroundColor: AppColors.textDark,
      elevation: 0, centerTitle: true,
      titleTextStyle: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    )),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white, selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textGrey, type: BottomNavigationBarType.fixed, elevation: 8,
    ),
  );
}