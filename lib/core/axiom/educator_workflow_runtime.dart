import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'education_client.dart';
import 'education_contract.dart';

/// Runtime representation of the bounded educator/learner workflow contract.
///
/// This layer validates workflow semantics and projects an exact event into the
/// pinned `axiom.education` learner-event action. It deliberately contains no
/// local persistence API. A valid local chain is not proof of actor authority,
/// learner mastery, a grade, credit, transcript status, or remote persistence.
abstract final class EducatorWorkflowRuntime {
  static const eventSchema = 'axiom-education-educator-workflow-event.v1';
  static const purpose = 'learning-progress-recording';

  static const Map<String, EducatorWorkflowEventSpec> eventSpecs = {
    'assignment.created': EducatorWorkflowEventSpec(
      actors: {'educator'},
      from: {null},
      to: 'assigned',
      requiredDigests: {'artifact_digest'},
    ),
    'submission.created': EducatorWorkflowEventSpec(
      actors: {'learner'},
      from: {'assigned'},
      to: 'submitted',
      requiredDigests: {'artifact_digest'},
    ),
    'review.started': EducatorWorkflowEventSpec(
      actors: {'educator'},
      from: {'submitted'},
      to: 'under-review',
      requiredDigests: {'artifact_digest'},
    ),
    'feedback.recorded': EducatorWorkflowEventSpec(
      actors: {'educator'},
      from: {'under-review'},
      to: 'feedback-available',
      requiredDigests: {'artifact_digest', 'feedback_digest'},
    ),
    'revision.requested': EducatorWorkflowEventSpec(
      actors: {'educator'},
      from: {'feedback-available'},
      to: 'revision-requested',
      requiredDigests: {'artifact_digest', 'feedback_digest'},
    ),
    'submission.resubmitted': EducatorWorkflowEventSpec(
      actors: {'learner'},
      from: {'revision-requested'},
      to: 'submitted',
      requiredDigests: {'artifact_digest'},
    ),
    'review.finalized': EducatorWorkflowEventSpec(
      actors: {'educator'},
      from: {'under-review', 'feedback-available', 'corrected'},
      to: 'finalized',
      requiredDigests: {'artifact_digest'},
    ),
    'appeal.filed': EducatorWorkflowEventSpec(
      actors: {'learner', 'authorized-representative'},
      from: {'feedback-available', 'finalized'},
      to: 'appealed',
      requiredDigests: {'artifact_digest', 'reason_digest'},
    ),
    'appeal.review.started': EducatorWorkflowEventSpec(
      actors: {'educator'},
      from: {'appealed'},
      to: 'under-review',
      requiredDigests: {'artifact_digest'},
    ),
    'correction.recorded': EducatorWorkflowEventSpec(
      actors: {'educator'},
      from: {'under-review', 'feedback-available'},
      to: 'corrected',
      requiredDigests: {'artifact_digest', 'feedback_digest'},
    ),
  };

  static String canonicalDigest(Object? value) {
    final normalized = _canonicalize(value);
    return sha256.convert(utf8.encode(jsonEncode(normalized))).toString();
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final sorted = SplayTreeMap<String, Object?>();
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw const EducatorWorkflowValidationException(
            'Canonical workflow JSON only permits string map keys.',
          );
        }
        sorted[entry.key as String] = _canonicalize(entry.value);
      }
      return sorted;
    }
    if (value is List) {
      return value.map(_canonicalize).toList(growable: false);
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw EducatorWorkflowValidationException(
      'Unsupported canonical workflow JSON type: ${value.runtimeType}.',
    );
  }

  static EducatorWorkflowChainResult verifyWorkflow(
    List<EducatorWorkflowEvent> events,
  ) {
    if (events.isEmpty) {
      throw const EducatorWorkflowValidationException(
        'Workflow must contain at least one event.',
      );
    }

    String? currentState;
    String? currentArtifactDigest;
    EducatorWorkflowEvent? previous;
    DateTime? previousTime;
    final eventIds = <String>{};
    _WorkflowInvariant? invariant;

    for (final event in events) {
      event.validate();
      if (!eventIds.add(event.eventId)) {
        throw EducatorWorkflowValidationException(
          'Duplicate workflow event_id: ${event.eventId}.',
        );
      }

      final nextInvariant = _WorkflowInvariant.fromEvent(event);
      invariant ??= nextInvariant;
      if (invariant != nextInvariant) {
        throw const EducatorWorkflowValidationException(
          'Workflow identity/context changed mid-chain.',
        );
      }

      final occurredAt = _parseTimestamp(event.occurredAt);
      if (previousTime != null && occurredAt.isBefore(previousTime)) {
        throw const EducatorWorkflowValidationException(
          'Workflow timestamps must be monotonic.',
        );
      }
      previousTime = occurredAt;

      final spec = eventSpecs[event.eventType]!;
      if (!spec.from.contains(currentState)) {
        throw EducatorWorkflowValidationException(
          'Invalid transition from ${currentState ?? 'null'} via '
          '${event.eventType}.',
        );
      }

      if (previous == null) {
        if (event.previousEventDigest != null) {
          throw const EducatorWorkflowValidationException(
            'First workflow event must not name a previous digest.',
          );
        }
      } else if (event.previousEventDigest != previous.payloadDigest) {
        throw const EducatorWorkflowValidationException(
          'previous_event_digest does not match prior event.',
        );
      }

      if (event.eventType == 'submission.created' ||
          event.eventType == 'submission.resubmitted') {
        currentArtifactDigest = event.artifactDigest;
      } else if (event.eventType != 'assignment.created' &&
          event.artifactDigest != null &&
          currentArtifactDigest != null &&
          event.artifactDigest != currentArtifactDigest) {
        throw const EducatorWorkflowValidationException(
          'Review event artifact digest does not match latest submission.',
        );
      }

      currentState = spec.to;
      previous = event;
    }

    return EducatorWorkflowChainResult(
      eventCount: events.length,
      finalState: currentState!,
      finalEventDigest: previous!.payloadDigest,
      workflowId: invariant!.workflowId,
    );
  }

  static DateTime _parseTimestamp(String value) {
    final hasZone = RegExp(r'(?:Z|[+-]\d{2}:\d{2})$').hasMatch(value);
    final parsed = DateTime.tryParse(value);
    if (!hasZone || parsed == null) {
      throw const EducatorWorkflowValidationException(
        'occurred_at must be an ISO-8601 timestamp with a timezone.',
      );
    }
    return parsed;
  }
}

class EducatorWorkflowEventSpec {
  final Set<String> actors;
  final Set<String?> from;
  final String to;
  final Set<String> requiredDigests;

  const EducatorWorkflowEventSpec({
    required this.actors,
    required this.from,
    required this.to,
    required this.requiredDigests,
  });
}

class EducatorWorkflowEvent {
  static final RegExp _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

  final String schema;
  final String workflowId;
  final String assignmentId;
  final String subjectId;
  final String learningContextId;
  final String? courseCode;
  final List<String> expectationIds;
  final String eventId;
  final String eventType;
  final String actorRole;
  final String occurredAt;
  final String? previousEventDigest;
  final String? artifactDigest;
  final String? feedbackDigest;
  final String? reasonDigest;
  final String reviewState;
  final String payloadDigest;

  const EducatorWorkflowEvent._({
    required this.schema,
    required this.workflowId,
    required this.assignmentId,
    required this.subjectId,
    required this.learningContextId,
    required this.courseCode,
    required this.expectationIds,
    required this.eventId,
    required this.eventType,
    required this.actorRole,
    required this.occurredAt,
    required this.previousEventDigest,
    required this.artifactDigest,
    required this.feedbackDigest,
    required this.reasonDigest,
    required this.reviewState,
    required this.payloadDigest,
  });

  factory EducatorWorkflowEvent.create({
    required String workflowId,
    required String assignmentId,
    required String subjectId,
    required String learningContextId,
    required String? courseCode,
    required List<String> expectationIds,
    required String eventId,
    required String eventType,
    required String actorRole,
    required String occurredAt,
    String? previousEventDigest,
    String? artifactDigest,
    String? feedbackDigest,
    String? reasonDigest,
  }) {
    final spec = EducatorWorkflowRuntime.eventSpecs[eventType];
    if (spec == null) {
      throw EducatorWorkflowValidationException(
        'Unsupported event_type: $eventType.',
      );
    }
    final data = <String, Object?>{
      'schema': EducatorWorkflowRuntime.eventSchema,
      'workflow_id': workflowId,
      'assignment_id': assignmentId,
      'subject_id': subjectId,
      'learning_context_id': learningContextId,
      'course_code': courseCode,
      'expectation_ids': List<String>.unmodifiable(expectationIds),
      'event_id': eventId,
      'event_type': eventType,
      'actor_role': actorRole,
      'occurred_at': occurredAt,
      'previous_event_digest': previousEventDigest,
      'artifact_digest': artifactDigest,
      'feedback_digest': feedbackDigest,
      'reason_digest': reasonDigest,
      'review_state': spec.to,
    };
    final event = EducatorWorkflowEvent._(
      schema: EducatorWorkflowRuntime.eventSchema,
      workflowId: workflowId,
      assignmentId: assignmentId,
      subjectId: subjectId,
      learningContextId: learningContextId,
      courseCode: courseCode,
      expectationIds: List<String>.unmodifiable(expectationIds),
      eventId: eventId,
      eventType: eventType,
      actorRole: actorRole,
      occurredAt: occurredAt,
      previousEventDigest: previousEventDigest,
      artifactDigest: artifactDigest,
      feedbackDigest: feedbackDigest,
      reasonDigest: reasonDigest,
      reviewState: spec.to,
      payloadDigest: EducatorWorkflowRuntime.canonicalDigest(data),
    );
    event.validate();
    return event;
  }

  factory EducatorWorkflowEvent.fromMap(Map<String, Object?> value) {
    const exactFields = {
      'schema',
      'workflow_id',
      'assignment_id',
      'subject_id',
      'learning_context_id',
      'course_code',
      'expectation_ids',
      'event_id',
      'event_type',
      'actor_role',
      'occurred_at',
      'previous_event_digest',
      'artifact_digest',
      'feedback_digest',
      'reason_digest',
      'review_state',
      'payload_digest',
    };
    if (value.keys.toSet().difference(exactFields).isNotEmpty ||
        exactFields.difference(value.keys.toSet()).isNotEmpty) {
      throw const EducatorWorkflowValidationException(
        'Workflow event fields must match the bounded schema exactly.',
      );
    }

    final expectations = value['expectation_ids'];
    if (expectations is! List) {
      throw const EducatorWorkflowValidationException(
        'expectation_ids must be a list.',
      );
    }
    final event = EducatorWorkflowEvent._(
      schema: _requiredString(value, 'schema'),
      workflowId: _requiredString(value, 'workflow_id'),
      assignmentId: _requiredString(value, 'assignment_id'),
      subjectId: _requiredString(value, 'subject_id'),
      learningContextId: _requiredString(value, 'learning_context_id'),
      courseCode: _nullableString(value, 'course_code'),
      expectationIds: List<String>.unmodifiable(
        expectations.map((item) {
          if (item is! String) {
            throw const EducatorWorkflowValidationException(
              'expectation_ids must contain strings.',
            );
          }
          return item;
        }),
      ),
      eventId: _requiredString(value, 'event_id'),
      eventType: _requiredString(value, 'event_type'),
      actorRole: _requiredString(value, 'actor_role'),
      occurredAt: _requiredString(value, 'occurred_at'),
      previousEventDigest: _nullableString(value, 'previous_event_digest'),
      artifactDigest: _nullableString(value, 'artifact_digest'),
      feedbackDigest: _nullableString(value, 'feedback_digest'),
      reasonDigest: _nullableString(value, 'reason_digest'),
      reviewState: _requiredString(value, 'review_state'),
      payloadDigest: _requiredString(value, 'payload_digest'),
    );
    event.validate();
    return event;
  }

  void validate() {
    if (schema != EducatorWorkflowRuntime.eventSchema) {
      throw const EducatorWorkflowValidationException(
        'Unsupported workflow event schema.',
      );
    }
    for (final entry in {
      'workflow_id': workflowId,
      'assignment_id': assignmentId,
      'subject_id': subjectId,
      'learning_context_id': learningContextId,
      'event_id': eventId,
      'event_type': eventType,
      'actor_role': actorRole,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        throw EducatorWorkflowValidationException('${entry.key} is required.');
      }
    }

    if (expectationIds.any((id) => id.isEmpty) ||
        expectationIds.length != expectationIds.toSet().length) {
      throw const EducatorWorkflowValidationException(
        'expectation_ids must contain unique non-empty strings.',
      );
    }
    EducatorWorkflowRuntime._parseTimestamp(occurredAt);

    final spec = EducatorWorkflowRuntime.eventSpecs[eventType];
    if (spec == null) {
      throw EducatorWorkflowValidationException(
        'Unsupported event_type: $eventType.',
      );
    }
    if (!spec.actors.contains(actorRole)) {
      throw const EducatorWorkflowValidationException(
        'Actor role is not allowed for this event type.',
      );
    }
    if (reviewState != spec.to) {
      throw const EducatorWorkflowValidationException(
        'review_state does not match event transition.',
      );
    }

    final digests = <String, String?>{
      'artifact_digest': artifactDigest,
      'feedback_digest': feedbackDigest,
      'reason_digest': reasonDigest,
    };
    for (final entry in digests.entries) {
      final required = spec.requiredDigests.contains(entry.key);
      if (entry.value == null) {
        if (required) {
          throw EducatorWorkflowValidationException(
            '${entry.key} is required for this event type.',
          );
        }
      } else if (!_sha256Pattern.hasMatch(entry.value!)) {
        throw EducatorWorkflowValidationException(
          '${entry.key} must be SHA-256.',
        );
      }
    }
    if (previousEventDigest != null &&
        !_sha256Pattern.hasMatch(previousEventDigest!)) {
      throw const EducatorWorkflowValidationException(
        'previous_event_digest must be SHA-256.',
      );
    }
    if (!_sha256Pattern.hasMatch(payloadDigest)) {
      throw const EducatorWorkflowValidationException(
        'payload_digest must be SHA-256.',
      );
    }
    if (payloadDigest !=
        EducatorWorkflowRuntime.canonicalDigest(toMap(includePayload: false))) {
      throw const EducatorWorkflowValidationException(
        'Workflow payload digest mismatch.',
      );
    }
  }

  Map<String, Object?> toMap({bool includePayload = true}) {
    final value = <String, Object?>{
      'schema': schema,
      'workflow_id': workflowId,
      'assignment_id': assignmentId,
      'subject_id': subjectId,
      'learning_context_id': learningContextId,
      'course_code': courseCode,
      'expectation_ids': expectationIds,
      'event_id': eventId,
      'event_type': eventType,
      'actor_role': actorRole,
      'occurred_at': occurredAt,
      'previous_event_digest': previousEventDigest,
      'artifact_digest': artifactDigest,
      'feedback_digest': feedbackDigest,
      'reason_digest': reasonDigest,
      'review_state': reviewState,
    };
    if (includePayload) value['payload_digest'] = payloadDigest;
    return Map<String, Object?>.unmodifiable(value);
  }

  static String _requiredString(Map<String, Object?> value, String key) {
    final field = value[key];
    if (field is! String || field.trim().isEmpty) {
      throw EducatorWorkflowValidationException('$key is required.');
    }
    return field;
  }

  static String? _nullableString(Map<String, Object?> value, String key) {
    final field = value[key];
    if (field == null) return null;
    if (field is! String) {
      throw EducatorWorkflowValidationException('$key must be string or null.');
    }
    return field;
  }
}

class EducatorWorkflowChainResult {
  final int eventCount;
  final String finalState;
  final String finalEventDigest;
  final String workflowId;

  const EducatorWorkflowChainResult({
    required this.eventCount,
    required this.finalState,
    required this.finalEventDigest,
    required this.workflowId,
  });
}

class GovernedLearnerEventWriter {
  final AxiomEducationClient client;

  const GovernedLearnerEventWriter({required this.client});

  Future<GovernedLearnerEventReceipt> append({
    required List<EducatorWorkflowEvent> workflow,
    required String consentId,
    required String memoryObjectId,
  }) async {
    if (consentId.trim().isEmpty) {
      throw const EducatorWorkflowValidationException(
        'consent_id is required.',
      );
    }
    if (memoryObjectId.trim().isEmpty) {
      throw const EducatorWorkflowValidationException(
        'memory_object_id is required.',
      );
    }

    final chain = EducatorWorkflowRuntime.verifyWorkflow(workflow);
    final event = workflow.last;
    final input = <String, Object?>{
      'subject_id': event.subjectId,
      'consent_id': consentId,
      'purpose': EducatorWorkflowRuntime.purpose,
      'event_id': event.eventId,
      'event_type': event.eventType,
      'occurred_at': event.occurredAt,
      'payload_digest': event.payloadDigest,
      'memory_object_id': memoryObjectId,
      'expectation_ids': event.expectationIds,
      'review_state': event.reviewState,
    };
    if (event.courseCode != null) input['course_code'] = event.courseCode;

    final response = await client.submit(
      action: AxiomEducationContract.learnerEventAppend,
      input: input,
      idempotencyKey: 'education-workflow:${event.payloadDigest}',
    );

    return GovernedLearnerEventReceipt(
      workflowId: chain.workflowId,
      eventId: event.eventId,
      eventType: event.eventType,
      reviewState: event.reviewState,
      payloadDigest: event.payloadDigest,
      gatewayResponse: response,
    );
  }
}

class GovernedLearnerEventReceipt {
  final String workflowId;
  final String eventId;
  final String eventType;
  final String reviewState;
  final String payloadDigest;
  final Map<String, Object?> gatewayResponse;

  const GovernedLearnerEventReceipt({
    required this.workflowId,
    required this.eventId,
    required this.eventType,
    required this.reviewState,
    required this.payloadDigest,
    required this.gatewayResponse,
  });
}

class EducatorWorkflowValidationException implements Exception {
  final String message;

  const EducatorWorkflowValidationException(this.message);

  @override
  String toString() => 'EducatorWorkflowValidationException: $message';
}

class _WorkflowInvariant {
  final String workflowId;
  final String assignmentId;
  final String subjectId;
  final String learningContextId;
  final String? courseCode;
  final List<String> expectationIds;

  const _WorkflowInvariant({
    required this.workflowId,
    required this.assignmentId,
    required this.subjectId,
    required this.learningContextId,
    required this.courseCode,
    required this.expectationIds,
  });

  factory _WorkflowInvariant.fromEvent(EducatorWorkflowEvent event) =>
      _WorkflowInvariant(
        workflowId: event.workflowId,
        assignmentId: event.assignmentId,
        subjectId: event.subjectId,
        learningContextId: event.learningContextId,
        courseCode: event.courseCode,
        expectationIds: event.expectationIds,
      );

  @override
  bool operator ==(Object other) =>
      other is _WorkflowInvariant &&
      workflowId == other.workflowId &&
      assignmentId == other.assignmentId &&
      subjectId == other.subjectId &&
      learningContextId == other.learningContextId &&
      courseCode == other.courseCode &&
      _listEquals(expectationIds, other.expectationIds);

  @override
  int get hashCode => Object.hash(
    workflowId,
    assignmentId,
    subjectId,
    learningContextId,
    courseCode,
    Object.hashAll(expectationIds),
  );

  static bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
