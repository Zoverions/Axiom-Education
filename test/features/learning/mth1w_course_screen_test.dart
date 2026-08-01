import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/practice/mth1w_practice_provider.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:ontarioedai/features/learning/mth1w_course_screen.dart';

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

  Widget buildScreen({List<CurriculumItem> items = expectations}) {
    return ProviderScope(
      overrides: [mth1wGoldenPathProvider.overrideWith((ref) async => items)],
      child: const MaterialApp(home: Mth1wCourseScreen()),
    );
  }

  testWidgets('presents a conventional course path before mixed practice', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Foundations preview'), findsOneWidget);
    expect(find.textContaining('without an AI tutor'), findsOneWidget);
    expect(find.textContaining('not a complete MTH1W course'), findsOneWidget);
    expect(
      find.text('Order of operations with rational numbers'),
      findsOneWidget,
    );
    expect(find.text('Percentages and proportional reasoning'), findsOneWidget);
    expect(find.text('Open mixed practice'), findsOneWidget);
    expect(find.text('Open home learning guide'), findsOneWidget);
    expect(find.text('Open source-mapped draft Unit 1'), findsOneWidget);
  });

  testWidgets('teaches with a worked example before focused practice', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final firstLesson = find.text('Order of operations with rational numbers');
    await tester.scrollUntilVisible(
      firstLesson,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(firstLesson);
    await tester.pumpAndSettle();

    expect(find.text('Learning goals'), findsOneWidget);
    expect(find.text('Before you begin'), findsOneWidget);
    expect(find.text('Worked example'), findsOneWidget);
    expect(find.text('Evaluate 18 − 3 × (4 − 6).'), findsOneWidget);

    await tester.ensureVisible(find.text('Compare methods'));
    await tester.pumpAndSettle();
    expect(find.text('Compare methods'), findsOneWidget);
    expect(find.textContaining('not fixed learner types'), findsOneWidget);
    expect(find.textContaining('Rule-and-line method'), findsOneWidget);
    expect(find.textContaining('Expression-tree method'), findsOneWidget);

    await tester.ensureVisible(find.text('Represent it more than one way'));
    await tester.pumpAndSettle();
    expect(find.text('Represent it more than one way'), findsOneWidget);
    expect(find.textContaining('expression tree'), findsWidgets);

    await tester.ensureVisible(find.text('Common mistake to avoid'));
    await tester.pumpAndSettle();
    expect(find.text('Common mistake to avoid'), findsOneWidget);

    final practiceButton = find.byKey(
      const ValueKey('mth1w-start-practice-MTH1W-A1'),
    );
    await tester.ensureVisible(practiceButton);
    await tester.pumpAndSettle();
    final focusedPracticeButton = tester
        .widgetList<FilledButton>(practiceButton)
        .first;
    expect(focusedPracticeButton.onPressed, isNotNull);
    focusedPracticeButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.textContaining('MTH1W-A1'), findsOneWidget);
    expect(find.text('Practice item'), findsOneWidget);
  });

  testWidgets('fails closed when a lesson expectation is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(items: expectations.take(3).toList()));
    await tester.pumpAndSettle();

    expect(
      find.text('The math foundations preview is unavailable'),
      findsOneWidget,
    );
    expect(find.textContaining('No ungrounded lesson'), findsOneWidget);
  });
}
