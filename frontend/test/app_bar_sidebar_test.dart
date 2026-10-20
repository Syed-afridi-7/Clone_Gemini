import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/gemini_model_type.dart';
import 'package:frontend/services/mock_gemini_engine.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/state/chat_controller.dart';
import 'package:frontend/views/components/gemini_app_bar.dart';
import 'package:frontend/views/components/sidebar_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    const engine = MockGeminiEngine(defaultDelay: Duration.zero);
    controller = ChatController(engine: engine, storage: storage);
    await controller.initialize();
  });

  testWidgets('GeminiAppBar displays model selector and switches models', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatController>.value(
          value: controller,
          child: const Scaffold(
            appBar: GeminiAppBar(),
          ),
        ),
      ),
    );

    expect(find.text('Gemini'), findsOneWidget);
    expect(find.text('Gemini 2.5 Flash'), findsOneWidget);

    // Open model selector dropdown
    await tester.tap(find.text('Gemini 2.5 Flash'));
    await tester.pumpAndSettle();

    expect(find.text('Gemini 1.5 Pro'), findsOneWidget);
    expect(find.text('Gemini Advanced'), findsOneWidget);

    // Select Gemini Pro
    await tester.tap(find.text('Gemini 1.5 Pro'));
    await tester.pumpAndSettle();

    expect(controller.selectedModel, GeminiModelType.pro);
  });

  testWidgets('SidebarDrawerWidget displays New chat button and session list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatController>.value(
          value: controller,
          child: const Scaffold(
            drawer: SidebarDrawerWidget(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatController>.value(
          value: controller,
          child: const Scaffold(
            body: SidebarDrawerWidget(),
          ),
        ),
      ),
    );

    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);

    // Tap new chat
    final initialCount = controller.sessions.length;
    await tester.tap(find.text('New chat'));
    await tester.pumpAndSettle();

    expect(controller.sessions.length, initialCount + 1);
  });
}
