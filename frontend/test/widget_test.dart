import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/mock_gemini_engine.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/state/chat_controller.dart';
import 'package:frontend/views/adaptive_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GeminiCloneApp builds and renders AdaptiveShell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    const engine = MockGeminiEngine(defaultDelay: Duration.zero);
    final controller = ChatController(engine: engine, storage: storage);
    await controller.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatController>.value(
        value: controller,
        child: const GeminiCloneApp(),
      ),
    );

    expect(find.byType(AdaptiveShell), findsOneWidget);
    expect(find.text('Gemini'), findsOneWidget);
    expect(find.text('Hello, Human'), findsOneWidget);
  });
}
