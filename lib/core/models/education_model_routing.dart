enum EducationModelTaskClass {
  explainConcept,
  socraticTutor,
  generatePractice,
  evaluatePracticeDraft,
  storyboard,
  gameOrSimulationPlan,
  resourceSummary,
  translation,
  accessibilityTransform,
  collaborationAssist,
}

enum EducationModelCapability {
  text,
  image,
  audio,
  structuredOutput,
  code,
}

enum EducationModelContextScope {
  targetCompetency,
  currentLearnerInput,
  assignmentContext,
  resourceContext,
  recentPedagogicalFeedback,
  misconceptionSummary,
  accessibilityRequirements,
  languagePreference,
  storyCharacterProfile,
}

class EducationModelContextGrant {
  final String grantId;
  final Set<EducationModelContextScope> allowedScopes;
  final bool remoteEgressAllowed;
  final Set<String> allowedRetentionClasses;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const EducationModelContextGrant({
    required this.grantId,
    required this.allowedScopes,
    required this.remoteEgressAllowed,
    required this.allowedRetentionClasses,
    required this.issuedAt,
    required this.expiresAt,
  });

  bool isCurrentAt(DateTime at) =>
      !at.isBefore(issuedAt) && at.isBefore(expiresAt);
}

class EducationModelBudget {
  final int maxCalls;
  final int maxInputUnits;
  final int maxOutputUnits;
  final int maxCostMicros;
  final Duration maxWallTime;

  const EducationModelBudget({
    required this.maxCalls,
    required this.maxInputUnits,
    required this.maxOutputUnits,
    required this.maxCostMicros,
    required this.maxWallTime,
  }) : assert(maxCalls >= 0),
       assert(maxInputUnits >= 0),
       assert(maxOutputUnits >= 0),
       assert(maxCostMicros >= 0);
}

class EducationModelCandidate {
  final String candidateId;
  final String providerId;
  final String modelId;
  final String runtimeId;
  final String computeNodeId;
  final bool isLocal;
  final bool admitted;
  final bool healthy;
  final Set<EducationModelCapability> capabilities;
  final Set<String> retentionClasses;
  final int estimatedInputUnits;
  final int estimatedOutputUnits;
  final int estimatedCostMicros;
  final Duration estimatedLatency;
  final double taskQualityScore;
  final double reliabilityScore;

  const EducationModelCandidate({
    required this.candidateId,
    required this.providerId,
    required this.modelId,
    required this.runtimeId,
    required this.computeNodeId,
    required this.isLocal,
    required this.admitted,
    required this.healthy,
    required this.capabilities,
    required this.retentionClasses,
    required this.estimatedInputUnits,
    required this.estimatedOutputUnits,
    required this.estimatedCostMicros,
    required this.estimatedLatency,
    required this.taskQualityScore,
    required this.reliabilityScore,
  }) : assert(estimatedInputUnits >= 0),
       assert(estimatedOutputUnits >= 0),
       assert(estimatedCostMicros >= 0),
       assert(taskQualityScore >= 0 && taskQualityScore <= 1),
       assert(reliabilityScore >= 0 && reliabilityScore <= 1);
}

class EducationModelRouteRequest {
  final EducationModelTaskClass taskClass;
  final Set<EducationModelCapability> requiredCapabilities;
  final Set<EducationModelContextScope> requestedContextScopes;
  final String retentionClass;
  final DateTime requestedAt;
  final EducationModelBudget budget;
  final bool localOnly;

  const EducationModelRouteRequest({
    required this.taskClass,
    required this.requiredCapabilities,
    required this.requestedContextScopes,
    required this.retentionClass,
    required this.requestedAt,
    required this.budget,
    this.localOnly = false,
  });
}

class EducationModelRouteDecision {
  final EducationModelCandidate? candidate;
  final String reason;

  const EducationModelRouteDecision._({
    required this.candidate,
    required this.reason,
  });

  const EducationModelRouteDecision.selected(EducationModelCandidate candidate)
      : this._(candidate: candidate, reason: 'eligible-candidate-selected');

  const EducationModelRouteDecision.denied(String reason)
      : this._(candidate: null, reason: reason);

  bool get allowed => candidate != null;
}

class EducationModelRouter {
  const EducationModelRouter();

  EducationModelRouteDecision route({
    required EducationModelRouteRequest request,
    required EducationModelContextGrant contextGrant,
    required Iterable<EducationModelCandidate> candidates,
  }) {
    if (!contextGrant.isCurrentAt(request.requestedAt)) {
      return const EducationModelRouteDecision.denied(
        'Model context grant is expired or not yet active.',
      );
    }
    if (!contextGrant.allowedScopes.containsAll(request.requestedContextScopes)) {
      return const EducationModelRouteDecision.denied(
        'Requested learner context exceeds the granted data scope.',
      );
    }
    if (!contextGrant.allowedRetentionClasses.contains(request.retentionClass)) {
      return const EducationModelRouteDecision.denied(
        'Requested retention class is not authorized.',
      );
    }

    final eligible = candidates.where((candidate) {
      if (!candidate.admitted || !candidate.healthy) return false;
      if (request.localOnly && !candidate.isLocal) return false;
      if (!candidate.isLocal && !contextGrant.remoteEgressAllowed) return false;
      if (!candidate.capabilities.containsAll(request.requiredCapabilities)) {
        return false;
      }
      if (!candidate.retentionClasses.contains(request.retentionClass)) {
        return false;
      }
      if (candidate.estimatedInputUnits > request.budget.maxInputUnits) {
        return false;
      }
      if (candidate.estimatedOutputUnits > request.budget.maxOutputUnits) {
        return false;
      }
      if (candidate.estimatedCostMicros > request.budget.maxCostMicros) {
        return false;
      }
      if (candidate.estimatedLatency > request.budget.maxWallTime) return false;
      if (request.budget.maxCalls < 1) return false;
      return true;
    }).toList(growable: false);

    if (eligible.isEmpty) {
      return const EducationModelRouteDecision.denied(
        'No admitted model satisfies policy, context, capability, retention, and budget constraints.',
      );
    }

    eligible.sort((a, b) {
      final quality = b.taskQualityScore.compareTo(a.taskQualityScore);
      if (quality != 0) return quality;
      final reliability = b.reliabilityScore.compareTo(a.reliabilityScore);
      if (reliability != 0) return reliability;
      final cost = a.estimatedCostMicros.compareTo(b.estimatedCostMicros);
      if (cost != 0) return cost;
      final latency = a.estimatedLatency.compareTo(b.estimatedLatency);
      if (latency != 0) return latency;
      return a.candidateId.compareTo(b.candidateId);
    });

    return EducationModelRouteDecision.selected(eligible.first);
  }
}

class EducationModelUsageReceipt {
  final String receiptId;
  final EducationModelTaskClass taskClass;
  final String providerId;
  final String modelId;
  final String runtimeId;
  final String computeNodeId;
  final Set<EducationModelContextScope> materializedContextScopes;
  final String retentionClass;
  final bool remoteEgressOccurred;
  final int inputUnits;
  final int outputUnits;
  final int actualCostMicros;
  final Duration latency;
  final String? fallbackReason;

  const EducationModelUsageReceipt({
    required this.receiptId,
    required this.taskClass,
    required this.providerId,
    required this.modelId,
    required this.runtimeId,
    required this.computeNodeId,
    required this.materializedContextScopes,
    required this.retentionClass,
    required this.remoteEgressOccurred,
    required this.inputUnits,
    required this.outputUnits,
    required this.actualCostMicros,
    required this.latency,
    this.fallbackReason,
  });

  bool get containsRawPrompt => false;

  bool get containsRawLearnerResponse => false;

  bool get establishesMastery => false;
}

class EducationModelOutputBoundary {
  const EducationModelOutputBoundary();

  bool mayCreateGradeOrCredit() => false;

  bool mayMintCredential() => false;

  bool mayChangeAuthority() => false;

  bool mayExpandContextScope() => false;

  bool mayRaiseBudget() => false;

  bool mayPublishWithoutSeparateAuthority() => false;

  bool consequentialAssessmentRequiresSeparateVerification() => true;
}
