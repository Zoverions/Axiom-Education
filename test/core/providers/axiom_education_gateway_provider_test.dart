import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/gateway_intent_transport.dart';
import 'package:ontarioedai/core/axiom/governed_learner_commit_runtime.dart';
import 'package:ontarioedai/core/axiom/governed_memory_runtime.dart';
import 'package:ontarioedai/core/providers/axiom_education_gateway_provider.dart';

AxiomGatewayRawResponse _successResponse() => AxiomGatewayRawResponse(
  statusCode: 201,
  headers: const {'content-type': 'application/json'},
  body: Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'intent_id': 'intent_test',
        'trace_id': 'trace_test_001',
        'status': 'completed',
        'evidence': <String, Object?>{},
      }),
    ),
  ),
);

void main() {
  test(
    'default provider is explicitly unbound and creates no network path',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(governedEducationRuntimeProvider);
      expect(state, isA<GovernedEducationRuntimeUnbound>());
      expect(state.isBound, isFalse);
      expect(
        (state as GovernedEducationRuntimeUnbound).reason,
        contains('No reviewed AXIOM Gateway host binding'),
      );
    },
  );

  test('reviewed host override creates bounded read/write services lazily', () {
    var requests = 0;
    final binding = AxiomEducationGatewayBinding(
      requester: (path, request) async {
        requests++;
        return _successResponse();
      },
      tokenProvider: () => 'memory-only-token',
    );
    final container = ProviderContainer(
      overrides: [
        axiomEducationGatewayBindingProvider.overrideWithValue(binding),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(governedEducationRuntimeProvider);
    expect(state, isA<GovernedEducationRuntimeBound>());
    expect(state.isBound, isTrue);
    expect(requests, 0);

    final bound = state as GovernedEducationRuntimeBound;
    expect(bound.client.transport, isA<AxiomGatewayIntentTransport>());
    expect(bound.memoryWriter, isA<GovernedEducationMemoryWriter>());
    expect(bound.memoryWriter.transport, same(bound.client.transport));
    expect(bound.learnerEventWriter.client, same(bound.client));
    expect(
      bound.learnerCommitCoordinator,
      isA<GovernedLearnerCommitCoordinator>(),
    );
    expect(
      bound.learnerCommitCoordinator.memoryWriter,
      same(bound.memoryWriter),
    );
    expect(
      bound.learnerCommitCoordinator.learnerEventWriter,
      same(bound.learnerEventWriter),
    );
    expect(bound.learnerProgressReader.client, same(bound.client));
  });

  test('binding does not expose a Gateway origin or learner-record store', () {
    final binding = AxiomEducationGatewayBinding(
      requester: (path, request) async => _successResponse(),
      tokenProvider: () => 'memory-only-token',
    );

    expect(binding.requester, isNotNull);
    expect(binding.tokenProvider, isNotNull);
    expect(binding.timeout, AxiomGatewayIntentTransport.defaultTimeout);

    final runtimeType = binding.runtimeType.toString().toLowerCase();
    expect(runtimeType, isNot(contains('store')));
    expect(runtimeType, isNot(contains('origin')));
  });
}
