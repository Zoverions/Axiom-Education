import 'model_errors.dart';

export 'handwriting_scorer.dart';
export 'model_errors.dart';
export 'watcher_model.dart';

/// Minimal lifecycle seam for an explicitly injected local tutor session.
///
/// This interface carries cleanup behavior only. It does not activate a model,
/// grant inference authority, or select a native runtime.
abstract interface class LocalTutorSession {
  void release();
}

/// Legacy Phi-3 binding retained only as an explicit unavailable adapter.
///
/// The previous implementation treated UTF-16 code units as model tokens and
/// returned a simulated logits message. That behavior has been removed. A
/// complete tutor requires a versioned tokenizer, autoregressive decoder,
/// generation limits, model artifact digest, and AXIOM provider contract.
class Phi3MiniModel {
  static const String modelAssetPath =
      'assets/models/phi3-mini-4k-instruct-q4.onnx';
  static const int maxModelAssetBytes = 8 * 1024 * 1024 * 1024;

  LocalTutorSession? _session;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initModel({
    Future<LocalTutorSession> Function()? testSessionLoader,
  }) async {
    if (_isInitialized) return;

    if (testSessionLoader == null) {
      throw const ModelUnavailableException(
        capability: 'tutor.local-inference',
        message:
            'Local tutor initialization is disabled until an approved AXIOM '
            'provider supplies a versioned tokenizer, bounded decoder, model '
            'digest, and compatible runtime adapter.',
      );
    }

    try {
      _session = await testSessionLoader();
      _isInitialized = true;
    } catch (error) {
      _session?.release();
      _session = null;
      _isInitialized = false;
      throw ModelUnavailableException(
        capability: 'tutor.local-inference',
        message: 'The injected local tutor session could not be initialized.',
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
      message:
          'Local tutor decoding is disabled until a versioned tokenizer, '
          'bounded autoregressive decoder, and AXIOM provider contract exist.',
    );
  }

  void dispose() {
    _session?.release();
    _session = null;
    _isInitialized = false;
  }
}
