import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/practice/mth1w_practice_provider.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:ontarioedai/features/learning/mth1w_learning_hub_screen.dart';

void main() {
  const expectations = <CurriculumItem>[
    CurriculumItem(
      id: 'MTH1W-A1',
      courseCode: 'MTH1W',
      strand: 'Foundations',
      expectation: 'Order of operations foundation reference',
      irtB: 0,
      irtA: 1.2,
      irtC: 0.2,
      tags: [],
    ),
    CurriculumItem(
      id: 'MTH1W-A2',
      courseCode: 'MTH1W',
      strand: 'Foundations',
      expectation: 'Percent and proportional reasoning foundation reference',
      irtB: 0,
      irtA: 1.2,
      irtC: 0.2,
      tags: [],
    ),
    CurriculumItem(
      id: 'MTH1W-B2',
      courseCode: 'MTH1W',
      strand: 'Foundations',
      expectation: 'Linear equation foundation reference',
      irtB: 0,
      irtA: 1.2,
      irtC: 0.2,
      tags: [],
    ),
    CurriculumItem(
      id: 'MTH1W-B4',
      courseCode: 'MTH1W',
      strand: 'Foundations',
      expectation: 'Linear relationship foundation reference',
      irtB: 0,
      irtA: 1.2,
      irtC: 0.2,
      tags: [],
    ),
  ];

  Widget buildHub({List<CurriculumItem> items = expectations}) {
    return ProviderScope(
      overrides: [
        mth1wGoldenPathProvider.overrideWith((ref) async => items),
      ],
      child: const MaterialApp(home: Mth1wLearningHubScreen()),
    );
  }

  testWidgets('puts the four foundation lessons before draft-course exploration', (
    tester,
  ) async {
    await tester.pumpWidget(buildHub());
    await tester.pumpAndSettle();

    expect(find.text('Build the foundations, then practise'), findsOneWidget);
    expect(find.text('Start here'), findsOneWidget);
    expect(find.text('Order of operations with rational numbers'), findsOneWidget);
    expect(find.text('Percentages and proportional reasoning'), findsOneWidget);
    expect(find.text('Solving linear equations'), findsOneWidget);
    expect(find.text('Equation of a line from two points'), findsOneWidget);
    expect(find.text('Start mixed practice'), findsOneWidget);
    expect(find.text('Explore more Grade 9 Math'), findsOneWidget);
    expect(find.text('Explore draft units'), findsOneWidget);

    expect(find.text('Open source-mapped draft Unit 1'), findsNothing);
    expect(find.text('Open source-mapped draft Unit 9'), findsNothing);
  });

  testWidgets('opens a foundation lesson directly from the learner hub', (
    tester,
  ) async {
    await tester.pumpWidget(buildHub());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hub-open-foundation-MTH1W-A1')));
    await tester.pumpAndSettle();

    expect(find.text('Math foundations lesson'), findsOneWidget);
    expect(find.text('Lesson 1 of 4'), findsOneWidget);
    expect(find.text('Order of operations with rational numbers'), findsOneWidget);
    expect(find.text('Learning goals'), findsOneWidget);
  });

  testWidgets('fails closed when a required local foundation reference is missing', (
    tester,
  ) async {
    await tester.pumpWidget(buildHub(items: expectations.take(3).toList()));
    await tester.pumpAndSettle();

    expect(find.text('Grade 9 Math could not be prepared'), findsOneWidget);
    expect(find.textContaining('No lesson or practice result was inferred'), findsOneWidget);
    expect(find.text('Start here'), findsNothing);
  });
}
