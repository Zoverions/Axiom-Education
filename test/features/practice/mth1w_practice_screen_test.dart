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

  Widget buildScreen({
    bool verifierAvailable = true,
    String? initialExpectationId,
  }) {
    return ProviderScope(
      overrides: [
        mth1wGoldenPathProvider.overrideWith((ref) async => expectations),
      ],
      child: MaterialApp(
        home: Mth1wPracticeScreen(
          verifier: verifierAvailable ? const MathAnswerVerifier() : null,
          initialExpectationId: initialExpectationId,
        ),
      ),
    );
  }

  testWidgets('keeps evidence details available without leading with jargon', (
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

    expect(find.text("What you're practising"), findsOneWidget);
    expect(find.text('Curriculum details'), findsOneWidget);
    expect(find.textContaining('MTH1W-A1'), findsNothing);
    expect(find.textContaining('uncalibrated'), findsNothing);
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.textContaining(item.itemDigest), findsNothing);

    final curriculumDetails = find.text('Curriculum details');
    await tester.ensureVisible(curriculumDetails);
    await tester.pumpAndSettle();
    await tester.tap(curriculumDetails);
    await tester.pumpAndSettle();
    expect(find.textContaining('MTH1W-A1'), findsOneWidget);
    expect(find.textContaining('uncalibrated'), findsOneWidget);
    expect(find.textContaining('review pending'), findsOneWidget);

    final technicalDetails = find.text('Technical details');
    await tester.ensureVisible(technicalDetails);
    await tester.pumpAndSettle();
    await tester.tap(technicalDetails);
    await tester.pumpAndSettle();
    expect(find.textContaining(item.itemDigest), findsOneWidget);

    await tester.enterText(find.byType(TextField), item.canonicalAnswer);
    await tester.pump();
    final checkButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check answer'),
    );
    expect(checkButton.onPressed, isNotNull);
    checkButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.textContaining('Correct.'), findsOneWidget);
    expect(find.text('Verification details'), findsOneWidget);
    expect(
      find.textContaining('Exact deterministic verification'),
      findsNothing,
    );
    expect(find.textContaining(MathAnswerVerifier.verifierId), findsNothing);

    final verificationDetails = find.text('Verification details');
    await tester.ensureVisible(verificationDetails);
    await tester.pumpAndSettle();
    await tester.tap(verificationDetails);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Exact deterministic verification'),
      findsOneWidget,
    );
    expect(find.textContaining(MathAnswerVerifier.verifierId), findsOneWidget);
  });

  testWidgets('requires a non-blank answer before checking', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    FilledButton checkButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check answer'),
    );

    expect(checkButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(checkButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '1');
    await tester.pump();
    expect(checkButton().onPressed, isNotNull);
  });

  testWidgets('shows an ephemeral distinct-question session summary', (
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
    expect(find.text('0 attempts • 0 questions correct'), findsOneWidget);
    expect(find.text('0 of 3 different questions checked'), findsOneWidget);
    expect(find.textContaining('Nothing is saved'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'not an answer');
    await tester.pump();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check answer'))
        .onPressed!();
    await tester.pump();
    expect(find.text('1 attempt • 0 questions correct'), findsOneWidget);

    await tester.enterText(find.byType(TextField), item.canonicalAnswer);
    await tester.pump();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check answer'))
        .onPressed!();
    await tester.pump();
    expect(find.text('2 attempts • 1 question correct'), findsOneWidget);
    expect(find.text('1 of 3 different questions checked'), findsOneWidget);
  });

  testWidgets('rechecking one correct question does not inflate success', (
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
    await tester.enterText(find.byType(TextField), item.canonicalAnswer);
    await tester.pump();

    for (var attempt = 0; attempt < 2; attempt += 1) {
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Check answer'),
          )
          .onPressed!();
      await tester.pump();
    }

    expect(find.text('2 attempts • 1 question correct'), findsOneWidget);
    expect(find.text('1 of 3 different questions checked'), findsOneWidget);
    expect(
      find.textContaining('Repeated checks of the same question'),
      findsOneWidget,
    );
  });

  testWidgets(
    'counts distinct checked questions and gives a non-mastery stop cue',
    (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      for (var itemIndex = 0; itemIndex < 3; itemIndex += 1) {
        await tester.enterText(find.byType(TextField), 'not an answer');
        await tester.pump();
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Check answer'),
            )
            .onPressed!();
        await tester.pump();

        if (itemIndex == 0) {
          await tester.enterText(find.byType(TextField), 'still not an answer');
          await tester.pump();
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Check answer'),
              )
              .onPressed!();
          await tester.pump();
          expect(
            find.text('1 of 3 different questions checked'),
            findsOneWidget,
          );
        }

        if (itemIndex < 2) {
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, 'Another question'),
              )
              .onPressed!();
          await tester.pump();
        }
      }

      expect(find.text('3 of 3 different questions checked'), findsOneWidget);
      expect(
        find.textContaining('not a grade or mastery result'),
        findsOneWidget,
      );
    },
  );

  testWidgets('reveals hints one step at a time', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final hintButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Show hint'),
    );
    expect(hintButton.onPressed, isNotNull);
    hintButton.onPressed!();
    await tester.pump();

    expect(find.text('Hints'), findsOneWidget);
    expect(find.textContaining('Multiply'), findsOneWidget);
  });

  testWidgets('starts with a lesson-selected expectation', (tester) async {
    await tester.pumpWidget(buildScreen(initialExpectationId: 'MTH1W-B2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('MTH1W-B2'), findsNothing);
    expect(find.text('Practice topic 3 of 4'), findsOneWidget);

    await tester.tap(find.text('Curriculum details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('MTH1W-B2'), findsOneWidget);
  });

  testWidgets('fails closed when the verifier is unavailable', (tester) async {
    await tester.pumpWidget(buildScreen(verifierAvailable: false));
    await tester.pumpAndSettle();

    expect(find.textContaining('Answer checking is unavailable'), findsWidgets);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check answer'),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('answers cannot be submitted'), findsOneWidget);
  });
}
