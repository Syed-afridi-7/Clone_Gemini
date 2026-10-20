import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/gemini_model_type.dart';
import 'package:frontend/services/mock_gemini_engine.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/state/chat_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late MockGeminiEngine engine;
  late ChatController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    engine = const MockGeminiEngine(defaultDelay: Duration.zero);
    controller = ChatController(engine: engine, storage: storage);
    await controller.initialize();
  });

  test('Initial state creates default session and initializes theme', () {
    expect(controller.sessions.isNotEmpty, true);
    expect(controller.activeSession, isNotNull);
    expect(controller.selectedModel, GeminiModelType.flash);
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.isStreaming, false);
  });

  test('sendMessage streams model response and updates session', () async {
    await controller.sendMessage('Hello Gemini', delayOverride: Duration.zero);

    // Wait for the stream to complete
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.messages.length, 2);
    expect(controller.messages.first.isUser, true);
    expect(controller.messages.first.text, 'Hello Gemini');

    expect(controller.messages.last.isModel, true);
    expect(controller.messages.last.text.isNotEmpty, true);
    expect(controller.isStreaming, false);
  });

  test('createNewSession and deleteSession manage session list', () async {
    final session2 = await controller.createNewSession(initialTitle: 'Custom Session');
    expect(controller.sessions.length, 2);
    expect(controller.activeSessionId, session2.id);

    await controller.deleteSession(session2.id);
    expect(controller.sessions.length, 1);
  });

  test('switchModel and attachments update state', () {
    controller.switchModel(GeminiModelType.advanced);
    expect(controller.selectedModel, GeminiModelType.advanced);

    controller.addAttachment('/path/image.jpg');
    expect(controller.stagedAttachments.length, 1);
    expect(controller.stagedAttachments.first, '/path/image.jpg');

    controller.removeAttachment('/path/image.jpg');
    expect(controller.stagedAttachments.isEmpty, true);
  });
}
