import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/adaptive_engine.dart';

void main() {
  group('AdaptiveEngine', () {
    group('updateTheta', () {
      test('should return original theta when responses and difficulties are empty', () {
        const initialTheta = 0.5;

        final result = AdaptiveEngine.updateTheta(
          currentTheta: initialTheta,
          responses: [],
          difficulties: [],
        );

        expect(result, equals(initialTheta));
      });
    });
  });
}
