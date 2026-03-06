import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/model_bindings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HandwritingScorer', () {
    test('initModel error leaves it uninitialized and returns fallback scores', () async {
      final scorer = HandwritingScorer();

      // Attempt init using our injected mock loader that explicitly throws
      await scorer.initModel(
        interpreterLoader: () async => throw Exception('Mock TFLite Load Failure'),
      );

      // Verify that the explicitly failed mock caused isInitialized to be false
      expect(scorer.isInitialized, isFalse);

      // Ensure it uses fallback by calling scoreHandwriting
      final scores = await scorer.scoreHandwriting([]);
      expect(scores, equals((0.8, 0.85)));
    });
  });
}
