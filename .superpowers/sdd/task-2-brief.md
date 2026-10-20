# Task 2 Brief: Design Tokens, Themes & Responsive Breakpoints

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/core/theme/gemini_colors.dart`:
   - Exact Gemini Dark palette:
     - `darkBackground` = `Color(0xFF131314)`
     - `darkSurface` = `Color(0xFF1E1F20)`
     - `darkHover` = `Color(0xFF282A2C)`
     - `darkBorder` = `Color(0xFF3C4043)`
     - `darkTextPrimary` = `Color(0xFFE3E3E3)`
     - `darkTextSecondary` = `Color(0xFFC4C7C5)`
   - Exact Gemini Light palette:
     - `lightBackground` = `Color(0xFFFFFFFF)`
     - `lightSurface` = `Color(0xFFF0F4F9)`
     - `lightHover` = `Color(0xFFE1E5EA)`
     - `lightBorder` = `Color(0xFFE3E3E3)`
     - `lightTextPrimary` = `Color(0xFF1F1F1F)`
     - `lightTextSecondary` = `Color(0xFF444746)`
   - Gemini Signature Gradient colors:
     - `gradientBlue` = `Color(0xFF4285F4)`
     - `gradientPurple` = `Color(0xFF9B72CB)`
     - `gradientCoral` = `Color(0xFFD96570)`
     - `geminiGradient` LinearGradient with these 3 colors
2. Create `frontend/lib/core/theme/app_theme.dart`:
   - `AppTheme.darkTheme`: Material 3 ThemeData with `GeminiColors.darkBackground`, custom ColorScheme, GoogleFonts text theme, and transparent AppBar.
   - `AppTheme.lightTheme`: Material 3 ThemeData with `GeminiColors.lightBackground`, light ColorScheme, GoogleFonts text theme, and transparent AppBar.
3. Create `frontend/lib/core/constants/breakpoints.dart`:
   - `mobileBreakpoint = 768.0`
   - Helper methods: `isMobile(BuildContext context)`, `isDesktop(BuildContext context)`
4. Create test `frontend/test/theme_test.dart`:
   - Asserts color constants match exact hex values.
   - Asserts Dark and Light ThemeData produce correct brightness and background colors.
5. Run `flutter test test/theme_test.dart` and `flutter analyze` from `E:\gemini-clone\frontend`.
6. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-2-report.md`.
