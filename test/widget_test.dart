import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:ontarioedai/main.dart';

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

  testWidgets('opens a searchable local curriculum browser', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Ontario Secondary Curriculum Pack'), findsOneWidget);
    expect(find.text('3 courses • 31 expectations'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(EditableText), 'English');
    await tester.pump();

    expect(find.text('ENG3U'), findsOneWidget);
    expect(find.text('MTH1W'), findsNothing);
  });

  testWidgets('shows a clear empty search state', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'not-a-course');
    await tester.pump();

    expect(find.text('No courses match “not-a-course”'), findsOneWidget);
    expect(find.text('Search by course code or course name.'), findsOneWidget);
  });

  testWidgets('recovers when local startup succeeds on retry', (tester) async {
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
    expect(find.text('Ontario Secondary Curriculum Pack'), findsOneWidget);
  });
}
