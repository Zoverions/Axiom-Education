import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/gateway_intent_transport.dart';
import 'package:ontarioedai/core/axiom/governed_learner_commit_runtime.dart';
import 'package:ontarioedai/core/axiom/governed_memory_runtime.dart';
import 'package:ontarioedai/core/axiom/mesh_compatibility.dart';
import 'package:ontarioedai/core/providers/axiom_education_gateway_provider.dart';

AxiomGatewayRawResponse _successResponse() => AxiomGatewayRawResponse(
  statusCode: 201,
  headers: const {
    'content-type': 'application/json',
    'x-trace-id': 'trace_test_001',
  },
  body: Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'intent_id': 'intent_${'a' * 64}',
        'trace_id': 'trace_test_001',
        'status': 'completed',
        'evidence': <String, Object?>{},
      }),
    ),
  ),
);

AxiomMeshCompatibilityProfile _profile({
  String? baselineHead,
  String? gatewayIntentsSubmitSeamSha256,
}) {
  const current = AxiomMeshCompatibilityProfile.current();
  return AxiomMeshCompatibilityProfile(
    profileId: current.profileId,
    kernelVersion: current.kernelVersion,
    baselineHead: baselineHead ?? current.baselineHead,
    providerHead: current.providerHead,
    gatewayContractSourceHead: current.gatewayContractSourceHead,
    gatewayContractCanonicalSha256: current.gatewayContractCanonicalSha256,
    gatewayCompatibilityMode: current.gatewayCompatibilityMode,
    gatewayIntentsSubmitSeamSha256:
        gatewayIntentsSubmitSeamSha256 ??
        current.gatewayIntentsSubmitSeamSha256,
    authorityPath: current.authorityPath,
    requiredContractSha256: current.requiredContractSha256,
    nativeLearnerSelfWrite: true,
    nativeLearnerSelfRead: true,
    delegatedHumanAuthority: false,
    axiomHostProfile: false,
    assuranceGraph: false,
    providerObservation: false,
    checkoutFreshness: false,
    localTrustActivation: false,
    releasedArtifactPinsWithoutSubmodule: true,
    gatewayIsOnlyNetworkAuthorityEntry: true,
    directInternalServiceAccessAllowed: false,
    contractPresenceGrantsAuthority: false,
    installationGrantsLearnerDataAccess: false,
    draftsMayPromoteThemselves: false,
    applicationOwnsKernelAuthority: false,
  );
}

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
      compatibilityProfile: const AxiomMeshCompatibilityProfile.current(),
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
      compatibilityProfile: const AxiomMeshCompatibilityProfile.current(),
    );

    expect(binding.requester, isNotNull);
    expect(binding.tokenProvider, isNotNull);
    expect(binding.timeout, AxiomGatewayIntentTransport.defaultTimeout);

    final runtimeType = binding.runtimeType.toString().toLowerCase();
    expect(runtimeType, isNot(contains('store')));
    expect(runtimeType, isNot(contains('origin')));
  });

  test('new unrelated Mesh provenance head does not break runtime binding', () {
    final binding = AxiomEducationGatewayBinding(
      requester: (path, request) async => _successResponse(),
      tokenProvider: () => 'memory-only-token',
      compatibilityProfile: _profile(baselineHead: '0' * 40),
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
  });

  test('mismatched Gateway semantic seam fails closed before any request', () {
    var requests = 0;
    final binding = AxiomEducationGatewayBinding(
      requester: (path, request) async {
        requests++;
        return _successResponse();
      },
      tokenProvider: () => 'memory-only-token',
      compatibilityProfile: _profile(
        gatewayIntentsSubmitSeamSha256: '0' * 64,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        axiomEducationGatewayBindingProvider.overrideWithValue(binding),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(governedEducationRuntimeProvider);
    expect(state, isA<GovernedEducationRuntimeUnbound>());
    expect(
      (state as GovernedEducationRuntimeUnbound).reason,
      contains('semantic seam'),
    );
    expect(requests, 0);
  });
}
