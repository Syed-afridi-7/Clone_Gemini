# Task 9 Brief: Empty State View & Suggestion Cards

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/views/components/empty_state_view.dart`:
   - Centered / top-aligned hero display when active session has no messages.
   - Large gradient masked text:
     - "Hello, Human" (masked with `GeminiColors.geminiGradient` using `ShaderMask`).
     - Subtitle: "How can I help you today?" in secondary text color.
   - Suggestion Cards Grid / Carousel (4 cards):
     1. "Help me write" (✏️ icon) -> "Help me draft a professional follow-up email"
     2. "Analyze & code" (💻 icon) -> "Write a responsive Flutter widget with smooth animations"
     3. "Brainstorm ideas" (💡 icon) -> "Brainstorm 5 innovative startup ideas in AI"
     4. "Plan an itinerary" (🧭 icon) -> "Create a 3-day travel itinerary for exploring Tokyo"
   - Tapping any card calls `onSuggestionSelected(prompt)` or `ChatController.sendMessage(prompt)`.
2. Create `frontend/test/empty_state_test.dart`:
   - Tests `EmptyStateView` displays gradient greeting and suggestion cards.
   - Tests tapping a suggestion card triggers callback.
3. Run `flutter test test/empty_state_test.dart`.
4. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-9-report.md`.
