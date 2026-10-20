import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/gemini_model_type.dart';
import 'package:frontend/models/chat_session.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/services/mock_gemini_engine.dart';
import 'package:frontend/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockGeminiEngine Tests', () {
    const engine = MockGeminiEngine(defaultDelay: Duration.zero);

    test('streamResponse produces markdown code block for coding queries', () async {
      final buffer = StringBuffer();
      await for (final token in engine.streamResponse(
        'Write flutter code for me',
        model: GeminiModelType.flash,
        delayOverride: Duration.zero,
      )) {
        buffer.write(token);
      }

      final fullResponse = buffer.toString();
      expect(fullResponse.contains('```dart'), true);
      expect(fullResponse.contains('GeminiFeatureWidget'), true);
    });

    test('streamResponse respects multimodal attachment flag', () async {
      final buffer = StringBuffer();
      await for (final token in engine.streamResponse(
        'Look at this picture',
        hasAttachments: true,
        delayOverride: Duration.zero,
      )) {
        buffer.write(token);
      }

      final response = buffer.toString();
      expect(response.contains('analyzed the image'), true);
    });

    test('streamResponse transforms response based on modifyStyle', () async {
      final buffer = StringBuffer();
      await for (final token in engine.streamResponse(
        'State management',
        modifyStyle: 'shorter',
        delayOverride: Duration.zero,
      )) {
        buffer.write(token);
      }

      final shorter = buffer.toString();
      expect(shorter.contains('**Summary:**'), true);
    });
  });

  group('StorageService Tests', () {
    test('saveSessions and loadSessions round-trip data correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final now = DateTime.now();
      final session = ChatSession(
        id: 's-1',
        title: 'Test Session',
        messages: [
          ChatMessage(
            id: 'm-1',
            role: 'user',
            text: 'Hello',
            timestamp: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      await storage.saveSessions([session]);
      await storage.saveActiveSessionId('s-1');
      await storage.saveThemeMode('dark');

      final loaded = storage.loadSessions();
      expect(loaded.length, 1);
      expect(loaded.first.id, 's-1');
      expect(loaded.first.title, 'Test Session');
      expect(loaded.first.messages.length, 1);
      expect(loaded.first.messages.first.text, 'Hello');

      expect(storage.loadActiveSessionId(), 's-1');
      expect(storage.loadThemeMode(), 'dark');

      await storage.clearAll();
      expect(storage.loadSessions().isEmpty, true);
      expect(storage.loadActiveSessionId(), isNull);
    });
  });
}
