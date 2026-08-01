import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/learning/mth1w_foundation.dart';
import 'package:ontarioedai/core/practice/mth1w_practice_provider.dart';

void main() {
  group('MTH1W traditional foundation', () {
    test('covers the complete deterministic golden path in course order', () {
      expect(
        mth1wFoundationLessons.map((lesson) => lesson.expectationId),
        mth1wGoldenPathOrder,
      );
      expect(mth1wFoundationLessons.map((lesson) => lesson.sequence), [
        1,
        2,
        3,
        4,
      ]);
    });

    test('every lesson has teach-practise instructional components', () {
      for (final lesson in mth1wFoundationLessons) {
        expect(lesson.title, isNotEmpty);
        expect(lesson.estimatedMinutes, greaterThan(0));
        expect(lesson.whyItMatters, isNotEmpty);
        expect(lesson.learningGoals.length, greaterThanOrEqualTo(2));
        expect(lesson.prerequisites.length, greaterThanOrEqualTo(2));
        expect(lesson.directInstruction, isNotEmpty);
        expect(lesson.workedExamplePrompt, isNotEmpty);
        expect(lesson.workedExampleSteps.length, greaterThanOrEqualTo(3));
        expect(lesson.commonMisconception, isNotEmpty);
        expect(lesson.reflectionPrompt, isNotEmpty);
      }
    });
  });
}
