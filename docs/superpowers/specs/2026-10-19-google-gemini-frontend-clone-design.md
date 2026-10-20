# Technical Design Specification: Google Gemini Cross-Platform Frontend Clone

**Date:** 2026-10-19  
**Status:** Approved by User  
**Target Architecture:** Cross-Platform Flutter 3.47+ (Android, iOS, Windows Desktop, Web)  
**Root Path:** `E:\gemini-clone`  
**Methodology:** Reverse Engineering Anything (REA) UI/UX decomposition and reconstruction  

---

## 1. Executive Summary & Objectives

The goal of this project is to construct a pixel-faithful, responsive, cross-platform clone of the **Google Gemini** user interface, mirroring both the desktop web layout (`gemini.google.com`) and mobile touch ergonomics.

### Core Requirements
1. **Directory Structure:** Create `E:\gemini-clone` containing two primary directories:
   - `frontend/`: The full Flutter application codebase.
   - `backend/`: Placeholder directory reserved for future backend services.
2. **Zero External API Dependency:** The application is self-contained. It simulates high-fidelity typewriter streaming responses without calling the Google Gemini API or requiring API keys.
3. **Adaptive Form Factor:** Dynamically transitions between mobile app ergonomics (bottom action bar, mobile drawer, tactile buttons) and desktop web layout (collapsible navigation rail/sidebar, wide prompt bar) based on screen width.
4. **Rich Interactivity:**
   - Full conversation session history grouped by Today, Yesterday, and Previous 7 Days.
   - Model selection dropdown (Gemini 2.5 Flash, Gemini Pro, Gemini Advanced).
   - Multimodal attachments (image selection with thumbnail preview and removal chip).
   - Microphone voice mode with animated pulsating audio waveforms.
   - Formatted Markdown output with code syntax highlighting and one-tap copy button.
   - Gemini response action bar (Thumbs up/down, Copy, Regenerate, and Modify: Shorter/Longer/Simpler/Casual/Professional).
   - Gemini Dark and Light Material 3 design systems.
   - Offline session persistence via local storage.

---

## 2. Target Directory & File Layout

```text
E:\gemini-clone\
├── backend\                             # Reserved directory for backend services
│   └── README.md
├── docs\
│   └── superpowers\
│       └── specs\
│           └── 2026-10-19-google-gemini-frontend-clone-design.md
└── frontend\                            # Flutter application
    ├── pubspec.yaml
    ├── assets\
    │   ├── icons\                       # Gemini sparkle SVG, action icons
    │   └── avatars\                     # Default user and AI avatars
    └── lib\
        ├── main.dart                    # App initialization, theme & route binding
        ├── core\
        │   ├── constants\
        │   │   └── breakpoints.dart     # Responsive layout breakpoints
        │   ├── theme\
        │   │   ├── gemini_colors.dart   # Hex palettes for Dark and Light modes
        │   │   └── app_theme.dart       # Material 3 Theme configurations
        │   └── typography\
        │       └── text_styles.dart     # Google Sans / Roboto type scale
        ├── models\
        │   ├── chat_message.dart        # Message entity (id, text, role, attachments, timestamp)
        │   ├── chat_session.dart        # Session entity (id, title, messages, isPinned, createdAt)
        │   └── gemini_model_type.dart   # Model enum & metadata (Flash, Pro, Advanced)
        ├── services\
        │   ├── mock_gemini_engine.dart  # Simulated token streaming engine with contextual responses
        │   └── storage_service.dart     # Local persistence with SharedPreferences / JSON
        ├── state\
        │   └── chat_controller.dart     # Central ChangeNotifier managing state & active stream
        └── views\
            ├── adaptive_shell.dart      # Breakpoint-aware Shell (Mobile vs Desktop)
            ├── components\
            │   ├── gemini_app_bar.dart  # Top bar with model dropdown and user profile avatar
            │   ├── sidebar_drawer.dart  # Collapsible history drawer with grouped dates
            │   ├── empty_state_view.dart# Shimmering "Hello" greeting & suggestion cards
            │   ├── message_bubble.dart  # User and Gemini message presentation
            │   ├── code_block_view.dart # Syntax highlighter with language pill & copy action
            │   ├── response_actions.dart# Thumbs, Copy, Modify popover, Regenerate
            │   ├── prompt_input_bar.dart# Rounded pill input with multimodal & voice triggers
            │   └── voice_wave_dialog.dart# Animated pulsating waveform visualizer
            └── settings\
                └── settings_dialog.dart # Theme toggle (Dark/Light/System) & reset history
```

---

## 3. Visual Tokens & Design System

### A. Color Palette
- **Gemini Dark (Primary):**
  - Background Canvas: `#131314`
  - Elevated Container / Input Pill: `#1E1F20`
  - Hover / Selection Highlight: `#282A2C`
  - Subtle Borders & Dividers: `#3C4043`
  - Text Primary: `#E3E3E3`
  - Text Secondary: `#C4C7C5`
- **Gemini Light:**
  - Background Canvas: `#FFFFFF`
  - Elevated Container / Input Pill: `#F0F4F9`
  - Hover / Selection Highlight: `#E1E5EA`
  - Subtle Borders & Dividers: `#E3E3E3`
  - Text Primary: `#1F1F1F`
  - Text Secondary: `#444746`
- **Google Gemini Signature Gradient:**
  - Linear Gradient: `#4285F4` (Blue) → `#9B72CB` (Purple) → `#D96570` (Coral)
  - Used for the "Hello" hero greeting shader, sparkle logo accents, and thinking shimmer.

---

## 4. Component Decomposition & Behavior

### 1. Header (`gemini_app_bar.dart`)
- Left hamburger menu toggle (expands/collapses sidebar on desktop; opens drawer on mobile).
- Centered or left-aligned **Model Selector Dropdown**:
  - `Gemini 2.5 Flash` (Default, badge: Fast & light)
  - `Gemini 1.5 Pro` (Badge: Deep reasoning & coding)
  - `Gemini Advanced` (Badge: Ultra capability & multimodal)
- Right action: User profile avatar with dropdown menu (Theme toggle, Settings).

### 2. History Sidebar (`sidebar_drawer.dart`)
- **+ New Chat** rounded button at top.
- Chronological list of chat sessions:
  - "Today"
  - "Yesterday"
  - "Previous 7 Days"
- Hover/long-press reveals action options: Pin, Rename, Delete.
- Bottom actions: Help, Settings, and Gemini Advanced promotion pill.

### 3. Main Chat View (`message_bubble.dart` & `empty_state_view.dart`)
- **When no messages exist:**
  - Display gradient-masked heading: *"Hello, Human"*.
  - Sub-heading: *"How can I help you today?"*
  - 4 quick-start suggestion cards (e.g., Coding help, Creative writing, Travel plan, Concept explanation). Clicking immediately sends or fills the prompt.
- **When conversation is active:**
  - Smooth list view of messages auto-scrolling to bottom.
  - User messages formatted with dark gray rounded bubble and attachment badges.
  - Gemini responses formatted with animated sparkle avatar, markdown text, bullet lists, and syntax-highlighted code blocks with a one-tap copy button.
  - Bottom action bar with Thumbs Up/Down, Copy text, Regenerate, and Modify Response dropdown.

### 4. Floating Prompt Bar (`prompt_input_bar.dart`)
- Pill-shaped elevation pinned at the bottom.
- Left **+ button**: Opens image picker; selected images appear as removable thumbnail chips above the text field.
- Auto-expanding text input field (single line up to 5 lines).
- Right **Mic button**: Tapping opens the interactive voice visualizer showing animated waveform bars.
- Right **Send/Stop button**:
  - Inactive gray arrow when empty.
  - Active blue/white arrow when text is entered.
  - Square "Stop" icon while AI response is streaming.
- Footnote caption: *"Gemini may display inaccurate info, including about people, so double-check its responses."*

---

## 5. Streaming Engine & Mock Logic (`mock_gemini_engine.dart`)

1. **Token Streaming:** Emits response chunks via Dart `Stream<String>` with a 15–25ms delay per token, creating an authentic typewriter effect.
2. **Context-Aware Responses:**
   - Detects programming keywords (`flutter`, `code`, `python`, `api`, `ui`, `bug`) and returns comprehensive markdown with syntax-highlighted code blocks.
   - Detects attached images and outputs simulated vision analysis.
   - General knowledge queries return structured bullet points and bold summaries.
3. **Response Variations:**
   - `Flash`: Ultra-rapid delivery, concise answers.
   - `Pro`: Analytical, well-structured multi-part answers.
   - `Advanced`: Displays a temporary glowing "Thinking..." state before streaming.
4. **Modifications:**
   - `Shorter`: Re-streams 2 bullet-point summary.
   - `Longer`: Re-streams comprehensive in-depth breakdown.
   - `Simpler`: Re-streams plain ELI5 explanation.
   - `Professional`: Formal executive style.
   - `Casual`: Friendly emoji-infused tone.

---

## 6. Persistence & Error Handling

- **Persistence:** All chat sessions and messages are serialized to JSON and persisted locally via `SharedPreferences`. Previous chats survive page reloads and app restarts.
- **Cancellation:** Pressing the Stop button aborts the stream subscription immediately without corrupting the message history.
- **Responsive Layout:** Automatically scales across mobile phone (< 768px), tablet (768px - 1024px), and desktop/web (> 1024px).

---

## 7. Verification & Testing Plan

1. **Static Analysis:**
   - `flutter analyze` must pass with zero errors.
2. **Platform Verification:**
   - `flutter run -d chrome` (Web target verification).
   - `flutter run -d windows` (Desktop target verification).
   - `flutter build apk` (Mobile Android APK verification).
3. **Interactive Validation:**
   - Verify prompt sending and token streaming typewriter effect.
   - Verify model selector dropdown switching.
   - Verify new chat creation, session switching, and deletion.
   - Verify attachment thumbnail chip adding and removing.
   - Verify code syntax highlighting and copy button functionality.
   - Verify dark and light theme switching.
   - Verify voice wave animation modal.
