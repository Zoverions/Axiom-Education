import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// TFLite vision model for canvas observation ("The Watcher")
class WatcherModel {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initModel() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/watcher_vision.tflite',
        options: options,
      );
      _isInitialized = true;
    } catch (e) {
      // Error is caught but not printed
    }
  }

  /// Parses the canvas visual input (or stroke history)
  Future<String> parseCanvas(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null)
      return "Mock parsed equation: y = mx + b";

    // Security Fix: Limit image size to prevent unbounded memory allocation
    const int maxImageSize = 10 * 1024 * 1024; // 10MB
    if (imageBytes.length > maxImageSize) return "Image size too large";

    try {
      // 1. Decode and preprocess the image
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return "Failed to decode image";

      // Resize to model's expected input size, e.g., 224x224
      img.Image resizedImage = img.copyResize(
        decodedImage,
        width: 224,
        height: 224,
      );

      // Convert to a 4D tensor: [1, 224, 224, 3] float32 array
      var inputTensor = List.generate(
        1,
        (_) => List.generate(
          224,
          (_) => List.generate(224, (_) => List.filled(3, 0.0)),
        ),
      );
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          img.Pixel pixel = resizedImage.getPixel(x, y);
          inputTensor[0][y][x][0] = pixel.r / 255.0; // Normalize
          inputTensor[0][y][x][1] = pixel.g / 255.0;
          inputTensor[0][y][x][2] = pixel.b / 255.0;
        }
      }

      // 2. Output tensor (e.g., classification probabilities or feature vector)
      // Assuming output shape [1, 1000]
      var outputTensor = List.generate(1, (_) => List.filled(1000, 0.0));

      // 3. Run inference
      _interpreter!.run(inputTensor, outputTensor);

      // 4. Post-process: Find the argmax (index with highest probability)
      // This assumes the output is a 1D vector of probabilities from a Softmax layer.
      double maxProb = 0.0;
      int maxIdx = -1;
      final int numClasses = outputTensor[0].length;

      for (int i = 0; i < numClasses; i++) {
        if (outputTensor[0][i] > maxProb) {
          maxProb = outputTensor[0][i];
          maxIdx = i;
        }
      }

      // In a real scenario, maxIdx would be mapped to a label map (e.g. {0: '+', 1: '-', ...})
      return "Parsed symbol ID: $maxIdx with probability ${maxProb.toStringAsFixed(2)}";
    } catch (e) {
      return "Error parsing canvas image.";
    }
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
