import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/education_model_execution.dart';
import 'package:ontarioedai/core/models/education_model_routing.dart';

void main() {
  final now = DateTime.utc(2026, 9, 1, 23);

  const budget = EducationModelBudget(
    maxCalls: 1,
    maxInputUnits: 1000,
    maxOutputUnits: 500,
    maxCostMicros: 100000,
    maxWallTime: Duration(seconds: 10),
  );

  EducationModelContextGrant grant({
    String learnerSubjectId = 'learner:1',
    bool remoteEgressAllowed = false,
    Set<EducationModelTaskClass> tasks = const <EducationModelTaskClass>{
      EducationModelTaskClass.socraticTutor,
    },
    Set<EducationModelContextScope> scopes = const <EducationModelContextScope>{
      EducationModelContextScope.targetCompetency,
      EducationModelContextScope.currentLearnerInput,
    },
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) => EducationModelContextGrant(
    grantId: 'grant:socratic:1',
    learnerSubjectId: learnerSubjectId,
    allowedTaskClasses: tasks,
    allowedScopes: scopes,
    remoteEgressAllowed: remoteEgressAllowed,
    allowedRetentionClasses: const <String>{'ephemeral'},
    issuedAt: issuedAt ?? now.subtract(const Duration(minutes: 1)),
    expiresAt: expiresAt ?? now.add(const Duration(minutes: 10)),
  );

  EducationModelRouteRequest request({
    String learnerSubjectId = 'learner:1',
    Set<EducationModelContextScope> scopes = const <EducationModelContextScope>{
      EducationModelContextScope.targetCompetency,
      EducationModelContextScope.currentLearnerInput,
    },
  }) => EducationModelRouteRequest(
    learnerSubjectId: learnerSubjectId,
    taskClass: EducationModelTaskClass.socraticTutor,
    requiredCapabilities: const <EducationModelCapability>{
      EducationModelCapability.text,
    },
    requestedContextScopes: scopes,
    retentionClass: 'ephemeral',
    requestedAt: now,
    budget: budget,
  );

  EducationModelCandidate localCandidate({
    int estimatedCostMicros = 0,
  }) => EducationModelCandidate(
    candidateId: 'candidate:local',
    providerId: 'provider:local',
    modelId: 'model:local',
    runtimeId: 'runtime:test',
    computeNodeId: 'node:personal',
    isLocal: true,
    admitted: true,
    healthy: true,
    capabilities: const <EducationModelCapability>{EducationModelCapability.text},
    retentionClasses: const <String>{'ephemeral'},
    estimatedInputUnits: 100,
    estimatedOutputUnits: 100,
    estimatedCostMicros: estimatedCostMicros,
    estimatedLatency: const Duration(seconds: 1),
    taskQualityScore: 0.8,
    reliabilityScore: 0.9,
  );

  EducationModelCandidate remoteCandidate() => EducationModelCandidate(
    candidateId: 'candidate:remote',
    providerId: 'provider:remote',
    modelId: 'model:remote',
    runtimeId: 'runtime:test',
    computeNodeId: 'node:remote',
    isLocal: false,
    admitted: true,
    healthy: true,
    capabilities: const <EducationModelCapability>{EducationModelCapability.text},
    retentionClasses: const <String>{'ephemeral'},
    estimatedInputUnits: 100,
    estimatedOutputUnits: 100,
    estimatedCostMicros: 1000,
    estimatedLatency: const Duration(seconds: 1),
    taskQualityScore: 0.9,
    reliabilityScore: 0.9,
  );

  Map<EducationModelContextScope, String> context() =>
      const <EducationModelContextScope, String>{
        EducationModelContextScope.targetCompetency:
            'math:fractions:equivalence',
        EducationModelContextScope.currentLearnerInput:
            'I think they are equal because both are half.',
      };

  test('route denial causes zero provider calls', () async {
    final provider = _RecordingProvider();
    final executor = EducationModelExecutor(
      providersById: <String, EducationModelInferenceProvider>{
        'provider:local': provider,
      },
    );

    final result = await executor.execute(
      request: request(learnerSubjectId: 'learner:2'),
      contextGrant: grant(learnerSubjectId: 'learner:1'),
      candidates: <EducationModelCandidate>[localCandidate()],
      materializedContext: context(),
    );

    expect(result.succeeded, isFalse);
    expect(result.failureReason, contains('different learner subject'));
    expect(provider.calls, equals(0));
  });

  test('remote-egress denial causes zero provider calls', () async {
    final provider = _RecordingProvider();
    final executor = EducationModelExecutor(
      providersById: <String, EducationModelInferenceProvider>{
        'provider:remote': provider,
      },
    );

    final result = await executor.execute(
      request: request(),
      contextGrant: grant(remoteEgressAllowed: false),
      candidates: <EducationModelCandidate>[remoteCandidate()],
      materializedContext: context(),
    );

    expect(result.succeeded, isFalse);
    expect(result.failureReason, contains('No admitted model'));
    expect(provider.calls, equals(0));
  });

  test('over-budget candidate causes zero provider calls', () async {
    final provider = _RecordingProvider();
    final executor = EducationModelExecutor(
      providersById: <String, EducationModelInferenceProvider>{
        'provider:local': provider,
      },
    );

    final result = await executor.execute(
      request: request(),
      contextGrant: grant(),
      candidates: <EducationModelCandidate>[
        localCandidate(estimatedCostMicros: 100001),
      ],
      materializedContext: context(),
    );

    expect(result.succeeded, isFalse);
    expect(provider.calls, equals(0));
  });

  test('undeclared materialized context fails before provider invocation', () async {
    final provider = _RecordingProvider();
    final executor = EducationModelExecutor(
      providersById: <String, EducationModelInferenceProvider>{
        'provider:local': provider,
      },
    );

    final materialized = <EducationModelContextScope, String>{
      ...context(),
      EducationModelContextScope.storyCharacterProfile: 'Professor Zov',
    };

    final result = await executor.execute(
      request: request(),
      contextGrant: grant(),
      candidates: <EducationModelCandidate>[localCandidate()],
      materializedContext: materialized,
    );

    expect(result.succeeded, isFalse);
    expect(result.failureReason, contains('undeclared context scope'));
    expect(provider.calls, equals(0));
  });

  test('successful route invokes only selected provider and returns minimized receipt', () async {
    final provider = _RecordingProvider(
      result: const EducationModelProviderResult(
        outputText: 'What stayed the same when both numbers doubled?',
        inputUnits: 48,
        outputUnits: 12,
        actualCostMicros: 0,
        latency: Duration(milliseconds: 40),
      ),
    );
    final executor = EducationModelExecutor(
      providersById: <String, EducationModelInferenceProvider>{
        'provider:local': provider,
      },
    );

    final result = await executor.execute(
      request: request(),
      contextGrant: grant(),
      candidates: <EducationModelCandidate>[localCandidate()],
      materializedContext: context(),
    );

    expect(result.succeeded, isTrue);
    expect(provider.calls, equals(1));
    expect(provider.lastRequest!.candidate.candidateId, 'candidate:local');
    expect(
      result.outputText,
      'What stayed the same when both numbers doubled?',
    );
    expect(result.usageReceipt, isNotNull);
    expect(result.usageReceipt!.containsRawPrompt, isFalse);
    expect(result.usageReceipt!.containsRawLearnerResponse, isFalse);
    expect(result.usageReceipt!.establishesMastery, isFalse);
    expect(
      result.usageReceipt!.materializedContextScopes,
      equals(request().requestedContextScopes),
    );
  });

  test('provider exception is explicit failure with no retry', () async {
    final provider = _RecordingProvider(throwOnInfer: true);
    final executor = EducationModelExecutor(
      providersById: <String, EducationModelInferenceProvider>{
        'provider:local': provider,
      },
    );

    final result = await executor.execute(
      request: request(),
      contextGrant: grant(),
      candidates: <EducationModelCandidate>[localCandidate()],
      materializedContext: context(),
    );

    expect(result.succeeded, isFalse);
    expect(result.failureReason, equals('provider-failure'));
    expect(provider.calls, equals(1));
    expect(result.usageReceipt, isNull);
  });
}

class _RecordingProvider implements EducationModelInferenceProvider {
  int calls = 0;
  EducationModelProviderRequest? lastRequest;
  final EducationModelProviderResult result;
  final bool throwOnInfer;

  _RecordingProvider({
    this.result = const EducationModelProviderResult(
      outputText: 'Follow-up question',
      inputUnits: 10,
      outputUnits: 5,
      actualCostMicros: 0,
      latency: Duration(milliseconds: 10),
    ),
    this.throwOnInfer = false,
  });

  @override
  Future<EducationModelProviderResult> infer(
    EducationModelProviderRequest request,
  ) async {
    calls += 1;
    lastRequest = request;
    if (throwOnInfer) {
      throw StateError('provider failed');
    }
    return result;
  }
}
