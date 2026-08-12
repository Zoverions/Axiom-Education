import 'package:flutter_test/flutter_test.dart';

import 'package:axiom_education/core/axiom/education_client.dart';
import 'package:axiom_education/core/axiom/educator_workflow_runtime.dart';
import 'package:axiom_education/core/axiom/governed_memory_runtime.dart';

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

EducatorWorkflowEvent _event({
  String eventType = 'assignment.created',
  String eventId = 'event:assignment-001',
}) {
  return EducatorWorkflowEvent.create(
    workflowId: 'workflow:001',
    assignmentId: 'assignment:001',
    subjectId: 'learner:001',
    learningContextId: 'class:MTH1W',
    courseCode: 'MTH1W',
    expectationIds: const ['MTH1W-A1.1'],
    eventId: eventId,
    eventType: eventType,
    actorRole: eventType == 'submission.created' ? 'learner' : 'educator',
    occurredAt: '2026-08-11T20:00:00-04:00',
    previousEventDigest: eventType == 'assignment.created' ? null : digestB,
    artifactDigest: digestA,
  );
}

AxiomTransportResponse _success(_IntentCall call) {
  return AxiomTransportResponse(
    statusCode: 201,
    body: {
      'object_id': 'memory_$digestB',
      'content_digest': digestB,
      'intent_id': 'intent:memory-001',
      'trace_id': 'trace:memory-001',
      'status': 'completed',
      'evidence': {'execution_digest': digestA},
    },
  );
}

void main() {
  test('stores education content through core memory.put without contract fields', () async {
    final transport = _RecordingTransport(_success);
    final writer = GovernedEducationMemoryWriter(transport: transport);
    final event = _event();

    final receipt = await writer.storeForEvent(
      event: event,
      content: {
        'title': 'Linear relations practice',
        'private_body': 'Learner-visible assignment content.',
      },
    );

    expect(transport.calls, hasLength(1));
    final call = transport.calls.single;
    expect(call.action, 'memory.put');
    expect(call.input.keys, containsAll(['kind', 'content', 'metadata']));
    expect(call.input, isNot(contains('contract_id')));
    expect(call.input, isNot(contains('contract_version')));
    expect(call.input, isNot(contains('contract_sha256')));
    expect(call.input['kind'], 'education.assignment-artifact');
    expect(call.idempotencyKey, startsWith('education-memory:'));
    expect(call.idempotencyKey.length, inInclusiveRange(16, 160));

    final metadata = Map<String, Object?>.from(call.input['metadata']! as Map);
    expect(metadata, {
      'schema': GovernedEducationMemoryWriter.metadataSchema,
      'workflow_id': event.workflowId,
      'assignment_id': event.assignmentId,
      'event_id': event.eventId,
      'event_type': event.eventType,
      'workflow_payload_digest': event.payloadDigest,
    });
    expect(metadata.toString(), isNot(contains('Learner-visible assignment content.')));

    expect(receipt.objectId, 'memory_$digestB');
    expect(receipt.contentDigest, digestB);
    expect(receipt.kind, 'education.assignment-artifact');
    expect(receipt.workflowPayloadDigest, event.payloadDigest);
  });

  test('same governed memory request derives the same retry idempotency key', () async {
    final transport = _RecordingTransport(_success);
    final writer = GovernedEducationMemoryWriter(transport: transport);
    final event = _event();
    final content = {'body': 'Stable content'};

    await writer.storeForEvent(event: event, content: content);
    await writer.storeForEvent(event: event, content: content);

    expect(transport.calls, hasLength(2));
    expect(
      transport.calls[0].idempotencyKey,
      transport.calls[1].idempotencyKey,
    );
  });

  test('different governed content changes the retry idempotency key', () async {
    final transport = _RecordingTransport(_success);
    final writer = GovernedEducationMemoryWriter(transport: transport);
    final event = _event();

    await writer.storeForEvent(event: event, content: {'body': 'Version A'});
    await writer.storeForEvent(event: event, content: {'body': 'Version B'});

    expect(
      transport.calls[0].idempotencyKey,
      isNot(transport.calls[1].idempotencyKey),
    );
  });

  test('events without new content must reuse an existing governed reference', () async {
    final transport = _RecordingTransport(_success);
    final writer = GovernedEducationMemoryWriter(transport: transport);
    final event = EducatorWorkflowEvent.create(
      workflowId: 'workflow:001',
      assignmentId: 'assignment:001',
      subjectId: 'learner:001',
      learningContextId: 'class:MTH1W',
      courseCode: 'MTH1W',
      expectationIds: const ['MTH1W-A1.1'],
      eventId: 'event:review-001',
      eventType: 'review.started',
      actorRole: 'educator',
      occurredAt: '2026-08-11T20:05:00-04:00',
      previousEventDigest: digestB,
      artifactDigest: digestA,
    );

    expect(
      () => writer.storeForEvent(event: event, content: {'body': 'not new'}),
      throwsA(isA<GovernedEducationMemoryValidationException>()),
    );
    expect(transport.calls, isEmpty);
  });

  test('response must preserve AXIOM content-address identity', () async {
    final transport = _RecordingTransport(
      (_) => const AxiomTransportResponse(
        statusCode: 201,
        body: {
          'object_id':
              'memory_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'content_digest':
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          'intent_id': 'intent:memory-001',
          'trace_id': 'trace:memory-001',
          'status': 'completed',
          'evidence': <String, Object?>{},
        },
      ),
    );
    final writer = GovernedEducationMemoryWriter(transport: transport);

    await expectLater(
      writer.storeForEvent(event: _event(), content: {'body': 'content'}),
      throwsA(isA<GovernedEducationMemoryProtocolException>()),
    );
  });

  test('Gateway rejection does not become synthetic memory success', () async {
    final transport = _RecordingTransport(
      (_) => const AxiomTransportResponse(
        statusCode: 403,
        body: {
          'error': {
            'code': 'policy_denied',
            'message': 'Memory write denied by policy.',
          },
          'trace_id': 'trace:denied',
        },
      ),
    );
    final writer = GovernedEducationMemoryWriter(transport: transport);

    await expectLater(
      writer.storeForEvent(event: _event(), content: {'body': 'content'}),
      throwsA(
        isA<GovernedEducationMemoryGatewayException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having((error) => error.code, 'code', 'policy_denied'),
      ),
    );
  });
}
