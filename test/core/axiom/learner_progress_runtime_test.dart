import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/education_client.dart';
import 'package:ontarioedai/core/axiom/education_contract.dart';
import 'package:ontarioedai/core/axiom/learner_progress_runtime.dart';

class _ProgressTransport implements AxiomIntentTransport {
  AxiomTransportResponse response;
  int callCount = 0;
  String? action;
  Map<String, Object?>? input;
  String? idempotencyKey;

  _ProgressTransport({
    this.response = const AxiomTransportResponse(
      statusCode: 200,
      body: {'provider': 'test', 'opaque_progress': true},
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

void main() {
  test(
    'progress read uses consent-bound AXIOM action and opaque response',
    () async {
      final transport = _ProgressTransport();
      final reader = GovernedLearnerProgressReader(
        client: AxiomEducationClient(
          transport: transport,
          idempotencyKeyFactory: () => 'unused-idempotency-factory',
        ),
      );

      final envelope = await reader.read(
        subjectId: 'learner:test',
        consentId: 'consent:test',
        courseCode: 'MTH1W',
        expectationIds: const ['MTH1W-A1.1'],
        asOf: '2026-08-11T18:30:00-04:00',
      );

      expect(transport.callCount, 1);
      expect(transport.action, AxiomEducationContract.learnerProgressRead);
      expect(transport.input, containsPair('subject_id', 'learner:test'));
      expect(transport.input, containsPair('consent_id', 'consent:test'));
      expect(
        transport.input,
        containsPair('purpose', GovernedLearnerProgressReader.purpose),
      );
      expect(transport.input, containsPair('course_code', 'MTH1W'));
      expect(
        transport.input,
        containsPair('expectation_ids', const ['MTH1W-A1.1']),
      );
      expect(
        transport.input,
        containsPair('contract_id', AxiomEducationContract.id),
      );
      expect(envelope.responseSchemaDefinedByContract, isFalse);
      expect(envelope.rawGatewayResponse['opaque_progress'], isTrue);
    },
  );

  test(
    'identical progress reads use a deterministic request idempotency key',
    () async {
      final firstTransport = _ProgressTransport();
      final secondTransport = _ProgressTransport();
      final first = GovernedLearnerProgressReader(
        client: AxiomEducationClient(
          transport: firstTransport,
          idempotencyKeyFactory: () => 'unused-first-factory',
        ),
      );
      final second = GovernedLearnerProgressReader(
        client: AxiomEducationClient(
          transport: secondTransport,
          idempotencyKeyFactory: () => 'unused-second-factory',
        ),
      );

      final firstEnvelope = await first.read(
        subjectId: 'learner:test',
        consentId: 'consent:test',
        courseCode: 'MTH1W',
        expectationIds: const ['MTH1W-A1.1', 'MTH1W-A1.2'],
      );
      final secondEnvelope = await second.read(
        subjectId: 'learner:test',
        consentId: 'consent:test',
        courseCode: 'MTH1W',
        expectationIds: const ['MTH1W-A1.1', 'MTH1W-A1.2'],
      );

      expect(firstEnvelope.requestDigest, secondEnvelope.requestDigest);
      expect(firstTransport.idempotencyKey, secondTransport.idempotencyKey);
      expect(
        firstTransport.idempotencyKey,
        'education-progress-read:${firstEnvelope.requestDigest}',
      );
    },
  );

  test('invalid progress selectors fail before transport', () async {
    final transport = _ProgressTransport();
    final reader = GovernedLearnerProgressReader(
      client: AxiomEducationClient(
        transport: transport,
        idempotencyKeyFactory: () => 'unused-idempotency-factory',
      ),
    );

    await expectLater(
      reader.read(
        subjectId: 'learner:test',
        consentId: 'consent:test',
        courseCode: 'MTH1W',
        expectationIds: const ['MTH1W-A1.1', 'MTH1W-A1.1'],
      ),
      throwsA(isA<LearnerProgressValidationException>()),
    );
    await expectLater(
      reader.read(
        subjectId: 'learner:test',
        consentId: 'consent:test',
        courseCode: 'MTH1W',
        asOf: '2026-08-11T18:30:00',
      ),
      throwsA(isA<LearnerProgressValidationException>()),
    );
    expect(transport.callCount, 0);
  });

  test(
    'unavailable learner-record provider propagates without local fallback',
    () async {
      final transport = _ProgressTransport(
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
      final reader = GovernedLearnerProgressReader(
        client: AxiomEducationClient(
          transport: transport,
          idempotencyKeyFactory: () => 'unused-idempotency-factory',
        ),
      );

      await expectLater(
        reader.read(
          subjectId: 'learner:test',
          consentId: 'consent:test',
          courseCode: 'MTH1W',
        ),
        throwsA(isA<AxiomEducationCapabilityUnavailableException>()),
      );
      expect(transport.callCount, 1);
    },
  );
}
