import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/practice/math_answer_verifier.dart';
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

  testWidgets(
    'teaches verifier selection without changing correctness authority',
    (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('How should we check an exact answer here?'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mth1w-verifier-exact')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mth1w-verifier-estimate')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mth1w-verifier-model')),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();

      FilledButton checkButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Check answer'),
      );

      expect(checkButton().onPressed, isNotNull);

      final estimateChoice = find.byKey(
        const ValueKey('mth1w-verifier-estimate'),
      );
      await tester.ensureVisible(estimateChoice);
      await tester.pumpAndSettle();
      await tester.tap(estimateChoice);
      await tester.pump();
      expect(checkButton().onPressed, isNull);
      expect(
        find.textContaining('cannot establish an exact answer'),
        findsOneWidget,
      );

      final modelChoice = find.byKey(const ValueKey('mth1w-verifier-model'));
      await tester.ensureVisible(modelChoice);
      await tester.pumpAndSettle();
      await tester.tap(modelChoice);
      await tester.pump();
      expect(checkButton().onPressed, isNull);
      expect(
        find.textContaining('not an authoritative verifier'),
        findsOneWidget,
      );

      final exactChoice = find.byKey(const ValueKey('mth1w-verifier-exact'));
      await tester.ensureVisible(exactChoice);
      await tester.pumpAndSettle();
      await tester.tap(exactChoice);
      await tester.pump();
      expect(checkButton().onPressed, isNotNull);

      final reasoningDetails = find.text('Reasoning details');
      await tester.ensureVisible(reasoningDetails);
      await tester.pumpAndSettle();
      await tester.tap(reasoningDetails);
      await tester.pumpAndSettle();
      expect(find.text('Verification → method selection'), findsOneWidget);
      expect(find.textContaining('Nothing is saved'), findsWidgets);
    },
  );

  testWidgets(
    'verifier absence still fails closed after exact method selection',
    (tester) async {
      await tester.pumpWidget(buildScreen(verifierAvailable: false));
      await tester.pumpAndSettle();

      final exactChoice = find.byKey(const ValueKey('mth1w-verifier-exact'));
      await tester.ensureVisible(exactChoice);
      await tester.pumpAndSettle();
      await tester.tap(exactChoice);
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Check answer'),
      );
      expect(button.onPressed, isNull);
      expect(
        find.textContaining('Answer checking is unavailable'),
        findsWidgets,
      );
    },
  );
}
