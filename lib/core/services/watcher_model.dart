import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_errors.dart';

/// Experimental TFLite image classifier used by the canvas prototype.
///
/// This is not yet a handwritten-mathematics parser. Until a label map,
/// grammar, and deterministic verifier are supplied, the output is only a
/// classifier result and must not be represented as a parsed equation.
class WatcherModel {
  static const int maxEncodedImageBytes = 10 * 1024 * 1024;
  static const int maxDecodedDimension = 4096;
  static const int maxDecodedPixels = 16 * 1024 * 1024;
  static const int inputWidth = 224;
  static const int inputHeight = 224;
  static const int outputClasses = 1000;

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
          'assets/models/watcher_vision.tflite',
          options: options,
        );
      }
      _isInitialized = true;
    } catch (error) {
      _interpreter = null;
      _isInitialized = false;
      throw ModelUnavailableException(
        capability: 'canvas.watcher',
        message: 'The Watcher model could not be initialized.',
        cause: error,
      );
    }
  }

  @visibleForTesting
  void setInterpreterForTest(Interpreter interpreter) {
    _interpreter = interpreter;
    _isInitialized = true;
  }

  /// Classifies a bounded canvas image.
  ///
  /// Throws [ModelUnavailableException] when no model is initialized and
  /// [ModelExecutionException] when inference fails. Invalid image input is
  /// reported explicitly rather than replaced by a mock equation.
  Future<String> parseCanvas(Uint8List imageBytes) async {
    if (imageBytes.length > maxEncodedImageBytes) {
      return 'Image size too large';
    }
    if (!_isInitialized || _interpreter == null) {
      throw const ModelUnavailableException(
        capability: 'canvas.watcher',
        message: 'The Watcher model is not initialized.',
      );
    }

    final img.Image? decodedImage;
    try {
      decodedImage = img.decodeImage(imageBytes);
    } catch (_) {
      return 'Failed to decode image';
    }
    if (decodedImage == null) return 'Failed to decode image';

    final decodedPixels = decodedImage.width * decodedImage.height;
    if (decodedImage.width > maxDecodedDimension ||
        decodedImage.height > maxDecodedDimension ||
        decodedPixels > maxDecodedPixels) {
      return 'Image dimensions too large';
    }

    try {
      final resizedImage = img.copyResize(
        decodedImage,
        width: inputWidth,
        height: inputHeight,
      );

      final inputTensor = List.generate(
        1,
        (_) => List.generate(
          inputHeight,
          (y) => List.generate(
            inputWidth,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return <double>[
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );
      final outputTensor = List.generate(
        1,
        (_) => List<double>.filled(outputClasses, 0.0),
      );

      _interpreter!.run(inputTensor, outputTensor);

      var maxProbability = double.negativeInfinity;
      var maxIndex = -1;
      for (var index = 0; index < outputTensor[0].length; index++) {
        final probability = outputTensor[0][index];
        if (probability > maxProbability) {
          maxProbability = probability;
          maxIndex = index;
        }
      }

      return 'Watcher classification ID: $maxIndex; confidence: '
          '${maxProbability.toStringAsFixed(4)}'; label-map: unavailable';
    } catch (error) {
      throw ModelExecutionException(
        capability: 'canvas.watcher',
        message: 'Watcher inference failed.',
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
