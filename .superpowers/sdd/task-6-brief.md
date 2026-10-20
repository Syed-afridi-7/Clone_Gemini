# Task 6 Brief: Core UI - Message Bubble, Markdown & Syntax Highlighted Code

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/views/components/gemini_sparkle_icon.dart`:
   - Pixel-accurate Gemini sparkle icon with Google Gemini gradient shader (`#4285F4` -> `#9B72CB` -> `#D96570`).
   - Supports size parameter (default 24x24).
2. Create `frontend/lib/views/components/code_block_view.dart`:
   - Dark code container with rounded corners and border (`GeminiColors.darkBorder`).
   - Header banner with language label (e.g. `dart`, `python`, `code`).
   - One-tap "Copy" button with animated checkmark feedback.
   - Code body rendered with `flutter_highlight` using `atom-one-dark` or `vs2015` theme.
3. Create `frontend/lib/views/components/response_actions.dart`:
   - Thumbs up & Thumbs down toggles.
   - Copy response text button with Snackbar feedback.
   - Modify response popover with options: "Shorter", "Longer", "Simpler", "Casual", "Professional".
   - Regenerate response trigger.
4. Create `frontend/lib/views/components/message_bubble.dart`:
   - If User message:
     - Right-aligned bubble with subtle background (`GeminiColors.darkHover` or light counterpart).
     - Displays attached image thumbnails if present.
   - If Gemini message:
     - Left-aligned layout with `GeminiSparkleIcon`.
     - Displays thinking indicator if message is streaming with empty text on `GeminiModelType.advanced`.
     - Rich Markdown rendering (`MarkdownBody`) using custom code block builder hooked to `CodeBlockView`.
     - When not streaming, renders `ResponseActionsBar` at bottom.
5. Create `frontend/test/message_bubble_test.dart`:
   - Tests rendering user message and model message.
   - Tests `CodeBlockView` copy button.
6. Run `flutter test test/message_bubble_test.dart`.
7. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-6-report.md`.
