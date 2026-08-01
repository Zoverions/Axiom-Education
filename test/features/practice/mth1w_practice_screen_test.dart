import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/practice/math_answer_verifier.dart';
import 'package:ontarioedai/core/practice/math_practice_generator.dart';
import 'package:ontarioedai/core/practice/mth1w_practice_provider.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:ontarioedai/features/practice/mth1w_practice_screen.dart';

void main() {
  const expectations = <CurriculumItem>[
    CurriculumItem(
      id: 'MTH1W-A1',
      courseCode: 'MTH1W',
      strand: 'A Number',
      expectation:
          'Perform operations on integers and rational numbers, including order of operations.',
      irtB: -0.8,
      irtA: 1.1,
      irtC: 0.2,
      tags: ['math', 'eqao'],
    ),
    CurriculumItem(
      id: 'MTH1W-A2',
      courseCode: 'MTH1W',
      strand: 'A Number',
      expectation:
          'Apply rates, ratios, percentages, and proportional reasoning to solve problems in various contexts.',
      irtB: -0.3,
      irtA: 1.2,
      irtC: 0.2,
      tags: ['math', 'eqao'],
    ),
    CurriculumItem(
      id: 'MTH1W-B2',
      courseCode: 'MTH1W',
      strand: 'B Algebra',
      expectation:
          'Solve linear equations and inequalities algebraically and represent solutions on a number line.',
      irtB: 0.4,
      irtA: 1.4,
      irtC: 0.2,
      tags: ['math', 'eqao'],
    ),
    CurriculumItem(
      id: 'MTH1W-B4',
      courseCode: 'MTH1W',
      strand: 'B Algebra',
      expectation:
          'Determine the equation of a line given slope and y-intercept, or two points.',
      irtB: 1.1,
      irtA: 1.4,
      irtC: 0.2,
      tags: ['math', 'eqao'],
    ),
  ];

  Widget buildScreen({bool verifierAvailable = true}) {
    return ProviderScope(
      overrides: [
        mth1wGoldenPathProvider.overrideWith((ref) async => expectations),
      ],
      child: MaterialApp(
        home: Mth1wPracticeScreen(
          verifier: verifierAvailable ? const MathAnswerVerifier() : null,
        ),
      ),
    );
  }

  testWidgets('checks an entered answer with exact local verification', (
    tester,
  ) async {
    const generator = MathPracticeGenerator();
    final item = generator.generate(
      expectationId: expectations.first.id,
      expectationText: expectations.first.expectation,
      difficultyValue: expectations.first.irtB,
      seed: 0,
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('MTH1W-A1'), findsOneWidget);
    expect(find.textContaining('uncalibrated'), findsOneWidget);
    expect(
      find.textContaining(item.itemDigest.substring(0, 12)),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), item.canonicalAnswer);
    final checkButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check answer'),
    );
    expect(checkButton.onPressed, isNotNull);
    checkButton.onPressed!();
    await tester.pump();

    expect(find.text('Exact deterministic verification'), findsOneWidget);
    expect(find.textContaining('Correct.'), findsOneWidget);
  });

  testWidgets('shows an ephemeral exact-verification session summary', (
    tester,
  ) async {
    const generator = MathPracticeGenerator();
    final item = generator.generate(
      expectationId: expectations.first.id,
      expectationText: expectations.first.expectation,
      difficultyValue: expectations.first.irtB,
      seed: 0,
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Session summary'), findsOneWidget);
    expect(find.text('0 checks • 0 exact successes'), findsOneWidget);
    expect(find.textContaining('Nothing is saved'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'not an answer');
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check answer'))
        .onPressed!();
    await tester.pump();
    expect(find.text('1 check • 0 exact successes'), findsOneWidget);

    await tester.enterText(find.byType(TextField), item.canonicalAnswer);
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check answer'))
        .onPressed!();
    await tester.pump();
    expect(find.text('2 checks • 1 exact success'), findsOneWidget);
  });

  testWidgets('reveals deterministic scaffolded hints', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final hintButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Show hint'),
    );
    expect(hintButton.onPressed, isNotNull);
    hintButton.onPressed!();
    await tester.pump();

    expect(find.text('Scaffolded hints'), findsOneWidget);
    expect(find.textContaining('Multiply'), findsOneWidget);
  });

  testWidgets('fails closed when the verifier is unavailable', (tester) async {
    await tester.pumpWidget(buildScreen(verifierAvailable: false));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fail-closed mode'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check answer'),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('answers cannot be submitted'), findsOneWidget);
  });
}
