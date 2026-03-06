import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/adaptive_engine.dart';

void main() {
  group('AdaptiveEngine.ontarioLevel', () {
    test('returns Level 4 for theta > 1.5', () {
      expect(AdaptiveEngine.ontarioLevel(1.51), 'Level 4 (80-100%)');
      expect(AdaptiveEngine.ontarioLevel(2.0), 'Level 4 (80-100%)');
      expect(AdaptiveEngine.ontarioLevel(10.0), 'Level 4 (80-100%)');
    });

    test('returns Level 3 for 0.0 < theta <= 1.5', () {
      expect(AdaptiveEngine.ontarioLevel(1.5), 'Level 3 (70-79%)');
      expect(AdaptiveEngine.ontarioLevel(1.0), 'Level 3 (70-79%)');
      expect(AdaptiveEngine.ontarioLevel(0.01), 'Level 3 (70-79%)');
    });

    test('returns Level 2 for -1.0 < theta <= 0.0', () {
      expect(AdaptiveEngine.ontarioLevel(0.0), 'Level 2 (60-69%)');
      expect(AdaptiveEngine.ontarioLevel(-0.5), 'Level 2 (60-69%)');
      expect(AdaptiveEngine.ontarioLevel(-0.99), 'Level 2 (60-69%)');
    });

    test('returns Level 1 for theta <= -1.0', () {
      expect(AdaptiveEngine.ontarioLevel(-1.0), 'Level 1 (50-59%)');
      expect(AdaptiveEngine.ontarioLevel(-1.5), 'Level 1 (50-59%)');
      expect(AdaptiveEngine.ontarioLevel(-10.0), 'Level 1 (50-59%)');
    });
  });

  group('AdaptiveEngine.nextReviewInterval', () {
    test('calculates correct days based on factor and rounds appropriately', () {
      // 10 * 0.5 = 5.0 -> 5
      expect(AdaptiveEngine.nextReviewInterval(10, 0.5), const Duration(days: 5));
      // 10 * 0.54 = 5.4 -> 5
      expect(AdaptiveEngine.nextReviewInterval(10, 0.54), const Duration(days: 5));
      // 10 * 0.55 = 5.5 -> 6
      expect(AdaptiveEngine.nextReviewInterval(10, 0.55), const Duration(days: 6));
    });

    test('returns minimum of 1 day if calculated value is < 1', () {
      // 10 * 0.01 = 0.1 -> 0, but max is 1
      expect(AdaptiveEngine.nextReviewInterval(10, 0.01), const Duration(days: 1));
      // 0 questions
      expect(AdaptiveEngine.nextReviewInterval(0, 1.0), const Duration(days: 1));
      // Negative factor (should theoretically not happen but testing the max boundary)
      expect(AdaptiveEngine.nextReviewInterval(10, -0.5), const Duration(days: 1));
    });
  });
}
