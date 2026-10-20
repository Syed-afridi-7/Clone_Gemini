# Task 5 Brief: Reactive Chat Controller (State Management)

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/state/chat_controller.dart`:
   - Extends `ChangeNotifier`.
   - Injected dependencies: `MockGeminiEngine` and `StorageService`.
   - Properties:
     - `List<ChatSession> sessions`
     - `String? activeSessionId`
     - `ChatSession? activeSession` (getter)
     - `List<ChatMessage> messages` (getter for active session messages)
     - `GeminiModelType selectedModel` (default `flash`)
     - `bool isStreaming`
     - `List<String> stagedAttachments`
     - `ThemeMode themeMode` (default `ThemeMode.dark`)
     - `bool isSidebarOpen` (default `true` on desktop, `false` on mobile)
   - Methods:
     - `Future<void> initialize()`: Loads sessions, active session id, and theme mode from `StorageService`.
     - `Future<void> createNewSession()`: Creates a new empty session, sets it active, and persists.
     - `Future<void> selectSession(String id)`
     - `Future<void> deleteSession(String id)`
     - `Future<void> renameSession(String id, String newTitle)`
     - `Future<void> togglePinSession(String id)`
     - `void switchModel(GeminiModelType model)`
     - `void addAttachment(String path)`
     - `void removeAttachment(String path)`
     - `void clearAttachments()`
     - `void toggleSidebar()`
     - `Future<void> setThemeMode(ThemeMode mode)`
     - `Future<void> sendMessage(String text)`:
       - Appends user `ChatMessage` (with staged attachments).
       - Clears staged attachments.
       - If session title is default "New Chat", generates title from prompt.
       - Appends placeholder model `ChatMessage` with `isStreaming = true`.
       - Subscribes to `MockGeminiEngine.streamResponse(text, model: selectedModel, hasAttachments: hasAttachments)`.
       - Updates model message text chunk by chunk, calling `notifyListeners()`.
       - Sets `isStreaming = false` on completion and calls `storageService.saveSessions()`.
     - `void stopStreaming()`: Cancels active `StreamSubscription`, marks model message `isStreaming = false`, and persists.
     - `Future<void> modifyResponse(String messageId, String style)`: Re-streams the response using the requested style ('shorter', 'longer', 'simpler', 'casual', 'professional').
     - `Future<void> clearAllChats()`
2. Create `frontend/test/chat_controller_test.dart`:
   - Tests initial state and loading from storage.
   - Tests `sendMessage` adds user message and streams model tokens.
   - Tests `stopStreaming` terminates stream cleanly.
   - Tests `createNewSession` and `deleteSession`.
3. Run `flutter test test/chat_controller_test.dart`.
4. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-5-report.md`.
