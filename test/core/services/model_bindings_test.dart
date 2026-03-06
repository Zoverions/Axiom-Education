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
  group('HandwritingScorer', () {
    late HandwritingScorer scorer;

    setUp(() {
      scorer = HandwritingScorer();
    });

    test('preprocessStrokes handles exactly 100 strokes without errors', () {
      // Create 100 mock strokes
      final strokes = List.generate(
        100,
        (index) => {'x': index.toDouble(), 'y': index.toDouble(), 'pressure': 0.5},
      );

      final result = scorer.preprocessStrokes(strokes);

      // Verify shape: [1][100][3]
      expect(result.length, 1);
      expect(result[0].length, 100);
      expect(result[0][0].length, 3);

      // Verify values for the first stroke
      expect(result[0][0][0], 0.0);
      expect(result[0][0][1], 0.0);
      expect(result[0][0][2], 0.5);

      // Verify values for the last (100th) stroke
      expect(result[0][99][0], 99.0);
      expect(result[0][99][1], 99.0);
      expect(result[0][99][2], 0.5);
    });

    test('preprocessStrokes handles excessive strokes (>100) safely by truncating', () {
      // Create 150 mock strokes
      final strokes = List.generate(
        150,
        (index) => {'x': index.toDouble(), 'y': index.toDouble(), 'pressure': 0.5},
      );

      final result = scorer.preprocessStrokes(strokes);

      // Verify shape is still [1][100][3] (maxStrokes is 100)
      expect(result.length, 1);
      expect(result[0].length, 100);
      expect(result[0][0].length, 3);

      // Verify values for the last (100th) stroke is from index 99
      expect(result[0][99][0], 99.0);
      expect(result[0][99][1], 99.0);
      expect(result[0][99][2], 0.5);
    });

    test('preprocessStrokes handles fewer than 100 strokes correctly', () {
      // Create 50 mock strokes
      final strokes = List.generate(
        50,
        (index) => {'x': index.toDouble(), 'y': index.toDouble(), 'pressure': 0.5},
      );

      final result = scorer.preprocessStrokes(strokes);

      // Verify shape is still [1][100][3]
      expect(result.length, 1);
      expect(result[0].length, 100);
      expect(result[0][0].length, 3);

      // Verify values for the 50th stroke (which is populated)
      expect(result[0][49][0], 49.0);
      expect(result[0][49][1], 49.0);
      expect(result[0][49][2], 0.5);

      // Verify values for the 51st stroke (which is default filled with 0.0)
      expect(result[0][50][0], 0.0);
      expect(result[0][50][1], 0.0);
      expect(result[0][50][2], 0.0);
    });
  });
}
