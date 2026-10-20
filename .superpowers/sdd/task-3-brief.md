# Task 3 Brief: Domain Models (Message, Session, Model Type, Attachment)

## Project Context
Building Google Gemini cross-platform frontend clone in `E:\gemini-clone\frontend`.
Spec: `E:\gemini-clone\docs\superpowers\specs\2026-10-19-google-gemini-frontend-clone-design.md`

## Requirements
1. Create `frontend/lib/models/gemini_model_type.dart`:
   - Enum `GeminiModelType` with values: `flash`, `pro`, `advanced`.
   - Getters/helpers:
     - `displayName` ("Gemini 2.5 Flash", "Gemini 1.5 Pro", "Gemini Advanced")
     - `description` ("Fast & lightweight for everyday tasks", "Deep reasoning, analysis and coding", "Ultra capability with thinking process")
     - `badge` ("Flash", "Pro", "Advanced")
     - `delayMs` (12ms, 22ms, 35ms)
     - `fromString(String val)`
2. Create `frontend/lib/models/chat_message.dart`:
   - Properties:
     - `String id`
     - `String role` ('user' or 'model')
     - `String text`
     - `List<String> attachments` (paths or URLs)
     - `DateTime timestamp`
     - `bool isStreaming`
     - `GeminiModelType? model`
   - Methods:
     - `toJson()` -> `Map<String, dynamic>`
     - `ChatMessage.fromJson(Map<String, dynamic> json)`
     - `copyWith(...)`
3. Create `frontend/lib/models/chat_session.dart`:
   - Properties:
     - `String id`
     - `String title`
     - `List<ChatMessage> messages`
     - `DateTime createdAt`
     - `DateTime updatedAt`
     - `bool isPinned`
   - Methods:
     - `toJson()` -> `Map<String, dynamic>`
     - `ChatSession.fromJson(Map<String, dynamic> json)`
     - `copyWith(...)`
4. Create `frontend/test/models_test.dart`:
   - Tests serializing and deserializing `ChatMessage` and `ChatSession` to/from JSON.
   - Tests `GeminiModelType` metadata properties.
5. Run `flutter test test/models_test.dart` and `flutter analyze lib/models test/models_test.dart`.
6. Write completion report to `E:\gemini-clone\.superpowers\sdd\task-3-report.md`.
