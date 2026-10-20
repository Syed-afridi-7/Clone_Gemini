# Google Gemini Frontend Clone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, pixel-faithful, responsive, cross-platform Google Gemini Frontend UI clone using Flutter 3.47+ in `E:\gemini-clone\frontend` with zero external API dependencies, featuring adaptive mobile/desktop layouts, animated token streaming, multimodal attachment previews, and local persistence.

**Architecture:** Layered feature-first architecture in Flutter (`core`, `models`, `services`, `state`, `views`). A reactive `ChatController` (`ChangeNotifier`) orchestrates conversations, streaming Dart `Stream<String>` tokens from a context-aware `MockGeminiEngine`, persisted locally via `StorageService`. An `AdaptiveShell` dynamically renders mobile touch ergonomics on small viewports and the full desktop web layout on large viewports.

**Tech Stack:** Flutter 3.47+, Dart 3.13+, `provider`, `flutter_markdown`, `flutter_highlight`, `google_fonts`, `shared_preferences`, `file_picker`.

**Spec:** [`E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`](file:///E:/gemini-clone/docs/superpowers/specs/2026-10-19-google-gemini-frontend-clone-design.md)

## Global Constraints

- Root location: `E:\gemini-clone` containing `frontend/` (Flutter app) and `backend/` (reserved directory).
- Zero external Gemini API calls or API keys; all streaming intelligence is self-contained.
- Strict Material 3 design tokens: Dark canvas `#131314`, Surface `#1E1F20`, Hover `#282A2C`, Border `#3C4043`, Gemini Gradient `#4285F4` → `#9B72CB` → `#D96570`.
- Light theme tokens: Canvas `#FFFFFF`, Surface `#F0F4F9`, Hover `#E1E5EA`, Border `#E3E3E3`.
- Responsive breakpoints: Mobile `< 768px`, Desktop `>= 768px`.
- Static analysis: `flutter analyze` must pass with zero issues.

---

### Task 1: Project Scaffolding & Directory Setup

**Files:**
- Create: `E:\gemini-clone\backend\README.md`
- Create: `E:\gemini-clone\frontend\pubspec.yaml`
- Test: `flutter analyze` & `flutter test`

**Interfaces:**
- Produces: Base Flutter workspace in `E:\gemini-clone\frontend` with verified dependencies.

- [ ] **Step 1: Create backend placeholder and scaffold Flutter project**
Create `E:\gemini-clone\backend\README.md` and initialize the Flutter project in `E:\gemini-clone\frontend` using `flutter create --org com.geminiclone --project-name frontend frontend`.

- [ ] **Step 2: Configure pubspec.yaml with project dependencies**
Update `frontend/pubspec.yaml` with:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  google_fonts: ^6.2.1
  flutter_markdown: ^0.7.4+1
  flutter_highlight: ^0.7.0
  shared_preferences: ^2.3.2
  file_picker: ^8.1.2
```

- [ ] **Step 3: Run flutter pub get and verify setup**
Run: `cd E:\gemini-clone\frontend && flutter pub get`  
Expected: Dependencies resolved with exit code 0.

---

### Task 2: Design Tokens, Themes & Responsive Breakpoints

**Files:**
- Create: `frontend/lib/core/theme/gemini_colors.dart`
- Create: `frontend/lib/core/theme/app_theme.dart`
- Create: `frontend/lib/core/constants/breakpoints.dart`
- Create: `frontend/test/theme_test.dart`

**Interfaces:**
- Produces: `GeminiColors` class, `AppTheme.darkTheme`, `AppTheme.lightTheme`, `Breakpoints.isMobile(context)`.

- [ ] **Step 1: Write unit test for color tokens and theme generation**
Create `frontend/test/theme_test.dart` asserting that `GeminiColors.darkBackground == Color(0xFF131314)` and `AppTheme.darkTheme.brightness == Brightness.dark`.

- [ ] **Step 2: Implement GeminiColors and AppTheme**
Implement `gemini_colors.dart` and `app_theme.dart` with exact Google Gemini dark/light tokens and Google Sans / Roboto typography.

- [ ] **Step 3: Run test to verify**
Run: `flutter test test/theme_test.dart`  
Expected: PASS.

---

### Task 3: Domain Models (Message, Session, Model Type, Attachment)

**Files:**
- Create: `frontend/lib/models/gemini_model_type.dart`
- Create: `frontend/lib/models/chat_message.dart`
- Create: `frontend/lib/models/chat_session.dart`
- Create: `frontend/test/models_test.dart`

**Interfaces:**
- Consumes: Dart primitive types.
- Produces: `GeminiModelType` (flash, pro, advanced), `ChatMessage`, `ChatSession` with `toJson()` and `fromJson()`.

- [ ] **Step 1: Write model serialization tests**
Create `frontend/test/models_test.dart` testing `ChatMessage` and `ChatSession` serialization and deserialization.

- [ ] **Step 2: Implement models**
Implement `gemini_model_type.dart`, `chat_message.dart`, and `chat_session.dart` supporting role, text, timestamp, attachments, and pinned state.

- [ ] **Step 3: Run test to verify**
Run: `flutter test test/models_test.dart`  
Expected: PASS.

---

### Task 4: Simulated Gemini Streaming Engine & Storage Service

**Files:**
- Create: `frontend/lib/services/mock_gemini_engine.dart`
- Create: `frontend/lib/services/storage_service.dart`
- Create: `frontend/test/engine_test.dart`

**Interfaces:**
- Consumes: `ChatMessage`, `ChatSession`, `GeminiModelType`.
- Produces: `MockGeminiEngine.streamResponse(prompt, model, modifyStyle)` returning `Stream<String>`, `StorageService.saveSessions()`, `StorageService.loadSessions()`.

- [ ] **Step 1: Write test for streaming engine**
Create `frontend/test/engine_test.dart` verifying that `streamResponse("write flutter code", GeminiModelType.flash)` emits code block markdown chunks.

- [ ] **Step 2: Implement MockGeminiEngine and StorageService**
Implement simulated token typewriter stream with context-aware triggers (code, vision, summaries) and modify styles (shorter, longer, simpler, casual, professional).

- [ ] **Step 3: Run test to verify**
Run: `flutter test test/engine_test.dart`  
Expected: PASS.

---

### Task 4: Simulated Gemini Streaming Engine & Storage Service

**Files:**
- Create: `frontend/lib/services/mock_gemini_engine.dart`
- Create: `frontend/lib/services/storage_service.dart`
- Create: `frontend/test/engine_test.dart`

---

### Task 5: Reactive Chat Controller (State Management)

**Files:**
- Create: `frontend/lib/state/chat_controller.dart`
- Create: `frontend/test/chat_controller_test.dart`

**Interfaces:**
- Consumes: `MockGeminiEngine`, `StorageService`, models.
- Produces: `ChatController` (`ChangeNotifier`) with `sendMessage()`, `stopStreaming()`, `switchModel()`, `createNewSession()`, `deleteSession()`, `modifyResponse()`.

- [ ] **Step 1: Write controller tests**
Create `frontend/test/chat_controller_test.dart` testing sending a message, receiving tokens, and stopping the stream.

- [ ] **Step 2: Implement ChatController**
Implement state transitions, error guards, token accumulation, and local persistence hooks.

- [ ] **Step 3: Run test to verify**
Run: `flutter test test/chat_controller_test.dart`  
Expected: PASS.

---

### Task 6: Core UI - Message Bubble, Markdown & Syntax Highlighted Code

**Files:**
- Create: `frontend/lib/views/components/code_block_view.dart`
- Create: `frontend/lib/views/components/response_actions.dart`
- Create: `frontend/lib/views/components/message_bubble.dart`
- Create: `frontend/test/message_bubble_test.dart`

**Interfaces:**
- Consumes: `ChatMessage`, `ChatController`.
- Produces: `MessageBubbleWidget`, `CodeBlockView` with copy button, `ResponseActionsBar` with modify popover.

- [ ] **Step 1: Implement CodeBlockView with copy feedback**
Dark background with language banner, formatted code, and animated "Copy" checkmark.

- [ ] **Step 2: Implement ResponseActionsBar & MessageBubble**
Implement Thumbs up/down, Copy message, Regenerate, and Modify popover menu.

- [ ] **Step 3: Run widget test**
Create and run `test/message_bubble_test.dart` verifying widget builds without errors.

---

### Task 7: Prompt Input Bar, Multimodal Attachments & Voice Wave Modal

**Files:**
- Create: `frontend/lib/views/components/prompt_input_bar.dart`
- Create: `frontend/lib/views/components/voice_wave_dialog.dart`
- Create: `frontend/test/prompt_bar_test.dart`

**Interfaces:**
- Consumes: `ChatController`.
- Produces: `PromptInputBarWidget` with image attachment chip preview, voice modal trigger, dynamic send/stop button.

- [ ] **Step 1: Implement PromptInputBar and VoiceWaveDialog**
Multi-line auto-expanding field, + attachment trigger, pulsating audio waveform dialog for voice mode, dynamic send/stop state.

- [ ] **Step 2: Run widget test**
Create and run `test/prompt_bar_test.dart`.  
Expected: PASS.

---

### Task 8: App Bar, Model Selector & History Sidebar

**Files:**
- Create: `frontend/lib/views/components/gemini_app_bar.dart`
- Create: `frontend/lib/views/components/sidebar_drawer.dart`
- Create: `frontend/lib/views/settings/settings_dialog.dart`

**Interfaces:**
- Consumes: `ChatController`.
- Produces: `GeminiAppBar`, `SidebarDrawerWidget`, `SettingsDialog`.

- [ ] **Step 1: Implement GeminiAppBar**
Model dropdown selector (Flash, Pro, Advanced) and user profile popup.

- [ ] **Step 2: Implement SidebarDrawer and SettingsDialog**
+ New Chat button, history grouped by Today / Yesterday / Previous 7 Days, theme toggle (Dark / Light / System).

---

### Task 9: Empty State View & Suggestion Cards

**Files:**
- Create: `frontend/lib/views/components/empty_state_view.dart`
- Test: `frontend/test/empty_state_test.dart`

**Interfaces:**
- Consumes: `ChatController`.
- Produces: `EmptyStateView` with gradient "Hello, Human" greeting and 4 prompt suggestion cards.

- [ ] **Step 1: Implement EmptyStateView**
Multicolor gradient shader on "Hello" greeting, 4 interactive chips filling the prompt input on click.

---

### Task 10: Adaptive Shell, Main Integration & Final Verification

**Files:**
- Create: `frontend/lib/views/adaptive_shell.dart`
- Modify: `frontend/lib/main.dart`

**Interfaces:**
- Assembles all components into the full responsive cross-platform app.

- [ ] **Step 1: Implement AdaptiveShell**
`LayoutBuilder` switching seamlessly between mobile drawer and desktop collapsible sidebar.

- [ ] **Step 2: Wire main.dart**
Set up `MultiProvider`, theme mode listener, and launch `AdaptiveShell`.

- [ ] **Step 3: Run comprehensive verification**
Run: `flutter analyze` and `flutter test`.  
Expected: All tests pass, zero analysis warnings.
