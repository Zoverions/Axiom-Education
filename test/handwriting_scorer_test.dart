import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/handwriting_scorer.dart';

void main() {
  group('HandwritingScorer', () {
    test('scoreHandwriting returns fallback scores when uninitialized', () async {
      // Arrange
      final scorer = HandwritingScorer();
      final strokes = [
        {'x': 10.0, 'y': 20.0, 'pressure': 0.5},
        {'x': 12.0, 'y': 22.0, 'pressure': 0.6},
      ];

      // Act
      final result = await scorer.scoreHandwriting(strokes);

      // Assert
      expect(result, (0.8, 0.85));
    });
  });
}
