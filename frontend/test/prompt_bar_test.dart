import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/mock_gemini_engine.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/state/chat_controller.dart';
import 'package:frontend/views/components/prompt_input_bar.dart';
import 'package:frontend/views/components/voice_wave_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PromptInputBarWidget renders input field and triggers send', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    const engine = MockGeminiEngine(defaultDelay: Duration.zero);
    final controller = ChatController(engine: engine, storage: storage);
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<ChatController>.value(
            value: controller,
            child: const PromptInputBarWidget(),
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    // Enter prompt text
    await tester.enterText(find.byType(TextField), 'Hello Flutter');
    await tester.pump();

    // Tap send
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump(const Duration(milliseconds: 50));

    // Input field cleared
    expect(find.text('Hello Flutter'), findsNothing);
  });

  testWidgets('VoiceWaveDialog renders pulsating waveform and closes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VoiceWaveDialog(),
        ),
      ),
    );

    expect(find.text('Listening...'), findsOneWidget);
    expect(find.text('End Voice Session'), findsOneWidget);

    await tester.tap(find.text('End Voice Session'));
    await tester.pumpAndSettle();
  });
}
