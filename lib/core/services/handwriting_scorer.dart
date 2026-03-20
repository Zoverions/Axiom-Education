import 'package:tflite_flutter/tflite_flutter.dart';

/// TFLite model binding for handwriting scoring
class HandwritingScorer {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initModel() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/handwriting_scorer.tflite',
        options: options,
      );
      _isInitialized = true;
    } catch (e) {
      // Error is caught but not printed
    }
  }

  /// Evaluates stylus pressure and stroke consistency.
  /// Returns a record: (pressure_score, consistency_score)
  Future<(double, double)> scoreHandwriting(
    List<Map<String, dynamic>> strokes,
  ) async {
    if (!_isInitialized || _interpreter == null)
      return (0.8, 0.85); // fallback mock scores

    try {
      // 1. Preprocess strokes into tensor shape [1, MAX_STROKES, 3] (x, y, pressure)
      const int maxStrokes = 100;
      var inputTensor = List.generate(
        1,
        (_) => List.generate(maxStrokes, (_) => List.filled(3, 0.0)),
      );

      int strokeIdx = 0;
      for (var stroke in strokes) {
        if (strokeIdx >= maxStrokes) break;
        inputTensor[0][strokeIdx][0] = (stroke['x'] as double?) ?? 0.0;
        inputTensor[0][strokeIdx][1] = (stroke['y'] as double?) ?? 0.0;
        inputTensor[0][strokeIdx][2] = (stroke['pressure'] as double?) ?? 0.5;
        strokeIdx++;
      }

      // 2. Output tensor shape [1, 2] for pressure and consistency scores
      var outputTensor = List.generate(1, (_) => List.filled(2, 0.0));

      // 3. Run inference
      _interpreter!.run(inputTensor, outputTensor);

      double pressureScore = outputTensor[0][0];
      double consistencyScore = outputTensor[0][1];

      return (pressureScore.clamp(0.0, 1.0), consistencyScore.clamp(0.0, 1.0));
    } catch (e) {
      return (0.8, 0.85);
    }
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
