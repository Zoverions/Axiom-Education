import 'education_model_routing.dart';

abstract class EducationModelInferenceProvider {
  Future<EducationModelProviderResult> infer(
    EducationModelProviderRequest request,
  );
}

class EducationModelProviderRequest {
  final EducationModelCandidate candidate;
  final String learnerSubjectId;
  final EducationModelTaskClass taskClass;
  final Map<EducationModelContextScope, String> materializedContext;
  final String retentionClass;
  final EducationModelBudget budget;

  EducationModelProviderRequest({
    required this.candidate,
    required this.learnerSubjectId,
    required this.taskClass,
    required Map<EducationModelContextScope, String> materializedContext,
    required this.retentionClass,
    required this.budget,
  }) : materializedContext =
           Map<EducationModelContextScope, String>.unmodifiable(
             materializedContext,
           );
}

class EducationModelProviderResult {
  final String outputText;
  final int inputUnits;
  final int outputUnits;
  final int actualCostMicros;
  final Duration latency;

  const EducationModelProviderResult({
    required this.outputText,
    required this.inputUnits,
    required this.outputUnits,
    required this.actualCostMicros,
    required this.latency,
  });
}

class EducationModelExecutionResult {
  final String? outputText;
  final EducationModelUsageReceipt? usageReceipt;
  final String? failureReason;

  const EducationModelExecutionResult._({
    this.outputText,
    this.usageReceipt,
    this.failureReason,
  });

  factory EducationModelExecutionResult.success({
    required String outputText,
    required EducationModelUsageReceipt usageReceipt,
  }) {
    return EducationModelExecutionResult._(
      outputText: outputText,
      usageReceipt: usageReceipt,
    );
  }

  factory EducationModelExecutionResult.failure(String reason) {
    return EducationModelExecutionResult._(failureReason: reason);
  }

  bool get succeeded =>
      failureReason == null && outputText != null && usageReceipt != null;
}

class EducationModelExecutor {
  final EducationModelRouter router;
  final Map<String, EducationModelInferenceProvider> providersById;

  EducationModelExecutor({
    EducationModelRouter router = const EducationModelRouter(),
    required Map<String, EducationModelInferenceProvider> providersById,
  }) : router = router,
       providersById = Map<String, EducationModelInferenceProvider>.unmodifiable(
         providersById,
       );

  Future<EducationModelExecutionResult> execute({
    required EducationModelRouteRequest request,
    required EducationModelContextGrant contextGrant,
    required List<EducationModelCandidate> candidates,
    required Map<EducationModelContextScope, String> materializedContext,
  }) async {
    final undeclaredScopes = materializedContext.keys
        .where((scope) => !request.requestedContextScopes.contains(scope))
        .toList(growable: false);
    if (undeclaredScopes.isNotEmpty) {
      return EducationModelExecutionResult.failure(
        'Materialized context contains an undeclared context scope.',
      );
    }

    final routeDecision = router.route(
      request: request,
      contextGrant: contextGrant,
      candidates: candidates,
    );
    if (!routeDecision.allowed || routeDecision.candidate == null) {
      return EducationModelExecutionResult.failure(
        routeDecision.reason ?? 'model-route-denied',
      );
    }

    final candidate = routeDecision.candidate!;
    final provider = providersById[candidate.providerId];
    if (provider == null) {
      return EducationModelExecutionResult.failure(
        'selected-provider-unavailable',
      );
    }

    EducationModelProviderResult providerResult;
    try {
      providerResult = await provider.infer(
        EducationModelProviderRequest(
          candidate: candidate,
          learnerSubjectId: request.learnerSubjectId,
          taskClass: request.taskClass,
          materializedContext: materializedContext,
          retentionClass: request.retentionClass,
          budget: request.budget,
        ),
      );
    } catch (_) {
      return EducationModelExecutionResult.failure('provider-failure');
    }

    if (!_providerResultWithinBudget(providerResult, request.budget)) {
      return EducationModelExecutionResult.failure('provider-budget-exceeded');
    }
    if (providerResult.outputText.trim().isEmpty) {
      return EducationModelExecutionResult.failure('provider-output-empty');
    }

    final usageReceipt = EducationModelUsageReceipt(
      receiptId: _receiptId(
        contextGrant: contextGrant,
        candidate: candidate,
        request: request,
      ),
      learnerSubjectId: request.learnerSubjectId,
      taskClass: request.taskClass,
      providerId: candidate.providerId,
      modelId: candidate.modelId,
      runtimeId: candidate.runtimeId,
      computeNodeId: candidate.computeNodeId,
      materializedContextScopes: Set<EducationModelContextScope>.unmodifiable(
        materializedContext.keys,
      ),
      retentionClass: request.retentionClass,
      remoteEgressOccurred: !candidate.isLocal,
      inputUnits: providerResult.inputUnits,
      outputUnits: providerResult.outputUnits,
      actualCostMicros: providerResult.actualCostMicros,
      latency: providerResult.latency,
    );

    return EducationModelExecutionResult.success(
      outputText: providerResult.outputText,
      usageReceipt: usageReceipt,
    );
  }

  bool _providerResultWithinBudget(
    EducationModelProviderResult result,
    EducationModelBudget budget,
  ) {
    if (result.inputUnits < 0 ||
        result.outputUnits < 0 ||
        result.actualCostMicros < 0 ||
        result.latency.isNegative) {
      return false;
    }
    if (result.inputUnits > budget.maxInputUnits ||
        result.outputUnits > budget.maxOutputUnits ||
        result.actualCostMicros > budget.maxCostMicros ||
        result.latency > budget.maxWallTime) {
      return false;
    }
    return true;
  }

  String _receiptId({
    required EducationModelContextGrant contextGrant,
    required EducationModelCandidate candidate,
    required EducationModelRouteRequest request,
  }) {
    return 'usage:${contextGrant.grantId}:${candidate.candidateId}:${request.requestedAt.toUtc().microsecondsSinceEpoch}';
  }
}
