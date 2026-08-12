import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'education_client.dart';
import 'educator_workflow_runtime.dart';

/// Stores raw education content through AXIOM core `memory.put` before a
/// workflow event records only its content-addressed memory reference.
///
/// This client deliberately does not use [AxiomEducationClient]: `memory.put`
/// is a core AXIOM action and must not receive education-domain contract fields.
class GovernedEducationMemoryWriter {
  static const memoryAction = 'memory.put';
  static const metadataSchema = 'axiom-education-governed-memory-ref.v1';

  /// Exact runtime projections pinned by
  /// `contracts/axiom-education-learner-memory.v1.json`.
  static const Map<String, String> eventTypeToMemoryKind = {
    'assignment.created': 'education.assignment-artifact',
    'submission.created': 'education.learner-submission',
    'submission.resubmitted': 'education.learner-submission',
    'feedback.recorded': 'education.educator-feedback',
    'revision.requested': 'education.educator-feedback',
    'appeal.filed': 'education.appeal-reason',
    'correction.recorded': 'education.correction-evidence',
  };

  /// `actor` means the authenticated AXIOM principal creating the content;
  /// `subject` means the learner identified by the workflow event.
  ///
  /// The app exposes this binding for parity/planning only. AXIOM-MESH remains
  /// authoritative for verifying the actual authenticated principal and memory
  /// owner at learner-record admission time.
  static const Map<String, String> eventTypeToMemoryOwner = {
    'assignment.created': 'actor',
    'submission.created': 'subject',
    'submission.resubmitted': 'subject',
    'feedback.recorded': 'actor',
    'revision.requested': 'actor',
    'appeal.filed': 'subject',
    'correction.recorded': 'actor',
  };

  static final RegExp _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');
  static final RegExp _memoryObjectPattern = RegExp(r'^memory_[a-f0-9]{64}$');

  final AxiomIntentTransport transport;

  const GovernedEducationMemoryWriter({required this.transport});

  Future<GovernedEducationMemoryReceipt> storeForEvent({
    required EducatorWorkflowEvent event,
    required Map<String, Object?> content,
  }) async {
    event.validate();
    final kind = eventTypeToMemoryKind[event.eventType];
    if (kind == null) {
      throw GovernedEducationMemoryValidationException(
        'Event type ${event.eventType} does not create new governed content. '
        'Reuse an existing governed memory reference instead.',
      );
    }
    if (content.isEmpty) {
      throw const GovernedEducationMemoryValidationException(
        'Governed memory content must not be empty.',
      );
    }

    final normalizedContent = _canonicalizeMap(content);
    final metadata = <String, Object?>{
      'schema': metadataSchema,
      'workflow_id': event.workflowId,
      'assignment_id': event.assignmentId,
      'event_id': event.eventId,
      'event_type': event.eventType,
      'workflow_payload_digest': event.payloadDigest,
    };
    final requestInput = <String, Object?>{
      'kind': kind,
      'content': normalizedContent,
      'metadata': metadata,
    };
    final requestDigest = _canonicalDigest(requestInput);
    final idempotencyKey = 'education-memory:$requestDigest';

    final AxiomTransportResponse response;
    try {
      response = await transport.postIntent(
        action: memoryAction,
        input: Map<String, Object?>.unmodifiable(requestInput),
        idempotencyKey: idempotencyKey,
      );
    } catch (error) {
      throw GovernedEducationMemoryTransportException(
        'AXIOM governed memory transport failed.',
        cause: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _gatewayFailure(response);
    }
    final body = response.body;
    if (body.containsKey('error')) {
      throw const GovernedEducationMemoryProtocolException(
        'Successful governed memory response must not contain an error.',
      );
    }

    final objectId = body['object_id'];
    final contentDigest = body['content_digest'];
    if (objectId is! String || !_memoryObjectPattern.hasMatch(objectId)) {
      throw const GovernedEducationMemoryProtocolException(
        'Governed memory response object_id is invalid.',
      );
    }
    if (contentDigest is! String || !_sha256Pattern.hasMatch(contentDigest)) {
      throw const GovernedEducationMemoryProtocolException(
        'Governed memory response content_digest is invalid.',
      );
    }
    if (objectId != 'memory_$contentDigest') {
      throw const GovernedEducationMemoryProtocolException(
        'Governed memory object_id does not match content_digest.',
      );
    }
    if (body['status'] != 'completed') {
      throw const GovernedEducationMemoryProtocolException(
        'Governed memory intent must complete before its reference is usable.',
      );
    }
    final intentId = body['intent_id'];
    final traceId = body['trace_id'];
    final evidence = body['evidence'];
    if (intentId is! String ||
        intentId.isEmpty ||
        traceId is! String ||
        traceId.isEmpty ||
        evidence is! Map) {
      throw const GovernedEducationMemoryProtocolException(
        'Governed memory response is missing intent evidence.',
      );
    }

    return GovernedEducationMemoryReceipt(
      objectId: objectId,
      contentDigest: contentDigest,
      kind: kind,
      requestDigest: requestDigest,
      workflowPayloadDigest: event.payloadDigest,
      intentId: intentId,
      traceId: traceId,
      evidence: Map<String, Object?>.unmodifiable(
        Map<String, Object?>.from(evidence),
      ),
    );
  }

  static GovernedEducationMemoryGatewayException _gatewayFailure(
    AxiomTransportResponse response,
  ) {
    final errorValue = response.body['error'];
    final error = errorValue is Map
        ? Map<String, Object?>.from(errorValue)
        : const <String, Object?>{};
    final code = error['code'] is String
        ? error['code']! as String
        : 'gateway_request_failed';
    return GovernedEducationMemoryGatewayException(
      statusCode: response.statusCode,
      code: code,
      message: error['message'] is String
          ? error['message']! as String
          : 'AXIOM Gateway rejected governed memory storage.',
    );
  }

  static Map<String, Object?> _canonicalizeMap(Map<String, Object?> value) {
    final normalized = _canonicalize(value);
    return Map<String, Object?>.unmodifiable(
      Map<String, Object?>.from(normalized! as Map),
    );
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final sorted = SplayTreeMap<String, Object?>();
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw const GovernedEducationMemoryValidationException(
            'Governed memory JSON only permits string map keys.',
          );
        }
        sorted[entry.key as String] = _canonicalize(entry.value);
      }
      return sorted;
    }
    if (value is List) {
      return value.map(_canonicalize).toList(growable: false);
    }
    if (value == null || value is String || value is bool) return value;
    if (value is num && value.isFinite) return value;
    throw GovernedEducationMemoryValidationException(
      'Unsupported governed memory JSON type: ${value.runtimeType}.',
    );
  }

  static String _canonicalDigest(Object? value) {
    final normalized = _canonicalize(value);
    return sha256.convert(utf8.encode(jsonEncode(normalized))).toString();
  }
}

class GovernedEducationMemoryReceipt {
  final String objectId;
  final String contentDigest;
  final String kind;
  final String requestDigest;
  final String workflowPayloadDigest;
  final String intentId;
  final String traceId;
  final Map<String, Object?> evidence;

  const GovernedEducationMemoryReceipt({
    required this.objectId,
    required this.contentDigest,
    required this.kind,
    required this.requestDigest,
    required this.workflowPayloadDigest,
    required this.intentId,
    required this.traceId,
    required this.evidence,
  });
}

sealed class GovernedEducationMemoryException implements Exception {
  final String message;
  final Object? cause;

  const GovernedEducationMemoryException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message';
}

class GovernedEducationMemoryValidationException
    extends GovernedEducationMemoryException {
  const GovernedEducationMemoryValidationException(super.message);
}

class GovernedEducationMemoryTransportException
    extends GovernedEducationMemoryException {
  const GovernedEducationMemoryTransportException(super.message, {super.cause});
}

class GovernedEducationMemoryProtocolException
    extends GovernedEducationMemoryException {
  const GovernedEducationMemoryProtocolException(super.message);
}

class GovernedEducationMemoryGatewayException
    extends GovernedEducationMemoryException {
  final int statusCode;
  final String code;

  const GovernedEducationMemoryGatewayException({
    required this.statusCode,
    required this.code,
    required String message,
  }) : super(message);
}
