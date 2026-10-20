import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/views/components/empty_state_view.dart';

void main() {
  testWidgets('EmptyStateView renders gradient greeting and 4 suggestion cards', (tester) async {
    String? selectedPrompt;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            onSuggestionSelected: (prompt) {
              selectedPrompt = prompt;
            },
          ),
        ),
      ),
    );

    expect(find.text('Hello, Human'), findsOneWidget);
    expect(find.text('How can I help you today?'), findsOneWidget);
    expect(find.text('Help me write'), findsOneWidget);
    expect(find.text('Analyze & code'), findsOneWidget);
    expect(find.text('Brainstorm ideas'), findsOneWidget);
    expect(find.text('Plan an itinerary'), findsOneWidget);

    // Tap a suggestion card
    await tester.tap(find.text('Analyze & code'));
    await tester.pump();

    expect(selectedPrompt, contains('Write a responsive Flutter widget'));
  });
}
