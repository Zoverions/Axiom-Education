enum EntryDeviceCapability {
  visualOutput,
  audioOutput,
  touchInput,
  pointerInput,
  keyboardInput,
  microphoneInput,
  cameraInput,
  hapticOutput,
}

enum EntryInteractionKind {
  observeChange,
  singleSelect,
  match,
  sequence,
  gestureOrPointer,
  textResponse,
  spokenResponse,
  cameraObservedResponse,
}

class EntryAssessmentProbe {
  final String probeId;
  final String competencyId;
  final EntryInteractionKind interactionKind;
  final Set<EntryDeviceCapability> requiredCapabilities;
  final int assumptionCost;

  const EntryAssessmentProbe({
    required this.probeId,
    required this.competencyId,
    required this.interactionKind,
    required this.requiredCapabilities,
    required this.assumptionCost,
  }) : assert(assumptionCost >= 0);
}

class EntryAssessmentEnvironment {
  final Set<EntryDeviceCapability> availableCapabilities;
  final Set<EntryDeviceCapability> authorizedCapabilities;

  const EntryAssessmentEnvironment({
    required this.availableCapabilities,
    required this.authorizedCapabilities,
  });

  bool supports(EntryAssessmentProbe probe) {
    return availableCapabilities.containsAll(probe.requiredCapabilities) &&
        authorizedCapabilities.containsAll(probe.requiredCapabilities);
  }
}

class EntryAssessmentPlan {
  final List<EntryAssessmentProbe> probes;
  final int probeBudget;

  const EntryAssessmentPlan({
    required this.probes,
    required this.probeBudget,
  });
}

class EntryAssessmentException implements Exception {
  final String message;

  const EntryAssessmentException(this.message);

  @override
  String toString() => 'EntryAssessmentException: $message';
}

/// Picks the lowest-assumption compatible probes for the requested
/// competencies. Missing hardware or consent causes a probe to be skipped,
/// never scored as learner failure.
class EntryAssessmentSelector {
  const EntryAssessmentSelector();

  EntryAssessmentPlan select({
    required Iterable<String> competencyIds,
    required Iterable<EntryAssessmentProbe> candidates,
    required EntryAssessmentEnvironment environment,
    int probeBudget = 8,
  }) {
    if (probeBudget <= 0) {
      throw const EntryAssessmentException('Probe budget must be positive.');
    }

    final requested = competencyIds.toSet();
    final compatible = candidates
        .where(
          (probe) =>
              requested.contains(probe.competencyId) &&
              environment.supports(probe),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final byCost = a.assumptionCost.compareTo(b.assumptionCost);
        if (byCost != 0) return byCost;
        return a.probeId.compareTo(b.probeId);
      });

    final selected = <EntryAssessmentProbe>[];
    final covered = <String>{};

    for (final probe in compatible) {
      if (selected.length >= probeBudget) break;
      if (covered.add(probe.competencyId)) {
        selected.add(probe);
      }
    }

    if (selected.length < probeBudget) {
      for (final probe in compatible) {
        if (selected.length >= probeBudget) break;
        if (selected.any((item) => item.probeId == probe.probeId)) continue;
        selected.add(probe);
      }
    }

    return EntryAssessmentPlan(
      probes: List<EntryAssessmentProbe>.unmodifiable(selected),
      probeBudget: probeBudget,
    );
  }
}

class EntryProbeResult {
  final String probeId;
  final String competencyId;
  final bool responseObserved;
  final bool deviceFailure;
  final double? evidenceStrength;

  const EntryProbeResult({
    required this.probeId,
    required this.competencyId,
    required this.responseObserved,
    required this.deviceFailure,
    this.evidenceStrength,
  }) : assert(
         evidenceStrength == null ||
             (evidenceStrength >= 0 && evidenceStrength <= 1),
       );

  bool get mayContributeLearnerEvidence =>
      responseObserved && !deviceFailure && evidenceStrength != null;

  bool get mayCountAsNegativeAbilityEvidence => false;
}
