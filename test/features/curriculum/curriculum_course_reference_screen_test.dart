import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/providers/curriculum_provider.dart';
import 'package:ontarioedai/features/curriculum/curriculum_course_reference_screen.dart';

void main() {
  Widget buildReference({
    required String courseId,
    required CourseDetail detail,
  }) {
    return ProviderScope(
      overrides: [
        courseDetailProvider(courseId).overrideWith((ref) async => detail),
      ],
      child: MaterialApp(
        home: CurriculumCourseReferenceScreen(
          courseId: courseId,
          fallbackCourseName: detail.name,
        ),
      ),
    );
  }

  testWidgets('keeps curriculum detail explicitly reference-only', (
    tester,
  ) async {
    const detail = CourseDetail('ENG3U', 'English, Grade 11', [
      StrandDetail('Writing', [
        ExpectationDetail('Develop and organize ideas for a purpose.', [
          'writing',
        ]),
      ]),
    ]);

    await tester.pumpWidget(buildReference(courseId: 'ENG3U', detail: detail));
    await tester.pumpAndSettle();

    expect(find.text('English, Grade 11'), findsOneWidget);
    expect(find.textContaining('Reference view only'), findsOneWidget);
    expect(find.textContaining('does not mark it complete'), findsOneWidget);
    expect(find.text('Open Grade 9 Math learning'), findsNothing);

    await tester.tap(find.text('Writing'));
    await tester.pumpAndSettle();
    expect(
      find.text('Develop and organize ideas for a purpose.'),
      findsOneWidget,
    );
  });

  testWidgets('offers MTH1W learning as a separate explicit action', (
    tester,
  ) async {
    const detail = CourseDetail('MTH1W', 'Mathematics, Grade 9', [
      StrandDetail('Algebra', [
        ExpectationDetail(
          'Use algebraic reasoning in mathematical situations.',
          ['algebra'],
        ),
      ]),
    ]);

    await tester.pumpWidget(buildReference(courseId: 'MTH1W', detail: detail));
    await tester.pumpAndSettle();

    expect(find.text('Mathematics, Grade 9'), findsOneWidget);
    expect(find.text('Open Grade 9 Math learning'), findsOneWidget);
    expect(find.textContaining('Reference view only'), findsOneWidget);
  });
}
