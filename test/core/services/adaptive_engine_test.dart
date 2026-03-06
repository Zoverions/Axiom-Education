import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/adaptive_engine.dart';

void main() {
  group('AdaptiveEngine', () {
    test('updateTheta should return currentTheta when responses and difficulties are empty lists', () {
      final currentTheta = 1.0;
      final newTheta = AdaptiveEngine.updateTheta(
        currentTheta: currentTheta,
        responses: [],
        difficulties: [],
      );

      expect(newTheta, currentTheta);
    });
  });
}
