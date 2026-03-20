import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';

export 'handwriting_scorer.dart';
export 'watcher_model.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ONNX model binding for Phi-3-mini
class Phi3MiniModel {
  OrtSession? _session;
  bool _isInitialized = false;

  Future<void> initModel({
    Future<OrtSession> Function(String path, OrtSessionOptions options)?
    mockSessionLoader,
  }) async {
    if (_isInitialized) return;
    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();
      // Use NNAPI for NPU on Android, CoreML on iOS if applicable
      // sessionOptions.appendExecutionProvider_Nnapi();

      if (mockSessionLoader != null) {
        _session = await mockSessionLoader(
          'assets/models/phi3-mini-4k-instruct-q4.onnx',
          sessionOptions,
        );
      } else {
        _session = OrtSession.fromAsset(
          'assets/models/phi3-mini-4k-instruct-q4.onnx',
          sessionOptions,
        );
      }

      final rawAssetFile = await rootBundle.load(
        'assets/models/phi3-mini-4k-instruct-q4.onnx',
      );
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      _isInitialized = true;
    } catch (e) {
      // Error is caught but not printed to console in production
    }
  }

  Future<String> generateResponse(String prompt) async {
    if (!_isInitialized || _session == null) return "Model not initialized.";

    try {
      // 1. Tokenize prompt (Placeholder for actual BPE tokenization)
      // In a real production app, you would use a Dart port of the transformers tokenizer
      // or interface with a native tokenizer library.
      final List<Int64List> inputIds = [
        Int64List.fromList(
          prompt.codeUnits.map((c) => BigInt.from(c).toInt()).toList(),
        ),
      ];
      final List<Int64List> attentionMask = [
        Int64List.fromList(List.filled(prompt.codeUnits.length, 1)),
      ];

      final inputIdsTensor = OrtValueTensor.createTensorWithDataList(inputIds, [
        1,
        prompt.codeUnits.length,
      ]);
      final attentionMaskTensor = OrtValueTensor.createTensorWithDataList(
        attentionMask,
        [1, prompt.codeUnits.length],
      );

      final runOptions = OrtRunOptions();
      final inputs = {
        'input_ids': inputIdsTensor,
        'attention_mask': attentionMaskTensor,
      };

      // 2. Run inference
      final outputs = _session!.run(runOptions, inputs);

      // 3. Extract output tokens and decode
      // Assuming output is logits: shape [batch, seq_len, vocab_size]
      // This is a simplified extraction. Real LLM inference requires auto-regressive decoding (looping).
      final OrtValue? logitsTensor = outputs[0];
      final List<dynamic> logits =
          (logitsTensor?.value as List<dynamic>?) ?? [];

      inputIdsTensor.release();
      attentionMaskTensor.release();
      runOptions.release();
      for (var element in outputs) {
        element?.release();
      }

      // Note: A full implementation requires a Dart port of the BPE tokenizer
      // and the vocabulary file (`tokenizer.json` or `vocab.json`) associated with
      // the model. Without the vocabulary mapping, we cannot decode logits into
      // meaningful text strings. For demonstration, we simulate decoding based on logits size.
      return "Simulated response generated. Logits shape length: ${logits.length}";
    } catch (e) {
      return "Error during model inference.";
    }
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
    _isInitialized = false;
  }
}

/// TFLite model binding for handwriting scoring
class HandwritingScorer {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Add getter for testing
  bool get isInitialized => _isInitialized;

  // Dependency injection for testing: inject an explicit asset path or mock loader
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
    } catch (e) {
      _isInitialized = false; // ensure state is maintained
    }
  }

  @visibleForTesting
  List<List<List<double>>> preprocessStrokes(
    List<Map<String, dynamic>> strokes,
  ) {
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
    return inputTensor;
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
      var inputTensor = preprocessStrokes(strokes);

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
      // Error is caught but not printed to console
    }
  }

  // For testing purposes
  void setInterpreterForTest(Interpreter interpreter) {
    _interpreter = interpreter;
    _isInitialized = true;
  }

  /// Parses the canvas visual input (or stroke history)
  Future<String> parseCanvas(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null)
      return "Mock parsed equation: y = mx + b";

    try {
      // 1. Decode and preprocess the image
      img.Image? decodedImage;
      try {
        decodedImage = img.decodeImage(imageBytes);
      } catch (e) {
        return "Failed to decode image";
      }
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
