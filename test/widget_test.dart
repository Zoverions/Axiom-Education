import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:ontarioedai/main.dart';

Future<void> tapVisibleText(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  final courses = <CourseOverview>[
    const CourseOverview('A', 'Arts Foundations', 1),
    const CourseOverview('ENG3U', 'English, Grade 11', 12),
    const CourseOverview('MTH1W', 'Mathematics, Grade 9', 18),
  ];

  Widget buildApp({AppInitializer? initializer}) {
    return ProviderScope(
      overrides: [courseOverviewProvider.overrideWith((ref) async => courses)],
      child: MyApp(initializer: initializer ?? () async {}),
    );
  }

  testWidgets('opens a learner-facing home', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Learn locally. Stay in control.'), findsOneWidget);
    expect(find.text('Grade 9 Math Foundations'), findsOneWidget);
    expect(find.text('Open math learning'), findsOneWidget);
    expect(find.text('Quick practice'), findsOneWidget);
    expect(find.text('Browse curriculum'), findsOneWidget);
    expect(find.text('Family tools'), findsOneWidget);
    expect(find.text('What this app does today'), findsOneWidget);
    expect(
      find.textContaining('Practice feedback is temporary'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a searchable curriculum library from home', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tapVisibleText(tester, 'Open curriculum library');

    expect(find.text('Curriculum library'), findsOneWidget);
    expect(find.text('Ontario secondary curriculum'), findsOneWidget);
    expect(find.text('3 courses • 31 expectations'), findsOneWidget);
    expect(find.textContaining('Arts Foundations'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.textContaining('Browsing here does not enrol'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'English');
    await tester.pump();

    expect(find.text('ENG3U'), findsOneWidget);
    expect(find.text('MTH1W'), findsNothing);
  });

  testWidgets('shows a clear empty curriculum search state', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tapVisibleText(tester, 'Open curriculum library');
    await tester.enterText(find.byType(EditableText), 'not-a-course');
    await tester.pump();

    expect(find.text('No courses match “not-a-course”'), findsOneWidget);
    expect(
      find.text('Try a course code, subject, or a shorter search.'),
      findsOneWidget,
    );
  });

  testWidgets('opens honest family tools and the home learning guide', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tapVisibleText(tester, 'Open family tools');

    expect(find.text('Family support that stays honest'), findsOneWidget);
    expect(find.text('Saved progress is not enabled yet'), findsOneWidget);
    expect(find.textContaining('made-up study time'), findsOneWidget);
    expect(find.text('45 mins today'), findsNothing);
    expect(find.text('5 / 7 tasks'), findsNothing);
    expect(find.text('Level 3 (75%)'), findsNothing);
    expect(find.text('Score: 90%'), findsNothing);

    await tapVisibleText(tester, 'Open home learning guide');

    expect(find.text('Home learning guide'), findsOneWidget);
    expect(find.text('A 45-minute session'), findsOneWidget);
    expect(find.text('Two learners, one device'), findsOneWidget);
    expect(find.textContaining('Use Another question'), findsOneWidget);
    expect(find.text('Ready to try the routine?'), findsOneWidget);
    expect(find.text('Start mixed practice'), findsOneWidget);
  });

  testWidgets(
    'recovers into learner home when local startup succeeds on retry',
    (tester) async {
      var attempts = 0;

      Future<void> initialize() async {
        attempts += 1;
        if (attempts == 1) {
          throw StateError('simulated local setup failure');
        }
      }

      await tester.pumpWidget(buildApp(initializer: initialize));
      await tester.pumpAndSettle();

      expect(find.text('Local setup could not finish'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('Learn locally. Stay in control.'), findsOneWidget);
    },
  );
}
