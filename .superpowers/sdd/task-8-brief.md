# Task 8 Brief: App Bar, Model Selector & History Sidebar

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/views/settings/settings_dialog.dart`:
   - Dialog with theme selector: Dark, Light, System.
   - Button to clear all chat histories with confirmation.
   - Info section showing version, offline status, and simulated intelligence model.
2. Create `frontend/lib/views/components/gemini_app_bar.dart`:
   - Left side: Menu / hamburger button (toggles sidebar on desktop or opens drawer on mobile).
   - Brand title: "Gemini" text next to menu button.
   - Model Selector dropdown:
     - Displays active model pill (e.g. `Gemini 2.5 Flash ▼`).
     - Tapping opens dropdown menu displaying:
       - `Gemini 2.5 Flash` (Fast & lightweight)
       - `Gemini 1.5 Pro` (Deep reasoning & coding)
       - `Gemini Advanced` (Ultra capability & multimodal)
     - Selecting updates `ChatController.switchModel()`.
   - Right side:
     - "Try Gemini Advanced" pill or help button.
     - User profile avatar circle (Google user avatar aesthetic) with popup menu leading to Settings or theme toggle.
3. Create `frontend/lib/views/components/sidebar_drawer.dart`:
   - Top: Hamburger toggle + `+ New chat` prominent pill button.
   - Scrollable history list grouped into chronological sections:
     - **Pinned** (if any pinned sessions)
     - **Today** (sessions updated today)
     - **Yesterday** (sessions updated yesterday)
     - **Previous 7 Days** (sessions within 7 days)
     - **Older** (earlier sessions)
   - Each session tile shows title, active highlight, and a popup menu on hover/tap:
     - Pin / Unpin
     - Rename
     - Delete
   - Bottom pinned actions:
     - Help & FAQ
     - Activity
     - Settings (triggers `SettingsDialog`)
4. Create `frontend/test/app_bar_sidebar_test.dart`:
   - Tests `GeminiAppBar` model selection dropdown.
   - Tests `SidebarDrawerWidget` session list grouping and new chat button.
5. Run `flutter test test/app_bar_sidebar_test.dart`.
6. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-8-report.md`.
