import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/education_model_execution.dart';
import 'package:ontarioedai/core/models/education_model_routing.dart';
import 'package:ontarioedai/features/claw/claw_foundations_preview_screen.dart';
import 'package:ontarioedai/features/claw/claw_foundations_story_arc.dart';

void main() {
  testWidgets('preview materializes only the bounded Socratic context', (
    tester,
  ) async {
    final provider = _RecordingProvider();
    final executor = EducationModelExecutor(
      providersById: <String, EducationModelInferenceProvider>{
        'provider:local-test': provider,
      },
    );
    final requestedAt = DateTime.utc(2026, 9, 2, 12);
    final binding = ClawFoundationsSocraticExecutionBinding(
      executor: executor,
      routeRequest: EducationModelRouteRequest(
        learnerSubjectId: 'learner:test',
        taskClass: EducationModelTaskClass.socraticTutor,
        requiredCapabilities: const <EducationModelCapability>{
          EducationModelCapability.text,
        },
        requestedContextScopes: const <EducationModelContextScope>{
          EducationModelContextScope.targetCompetency,
          EducationModelContextScope.currentLearnerInput,
        },
        retentionClass: 'ephemeral',
        requestedAt: requestedAt,
        budget: const EducationModelBudget(
          maxCalls: 1,
          maxInputUnits: 512,
          maxOutputUnits: 128,
          maxCostMicros: 0,
          maxWallTime: Duration(seconds: 2),
        ),
        localOnly: true,
      ),
      contextGrant: EducationModelContextGrant(
        grantId: 'grant:test:socratic',
        learnerSubjectId: 'learner:test',
        allowedTaskClasses: const <EducationModelTaskClass>{
          EducationModelTaskClass.socraticTutor,
        },
        allowedScopes: const <EducationModelContextScope>{
          EducationModelContextScope.targetCompetency,
          EducationModelContextScope.currentLearnerInput,
        },
        remoteEgressAllowed: false,
        allowedRetentionClasses: const <String>{'ephemeral'},
        issuedAt: requestedAt.subtract(const Duration(minutes: 1)),
        expiresAt: requestedAt.add(const Duration(minutes: 10)),
      ),
      candidates: const <EducationModelCandidate>[
        EducationModelCandidate(
          candidateId: 'candidate:local-test',
          providerId: 'provider:local-test',
          modelId: 'model:test',
          runtimeId: 'runtime:test',
          computeNodeId: 'device:test',
          isLocal: true,
          admitted: true,
          healthy: true,
          capabilities: <EducationModelCapability>{
            EducationModelCapability.text,
          },
          retentionClasses: <String>{'ephemeral'},
          estimatedInputUnits: 128,
          estimatedOutputUnits: 64,
          estimatedCostMicros: 0,
          estimatedLatency: Duration(milliseconds: 50),
          taskQualityScore: 0.8,
          reliabilityScore: 0.9,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: ClawFoundationsPreviewScreen(socraticBinding: binding)),
    );

    await _tap(tester, const ValueKey('claw-continue'));
    await _tap(tester, const ValueKey('claw-socratic-choice'));
    await tester.enterText(
      find.byKey(const ValueKey('claw-socratic-input')),
      'The same amount is split into more equal pieces.',
    );
    await _tap(tester, const ValueKey('claw-socratic-submit'));

    expect(provider.calls, 1);
    expect(
      provider.lastRequest!.materializedContext,
      const <EducationModelContextScope, String>{
        EducationModelContextScope.targetCompetency:
            ClawFoundationsStoryArc.competencyId,
        EducationModelContextScope.currentLearnerInput:
            'The same amount is split into more equal pieces.',
      },
    );
    expect(
      find.text('Can you name the factor used on both numbers?'),
      findsOneWidget,
    );
  });

  testWidgets('preview keeps the model path unavailable without a binding', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClawFoundationsPreviewScreen()),
    );

    await _tap(tester, const ValueKey('claw-continue'));

    expect(find.byKey(const ValueKey('claw-socratic-choice')), findsNothing);
    expect(find.byKey(const ValueKey('claw-another-way')), findsOneWidget);
    expect(find.byKey(const ValueKey('claw-continue')), findsOneWidget);
  });
}

class _RecordingProvider implements EducationModelInferenceProvider {
  int calls = 0;
  EducationModelProviderRequest? lastRequest;

  @override
  Future<EducationModelProviderResult> infer(
    EducationModelProviderRequest request,
  ) async {
    calls += 1;
    lastRequest = request;
    return const EducationModelProviderResult(
      outputText: 'Can you name the factor used on both numbers?',
      inputUnits: 96,
      outputUnits: 12,
      actualCostMicros: 0,
      latency: Duration(milliseconds: 20),
    );
  }
}

Future<void> _tap(WidgetTester tester, ValueKey<String> key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
