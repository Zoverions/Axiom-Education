import 'dart:async';

import 'education_contract.dart';

abstract interface class AxiomIntentTransport {
  Future<AxiomTransportResponse> postIntent({
    required String action,
    required Map<String, Object?> input,
    required String idempotencyKey,
  });
}

class AxiomTransportResponse {
  final int statusCode;
  final Map<String, Object?> body;

  const AxiomTransportResponse({required this.statusCode, required this.body});
}

class AxiomEducationClient {
  static final RegExp _idempotencyPattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$',
  );
  static final RegExp _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

  final AxiomIntentTransport transport;
  final String Function() idempotencyKeyFactory;

  AxiomEducationClient({
    required this.transport,
    required this.idempotencyKeyFactory,
  });

  Future<Map<String, Object?>> submit({
    required String action,
    required Map<String, Object?> input,
    String? idempotencyKey,
  }) async {
    final definition = AxiomEducationContract.actions[action];
    if (definition == null) {
      throw AxiomEducationValidationException(
        message: 'Unsupported education action: $action',
      );
    }

    final key = idempotencyKey ?? idempotencyKeyFactory();
    if (!_idempotencyPattern.hasMatch(key)) {
      throw const AxiomEducationValidationException(
        message: 'Idempotency key must be 8-128 safe ASCII characters.',
      );
    }

    for (final protectedField in const {
      'contract_id',
      'contract_version',
      'contract_sha256',
    }) {
      if (input.containsKey(protectedField)) {
        throw AxiomEducationValidationException(
          message: '$protectedField is controlled by the client contract pin.',
        );
      }
    }

    final contractInput = <String, Object?>{
      'contract_id': AxiomEducationContract.id,
      'contract_version': AxiomEducationContract.version,
      'contract_sha256': AxiomEducationContract.sha256,
      ...input,
    };
    _validateInput(action, definition, contractInput);

    final AxiomTransportResponse response;
    try {
      response = await transport.postIntent(
        action: action,
        input: Map.unmodifiable(contractInput),
        idempotencyKey: key,
      );
    } on AxiomEducationException {
      rethrow;
    } catch (error) {
      throw AxiomEducationTransportException(
        message: 'AXIOM Gateway transport failed.',
        cause: error,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.containsKey('error')) {
        throw const AxiomEducationProtocolException(
          message:
              'Successful AXIOM response must not contain an error object.',
        );
      }
      return Map.unmodifiable(response.body);
    }

    throw _mapGatewayError(response);
  }

  void _validateInput(
    String action,
    AxiomEducationActionDefinition definition,
    Map<String, Object?> input,
  ) {
    for (final field in input.keys) {
      if (!definition.allowedInput.contains(field)) {
        throw AxiomEducationValidationException(
          message: '$action input contains unsupported field: $field',
        );
      }
    }
    for (final field in definition.requiredInput) {
      if (!input.containsKey(field) || input[field] == null) {
        throw AxiomEducationValidationException(
          message: '$action input is missing required field: $field',
        );
      }
    }

    for (final entry in input.entries) {
      final field = entry.key;
      final value = entry.value;
      if (field.endsWith('_sha256') || field == 'payload_digest') {
        if (value is! String || !_sha256Pattern.hasMatch(value)) {
          throw AxiomEducationValidationException(
            message: '$field must be a lowercase SHA-256 digest.',
          );
        }
      }
    }

    if (definition.requiresConsent) {
      final expectedPurpose = definition.consentPurpose;
      if (input['purpose'] != expectedPurpose) {
        throw AxiomEducationValidationException(
          message: '$action purpose must be $expectedPurpose.',
        );
      }
      for (final field in const ['subject_id', 'consent_id']) {
        final value = input[field];
        if (value is! String || value.trim().isEmpty || value.length > 256) {
          throw AxiomEducationValidationException(
            message: '$action $field is invalid.',
          );
        }
      }
    }

    final limit = input['limit'];
    if (limit != null && (limit is! int || limit < 1 || limit > 50)) {
      throw const AxiomEducationValidationException(
        message: 'Curriculum query limit must be between 1 and 50.',
      );
    }
    final maxOutputTokens = input['max_output_tokens'];
    if (maxOutputTokens != null &&
        (maxOutputTokens is! int ||
            maxOutputTokens < 1 ||
            maxOutputTokens > 2048)) {
      throw const AxiomEducationValidationException(
        message: 'Tutor max_output_tokens must be between 1 and 2048.',
      );
    }
    final deadlineMs = input['deadline_ms'];
    if (deadlineMs != null &&
        (deadlineMs is! int || deadlineMs < 100 || deadlineMs > 120000)) {
      throw const AxiomEducationValidationException(
        message: 'Tutor deadline_ms must be between 100 and 120000.',
      );
    }
    final prompt = input['prompt'];
    if (prompt != null &&
        (prompt is! String || prompt.trim().isEmpty || prompt.length > 16000)) {
      throw const AxiomEducationValidationException(
        message: 'Tutor prompt must contain 1-16000 characters.',
      );
    }
  }

  AxiomEducationException _mapGatewayError(AxiomTransportResponse response) {
    final errorValue = response.body['error'];
    final error = errorValue is Map
        ? Map<String, Object?>.from(errorValue)
        : const <String, Object?>{};
    final code = error['code'] is String
        ? error['code']! as String
        : 'gateway_request_failed';
    final message = error['message'] is String
        ? error['message']! as String
        : 'AXIOM Gateway rejected the education intent.';
    final details = error['details'] is Map
        ? Map<String, Object?>.from(error['details']! as Map)
        : const <String, Object?>{};

    if (response.statusCode == 503 || code == 'capability_unavailable') {
      return AxiomEducationCapabilityUnavailableException(
        statusCode: response.statusCode,
        code: code,
        message: message,
        details: details,
      );
    }
    if (response.statusCode == 403 || code == 'policy_denied') {
      return AxiomEducationPolicyDeniedException(
        statusCode: response.statusCode,
        code: code,
        message: message,
        details: details,
      );
    }
    if (response.statusCode == 409 &&
        (code == 'confirmation_required' ||
            code == 'independent_approval_required')) {
      return AxiomEducationApprovalRequiredException(
        statusCode: response.statusCode,
        code: code,
        message: message,
        details: details,
      );
    }
    return AxiomEducationUnexpectedGatewayException(
      statusCode: response.statusCode,
      code: code,
      message: message,
      details: details,
    );
  }
}

sealed class AxiomEducationException implements Exception {
  final String message;
  final Object? cause;

  const AxiomEducationException({required this.message, this.cause});

  @override
  String toString() => '$runtimeType: $message';
}

class AxiomEducationValidationException extends AxiomEducationException {
  const AxiomEducationValidationException({required super.message});
}

class AxiomEducationTransportException extends AxiomEducationException {
  const AxiomEducationTransportException({required super.message, super.cause});
}

class AxiomEducationProtocolException extends AxiomEducationException {
  const AxiomEducationProtocolException({required super.message});
}

sealed class AxiomEducationGatewayException extends AxiomEducationException {
  final int statusCode;
  final String code;
  final Map<String, Object?> details;

  const AxiomEducationGatewayException({
    required this.statusCode,
    required this.code,
    required super.message,
    this.details = const {},
  });
}

class AxiomEducationUnexpectedGatewayException
    extends AxiomEducationGatewayException {
  const AxiomEducationUnexpectedGatewayException({
    required super.statusCode,
    required super.code,
    required super.message,
    super.details,
  });
}

class AxiomEducationCapabilityUnavailableException
    extends AxiomEducationGatewayException {
  const AxiomEducationCapabilityUnavailableException({
    required super.statusCode,
    required super.code,
    required super.message,
    super.details,
  });
}

class AxiomEducationPolicyDeniedException
    extends AxiomEducationGatewayException {
  const AxiomEducationPolicyDeniedException({
    required super.statusCode,
    required super.code,
    required super.message,
    super.details,
  });
}

class AxiomEducationApprovalRequiredException
    extends AxiomEducationGatewayException {
  const AxiomEducationApprovalRequiredException({
    required super.statusCode,
    required super.code,
    required super.message,
    super.details,
  });
}
