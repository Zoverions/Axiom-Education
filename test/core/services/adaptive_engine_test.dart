import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/adaptive_engine.dart';
import 'package:ontarioedai/core/models/student_profile.dart';

void main() {
  group('AdaptiveEngine', () {
    group('updateTheta', () {
      test('should return currentTheta when responses and difficulties are empty', () {
        final result = AdaptiveEngine.updateTheta(
          currentTheta: 0.5,
          responses: [],
          difficulties: [],
        );
        expect(result, equals(0.5));
      });

      test('should increase theta for a correct response', () {
        final initialTheta = 0.5;
        final result = AdaptiveEngine.updateTheta(
          currentTheta: initialTheta,
          responses: [1.0],
          difficulties: [0.5],
        );
        expect(result, greaterThan(initialTheta));
      });

      test('should decrease theta for an incorrect response', () {
        final initialTheta = 0.5;
        final result = AdaptiveEngine.updateTheta(
          currentTheta: initialTheta,
          responses: [0.0],
          difficulties: [0.5],
        );
        expect(result, lessThan(initialTheta));
      });

      test('should correctly accumulate updates for multiple responses', () {
        final initialTheta = 0.5;

        final resultCorrect = AdaptiveEngine.updateTheta(
          currentTheta: initialTheta,
          responses: [1.0],
          difficulties: [0.5],
        );
        final resultIncorrect = AdaptiveEngine.updateTheta(
          currentTheta: initialTheta,
          responses: [0.0],
          difficulties: [0.8],
        );

        final deltaCorrect = resultCorrect - initialTheta;
        final deltaIncorrect = resultIncorrect - initialTheta;

        final combinedResult = AdaptiveEngine.updateTheta(
          currentTheta: initialTheta,
          responses: [1.0, 0.0],
          difficulties: [0.5, 0.8],
        );

        // The engine calculates updates based on the initial currentTheta for all items in the batch
        expect(combinedResult, closeTo(initialTheta + deltaCorrect + deltaIncorrect, 1e-10));
      });
    });

    group('sessionLength', () {
      test('should return 15 minutes', () {
        final profile = StudentProfile();
        final result = AdaptiveEngine.sessionLength(profile);
        expect(result, equals(const Duration(minutes: 15)));
      });
    });

    group('ontarioLevel', () {
      test('should return Level 4 for theta > 1.5', () {
        expect(AdaptiveEngine.ontarioLevel(1.51), equals('Level 4 (80-100%)'));
        expect(AdaptiveEngine.ontarioLevel(2.0), equals('Level 4 (80-100%)'));
      });

      test('should return Level 3 for 0.0 < theta <= 1.5', () {
        expect(AdaptiveEngine.ontarioLevel(1.5), equals('Level 3 (70-79%)'));
        expect(AdaptiveEngine.ontarioLevel(0.01), equals('Level 3 (70-79%)'));
        expect(AdaptiveEngine.ontarioLevel(1.0), equals('Level 3 (70-79%)'));
      });

      test('should return Level 2 for -1.0 < theta <= 0.0', () {
        expect(AdaptiveEngine.ontarioLevel(0.0), equals('Level 2 (60-69%)'));
        expect(AdaptiveEngine.ontarioLevel(-0.99), equals('Level 2 (60-69%)'));
        expect(AdaptiveEngine.ontarioLevel(-0.5), equals('Level 2 (60-69%)'));
      });

      test('should return Level 1 for theta <= -1.0', () {
        expect(AdaptiveEngine.ontarioLevel(-1.0), equals('Level 1 (50-59%)'));
        expect(AdaptiveEngine.ontarioLevel(-1.5), equals('Level 1 (50-59%)'));
        expect(AdaptiveEngine.ontarioLevel(-5.0), equals('Level 1 (50-59%)'));
      });
    });

    group('nextReviewInterval', () {
      test('should return at least 1 day even for small inputs', () {
        expect(AdaptiveEngine.nextReviewInterval(0, 0.5), equals(const Duration(days: 1)));
        expect(AdaptiveEngine.nextReviewInterval(1, 0.1), equals(const Duration(days: 1)));
      });

      test('should return correctly rounded days for typical inputs', () {
        // 10 * 0.5 = 5.0 -> 5 days
        expect(AdaptiveEngine.nextReviewInterval(10, 0.5), equals(const Duration(days: 5)));
        // 10 * 0.54 = 5.4 -> 5 days
        expect(AdaptiveEngine.nextReviewInterval(10, 0.54), equals(const Duration(days: 5)));
        // 10 * 0.56 = 5.6 -> 6 days
        expect(AdaptiveEngine.nextReviewInterval(10, 0.56), equals(const Duration(days: 6)));
      });
    });
  });
}
