import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_errors.dart';

/// Experimental TFLite binding for stylus-signal scoring.
///
/// The scorer is disabled unless an explicit model is initialized. It never
/// substitutes fixed scores when the model is absent or execution fails.
class HandwritingScorer {
  static const int maxStrokes = 100;

  Interpreter? _interpreter;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initModel({
    Future<Interpreter> Function()? interpreterLoader,
  }) async {
    if (_isInitialized) return;

    try {
      if (interpreterLoader != null) {
        _interpreter = await interpreterLoader();
      } else {
        final options = InterpreterOptions()..threads = 4;
        _interpreter = await Interpreter.fromAsset(
          'assets/models/handwriting_scorer.tflite',
          options: options,
        );
      }
      _isInitialized = true;
    } catch (error) {
      _interpreter = null;
      _isInitialized = false;
      throw ModelUnavailableException(
        capability: 'input.handwriting-scorer',
        message: 'The handwriting scorer could not be initialized.',
        cause: error,
      );
    }
  }

  @visibleForTesting
  List<List<List<double>>> preprocessStrokes(
    List<Map<String, dynamic>> strokes,
  ) {
    if (strokes.length > maxStrokes) {
      throw const FormatException('Handwriting stroke limit exceeded.');
    }

    final inputTensor = List.generate(
      1,
      (_) => List.generate(maxStrokes, (_) => List<double>.filled(3, 0.0)),
    );

    for (var index = 0; index < strokes.length; index++) {
      final stroke = strokes[index];
      inputTensor[0][index][0] = _boundedNumber(stroke['x'], 'x');
      inputTensor[0][index][1] = _boundedNumber(stroke['y'], 'y');
      inputTensor[0][index][2] = _boundedNumber(
        stroke['pressure'] ?? 0.5,
        'pressure',
        minimum: 0.0,
        maximum: 1.0,
      );
    }

    return inputTensor;
  }

  static double _boundedNumber(
    Object? value,
    String field, {
    double minimum = -1000000.0,
    double maximum = 1000000.0,
  }) {
    if (value is! num || !value.isFinite) {
      throw FormatException('Invalid handwriting $field value.');
    }
    final converted = value.toDouble();
    if (converted < minimum || converted > maximum) {
      throw FormatException('Handwriting $field value is out of range.');
    }
    return converted;
  }

  /// Returns `(pressureScore, consistencyScore)` from an initialized model.
  Future<(double, double)> scoreHandwriting(
    List<Map<String, dynamic>> strokes,
  ) async {
    if (!_isInitialized || _interpreter == null) {
      throw const ModelUnavailableException(
        capability: 'input.handwriting-scorer',
        message: 'The handwriting scorer is not initialized.',
      );
    }

    try {
      final inputTensor = preprocessStrokes(strokes);
      final outputTensor = List.generate(1, (_) => List<double>.filled(2, 0.0));
      _interpreter!.run(inputTensor, outputTensor);

      return (
        outputTensor[0][0].clamp(0.0, 1.0).toDouble(),
        outputTensor[0][1].clamp(0.0, 1.0).toDouble(),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw ModelExecutionException(
        capability: 'input.handwriting-scorer',
        message: 'Handwriting scoring failed.',
        cause: error,
      );
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
