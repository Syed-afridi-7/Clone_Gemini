import 'package:flutter/material.dart';
import 'gemini_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Outfit',
      fontFamilyFallback: const ['Roboto', 'Segoe UI', 'sans-serif'],
      scaffoldBackgroundColor: GeminiColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: GeminiColors.darkSurface,
        onSurface: GeminiColors.darkTextPrimary,
        outline: GeminiColors.darkBorder,
        primary: GeminiColors.gradientBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: GeminiColors.darkTextPrimary),
      ),
      dividerColor: GeminiColors.darkBorder,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Outfit',
      fontFamilyFallback: const ['Roboto', 'Segoe UI', 'sans-serif'],
      scaffoldBackgroundColor: GeminiColors.lightBackground,
      colorScheme: const ColorScheme.light(
        surface: GeminiColors.lightSurface,
        onSurface: GeminiColors.lightTextPrimary,
        outline: GeminiColors.lightBorder,
        primary: GeminiColors.gradientBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: GeminiColors.lightTextPrimary),
      ),
      dividerColor: GeminiColors.lightBorder,
    );
  }
}
