# Task 4 Brief: Simulated Gemini Streaming Engine & Storage Service

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/services/mock_gemini_engine.dart`:
   - Method `Stream<String> streamResponse(String prompt, {GeminiModelType model = GeminiModelType.flash, String? modifyStyle, bool hasAttachments = false}) async*`
   - Yields token strings with natural delay based on `model.delayMs` (or fast yield during unit tests).
   - Generates contextual markdown based on prompt:
     - Coding queries (`flutter`, `code`, `python`, `api`, `widget`, `state`, etc.): Returns formatted Markdown with language header code blocks (e.g. ````dart ... ````) and bullet explanations.
     - Multimodal queries (when `hasAttachments == true`): Returns simulated image reasoning ("I've analyzed the uploaded image...").
     - General queries: Returns clear structured answers with bold headings and numbered takeaways.
     - Modify style transforms:
       - 'shorter': Returns condensed 2 bullet point answer.
       - 'longer': Returns expanded multi-section deep dive.
       - 'simpler': Returns simplified plain ELI5 explanation.
       - 'casual': Returns conversational friendly response with emojis.
       - 'professional': Returns executive corporate tone.
2. Create `frontend/lib/services/storage_service.dart`:
   - Wraps `SharedPreferences` to persist:
     - `Future<void> saveSessions(List<ChatSession> sessions)`
     - `Future<List<ChatSession>> loadSessions()`
     - `Future<void> saveActiveSessionId(String? id)`
     - `Future<String?> loadActiveSessionId()`
     - `Future<void> saveThemeMode(String mode)`
     - `Future<String?> loadThemeMode()`
     - `Future<void> clearAll()`
3. Create `frontend/test/engine_test.dart`:
   - Tests `MockGeminiEngine.streamResponse` produces markdown with code blocks for coding prompts.
   - Tests `MockGeminiEngine` modifyStyle parameter transforms output.
   - Tests `StorageService` saving and loading sessions via Mock/SharedPreferences.
4. Run `flutter test test/engine_test.dart`.
5. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-4-report.md`.
