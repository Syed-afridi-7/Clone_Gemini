# Task 10 Brief: Adaptive Shell, Main Integration & Final Verification

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/views/adaptive_shell.dart`:
   - Uses `LayoutBuilder` to determine width (`Breakpoints.isMobile(context)`).
   - Desktop view:
     - Side-by-side row: `SidebarDrawerWidget` (visible when `controller.isSidebarOpen`, with animated slide transition) + main chat body.
   - Mobile view:
     - Scaffold with `drawer: SidebarDrawerWidget()`.
   - Main Chat Body:
     - Top: `GeminiAppBar()`.
     - Center: If `controller.messages.isEmpty`, renders `EmptyStateView(onSuggestionSelected: ...)`. Otherwise, renders `ListView.builder` of `MessageBubbleWidget` with `ScrollController` auto-scrolling to bottom during streaming.
     - Bottom: Floating `PromptInputBarWidget()` constrained to max-width 820px.
2. Update `frontend/lib/main.dart`:
   - Calls `WidgetsFlutterBinding.ensureInitialized()`.
   - Initializes `StorageService` and `MockGeminiEngine`.
   - Wraps app in `ChangeNotifierProvider<ChatController>` with `controller.initialize()`.
   - Configures `MaterialApp` with `AppTheme.darkTheme`, `AppTheme.lightTheme`, and dynamic `controller.themeMode`.
   - Home: `AdaptiveShell()`.
3. Create `frontend/test/adaptive_shell_test.dart`:
   - Tests full app renders without errors.
   - Tests submitting prompt generates model response in chat feed.
4. Run full test suite: `flutter test`.
5. Run full static analysis: `flutter analyze`.
6. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-10-report.md`.
