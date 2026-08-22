import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/entry_assessment.dart';

void main() {
  const selector = EntryAssessmentSelector();

  const visualTap = EntryAssessmentProbe(
    probeId: 'probe:pattern:tap',
    competencyId: 'pattern:basic',
    interactionKind: EntryInteractionKind.singleSelect,
    requiredCapabilities: <EntryDeviceCapability>{
      EntryDeviceCapability.visualOutput,
      EntryDeviceCapability.touchInput,
    },
    assumptionCost: 1,
  );

  const spoken = EntryAssessmentProbe(
    probeId: 'probe:pattern:speech',
    competencyId: 'pattern:basic',
    interactionKind: EntryInteractionKind.spokenResponse,
    requiredCapabilities: <EntryDeviceCapability>{
      EntryDeviceCapability.audioOutput,
      EntryDeviceCapability.microphoneInput,
    },
    assumptionCost: 4,
  );

  const camera = EntryAssessmentProbe(
    probeId: 'probe:pattern:camera',
    competencyId: 'pattern:basic',
    interactionKind: EntryInteractionKind.cameraObservedResponse,
    requiredCapabilities: <EntryDeviceCapability>{
      EntryDeviceCapability.visualOutput,
      EntryDeviceCapability.cameraInput,
    },
    assumptionCost: 5,
  );

  test('selector prefers lower-assumption compatible probe', () {
    const environment = EntryAssessmentEnvironment(
      availableCapabilities: <EntryDeviceCapability>{
        EntryDeviceCapability.visualOutput,
        EntryDeviceCapability.touchInput,
        EntryDeviceCapability.audioOutput,
        EntryDeviceCapability.microphoneInput,
      },
      authorizedCapabilities: <EntryDeviceCapability>{
        EntryDeviceCapability.visualOutput,
        EntryDeviceCapability.touchInput,
        EntryDeviceCapability.audioOutput,
        EntryDeviceCapability.microphoneInput,
      },
    );

    final plan = selector.select(
      competencyIds: const <String>['pattern:basic'],
      candidates: const <EntryAssessmentProbe>[spoken, visualTap],
      environment: environment,
      probeBudget: 1,
    );

    expect(plan.probes.single.probeId, equals('probe:pattern:tap'));
  });

  test('camera probe is skipped when camera is unavailable', () {
    const environment = EntryAssessmentEnvironment(
      availableCapabilities: <EntryDeviceCapability>{
        EntryDeviceCapability.visualOutput,
        EntryDeviceCapability.touchInput,
      },
      authorizedCapabilities: <EntryDeviceCapability>{
        EntryDeviceCapability.visualOutput,
        EntryDeviceCapability.touchInput,
      },
    );

    final plan = selector.select(
      competencyIds: const <String>['pattern:basic'],
      candidates: const <EntryAssessmentProbe>[camera, visualTap],
      environment: environment,
      probeBudget: 2,
    );

    expect(
      plan.probes.map((probe) => probe.probeId),
      equals(<String>['probe:pattern:tap']),
    );
  });

  test('available sensor is still skipped without authorization', () {
    const environment = EntryAssessmentEnvironment(
      availableCapabilities: <EntryDeviceCapability>{
        EntryDeviceCapability.visualOutput,
        EntryDeviceCapability.cameraInput,
      },
      authorizedCapabilities: <EntryDeviceCapability>{
        EntryDeviceCapability.visualOutput,
      },
    );

    final plan = selector.select(
      competencyIds: const <String>['pattern:basic'],
      candidates: const <EntryAssessmentProbe>[camera],
      environment: environment,
    );

    expect(plan.probes, isEmpty);
  });

  test('device failure or non-response is not negative ability evidence', () {
    const deviceFailure = EntryProbeResult(
      probeId: 'probe:1',
      competencyId: 'pattern:basic',
      responseObserved: false,
      deviceFailure: true,
    );
    const noResponse = EntryProbeResult(
      probeId: 'probe:2',
      competencyId: 'pattern:basic',
      responseObserved: false,
      deviceFailure: false,
    );

    expect(deviceFailure.mayContributeLearnerEvidence, isFalse);
    expect(deviceFailure.mayCountAsNegativeAbilityEvidence, isFalse);
    expect(noResponse.mayContributeLearnerEvidence, isFalse);
    expect(noResponse.mayCountAsNegativeAbilityEvidence, isFalse);
  });
}
