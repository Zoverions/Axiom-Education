/// Raised when a model-backed capability has no configured, initialized, or
/// policy-approved provider.
class ModelUnavailableException implements Exception {
  final String capability;
  final String message;
  final Object? cause;

  const ModelUnavailableException({
    required this.capability,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'ModelUnavailableException($capability): $message';
}

/// Raised when an initialized model provider fails while processing a bounded
/// request. Callers must surface failure rather than substitute mock output.
class ModelExecutionException implements Exception {
  final String capability;
  final String message;
  final Object? cause;

  const ModelExecutionException({
    required this.capability,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'ModelExecutionException($capability): $message';
}
