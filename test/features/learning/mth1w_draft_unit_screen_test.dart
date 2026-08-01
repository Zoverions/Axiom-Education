import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/learning/mth1w_unit_content.dart';
import 'package:ontarioedai/core/providers/mth1w_unit_content_provider.dart';
import 'package:ontarioedai/features/learning/mth1w_draft_unit_screen.dart';

const contentPath = 'curriculum/content/mth1w/u1-number-systems.v1.json';
const unitTwoContentPath = 'curriculum/content/mth1w/u2-powers.v1.json';

Mth1wUnitContent loadUnit() {
  return Mth1wUnitContent.fromJsonString(File(contentPath).readAsStringSync());
}

Widget buildUnitScreen(Mth1wUnitContent unit, {int unitNumber = 1}) {
  final provider = unitNumber == 1
      ? mth1wUnitOneProvider
      : mth1wUnitTwoProvider;
  return ProviderScope(
    overrides: [provider.overrideWith((ref) async => unit)],
    child: MaterialApp(home: Mth1wDraftUnitScreen(unitNumber: unitNumber)),
  );
}

Finder outerScrollable() {
  return find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 500, scrollable: outerScrollable());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'presents the source-mapped draft boundary and full Unit 1 path',
    (tester) async {
      final unit = loadUnit();
      await tester.pumpWidget(buildUnitScreen(unit));
      await tester.pumpAndSettle();

      expect(find.text(unit.title), findsOneWidget);
      expect(
        find.textContaining('Source-mapped draft preview'),
        findsOneWidget,
      );
      expect(
        find.textContaining('not a complete MTH1W course'),
        findsOneWidget,
      );
      expect(
        find.text('Numbers across cultures: evidence and context'),
        findsOneWidget,
      );
      expect(find.text('Map the real-number family'), findsOneWidget);
      expect(
        find.text('Density, infinity, and approaching a limit'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('mth1w-u1-open-quiz')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mth1w-u1-open-performance-task')),
        findsOneWidget,
      );
    },
  );

  testWidgets('presents the source-mapped draft Unit 2 path', (tester) async {
    final unit = Mth1wUnitContent.fromJsonString(
      File(unitTwoContentPath).readAsStringSync(),
    );
    await tester.pumpWidget(buildUnitScreen(unit, unitNumber: 2));
    await tester.pumpAndSettle();

    expect(find.text(unit.title), findsOneWidget);
    expect(find.textContaining('B2.1, B2.2'), findsOneWidget);
    expect(
      find.text('Exponent patterns and scientific notation'),
      findsOneWidget,
    );
    expect(find.text('Build the exponent laws from patterns'), findsOneWidget);
    expect(find.byKey(const ValueKey('mth1w-u2-open-quiz')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mth1w-u2-open-performance-task')),
      findsOneWidget,
    );
  });

  testWidgets('teaches, accepts a response, and gives task-specific feedback', (
    tester,
  ) async {
    final unit = loadUnit();
    await tester.pumpWidget(buildUnitScreen(unit));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('mth1w-draft-lesson-mth1w-u1-l1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learning goals'), findsOneWidget);
    expect(find.text('Compare methods'), findsOneWidget);
    expect(find.textContaining('not a fixed learner type'), findsOneWidget);
    expect(find.text('Worked example 1'), findsOneWidget);

    await scrollTo(tester, find.text('Guided practice'));
    await tester.tap(find.text('Guided practice'));
    await tester.pumpAndSettle();

    final item = unit.lessons.first.practiceSets.guided.first;
    final dropdown = find.byType(DropdownButtonFormField<String>).first;
    await scrollTo(tester, dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(item.response.correctAnswer!).last);
    await tester.pumpAndSettle();

    final check = find.byKey(ValueKey('check-${item.id}'));
    await scrollTo(tester, check);
    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text(item.rationale), findsOneWidget);
  });

  testWidgets(
    'submits the quiz once and keeps explanations educator-reviewed',
    (tester) async {
      final unit = loadUnit();
      await tester.pumpWidget(
        MaterialApp(home: Mth1wDraftQuizScreen(quiz: unit.assessment.quiz)),
      );
      await tester.pumpAndSettle();

      final submit = find.byKey(const ValueKey('mth1w-u1-submit-quiz'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      for (final item in unit.assessment.quiz.items) {
        final input = find.byKey(
          PageStorageKey('quiz-response-${item.id}-false'),
        );
        await scrollTo(tester, input);
        if (item.response.type == Mth1wResponseType.selected) {
          final dropdown = find.descendant(
            of: input,
            matching: find.byType(DropdownButtonFormField<String>),
          );
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          await tester.tap(find.text(item.response.correctAnswer!).last);
        } else {
          final field = find.descendant(
            of: input,
            matching: find.byType(TextFormField),
          );
          await tester.enterText(field, item.response.disclosedAnswer);
        }
        await tester.pumpAndSettle();
      }

      await scrollTo(tester, submit);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      final summary = find.textContaining(
        'automatically checkable responses are exact',
      );
      await scrollTo(tester, summary);
      expect(summary, findsOneWidget);
      expect(
        find.textContaining('require adult or educator review'),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('mth1w-u1-correct-quiz')),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows transparent performance-task requirements and rubric', (
    tester,
  ) async {
    final task = loadUnit().assessment.performanceTask;
    await tester.pumpWidget(
      MaterialApp(home: Mth1wDraftPerformanceTaskScreen(task: task)),
    );
    await tester.pumpAndSettle();

    expect(find.text(task.title), findsOneWidget);
    expect(find.text('Required components'), findsOneWidget);
    expect(find.text('Review rubric'), findsOneWidget);
    expect(find.textContaining('does not generate a grade'), findsOneWidget);
  });
}
