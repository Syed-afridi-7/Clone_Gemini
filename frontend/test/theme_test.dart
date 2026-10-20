import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/gemini_colors.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/constants/breakpoints.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('GeminiColors defines exact dark and light hex values', () {
    expect(GeminiColors.darkBackground, const Color(0xFF131314));
    expect(GeminiColors.darkSurface, const Color(0xFF1E1F20));
    expect(GeminiColors.darkHover, const Color(0xFF282A2C));
    expect(GeminiColors.darkBorder, const Color(0xFF3C4043));
    expect(GeminiColors.lightBackground, const Color(0xFFFFFFFF));
    expect(GeminiColors.lightSurface, const Color(0xFFF0F4F9));
    expect(GeminiColors.gradientBlue, const Color(0xFF4285F4));
    expect(GeminiColors.gradientPurple, const Color(0xFF9B72CB));
    expect(GeminiColors.gradientCoral, const Color(0xFFD96570));
  });

  test('AppTheme generates valid ThemeData for Dark and Light modes', () {
    final dark = AppTheme.darkTheme;
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, GeminiColors.darkBackground);

    final light = AppTheme.lightTheme;
    expect(light.brightness, Brightness.light);
    expect(light.scaffoldBackgroundColor, GeminiColors.lightBackground);
  });

  test('Breakpoints defines standard screen threshold', () {
    expect(Breakpoints.mobile, 768.0);
    expect(Breakpoints.tablet, 1024.0);
  });
}
