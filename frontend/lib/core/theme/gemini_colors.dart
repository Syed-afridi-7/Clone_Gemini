import 'package:flutter/material.dart';

class GeminiColors {
  // Dark Theme Palette (Default)
  static const Color darkBackground = Color(0xFF131314);
  static const Color darkSurface = Color(0xFF1E1F20);
  static const Color darkHover = Color(0xFF282A2C);
  static const Color darkBorder = Color(0xFF3C4043);
  static const Color darkTextPrimary = Color(0xFFE3E3E3);
  static const Color darkTextSecondary = Color(0xFFC4C7C5);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF0F4F9);
  static const Color lightHover = Color(0xFFE1E5EA);
  static const Color lightBorder = Color(0xFFE3E3E3);
  static const Color lightTextPrimary = Color(0xFF1F1F1F);
  static const Color lightTextSecondary = Color(0xFF444746);

  // Google Gemini Signature Gradient Accent Colors
  static const Color gradientBlue = Color(0xFF4285F4);
  static const Color gradientPurple = Color(0xFF9B72CB);
  static const Color gradientCoral = Color(0xFFD96570);

  static const LinearGradient geminiGradient = LinearGradient(
    colors: [gradientBlue, gradientPurple, gradientCoral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
