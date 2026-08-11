import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/education_client.dart';
import 'package:ontarioedai/core/axiom/education_contract.dart';
import 'package:ontarioedai/core/axiom/educator_workflow_runtime.dart';

class _FakeTransport implements AxiomIntentTransport {
  AxiomTransportResponse response;
  int callCount = 0;
  String? action;
  Map<String, Object?>? input;
  String? idempotencyKey;

  _FakeTransport({
    this.response = const AxiomTransportResponse(
      statusCode: 200,
      body: {'status': 'completed', 'record_id': 'record:test'},
    ),
  });

  @override
  Future<AxiomTransportResponse> postIntent({
    required String action,
    required Map<String, Object?> input,
    required String idempotencyKey,
  }) async {
    callCount++;
    this.action = action;
    this.input = input;
    this.idempotencyKey = idempotencyKey;
    return response;
  }
}

EducatorWorkflowEvent _assignment({
  String artifact =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
}) => EducatorWorkflowEvent.create(
  workflowId: 'workflow:test:001',
  assignmentId: 'assignment:test:001',
  subjectId: 'learner:test',
  learningContextId: 'context:test',
  courseCode: 'MTH1W',
  expectationIds: const ['MTH1W-A1.1', 'MTH1W-A1.2'],
  eventId: 'event:test:assignment',
  eventType: 'assignment.created',
  actorRole: 'educator',
  occurredAt: '2026-08-11T18:30:00-04:00',
  artifactDigest: artifact,
);

void main() {
  const submittedArtifact =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  test('Dart workflow registry remains parity-bound to the JSON contract', () {
    final contract = jsonDecode(
      File(
        'contracts/axiom-education-educator-workflow.v1.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final parent = contract['parent_contract'] as Map<String, dynamic>;
    expect(parent['transport_action'], AxiomEducationContract.learnerEventAppend);
    expect(parent['purpose'], EducatorWorkflowRuntime.purpose);
    expect(parent['contract_id'], AxiomEducationContract.id);
    expect(parent['contract_version'], AxiomEducationContract.version);
    expect(parent['contract_sha256'], AxiomEducationContract.sha256);

    final types = contract['event_types'] as Map<String, dynamic>;
    expect(types.keys.toSet(), EducatorWorkflowRuntime.eventSpecs.keys.toSet());
    for (final entry in EducatorWorkflowRuntime.eventSpecs.entries) {
      final jsonSpec = types[entry.key] as Map<String, dynamic>;
      expect(
        (jsonSpec['actors'] as List).cast<String>().toSet(),
        entry.value.actors,
      );
      expect((jsonSpec['from'] as List).toSet(), entry.value.from);
      expect(jsonSpec['to'], entry.value.to);
      expect(
        (jsonSpec['required_digests'] as List).cast<String>().toSet(),
        entry.value.requiredDigests,
      );
    }
  });

  test('canonical event digest matches the Python verifier representation', () {
    final event = _assignment();
    expect(
      event.payloadDigest,
      '067d6065eabdaba633de7497cb5826646ba667de0ff0fa2d957138b3a2e86264',
    );
  });

  test('valid workflow follows transitions and binds review to latest submission', () {
    final assignment = _assignment();
    final submission = EducatorWorkflowEvent.create(
      workflowId: assignment.workflowId,
      assignmentId: assignment.assignmentId,
      subjectId: assignment.subjectId,
      learningContextId: assignment.learningContextId,
      courseCode: assignment.courseCode,
      expectationIds: assignment.expectationIds,
      eventId: 'event:test:submission',
      eventType: 'submission.created',
      actorRole: 'learner',
      occurredAt: '2026-08-11T18:35:00-04:00',
      previousEventDigest: assignment.payloadDigest,
      artifactDigest: submittedArtifact,
    );
    final review = EducatorWorkflowEvent.create(
      workflowId: assignment.workflowId,
      assignmentId: assignment.assignmentId,
      subjectId: assignment.subjectId,
      learningContextId: assignment.learningContextId,
      courseCode: assignment.courseCode,
      expectationIds: assignment.expectationIds,
      eventId: 'event:test:review',
      eventType: 'review.started',
      actorRole: 'educator',
      occurredAt: '2026-08-11T18:40:00-04:00',
      previousEventDigest: submission.payloadDigest,
      artifactDigest: submittedArtifact,
    );

    final result = EducatorWorkflowRuntime.verifyWorkflow([
      assignment,
      submission,
      review,
    ]);
    expect(result.eventCount, 3);
    expect(result.finalState, 'under-review');
    expect(result.finalEventDigest, review.payloadDigest);
  });

  test('stale artifact substitution fails before any governed write', () async {
    final assignment = _assignment();
    final submission = EducatorWorkflowEvent.create(
      workflowId: assignment.workflowId,
      assignmentId: assignment.assignmentId,
      subjectId: assignment.subjectId,
      learningContextId: assignment.learningContextId,
      courseCode: assignment.courseCode,
      expectationIds: assignment.expectationIds,
      eventId: 'event:test:submission',
      eventType: 'submission.created',
      actorRole: 'learner',
      occurredAt: '2026-08-11T18:35:00-04:00',
      previousEventDigest: assignment.payloadDigest,
      artifactDigest: submittedArtifact,
    );
    final review = EducatorWorkflowEvent.create(
      workflowId: assignment.workflowId,
      assignmentId: assignment.assignmentId,
      subjectId: assignment.subjectId,
      learningContextId: assignment.learningContextId,
      courseCode: assignment.courseCode,
      expectationIds: assignment.expectationIds,
      eventId: 'event:test:review',
      eventType: 'review.started',
      actorRole: 'educator',
      occurredAt: '2026-08-11T18:40:00-04:00',
      previousEventDigest: submission.payloadDigest,
      artifactDigest:
          'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    );
    final transport = _FakeTransport();
    final writer = GovernedLearnerEventWriter(
      client: AxiomEducationClient(
        transport: transport,
        idempotencyKeyFactory: () => 'unused-idempotency-factory',
      ),
    );

    await expectLater(
      writer.append(
        workflow: [assignment, submission, review],
        consentId: 'consent:test',
        memoryObjectId: 'memory:test',
      ),
      throwsA(isA<EducatorWorkflowValidationException>()),
    );
    expect(transport.callCount, 0);
  });

  test('governed writer projects only bounded metadata into AXIOM', () async {
    final assignment = _assignment();
    final transport = _FakeTransport();
    final writer = GovernedLearnerEventWriter(
      client: AxiomEducationClient(
        transport: transport,
        idempotencyKeyFactory: () => 'unused-idempotency-factory',
      ),
    );

    final receipt = await writer.append(
      workflow: [assignment],
      consentId: 'consent:test',
      memoryObjectId: 'memory:assignment:test',
    );

    expect(transport.callCount, 1);
    expect(transport.action, AxiomEducationContract.learnerEventAppend);
    expect(
      transport.idempotencyKey,
      'education-workflow:${assignment.payloadDigest}',
    );
    expect(transport.input, containsPair('subject_id', 'learner:test'));
    expect(transport.input, containsPair('consent_id', 'consent:test'));
    expect(
      transport.input,
      containsPair('purpose', 'learning-progress-recording'),
    );
    expect(
      transport.input,
      containsPair('memory_object_id', 'memory:assignment:test'),
    );
    expect(
      transport.input,
      containsPair('payload_digest', assignment.payloadDigest),
    );
    expect(transport.input, containsPair('contract_id', AxiomEducationContract.id));
    expect(transport.input, isNot(contains('raw_student_work')));
    expect(transport.input, isNot(contains('raw_feedback')));
    expect(transport.input, isNot(contains('grade')));
    expect(transport.input, isNot(contains('credit')));
    expect(receipt.payloadDigest, assignment.payloadDigest);
    expect(receipt.gatewayResponse['status'], 'completed');
  });

  test('gateway failure propagates and cannot become local synthetic success', () async {
    final assignment = _assignment();
    final transport = _FakeTransport(
      response: const AxiomTransportResponse(
        statusCode: 503,
        body: {
          'error': {
            'code': 'capability_unavailable',
            'message': 'No governed learner-record provider is configured.',
          },
        },
      ),
    );
    final writer = GovernedLearnerEventWriter(
      client: AxiomEducationClient(
        transport: transport,
        idempotencyKeyFactory: () => 'unused-idempotency-factory',
      ),
    );

    await expectLater(
      writer.append(
        workflow: [assignment],
        consentId: 'consent:test',
        memoryObjectId: 'memory:assignment:test',
      ),
      throwsA(isA<AxiomEducationCapabilityUnavailableException>()),
    );
    expect(transport.callCount, 1);
  });

  test('tampering or schema expansion is rejected', () {
    final assignment = _assignment();
    final tampered = Map<String, Object?>.from(assignment.toMap())
      ..['review_state'] = 'finalized';
    expect(
      () => EducatorWorkflowEvent.fromMap(tampered),
      throwsA(isA<EducatorWorkflowValidationException>()),
    );

    final expanded = Map<String, Object?>.from(assignment.toMap())
      ..['student_answer'] = 'sensitive raw work';
    expect(
      () => EducatorWorkflowEvent.fromMap(expanded),
      throwsA(isA<EducatorWorkflowValidationException>()),
    );
  });

  test('self-asserted actor role cannot bypass event-type role restrictions', () {
    expect(
      () => EducatorWorkflowEvent.create(
        workflowId: 'workflow:test:002',
        assignmentId: 'assignment:test:002',
        subjectId: 'learner:test',
        learningContextId: 'context:test',
        courseCode: 'MTH1W',
        expectationIds: const ['MTH1W-A1.1'],
        eventId: 'event:test:invalid-role',
        eventType: 'assignment.created',
        actorRole: 'learner',
        occurredAt: '2026-08-11T18:30:00-04:00',
        artifactDigest:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ),
      throwsA(isA<EducatorWorkflowValidationException>()),
    );
  });
}
