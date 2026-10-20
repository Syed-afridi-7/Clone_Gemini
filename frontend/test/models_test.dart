import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/gemini_model_type.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/models/chat_session.dart';

void main() {
  test('GeminiModelType returns correct metadata and parsing', () {
    expect(GeminiModelType.flash.displayName, 'Gemini 2.5 Flash');
    expect(GeminiModelType.pro.displayName, 'Gemini 1.5 Pro');
    expect(GeminiModelType.advanced.displayName, 'Gemini Advanced');

    expect(GeminiModelType.fromString('flash'), GeminiModelType.flash);
    expect(GeminiModelType.fromString('PRO'), GeminiModelType.pro);
    expect(GeminiModelType.fromString('advanced'), GeminiModelType.advanced);
    expect(GeminiModelType.fromString(null), GeminiModelType.flash);
  });

  test('ChatMessage serializes and deserializes cleanly', () {
    final now = DateTime.now();
    final message = ChatMessage(
      id: 'msg-1',
      role: 'user',
      text: 'Hello Gemini',
      attachments: ['/path/to/image.png'],
      timestamp: now,
      isStreaming: false,
      model: GeminiModelType.pro,
    );

    final json = message.toJson();
    final restored = ChatMessage.fromJson(json);

    expect(restored.id, 'msg-1');
    expect(restored.role, 'user');
    expect(restored.text, 'Hello Gemini');
    expect(restored.attachments.length, 1);
    expect(restored.attachments.first, '/path/to/image.png');
    expect(restored.model, GeminiModelType.pro);
    expect(restored.isUser, true);
    expect(restored.isModel, false);
  });

  test('ChatSession serializes and deserializes messages and metadata', () {
    final now = DateTime.now();
    final session = ChatSession(
      id: 'session-123',
      title: 'Flutter Exploration',
      messages: [
        ChatMessage(
          id: 'msg-1',
          role: 'user',
          text: 'What is Flutter?',
          timestamp: now,
        ),
        ChatMessage(
          id: 'msg-2',
          role: 'model',
          text: 'Flutter is a multiplatform UI toolkit.',
          timestamp: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isPinned: true,
    );

    final json = session.toJson();
    final restored = ChatSession.fromJson(json);

    expect(restored.id, 'session-123');
    expect(restored.title, 'Flutter Exploration');
    expect(restored.messages.length, 2);
    expect(restored.messages.first.text, 'What is Flutter?');
    expect(restored.messages.last.text, 'Flutter is a multiplatform UI toolkit.');
    expect(restored.isPinned, true);
  });
}
