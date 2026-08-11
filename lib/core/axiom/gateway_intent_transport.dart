import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'education_client.dart';

/// Zero-origin transport boundary for the authenticated AXIOM Gateway.
///
/// The requester receives only a same-origin-relative `/v1/...` path. Browser,
/// desktop, and local-host shells remain responsible for binding that relative
/// request to their reviewed ingress. This layer cannot form Grid, Hypervisor,
/// Sandbox, or arbitrary remote-service requests.
typedef AxiomGatewayRelativeRequester =
    Future<AxiomGatewayRawResponse> Function(
      String relativePath,
      AxiomGatewayRawRequest request,
    );

typedef AxiomGatewayTokenProvider = FutureOr<String> Function();

class AxiomGatewayRawRequest {
  final String method;
  final Map<String, String> headers;
  final Uint8List body;
  final Duration timeout;
  final int maximumResponseBytes;

  const AxiomGatewayRawRequest({
    required this.method,
    required this.headers,
    required this.body,
    required this.timeout,
    required this.maximumResponseBytes,
  });
}

class AxiomGatewayRawResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List body;

  const AxiomGatewayRawResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}

/// Implements the `intents.submit` slice of `axiom-gateway-client-contract.v1`.
///
/// It deliberately does not retry. An application that retries an ambiguous
/// effect must call again with the same idempotency key and keep the user-visible
/// operation pending until the governed result is known.
class AxiomGatewayIntentTransport implements AxiomIntentTransport {
  static const relativePath = '/v1/intents';
  static const maximumRequestBytes = 1024 * 1024;
  static const maximumResponseBytes = 2 * 1024 * 1024;
  static const maximumTimeout = Duration(seconds: 30);
  static const defaultTimeout = Duration(seconds: 10);
  static const maximumTokenLength = 4096;

  static final RegExp _actionPattern = RegExp(r'^[a-z][a-z0-9.-]+$');
  static final RegExp _idempotencyPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
  static final RegExp _errorCodePattern = RegExp(r'^[a-z][a-z0-9_]{0,63}$');

  static const Set<String> stableErrorCodes = {
    'authentication_required',
    'invalid_token',
    'forbidden',
    'rate_limited',
    'body_too_large',
    'validation_error',
    'not_found',
    'idempotency_conflict',
    'confirmation_required',
    'independent_approval_required',
    'approval_mismatch',
    'approval_unavailable',
    'policy_denied',
    'capability_unavailable',
    'dependency_unavailable',
    'request_cancelled',
    'request_timeout',
    'response_too_large',
    'invalid_client_request',
    'invalid_gateway_response',
  };

  final AxiomGatewayRelativeRequester requester;
  final AxiomGatewayTokenProvider tokenProvider;
  final Duration timeout;

  const AxiomGatewayIntentTransport({
    required this.requester,
    required this.tokenProvider,
    this.timeout = defaultTimeout,
  });

  @override
  Future<AxiomTransportResponse> postIntent({
    required String action,
    required Map<String, Object?> input,
    required String idempotencyKey,
  }) async {
    _validateConfiguration();
    _validateAction(action);
    _validateIdempotencyKey(idempotencyKey);

    final token = await _loadToken();
    final encoded = _encodeIntent(action, input);
    if (encoded.length > maximumRequestBytes) {
      throw const AxiomGatewayTransportException(
        code: 'invalid_client_request',
        message: 'Intent request exceeds the Gateway contract byte limit.',
      );
    }

    final request = AxiomGatewayRawRequest(
      method: 'POST',
      headers: Map<String, String>.unmodifiable({
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
        'idempotency-key': idempotencyKey,
      }),
      body: Uint8List.fromList(encoded),
      timeout: timeout,
      maximumResponseBytes: maximumResponseBytes,
    );

    final AxiomGatewayRawResponse response;
    try {
      response = await requester(relativePath, request).timeout(timeout);
    } on TimeoutException catch (error) {
      throw AxiomGatewayTransportException(
        code: 'request_timeout',
        message: 'Gateway request exceeded its bounded timeout.',
        retryable: true,
        cause: error,
      );
    } on AxiomGatewayTransportException {
      rethrow;
    } catch (error) {
      throw AxiomGatewayTransportException(
        code: 'dependency_unavailable',
        message: 'Gateway request could not reach the configured ingress.',
        retryable: true,
        cause: error,
      );
    }

    return _validateResponse(response);
  }

  void _validateConfiguration() {
    if (timeout <= Duration.zero || timeout > maximumTimeout) {
      throw const AxiomGatewayTransportException(
        code: 'invalid_client_request',
        message: 'Gateway request timeout is outside the contract.',
      );
    }
  }

  static void _validateAction(String action) {
    if (action.isEmpty ||
        action.length > 128 ||
        !_actionPattern.hasMatch(action)) {
      throw const AxiomGatewayTransportException(
        code: 'invalid_client_request',
        message: 'Intent action is invalid.',
      );
    }
  }

  static void _validateIdempotencyKey(String value) {
    if (value.length < 16 ||
        value.length > 160 ||
        !_idempotencyPattern.hasMatch(value)) {
      throw const AxiomGatewayTransportException(
        code: 'invalid_client_request',
        message: 'Gateway idempotency key is invalid.',
      );
    }
  }

  Future<String> _loadToken() async {
    final String token;
    try {
      token = await tokenProvider();
    } catch (error) {
      throw AxiomGatewayTransportException(
        code: 'invalid_client_request',
        message: 'Gateway token provider failed.',
        cause: error,
      );
    }
    if (token.isEmpty ||
        token.length > maximumTokenLength ||
        token.contains('\r') ||
        token.contains('\n')) {
      throw const AxiomGatewayTransportException(
        code: 'invalid_client_request',
        message: 'Gateway bearer token is invalid.',
      );
    }
    return token;
  }

  static Uint8List _encodeIntent(String action, Map<String, Object?> input) {
    try {
      final text = jsonEncode({'action': action, 'input': input});
      return Uint8List.fromList(utf8.encode(text));
    } catch (error) {
      throw AxiomGatewayTransportException(
        code: 'invalid_client_request',
        message: 'Intent request is not serializable.',
        cause: error,
      );
    }
  }

  static AxiomTransportResponse _validateResponse(
    AxiomGatewayRawResponse response,
  ) {
    if (response.statusCode < 100 || response.statusCode > 599) {
      throw const AxiomGatewayTransportException(
        code: 'invalid_gateway_response',
        message: 'Gateway returned an invalid HTTP status.',
      );
    }
    if (response.body.length > maximumResponseBytes) {
      throw AxiomGatewayTransportException(
        code: 'response_too_large',
        message: 'Gateway response exceeds the client contract limit.',
        statusCode: response.statusCode,
        traceId: _header(response.headers, 'x-trace-id'),
      );
    }
    final traceId = _header(response.headers, 'x-trace-id');
    final mediaType = (_header(response.headers, 'content-type') ?? '')
        .split(';')
        .first
        .trim()
        .toLowerCase();
    if (mediaType != 'application/json') {
      throw AxiomGatewayTransportException(
        code: 'invalid_gateway_response',
        message: 'Gateway response media type is invalid.',
        statusCode: response.statusCode,
        traceId: traceId,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.body, allowMalformed: false));
    } catch (error) {
      throw AxiomGatewayTransportException(
        code: 'invalid_gateway_response',
        message: 'Gateway returned invalid JSON.',
        statusCode: response.statusCode,
        traceId: traceId,
        cause: error,
      );
    }
    if (decoded is! Map) {
      throw AxiomGatewayTransportException(
        code: 'invalid_gateway_response',
        message: 'Gateway response must be a JSON object.',
        statusCode: response.statusCode,
        traceId: traceId,
      );
    }
    final body = Map<String, Object?>.from(decoded);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      for (final field in const [
        'intent_id',
        'trace_id',
        'status',
        'evidence',
      ]) {
        if (!body.containsKey(field)) {
          throw AxiomGatewayTransportException(
            code: 'invalid_gateway_response',
            message:
                'Gateway intent response is missing required field: $field.',
            statusCode: response.statusCode,
            traceId: traceId,
          );
        }
      }
      return AxiomTransportResponse(
        statusCode: response.statusCode,
        body: Map<String, Object?>.unmodifiable(body),
      );
    }

    return AxiomTransportResponse(
      statusCode: response.statusCode,
      body: _validatedErrorEnvelope(body, response.statusCode, traceId),
    );
  }

  static Map<String, Object?> _validatedErrorEnvelope(
    Map<String, Object?> body,
    int statusCode,
    String? responseTraceId,
  ) {
    if (body.keys.toSet().difference(const {'error', 'trace_id'}).isNotEmpty ||
        !body.containsKey('error') ||
        !body.containsKey('trace_id')) {
      throw AxiomGatewayTransportException(
        code: 'invalid_gateway_response',
        message: 'Gateway error envelope is invalid.',
        statusCode: statusCode,
        traceId: responseTraceId,
      );
    }
    final errorValue = body['error'];
    final traceValue = body['trace_id'];
    if (errorValue is! Map ||
        traceValue is! String ||
        traceValue.isEmpty ||
        traceValue.length > 160) {
      throw AxiomGatewayTransportException(
        code: 'invalid_gateway_response',
        message: 'Gateway error envelope is invalid.',
        statusCode: statusCode,
        traceId: responseTraceId,
      );
    }
    final error = Map<String, Object?>.from(errorValue);
    if (error.keys.toSet().difference(const {
          'code',
          'message',
          'details',
        }).isNotEmpty ||
        error['code'] is! String ||
        error['message'] is! String ||
        (error['message'] as String).isEmpty ||
        !_errorCodePattern.hasMatch(error['code'] as String)) {
      throw AxiomGatewayTransportException(
        code: 'invalid_gateway_response',
        message: 'Gateway error envelope is invalid.',
        statusCode: statusCode,
        traceId: responseTraceId,
      );
    }

    final code = error['code']! as String;
    final stable = stableErrorCodes.contains(code);
    final normalizedError = <String, Object?>{
      'code': code,
      'message': stable
          ? error['message']! as String
          : 'Gateway request failed',
    };
    if (stable && error['details'] is Map) {
      normalizedError['details'] = Map<String, Object?>.from(
        error['details']! as Map,
      );
    }
    return Map<String, Object?>.unmodifiable({
      'error': Map<String, Object?>.unmodifiable(normalizedError),
      'trace_id': traceValue,
    });
  }

  static String? _header(Map<String, String> headers, String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name) return entry.value;
    }
    return null;
  }
}

class AxiomGatewayTransportException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final String? traceId;
  final bool retryable;
  final Object? cause;

  const AxiomGatewayTransportException({
    required this.code,
    required this.message,
    this.statusCode = 0,
    this.traceId,
    this.retryable = false,
    this.cause,
  });

  @override
  String toString() => 'AxiomGatewayTransportException($code): $message';
}
