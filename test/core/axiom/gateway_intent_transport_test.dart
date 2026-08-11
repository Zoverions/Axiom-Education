import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/education_client.dart';
import 'package:ontarioedai/core/axiom/gateway_intent_transport.dart';

class _RecordingRequester {
  int calls = 0;
  String? path;
  AxiomGatewayRawRequest? request;
  AxiomGatewayRawResponse response;
  Object? failure;

  _RecordingRequester({AxiomGatewayRawResponse? response})
    : response =
          response ??
          _jsonResponse(201, {
            'intent_id': 'intent_test',
            'trace_id': 'trace_test_001',
            'status': 'completed',
            'evidence': <String, Object?>{},
            'provider_result': 'ok',
          });

  Future<AxiomGatewayRawResponse> call(
    String path,
    AxiomGatewayRawRequest request,
  ) async {
    calls++;
    this.path = path;
    this.request = request;
    if (failure != null) throw failure!;
    return response;
  }
}

AxiomGatewayRawResponse _jsonResponse(
  int statusCode,
  Map<String, Object?> body, {
  Map<String, String> headers = const {},
}) => AxiomGatewayRawResponse(
  statusCode: statusCode,
  headers: {
    'content-type': 'application/json; charset=utf-8',
    'x-trace-id': 'trace_header_001',
    ...headers,
  },
  body: Uint8List.fromList(utf8.encode(jsonEncode(body))),
);

void main() {
  test('submits exact action+input body to relative Gateway intent route', () async {
    final requester = _RecordingRequester();
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'memory-only-test-token',
    );

    final response = await transport.postIntent(
      action: 'education.learner.event.append',
      input: const {
        'contract_id': 'axiom.education',
        'purpose': 'learning-progress-recording',
      },
      idempotencyKey: 'education-workflow:0123456789abcdef',
    );

    expect(requester.calls, 1);
    expect(requester.path, '/v1/intents');
    expect(requester.request!.method, 'POST');
    expect(requester.request!.headers['accept'], 'application/json');
    expect(
      requester.request!.headers['authorization'],
      'Bearer memory-only-test-token',
    );
    expect(requester.request!.headers['content-type'], 'application/json');
    expect(
      requester.request!.headers['idempotency-key'],
      'education-workflow:0123456789abcdef',
    );
    expect(requester.request!.timeout, const Duration(seconds: 10));
    expect(
      jsonDecode(utf8.decode(requester.request!.body)),
      const {
        'action': 'education.learner.event.append',
        'input': {
          'contract_id': 'axiom.education',
          'purpose': 'learning-progress-recording',
        },
      },
    );
    expect(response.statusCode, 201);
    expect(response.body['provider_result'], 'ok');
  });

  test('transport has no configurable origin and requester receives relative path only', () async {
    final requester = _RecordingRequester();
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'memory-only-test-token',
    );

    await transport.postIntent(
      action: 'education.learner.progress.read',
      input: const {'contract_id': 'axiom.education'},
      idempotencyKey: 'education-progress-read:0123456789abcdef',
    );

    expect(requester.path, startsWith('/v1/'));
    expect(requester.path, isNot(contains('://')));
  });

  test('invalid bearer token fails before request', () async {
    final requester = _RecordingRequester();
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'bad\ntoken',
    );

    await expectLater(
      transport.postIntent(
        action: 'education.learner.progress.read',
        input: const {},
        idempotencyKey: 'education-progress-read:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>().having(
          (error) => error.code,
          'code',
          'invalid_client_request',
        ),
      ),
    );
    expect(requester.calls, 0);
  });

  test('Gateway-strength idempotency key is enforced before request', () async {
    final requester = _RecordingRequester();
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'token',
    );

    await expectLater(
      transport.postIntent(
        action: 'education.learner.progress.read',
        input: const {},
        idempotencyKey: 'short-key',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>().having(
          (error) => error.code,
          'code',
          'invalid_client_request',
        ),
      ),
    );
    expect(requester.calls, 0);
  });

  test('non-serializable or oversized intent fails before request', () async {
    final requester = _RecordingRequester();
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'token',
    );

    await expectLater(
      transport.postIntent(
        action: 'education.learner.progress.read',
        input: {'bad': Object()},
        idempotencyKey: 'education-progress-read:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>().having(
          (error) => error.code,
          'code',
          'invalid_client_request',
        ),
      ),
    );

    await expectLater(
      transport.postIntent(
        action: 'education.learner.progress.read',
        input: {'large': 'x' * AxiomGatewayIntentTransport.maximumRequestBytes},
        idempotencyKey: 'education-progress-read:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>().having(
          (error) => error.code,
          'code',
          'invalid_client_request',
        ),
      ),
    );
    expect(requester.calls, 0);
  });

  test('successful Gateway response must contain intent result fields', () async {
    final requester = _RecordingRequester(
      response: _jsonResponse(201, {
        'trace_id': 'trace_test_001',
        'status': 'completed',
        'evidence': <String, Object?>{},
      }),
    );
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'token',
    );

    await expectLater(
      transport.postIntent(
        action: 'education.learner.progress.read',
        input: const {},
        idempotencyKey: 'education-progress-read:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>().having(
          (error) => error.code,
          'code',
          'invalid_gateway_response',
        ),
      ),
    );
  });

  test('wrong media type and malformed JSON fail closed', () async {
    final wrongMediaRequester = _RecordingRequester(
      response: AxiomGatewayRawResponse(
        statusCode: 201,
        headers: const {'content-type': 'text/plain'},
        body: Uint8List.fromList(utf8.encode('{}')),
      ),
    );
    final wrongMediaTransport = AxiomGatewayIntentTransport(
      requester: wrongMediaRequester.call,
      tokenProvider: () => 'token',
    );
    await expectLater(
      wrongMediaTransport.postIntent(
        action: 'education.learner.progress.read',
        input: const {},
        idempotencyKey: 'education-progress-read:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>().having(
          (error) => error.code,
          'code',
          'invalid_gateway_response',
        ),
      ),
    );

    final malformedRequester = _RecordingRequester(
      response: AxiomGatewayRawResponse(
        statusCode: 201,
        headers: const {'content-type': 'application/json'},
        body: Uint8List.fromList(utf8.encode('{bad json')),
      ),
    );
    final malformedTransport = AxiomGatewayIntentTransport(
      requester: malformedRequester.call,
      tokenProvider: () => 'token',
    );
    await expectLater(
      malformedTransport.postIntent(
        action: 'education.learner.progress.read',
        input: const {},
        idempotencyKey: 'education-progress-read:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>().having(
          (error) => error.code,
          'code',
          'invalid_gateway_response',
        ),
      ),
    );
  });

  test('stable Gateway error is preserved for education client mapping', () async {
    final requester = _RecordingRequester(
      response: _jsonResponse(503, {
        'error': {
          'code': 'capability_unavailable',
          'message': 'No governed education provider is configured.',
          'details': {'capability': 'education.learner-record'},
        },
        'trace_id': 'trace_test_001',
      }),
    );
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'token',
    );
    final client = AxiomEducationClient(
      transport: transport,
      idempotencyKeyFactory: () => 'unused-client-factory',
    );

    await expectLater(
      client.submit(
        action: 'education.learner.progress.read',
        input: const {
          'subject_id': 'learner:test',
          'consent_id': 'consent:test',
          'purpose': 'learning-progress-review',
          'course_code': 'MTH1W',
        },
        idempotencyKey: 'education-progress-read:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomEducationCapabilityUnavailableException>().having(
          (error) => error.code,
          'code',
          'capability_unavailable',
        ),
      ),
    );
  });

  test('unknown domain error code is preserved but message/details are sanitized', () async {
    final requester = _RecordingRequester(
      response: _jsonResponse(409, {
        'error': {
          'code': 'education_provider_changed',
          'message': 'Unreviewed implementation detail that must not be surfaced.',
          'details': {'private': 'unreviewed'},
        },
        'trace_id': 'trace_test_001',
      }),
    );
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'token',
    );

    final response = await transport.postIntent(
      action: 'education.learner.progress.read',
      input: const {},
      idempotencyKey: 'education-progress-read:0123456789abcdef',
    );
    final error = response.body['error']! as Map<String, Object?>;
    expect(error['code'], 'education_provider_changed');
    expect(error['message'], 'Gateway request failed');
    expect(error, isNot(contains('details')));
  });

  test('request failures are bounded and never automatically retried', () async {
    final requester = _RecordingRequester()..failure = StateError('offline');
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'token',
    );

    await expectLater(
      transport.postIntent(
        action: 'education.learner.event.append',
        input: const {},
        idempotencyKey: 'education-workflow:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>()
            .having(
              (error) => error.code,
              'code',
              'dependency_unavailable',
            )
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
    expect(requester.calls, 1);
  });

  test('bounded timeout is enforced without a retry', () async {
    var calls = 0;
    Future<AxiomGatewayRawResponse> slowRequester(
      String path,
      AxiomGatewayRawRequest request,
    ) async {
      calls++;
      await Completer<void>().future;
      throw StateError('unreachable');
    }

    final transport = AxiomGatewayIntentTransport(
      requester: slowRequester,
      tokenProvider: () => 'token',
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      transport.postIntent(
        action: 'education.learner.event.append',
        input: const {},
        idempotencyKey: 'education-workflow:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>()
            .having((error) => error.code, 'code', 'request_timeout')
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
    expect(calls, 1);
  });

  test('response byte ceiling is enforced even if requester misbehaves', () async {
    final requester = _RecordingRequester(
      response: AxiomGatewayRawResponse(
        statusCode: 201,
        headers: const {'content-type': 'application/json'},
        body: Uint8List(AxiomGatewayIntentTransport.maximumResponseBytes + 1),
      ),
    );
    final transport = AxiomGatewayIntentTransport(
      requester: requester.call,
      tokenProvider: () => 'token',
    );

    await expectLater(
      transport.postIntent(
        action: 'education.learner.progress.read',
        input: const {},
        idempotencyKey: 'education-progress-read:0123456789abcdef',
      ),
      throwsA(
        isA<AxiomGatewayTransportException>().having(
          (error) => error.code,
          'code',
          'response_too_large',
        ),
      ),
    );
    expect(requester.request!.maximumResponseBytes, 2 * 1024 * 1024);
  });
}
