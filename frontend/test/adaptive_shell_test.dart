import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/mock_gemini_engine.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/state/chat_controller.dart';
import 'package:frontend/views/adaptive_shell.dart';
import 'package:frontend/views/components/message_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AdaptiveShell renders empty state, sends prompt, and displays response', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    const engine = MockGeminiEngine(defaultDelay: Duration.zero);
    final controller = ChatController(engine: engine, storage: storage);
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatController>.value(
          value: controller,
          child: const AdaptiveShell(),
        ),
      ),
    );

    // Initial Empty State
    expect(find.text('Hello, Human'), findsOneWidget);

    // Enter prompt into the input bar
    await tester.enterText(find.byType(TextField), 'Explain quantum computing');
    await tester.pump();

    // Tap send button
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    // Verify messages rendered in feed
    expect(find.byType(MessageBubbleWidget), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(MessageBubbleWidget),
        matching: find.text('Explain quantum computing'),
      ),
      findsOneWidget,
    );
  });
}
