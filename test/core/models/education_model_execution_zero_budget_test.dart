import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/education_model_execution.dart';
import 'package:ontarioedai/core/models/education_model_routing.dart';

void main() {
  test('zero wall-time budget fails before provider invocation', () async {
    final now = DateTime.utc(2026, 9, 18, 4, 30);
    final provider = _RecordingProvider();
    final executor = EducationModelExecutor(
      now: () => now,
      providersById: <String, EducationModelInferenceProvider>{
        'provider:local': provider,
      },
    );

    const budget = EducationModelBudget(
      maxCalls: 1,
      maxInputUnits: 100,
      maxOutputUnits: 100,
      maxCostMicros: 0,
      maxWallTime: Duration.zero,
    );
    final request = EducationModelRouteRequest(
      learnerSubjectId: 'learner:zero-budget',
      taskClass: EducationModelTaskClass.socraticTutor,
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
      localOnly: true,
    );
    final grant = EducationModelContextGrant(
      grantId: 'grant:zero-budget',
      learnerSubjectId: 'learner:zero-budget',
      allowedTaskClasses: const <EducationModelTaskClass>{
        EducationModelTaskClass.socraticTutor,
      },
      allowedScopes: request.requestedContextScopes,
      remoteEgressAllowed: false,
      allowedRetentionClasses: const <String>{'ephemeral'},
      issuedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(minutes: 1)),
    );
    const candidate = EducationModelCandidate(
      candidateId: 'candidate:local-zero-budget',
      providerId: 'provider:local',
      modelId: 'model:local',
      modelArtifactDigest: 'sha256:model-local-zero-budget',
      runtimeId: 'runtime:test',
      computeNodeId: 'node:local',
      isLocal: true,
      admitted: true,
      healthy: true,
      capabilities: <EducationModelCapability>{EducationModelCapability.text},
      retentionClasses: <String>{'ephemeral'},
      estimatedInputUnits: 0,
      estimatedOutputUnits: 0,
      estimatedCostMicros: 0,
      estimatedLatency: Duration.zero,
      taskQualityScore: 0.8,
      reliabilityScore: 0.9,
    );
    const provenance = EducationModelResponseProvenance(
      promptContractVersion: 'claw-socratic-prompt.v1',
      curriculumPackDigest: 'sha256:curriculum-pack-test',
      sourceExpectationIds: <String>{'math:fractions:equivalence'},
      verifierState: 'not-required-instructional',
    );

    final result = await executor.execute(
      request: request,
      contextGrant: grant,
      candidates: const <EducationModelCandidate>[candidate],
      materializedContext: const <EducationModelContextScope, String>{
        EducationModelContextScope.targetCompetency:
            'math:fractions:equivalence',
        EducationModelContextScope.currentLearnerInput: 'They are equal.',
      },
      provenance: provenance,
    );

    expect(result.succeeded, isFalse);
    expect(result.failureReason, equals('provider-timeout'));
    expect(provider.calls, equals(0));
  });
}

class _RecordingProvider implements EducationModelInferenceProvider {
  int calls = 0;

  @override
  Future<EducationModelProviderResult> infer(
    EducationModelProviderRequest request,
  ) async {
    calls += 1;
    return const EducationModelProviderResult(
      outputText: 'unused',
      inputUnits: 0,
      outputUnits: 0,
      actualCostMicros: 0,
      latency: Duration.zero,
    );
  }
}
