import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../axiom/education_client.dart';
import '../axiom/educator_workflow_runtime.dart';
import '../axiom/gateway_intent_transport.dart';
import '../axiom/learner_progress_runtime.dart';

/// Reviewed host-shell binding for the Axiom Education -> AXIOM Gateway seam.
///
/// Axiom Education deliberately does not invent a Gateway origin, loopback port,
/// bearer-token store, or local learner-record fallback. A reviewed web/desktop/
/// mobile host must provide a requester that resolves only the relative `/v1/...`
/// targets emitted by [AxiomGatewayIntentTransport], plus a memory-only token
/// provider appropriate to that host.
class AxiomEducationGatewayBinding {
  final AxiomGatewayRelativeRequester requester;
  final AxiomGatewayTokenProvider tokenProvider;
  final Duration timeout;

  const AxiomEducationGatewayBinding({
    required this.requester,
    required this.tokenProvider,
    this.timeout = AxiomGatewayIntentTransport.defaultTimeout,
  });
}

/// Host override point. The repository default is intentionally unbound.
final axiomEducationGatewayBindingProvider =
    Provider<AxiomEducationGatewayBinding?>((ref) => null);

sealed class GovernedEducationRuntimeState {
  const GovernedEducationRuntimeState();

  bool get isBound;
}

/// No reviewed AXIOM ingress has been supplied by the current host.
///
/// This is an explicit unavailable state, not permission to persist learner
/// progress in Hive or synthesize a successful learner-record operation.
class GovernedEducationRuntimeUnbound extends GovernedEducationRuntimeState {
  final String reason;

  const GovernedEducationRuntimeUnbound({
    this.reason = 'No reviewed AXIOM Gateway host binding is configured.',
  });

  @override
  bool get isBound => false;
}

/// Bound services still depend on AXIOM policy, consent, authority, and provider
/// availability for each operation. Being bound does not mean an operation will
/// be allowed or persisted.
class GovernedEducationRuntimeBound extends GovernedEducationRuntimeState {
  final AxiomEducationClient client;
  final GovernedLearnerEventWriter learnerEventWriter;
  final GovernedLearnerProgressReader learnerProgressReader;

  const GovernedEducationRuntimeBound({
    required this.client,
    required this.learnerEventWriter,
    required this.learnerProgressReader,
  });

  @override
  bool get isBound => true;
}

final governedEducationRuntimeProvider = Provider<GovernedEducationRuntimeState>((
  ref,
) {
  final binding = ref.watch(axiomEducationGatewayBindingProvider);
  if (binding == null) return const GovernedEducationRuntimeUnbound();

  final transport = AxiomGatewayIntentTransport(
    requester: binding.requester,
    tokenProvider: binding.tokenProvider,
    timeout: binding.timeout,
  );
  final client = AxiomEducationClient(
    transport: transport,
    idempotencyKeyFactory: () {
      throw const AxiomEducationValidationException(
        message:
            'Governed education operations must supply deterministic idempotency keys.',
      );
    },
  );
  return GovernedEducationRuntimeBound(
    client: client,
    learnerEventWriter: GovernedLearnerEventWriter(client: client),
    learnerProgressReader: GovernedLearnerProgressReader(client: client),
  );
});
