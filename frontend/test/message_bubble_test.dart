import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/views/components/code_block_view.dart';
import 'package:frontend/views/components/message_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CodeBlockView renders code and language header', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          return null;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CodeBlockView(
            code: 'print("Hello world");',
            language: 'dart',
          ),
        ),
      ),
    );

    expect(find.text('dart'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);
    expect(find.byType(HighlightView), findsOneWidget);

    await tester.tap(find.text('Copy code'));
    await tester.pump();
    expect(find.text('Copied'), findsOneWidget);

    // Drain the 2s timer
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('MessageBubbleWidget renders user message', (tester) async {
    final userMessage = ChatMessage(
      id: 'm-1',
      role: 'user',
      text: 'How does Flutter handle state?',
      timestamp: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubbleWidget(message: userMessage),
        ),
      ),
    );

    expect(find.text('How does Flutter handle state?'), findsOneWidget);
  });

  testWidgets('MessageBubbleWidget renders model message with markdown', (tester) async {
    final modelMessage = ChatMessage(
      id: 'm-2',
      role: 'model',
      text: '**Flutter** is awesome!',
      timestamp: DateTime.now(),
      isStreaming: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubbleWidget(message: modelMessage),
        ),
      ),
    );

    expect(find.byType(MessageBubbleWidget), findsOneWidget);
  });
}
