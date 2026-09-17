import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/widgets/cross_cutting_reasoning_card.dart';

void main() {
  testWidgets('context stays visible while canonical detail is learner controlled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CrossCuttingReasoningCard(
            learnerFacingPrompt:
                'How could you check that this result must be correct?',
            dimensionLabel: 'Verification',
            competencyLabel: 'method selection',
          ),
        ),
      ),
    );

    expect(
      find.text('How could you check that this result must be correct?'),
      findsOneWidget,
    );
    expect(find.text('Reasoning details'), findsOneWidget);
    expect(find.text('Verification → method selection'), findsNothing);

    await tester.tap(find.text('Reasoning details'));
    await tester.pumpAndSettle();

    expect(find.text('Verification → method selection'), findsOneWidget);
  });

  testWidgets('context remains readable at large text scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: CrossCuttingReasoningCard(
              learnerFacingPrompt: 'Choose a way to verify this result.',
              dimensionLabel: 'Verification',
              competencyLabel: 'method selection',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Choose a way to verify this result.'), findsOneWidget);
    expect(find.text('Reasoning details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
