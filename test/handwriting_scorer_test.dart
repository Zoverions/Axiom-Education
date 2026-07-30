import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/handwriting_scorer.dart';
import 'package:ontarioedai/core/services/model_errors.dart';

void main() {
  group('HandwritingScorer', () {
    test('scoreHandwriting fails closed when uninitialized', () async {
      final scorer = HandwritingScorer();
      final strokes = [
        {'x': 10.0, 'y': 20.0, 'pressure': 0.5},
        {'x': 12.0, 'y': 22.0, 'pressure': 0.6},
      ];

      await expectLater(
        scorer.scoreHandwriting(strokes),
        throwsA(
          isA<ModelUnavailableException>().having(
            (error) => error.capability,
            'capability',
            'input.handwriting-scorer',
          ),
        ),
      );
    });
  });
}
