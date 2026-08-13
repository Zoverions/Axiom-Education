import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/education_client.dart';
import 'package:ontarioedai/core/axiom/education_contract.dart';

class FakeAxiomTransport implements AxiomIntentTransport {
  AxiomTransportResponse response;
  Object? failure;
  String? action;
  Map<String, Object?>? input;
  String? idempotencyKey;
  int callCount = 0;

  FakeAxiomTransport({
    this.response = const AxiomTransportResponse(
      statusCode: 200,
      body: {'status': 'completed'},
    ),
    this.failure,
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
    final error = failure;
    if (error != null) throw error;
    return response;
  }
}

void main() {
  const digest =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('canonical contract bytes match the cross-repository digest pin', () {
    final bytes = File('contracts/axiom-education.v1.json').readAsBytesSync();
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    expect(sha256.convert(bytes).toString(), AxiomEducationContract.sha256);
    expect(decoded['schema'], AxiomEducationContract.schema);
    expect(decoded['contract_id'], AxiomEducationContract.id);
    expect(decoded['contract_version'], AxiomEducationContract.version);
    expect(decoded['install_grants_authority'], isFalse);
    expect(
      (decoded['actions'] as Map).keys.toSet(),
      AxiomEducationContract.actions.keys.toSet(),
    );
  });

  test('curriculum query inserts the immutable contract pin', () async {
    final transport = FakeAxiomTransport();
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'education-query-0001',
    );

    final result = await client.submit(
      action: AxiomEducationContract.curriculumQuery,
      input: const {
        'active_pack_manifest_sha256': digest,
        'course_code': 'MTH1W',
        'query': 'linear relations',
        'limit': 20,
      },
    );

    expect(result['status'], 'completed');
    expect(transport.callCount, 1);
    expect(transport.action, AxiomEducationContract.curriculumQuery);
    expect(transport.idempotencyKey, 'education-query-0001');
    expect(
      transport.input,
      containsPair('contract_id', AxiomEducationContract.id),
    );
    expect(
      transport.input,
      containsPair('contract_version', AxiomEducationContract.version),
    );
    expect(
      transport.input,
      containsPair('contract_sha256', AxiomEducationContract.sha256),
    );
  });

  test('invalid or unknown input fails before transport', () async {
    final transport = FakeAxiomTransport();
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'education-query-0002',
    );

    await expectLater(
      client.submit(
        action: AxiomEducationContract.curriculumQuery,
        input: const {
          'active_pack_manifest_sha256': digest,
          'course_code': 'MTH1W',
          'ambient_filesystem_path': '/tmp/unsafe',
        },
      ),
      throwsA(isA<AxiomEducationValidationException>()),
    );
    await expectLater(
      client.submit(
        action: AxiomEducationContract.curriculumQuery,
        input: const {
          'active_pack_manifest_sha256': digest,
          'course_code': 'MTH1W',
          'limit': 51,
        },
      ),
      throwsA(isA<AxiomEducationValidationException>()),
    );
    await expectLater(
      client.submit(
        action: AxiomEducationContract.curriculumQuery,
        input: const {
          'contract_id': 'caller-controlled',
          'active_pack_manifest_sha256': digest,
          'course_code': 'MTH1W',
        },
      ),
      throwsA(isA<AxiomEducationValidationException>()),
    );
    expect(transport.callCount, 0);
  });

  test('non-finite and oversized input fails before transport', () async {
    final transport = FakeAxiomTransport();
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'education-query-bounds-0001',
    );
    final baseline = <String, Object?>{
      'active_pack_manifest_sha256': digest,
      'course_code': 'MTH1W',
    };

    for (final input in <Map<String, Object?>>[
      {...baseline, 'limit': double.nan},
      {...baseline, 'course_code': 'x' * 257},
      {...baseline, 'query': 'x' * 4097},
      {...baseline, 'expectation_ids': List.filled(257, 'MTH1W-A1')},
    ]) {
      await expectLater(
        client.submit(
          action: AxiomEducationContract.curriculumQuery,
          input: input,
        ),
        throwsA(isA<AxiomEducationValidationException>()),
      );
    }
    expect(transport.callCount, 0);
  });

  test('event timestamps must be bounded ISO-8601 values', () async {
    final transport = FakeAxiomTransport();
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'education-event-bounds-0001',
    );
    for (final occurredAt in const ['not-a-timestamp', '2026-08-13T12:00:00']) {
      await expectLater(
        client.submit(
          action: AxiomEducationContract.learnerEventAppend,
          input: {
            'subject_id': 'learner:test',
            'consent_id': 'consent:test',
            'purpose': 'learning-progress-recording',
            'event_id': 'event:test',
            'event_type': 'submission.created',
            'occurred_at': occurredAt,
            'payload_digest': digest,
            'memory_object_id': 'memory:test',
          },
        ),
        throwsA(isA<AxiomEducationValidationException>()),
      );
    }
    expect(transport.callCount, 0);
  });

  test('tutor intent requires exact subject consent and purpose', () async {
    final transport = FakeAxiomTransport();
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'education-tutor-0001',
    );
    final valid = <String, Object?>{
      'subject_id': 'learner:test',
      'consent_id': 'consent:test',
      'purpose': 'personalized-local-tutoring',
      'active_pack_manifest_sha256': digest,
      'expectation_ids': ['MTH1W-A1'],
      'prompt': 'Explain this relationship without giving the final answer.',
      'max_output_tokens': 256,
      'deadline_ms': 10000,
    };

    await client.submit(
      action: AxiomEducationContract.tutorRespond,
      input: valid,
    );
    expect(transport.callCount, 1);

    await expectLater(
      client.submit(
        action: AxiomEducationContract.tutorRespond,
        input: {...valid, 'purpose': 'advertising'},
      ),
      throwsA(isA<AxiomEducationValidationException>()),
    );
    await expectLater(
      client.submit(
        action: AxiomEducationContract.tutorRespond,
        input: {...valid}..remove('consent_id'),
      ),
      throwsA(isA<AxiomEducationValidationException>()),
    );
    expect(transport.callCount, 1);
  });

  test(
    'capability unavailable is surfaced without synthetic success',
    () async {
      final transport = FakeAxiomTransport(
        response: const AxiomTransportResponse(
          statusCode: 503,
          body: {
            'error': {
              'code': 'capability_unavailable',
              'message':
                  'No verified education.tutor provider capsule is configured.',
            },
          },
        ),
      );
      final client = AxiomEducationClient(
        transport: transport,
        idempotencyKeyFactory: () => 'education-tutor-0002',
      );

      await expectLater(
        client.submit(
          action: AxiomEducationContract.tutorRespond,
          input: const {
            'subject_id': 'learner:test',
            'consent_id': 'consent:test',
            'purpose': 'personalized-local-tutoring',
            'active_pack_manifest_sha256': digest,
            'expectation_ids': ['MTH1W-A1'],
            'prompt': 'Explain slope.',
          },
        ),
        throwsA(
          isA<AxiomEducationCapabilityUnavailableException>()
              .having((error) => error.statusCode, 'statusCode', 503)
              .having((error) => error.code, 'code', 'capability_unavailable'),
        ),
      );
    },
  );

  test('policy and approval errors retain AXIOM semantics', () async {
    final transport = FakeAxiomTransport(
      response: const AxiomTransportResponse(
        statusCode: 403,
        body: {
          'error': {'code': 'policy_denied', 'message': 'Denied by policy.'},
        },
      ),
    );
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'education-query-0003',
    );

    await expectLater(
      client.submit(
        action: AxiomEducationContract.curriculumQuery,
        input: const {
          'active_pack_manifest_sha256': digest,
          'course_code': 'MTH1W',
        },
      ),
      throwsA(isA<AxiomEducationPolicyDeniedException>()),
    );

    transport.response = const AxiomTransportResponse(
      statusCode: 409,
      body: {
        'error': {
          'code': 'independent_approval_required',
          'message': 'Independent approval is required.',
          'details': {
            'required_confirmation_values': ['confirm:test'],
          },
        },
      },
    );
    await expectLater(
      client.submit(
        action: AxiomEducationContract.portfolioExport,
        input: const {
          'subject_id': 'learner:test',
          'consent_id': 'consent:export',
          'purpose': 'learner-controlled-portfolio-export',
          'selectors': ['work:1'],
          'recipient_public_key': 'test-public-key',
        },
      ),
      throwsA(isA<AxiomEducationApprovalRequiredException>()),
    );
  });

  test('transport failure becomes an explicit transport exception', () async {
    final transport = FakeAxiomTransport(failure: StateError('offline'));
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'education-query-0004',
    );

    await expectLater(
      client.submit(
        action: AxiomEducationContract.curriculumQuery,
        input: const {
          'active_pack_manifest_sha256': digest,
          'course_code': 'MTH1W',
        },
      ),
      throwsA(
        isA<AxiomEducationTransportException>().having(
          (error) => error.cause,
          'cause',
          isA<StateError>(),
        ),
      ),
    );
  });

  test('successful response containing an error object is rejected', () async {
    final transport = FakeAxiomTransport(
      response: const AxiomTransportResponse(
        statusCode: 200,
        body: {
          'error': {'code': 'synthetic_success'},
        },
      ),
    );
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'education-query-0005',
    );

    await expectLater(
      client.submit(
        action: AxiomEducationContract.curriculumQuery,
        input: const {
          'active_pack_manifest_sha256': digest,
          'course_code': 'MTH1W',
        },
      ),
      throwsA(isA<AxiomEducationProtocolException>()),
    );
  });
}
