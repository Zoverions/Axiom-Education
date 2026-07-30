import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';

import 'model_errors.dart';

export 'handwriting_scorer.dart';
export 'model_errors.dart';
export 'watcher_model.dart';

/// Legacy Phi-3 ONNX binding retained only as an explicit unavailable adapter.
///
/// The previous implementation treated UTF-16 code units as model tokens and
/// returned a simulated logits message. That behavior has been removed. A
/// complete tutor requires a versioned tokenizer, autoregressive decoder,
/// generation limits, model artifact digest, and AXIOM provider contract.
class Phi3MiniModel {
  static const String modelAssetPath =
      'assets/models/phi3-mini-4k-instruct-q4.onnx';
  static const int maxModelAssetBytes = 8 * 1024 * 1024 * 1024;

  OrtSession? _session;
  bool _isInitialized = false;
  bool _environmentInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initModel({
    Future<OrtSession> Function(String path, OrtSessionOptions options)?
        mockSessionLoader,
  }) async {
    if (_isInitialized) return;

    final sessionOptions = OrtSessionOptions();
    try {
      OrtEnv.instance.init();
      _environmentInitialized = true;

      if (mockSessionLoader != null) {
        _session = await mockSessionLoader(modelAssetPath, sessionOptions);
      } else {
        final asset = await rootBundle.load(modelAssetPath);
        if (asset.lengthInBytes > maxModelAssetBytes) {
          throw const FormatException('Local tutor model artifact is too large.');
        }
        _session = OrtSession.fromBuffer(
          asset.buffer.asUint8List(
            asset.offsetInBytes,
            asset.lengthInBytes,
          ),
          sessionOptions,
        );
      }
      _isInitialized = true;
    } catch (error) {
      _session?.release();
      _session = null;
      _isInitialized = false;
      if (_environmentInitialized) {
        OrtEnv.instance.release();
        _environmentInitialized = false;
      }
      throw ModelUnavailableException(
        capability: 'tutor.local-inference',
        message: 'The Phi-3 ONNX artifact could not be initialized.',
        cause: error,
      );
    }
  }

  /// Always fails closed until a complete tokenizer and bounded
  /// autoregressive decoder are supplied by an approved tutor provider.
  Future<String> generateResponse(String prompt) async {
    if (prompt.trim().isEmpty) {
      throw const FormatException('Tutor prompt must not be empty.');
    }
    if (!_isInitialized || _session == null) {
      throw const ModelUnavailableException(
        capability: 'tutor.local-inference',
        message: 'The local tutor model is not initialized.',
      );
    }

    throw const ModelUnavailableException(
      capability: 'tutor.local-inference',
      message: 'Local tutor decoding is disabled until a versioned tokenizer, '
          'bounded autoregressive decoder, and AXIOM provider contract exist.',
    );
  }

  void dispose() {
    _session?.release();
    _session = null;
    _isInitialized = false;
    if (_environmentInitialized) {
      OrtEnv.instance.release();
      _environmentInitialized = false;
    }
  }
}
