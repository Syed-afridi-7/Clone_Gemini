# Task 7 Brief: Prompt Input Bar, Multimodal Attachments & Voice Wave Modal

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/views/components/voice_wave_dialog.dart`:
   - Fullscreen/modal dialog simulating Google Gemini Live voice interface.
   - 4-5 animated pulsating vertical waveform bars with Google Gemini gradient colors.
   - Text status: "Listening... speak now" with subtitle "Gemini is ready".
   - Close / End voice mode button.
2. Create `frontend/lib/views/components/prompt_input_bar.dart`:
   - Rounded pill shaped container (`#1E1F20` dark surface, `#3C4043` border, or light equivalents).
   - Top area for staged image thumbnail chips (shows filename and 'X' delete button).
   - Left '+' button: calls `FilePicker.platform.pickFiles(type: FileType.image)` and adds path to `ChatController.addAttachment()`.
   - Multi-line auto-expanding `TextField` (hint: "Ask Gemini" or "Type a prompt...").
   - Right microphone button: opens `VoiceWaveDialog`.
   - Right action button:
     - When streaming: Displays square stop icon (taps call `ChatController.stopStreaming()`).
     - When not streaming: Displays arrow-up / send icon. Enabled and bright blue/white when text is typed or attachment staged; disabled/muted when empty.
   - Disclaimer footer caption: "Gemini may display inaccurate info, including about people, so double-check its responses."
3. Create `frontend/test/prompt_bar_test.dart`:
   - Tests rendering `PromptInputBarWidget` inside `Provider<ChatController>`.
   - Tests typing into field enables send button.
   - Tests tapping microphone opens voice wave dialog.
4. Run `flutter test test/prompt_bar_test.dart`.
5. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-7-report.md`.
