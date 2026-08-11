import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/student_profile.dart';
import 'package:ontarioedai/core/services/adaptive_engine.dart';

void main() {
  group('AdaptiveEngine.updateTheta', () {
    test('returns the current theta when no responses are supplied', () {
      final result = AdaptiveEngine.updateTheta(
        currentTheta: 0.5,
        responses: const [],
        difficulties: const [],
      );

      expect(result, 0.5);
    });

    test('increases theta after a correct response', () {
      const initialTheta = 0.5;
      final result = AdaptiveEngine.updateTheta(
        currentTheta: initialTheta,
        responses: const [1.0],
        difficulties: const [0.5],
      );

      expect(result, greaterThan(initialTheta));
    });

    test('decreases theta after an incorrect response', () {
      const initialTheta = 0.5;
      final result = AdaptiveEngine.updateTheta(
        currentTheta: initialTheta,
        responses: const [0.0],
        difficulties: const [0.5],
      );

      expect(result, lessThan(initialTheta));
    });

    test('accumulates updates for multiple responses', () {
      const initialTheta = 0.5;
      final correctOnly = AdaptiveEngine.updateTheta(
        currentTheta: initialTheta,
        responses: const [1.0],
        difficulties: const [0.5],
      );
      final incorrectOnly = AdaptiveEngine.updateTheta(
        currentTheta: initialTheta,
        responses: const [0.0],
        difficulties: const [0.8],
      );
      final combined = AdaptiveEngine.updateTheta(
        currentTheta: initialTheta,
        responses: const [1.0, 0.0],
        difficulties: const [0.5, 0.8],
      );

      final expected =
          initialTheta +
          (correctOnly - initialTheta) +
          (incorrectOnly - initialTheta);
      expect(combined, closeTo(expected, 1e-10));
    });
  });

  group('AdaptiveEngine.sessionLength', () {
    test('returns the current fixed development session length', () {
      final result = AdaptiveEngine.sessionLength(StudentProfile());

      expect(result, const Duration(minutes: 15));
    });
  });

  group('AdaptiveEngine.ontarioLevel', () {
    test('maps values above 1.5 to Level 4', () {
      expect(AdaptiveEngine.ontarioLevel(1.51), 'Level 4 (80-100%)');
      expect(AdaptiveEngine.ontarioLevel(10.0), 'Level 4 (80-100%)');
    });

    test('maps values above 0.0 through 1.5 to Level 3', () {
      expect(AdaptiveEngine.ontarioLevel(1.5), 'Level 3 (70-79%)');
      expect(AdaptiveEngine.ontarioLevel(0.01), 'Level 3 (70-79%)');
    });

    test('maps values above -1.0 through 0.0 to Level 2', () {
      expect(AdaptiveEngine.ontarioLevel(0.0), 'Level 2 (60-69%)');
      expect(AdaptiveEngine.ontarioLevel(-0.99), 'Level 2 (60-69%)');
    });

    test('maps values at or below -1.0 to Level 1', () {
      expect(AdaptiveEngine.ontarioLevel(-1.0), 'Level 1 (50-59%)');
      expect(AdaptiveEngine.ontarioLevel(-10.0), 'Level 1 (50-59%)');
    });
  });

  group('AdaptiveEngine.nextReviewInterval', () {
    test('rounds the calculated interval to whole days', () {
      expect(
        AdaptiveEngine.nextReviewInterval(10, 0.5),
        const Duration(days: 5),
      );
      expect(
        AdaptiveEngine.nextReviewInterval(10, 0.54),
        const Duration(days: 5),
      );
      expect(
        AdaptiveEngine.nextReviewInterval(10, 0.56),
        const Duration(days: 6),
      );
    });

    test('never returns less than one day', () {
      expect(
        AdaptiveEngine.nextReviewInterval(0, 0.5),
        const Duration(days: 1),
      );
      expect(
        AdaptiveEngine.nextReviewInterval(10, -0.5),
        const Duration(days: 1),
      );
    });
  });
}
