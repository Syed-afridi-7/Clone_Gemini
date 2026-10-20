import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/mock_gemini_engine.dart';
import 'services/storage_service.dart';
import 'state/chat_controller.dart';
import 'views/adaptive_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline storage service
  final storageService = await StorageService.initialize();
  const geminiEngine = MockGeminiEngine();

  final chatController = ChatController(
    engine: geminiEngine,
    storage: storageService,
  );

  // Load previous conversations and settings
  await chatController.initialize();

  runApp(
    ChangeNotifierProvider<ChatController>.value(
      value: chatController,
      child: const GeminiCloneApp(),
    ),
  );
}

class GeminiCloneApp extends StatelessWidget {
  const GeminiCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();

    return MaterialApp(
      title: 'Google Gemini',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: controller.themeMode,
      home: const AdaptiveShell(),
    );
  }
}
