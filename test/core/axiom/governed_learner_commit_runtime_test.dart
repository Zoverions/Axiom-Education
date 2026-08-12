import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/education_client.dart';
import 'package:ontarioedai/core/axiom/educator_workflow_runtime.dart';
import 'package:ontarioedai/core/axiom/governed_learner_commit_runtime.dart';
import 'package:ontarioedai/core/axiom/governed_memory_runtime.dart';

const digestA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const digestB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

class _IntentCall {
  final String action;
  final Map<String, Object?> input;
  final String idempotencyKey;

  const _IntentCall({
    required this.action,
    required this.input,
    required this.idempotencyKey,
  });
}

class _RecordingTransport implements AxiomIntentTransport {
  final List<_IntentCall> calls = [];
  final AxiomTransportResponse Function(_IntentCall call) responder;

  _RecordingTransport(this.responder);

  @override
  Future<AxiomTransportResponse> postIntent({
    required String action,
    required Map<String, Object?> input,
    required String idempotencyKey,
  }) async {
    final call = _IntentCall(
      action: action,
      input: Map<String, Object?>.from(input),
      idempotencyKey: idempotencyKey,
    );
    calls.add(call);
    return responder(call);
  }
}

List<EducatorWorkflowEvent> _workflow() => [
  EducatorWorkflowEvent.create(
    workflowId: 'workflow:commit-001',
    assignmentId: 'assignment:001',
    subjectId: 'learner:001',
    learningContextId: 'class:MTH1W',
    courseCode: 'MTH1W',
    expectationIds: const ['MTH1W-A1.1'],
    eventId: 'event:assignment-001',
    eventType: 'assignment.created',
    actorRole: 'educator',
    occurredAt: '2026-08-11T20:30:00-04:00',
    artifactDigest: digestA,
  ),
];

AxiomTransportResponse _memorySuccess() => const AxiomTransportResponse(
  statusCode: 201,
  body: {
    'object_id':
        'memory_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    'content_digest': digestB,
    'intent_id': 'intent:memory-001',
    'trace_id': 'trace:memory-001',
    'status': 'completed',
    'evidence': <String, Object?>{},
  },
);

AxiomTransportResponse _eventSuccess() => const AxiomTransportResponse(
  statusCode: 201,
  body: {
    'intent_id': 'intent:event-001',
    'trace_id': 'trace:event-001',
    'status': 'completed',
    'evidence': <String, Object?>{},
  },
);

GovernedLearnerCommitCoordinator _coordinator(_RecordingTransport transport) {
  final client = AxiomEducationClient(
    transport: transport,
    idempotencyKeyFactory: () => throw StateError('deterministic key required'),
  );
  return GovernedLearnerCommitCoordinator(
    memoryWriter: GovernedEducationMemoryWriter(transport: transport),
    learnerEventWriter: GovernedLearnerEventWriter(client: client),
  );
}

void main() {
  test(
    'confirmed governed memory is recorded before learner-event append',
    () async {
      final transport = _RecordingTransport((call) {
        if (call.action == 'memory.put') return _memorySuccess();
        if (call.action == 'education.learner.event.append') {
          return _eventSuccess();
        }
        fail('Unexpected action: ${call.action}');
      });
      final coordinator = _coordinator(transport);

      final receipt = await coordinator.storeAndAppend(
        workflow: _workflow(),
        consentId: 'consent:write-001',
        content: {'body': 'Assignment content'},
      );

      expect(transport.calls.map((call) => call.action).toList(), [
        'memory.put',
        'education.learner.event.append',
      ]);
      expect(
        transport.calls[1].input['memory_object_id'],
        receipt.memoryReceipt.objectId,
      );
      expect(
        receipt.learnerEventReceipt.payloadDigest,
        receipt.memoryReceipt.workflowPayloadDigest,
      );
    },
  );

  test('memory failure prevents learner-event append', () async {
    final transport = _RecordingTransport(
      (_) => const AxiomTransportResponse(
        statusCode: 403,
        body: {
          'error': {'code': 'policy_denied', 'message': 'Memory write denied.'},
        },
      ),
    );
    final coordinator = _coordinator(transport);

    await expectLater(
      coordinator.storeAndAppend(
        workflow: _workflow(),
        consentId: 'consent:write-001',
        content: {'body': 'Assignment content'},
      ),
      throwsA(isA<GovernedEducationMemoryGatewayException>()),
    );
    expect(transport.calls.map((call) => call.action), ['memory.put']);
  });

  test(
    'append failure preserves confirmed memory reference and issues no compensation',
    () async {
      final transport = _RecordingTransport((call) {
        if (call.action == 'memory.put') return _memorySuccess();
        return const AxiomTransportResponse(
          statusCode: 503,
          body: {
            'error': {
              'code': 'capability_unavailable',
              'message': 'Learner record provider unavailable.',
            },
          },
        );
      });
      final coordinator = _coordinator(transport);

      GovernedLearnerCommitAppendException? captured;
      try {
        await coordinator.storeAndAppend(
          workflow: _workflow(),
          consentId: 'consent:write-001',
          content: {'body': 'Assignment content'},
        );
        fail('Expected append failure.');
      } on GovernedLearnerCommitAppendException catch (error) {
        captured = error;
      }

      expect(captured, isNotNull);
      expect(captured!.memoryReceipt.objectId, 'memory_$digestB');
      expect(
        captured.cause,
        isA<AxiomEducationCapabilityUnavailableException>(),
      );
      expect(transport.calls.map((call) => call.action).toList(), [
        'memory.put',
        'education.learner.event.append',
      ]);
      expect(
        transport.calls.any((call) => call.action == 'memory.tombstone'),
        isFalse,
      );
    },
  );

  test(
    'caller retry reuses deterministic memory and learner-event identities',
    () async {
      final transport = _RecordingTransport((call) {
        if (call.action == 'memory.put') return _memorySuccess();
        return _eventSuccess();
      });
      final coordinator = _coordinator(transport);
      final workflow = _workflow();
      final content = {'body': 'Stable assignment content'};

      await coordinator.storeAndAppend(
        workflow: workflow,
        consentId: 'consent:write-001',
        content: content,
      );
      await coordinator.storeAndAppend(
        workflow: workflow,
        consentId: 'consent:write-001',
        content: content,
      );

      expect(transport.calls, hasLength(4));
      expect(transport.calls[0].action, 'memory.put');
      expect(transport.calls[1].action, 'education.learner.event.append');
      expect(transport.calls[2].action, 'memory.put');
      expect(transport.calls[3].action, 'education.learner.event.append');
      expect(
        transport.calls[0].idempotencyKey,
        transport.calls[2].idempotencyKey,
      );
      expect(
        transport.calls[1].idempotencyKey,
        transport.calls[3].idempotencyKey,
      );
    },
  );

  test('invalid workflow fails before governed memory transport', () async {
    final transport = _RecordingTransport((_) => _memorySuccess());
    final coordinator = _coordinator(transport);

    await expectLater(
      coordinator.storeAndAppend(
        workflow: const [],
        consentId: 'consent:write-001',
        content: {'body': 'Must not be stored'},
      ),
      throwsA(isA<EducatorWorkflowValidationException>()),
    );
    expect(transport.calls, isEmpty);
  });
}
