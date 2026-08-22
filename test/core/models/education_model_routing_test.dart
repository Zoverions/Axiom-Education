import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/education_model_routing.dart';

void main() {
  const router = EducationModelRouter();
  const outputBoundary = EducationModelOutputBoundary();
  final now = DateTime.utc(2026, 8, 21, 21);

  const budget = EducationModelBudget(
    maxCalls: 2,
    maxInputUnits: 4000,
    maxOutputUnits: 2000,
    maxCostMicros: 500000,
    maxWallTime: Duration(seconds: 20),
  );

  EducationModelCandidate localCandidate({double quality = 0.8}) =>
      EducationModelCandidate(
        candidateId: 'candidate:local',
        providerId: 'provider:local',
        modelId: 'model:local',
        runtimeId: 'runtime:single-agent',
        computeNodeId: 'node:personal',
        isLocal: true,
        admitted: true,
        healthy: true,
        capabilities: const <EducationModelCapability>{
          EducationModelCapability.text,
          EducationModelCapability.structuredOutput,
        },
        retentionClasses: const <String>{'ephemeral', 'owner-local'},
        estimatedInputUnits: 1000,
        estimatedOutputUnits: 500,
        estimatedCostMicros: 0,
        estimatedLatency: const Duration(seconds: 3),
        taskQualityScore: quality,
        reliabilityScore: 0.95,
      );

  EducationModelCandidate remoteCandidate({double quality = 0.95}) =>
      EducationModelCandidate(
        candidateId: 'candidate:remote',
        providerId: 'provider:remote',
        modelId: 'model:remote',
        runtimeId: 'runtime:single-agent',
        computeNodeId: 'node:managed-api',
        isLocal: false,
        admitted: true,
        healthy: true,
        capabilities: const <EducationModelCapability>{
          EducationModelCapability.text,
          EducationModelCapability.structuredOutput,
        },
        retentionClasses: const <String>{'ephemeral'},
        estimatedInputUnits: 1000,
        estimatedOutputUnits: 500,
        estimatedCostMicros: 120000,
        estimatedLatency: const Duration(seconds: 2),
        taskQualityScore: quality,
        reliabilityScore: 0.98,
      );

  test('remote model is excluded when learner context may not leave local trust boundary', () {
    final grant = EducationModelContextGrant(
      grantId: 'grant:model:1',
      allowedScopes: const <EducationModelContextScope>{
        EducationModelContextScope.targetCompetency,
        EducationModelContextScope.currentLearnerInput,
      },
      remoteEgressAllowed: false,
      allowedRetentionClasses: const <String>{'ephemeral'},
      issuedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(minutes: 10)),
    );

    final decision = router.route(
      request: EducationModelRouteRequest(
        taskClass: EducationModelTaskClass.explainConcept,
        requiredCapabilities: const <EducationModelCapability>{
          EducationModelCapability.text,
        },
        requestedContextScopes: const <EducationModelContextScope>{
          EducationModelContextScope.targetCompetency,
          EducationModelContextScope.currentLearnerInput,
        },
        retentionClass: 'ephemeral',
        requestedAt: now,
        budget: budget,
      ),
      contextGrant: grant,
      candidates: <EducationModelCandidate>[
        remoteCandidate(),
        localCandidate(),
      ],
    );

    expect(decision.allowed, isTrue);
    expect(decision.candidate!.candidateId, equals('candidate:local'));
  });

  test('quality ranking happens only after privacy and budget hard filters', () {
    final grant = EducationModelContextGrant(
      grantId: 'grant:model:2',
      allowedScopes: const <EducationModelContextScope>{
        EducationModelContextScope.targetCompetency,
      },
      remoteEgressAllowed: true,
      allowedRetentionClasses: const <String>{'ephemeral'},
      issuedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(minutes: 10)),
    );

    final overBudgetRemote = EducationModelCandidate(
      candidateId: 'candidate:expensive',
      providerId: 'provider:remote',
      modelId: 'model:expensive',
      runtimeId: 'runtime:single-agent',
      computeNodeId: 'node:managed-api',
      isLocal: false,
      admitted: true,
      healthy: true,
      capabilities: const <EducationModelCapability>{EducationModelCapability.text},
      retentionClasses: const <String>{'ephemeral'},
      estimatedInputUnits: 1000,
      estimatedOutputUnits: 500,
      estimatedCostMicros: 900000,
      estimatedLatency: const Duration(seconds: 2),
      taskQualityScore: 1,
      reliabilityScore: 1,
    );

    final decision = router.route(
      request: EducationModelRouteRequest(
        taskClass: EducationModelTaskClass.socraticTutor,
        requiredCapabilities: const <EducationModelCapability>{
          EducationModelCapability.text,
        },
        requestedContextScopes: const <EducationModelContextScope>{
          EducationModelContextScope.targetCompetency,
        },
        retentionClass: 'ephemeral',
        requestedAt: now,
        budget: budget,
      ),
      contextGrant: grant,
      candidates: <EducationModelCandidate>[
        overBudgetRemote,
        localCandidate(quality: 0.7),
      ],
    );

    expect(decision.candidate!.candidateId, equals('candidate:local'));
  });

  test('router fails closed when requested context exceeds grant', () {
    final grant = EducationModelContextGrant(
      grantId: 'grant:model:3',
      allowedScopes: const <EducationModelContextScope>{
        EducationModelContextScope.targetCompetency,
      },
      remoteEgressAllowed: true,
      allowedRetentionClasses: const <String>{'ephemeral'},
      issuedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(minutes: 10)),
    );

    final decision = router.route(
      request: EducationModelRouteRequest(
        taskClass: EducationModelTaskClass.storyboard,
        requiredCapabilities: const <EducationModelCapability>{
          EducationModelCapability.text,
        },
        requestedContextScopes: const <EducationModelContextScope>{
          EducationModelContextScope.targetCompetency,
          EducationModelContextScope.storyCharacterProfile,
        },
        retentionClass: 'ephemeral',
        requestedAt: now,
        budget: budget,
      ),
      contextGrant: grant,
      candidates: <EducationModelCandidate>[localCandidate()],
    );

    expect(decision.allowed, isFalse);
  });

  test('usage receipt contains accounting metadata but not raw learner content', () {
    const receipt = EducationModelUsageReceipt(
      receiptId: 'receipt:model:1',
      taskClass: EducationModelTaskClass.explainConcept,
      providerId: 'provider:local',
      modelId: 'model:local',
      runtimeId: 'runtime:single-agent',
      computeNodeId: 'node:personal',
      materializedContextScopes: <EducationModelContextScope>{
        EducationModelContextScope.targetCompetency,
      },
      retentionClass: 'owner-local',
      remoteEgressOccurred: false,
      inputUnits: 900,
      outputUnits: 300,
      actualCostMicros: 0,
      latency: Duration(seconds: 2),
    );

    expect(receipt.containsRawPrompt, isFalse);
    expect(receipt.containsRawLearnerResponse, isFalse);
    expect(receipt.establishesMastery, isFalse);
  });

  test('model output cannot create education or governance authority', () {
    expect(outputBoundary.mayCreateGradeOrCredit(), isFalse);
    expect(outputBoundary.mayMintCredential(), isFalse);
    expect(outputBoundary.mayChangeAuthority(), isFalse);
    expect(outputBoundary.mayExpandContextScope(), isFalse);
    expect(outputBoundary.mayRaiseBudget(), isFalse);
    expect(outputBoundary.mayPublishWithoutSeparateAuthority(), isFalse);
    expect(
      outputBoundary.consequentialAssessmentRequiresSeparateVerification(),
      isTrue,
    );
  });
}
