enum InstructionalEvidenceLevel {
  officialOrStandardsFramework,
  systematicReviewOrMetaAnalysis,
  randomizedControlledTrial,
  strongQuasiExperimentalOrReplicatedFieldEvidence,
  observationalOrImplementationEvidence,
  localGovernedEvaluation,
  pilotOrExploratoryEvidence,
  hypothesisOrUnverifiedDesign,
}

extension InstructionalEvidenceLevelWire on InstructionalEvidenceLevel {
  String get wireName => switch (this) {
    InstructionalEvidenceLevel.officialOrStandardsFramework =>
      'official-or-standards-framework',
    InstructionalEvidenceLevel.systematicReviewOrMetaAnalysis =>
      'systematic-review-or-meta-analysis',
    InstructionalEvidenceLevel.randomizedControlledTrial =>
      'randomized-controlled-trial',
    InstructionalEvidenceLevel.strongQuasiExperimentalOrReplicatedFieldEvidence =>
      'strong-quasi-experimental-or-replicated-field-evidence',
    InstructionalEvidenceLevel.observationalOrImplementationEvidence =>
      'observational-or-implementation-evidence',
    InstructionalEvidenceLevel.localGovernedEvaluation =>
      'local-governed-evaluation',
    InstructionalEvidenceLevel.pilotOrExploratoryEvidence =>
      'pilot-or-exploratory-evidence',
    InstructionalEvidenceLevel.hypothesisOrUnverifiedDesign =>
      'hypothesis-or-unverified-design',
  };
}

enum InstructionalStrategyKind {
  explicitExplanation,
  directInstruction,
  workedExample,
  guidedPractice,
  independentPractice,
  retrievalWithFeedback,
  spacedReview,
  interleaving,
  multipleRepresentations,
  socraticQuestioning,
  selfExplanation,
  metacognitionAndSelfRegulation,
  masteryOrientedPacing,
  peerExplanation,
  peerTutoring,
  smallGroupTutoring,
  oneToOneTutoring,
  projectBasedLearning,
  problemBasedLearning,
  phenomenonBasedLearning,
  simulation,
  storyOrComic,
  gameBasedChallenge,
  creativeConstruction,
  authenticRealWorldTask,
  humanEducatorEscalation,
  aiTutoring,
  humanAiCopilot,
}

extension InstructionalStrategyKindWire on InstructionalStrategyKind {
  String get wireName => switch (this) {
    InstructionalStrategyKind.explicitExplanation => 'explicit-explanation',
    InstructionalStrategyKind.directInstruction => 'direct-instruction',
    InstructionalStrategyKind.workedExample => 'worked-example',
    InstructionalStrategyKind.guidedPractice => 'guided-practice',
    InstructionalStrategyKind.independentPractice => 'independent-practice',
    InstructionalStrategyKind.retrievalWithFeedback => 'retrieval-with-feedback',
    InstructionalStrategyKind.spacedReview => 'spaced-review',
    InstructionalStrategyKind.interleaving => 'interleaving',
    InstructionalStrategyKind.multipleRepresentations =>
      'multiple-representations',
    InstructionalStrategyKind.socraticQuestioning => 'socratic-questioning',
    InstructionalStrategyKind.selfExplanation => 'self-explanation',
    InstructionalStrategyKind.metacognitionAndSelfRegulation =>
      'metacognition-and-self-regulation',
    InstructionalStrategyKind.masteryOrientedPacing => 'mastery-oriented-pacing',
    InstructionalStrategyKind.peerExplanation => 'peer-explanation',
    InstructionalStrategyKind.peerTutoring => 'peer-tutoring',
    InstructionalStrategyKind.smallGroupTutoring => 'small-group-tutoring',
    InstructionalStrategyKind.oneToOneTutoring => 'one-to-one-tutoring',
    InstructionalStrategyKind.projectBasedLearning => 'project-based-learning',
    InstructionalStrategyKind.problemBasedLearning => 'problem-based-learning',
    InstructionalStrategyKind.phenomenonBasedLearning =>
      'phenomenon-based-learning',
    InstructionalStrategyKind.simulation => 'simulation',
    InstructionalStrategyKind.storyOrComic => 'story-or-comic',
    InstructionalStrategyKind.gameBasedChallenge => 'game-based-challenge',
    InstructionalStrategyKind.creativeConstruction => 'creative-construction',
    InstructionalStrategyKind.authenticRealWorldTask =>
      'authentic-real-world-task',
    InstructionalStrategyKind.humanEducatorEscalation =>
      'human-educator-escalation',
    InstructionalStrategyKind.aiTutoring => 'ai-tutoring',
    InstructionalStrategyKind.humanAiCopilot => 'human-ai-copilot',
  };
}

enum InstructionalOutcomeMetric {
  learningGain,
  delayedRetention,
  transferOrGeneralization,
  misconceptionRecovery,
  timeToDemonstratedCriterion,
  robustnessAcrossRepresentations,
  calibration,
  helpSeekingEffectiveness,
  strategyFlexibility,
  learnerAgency,
  accessibilitySuccess,
  barrierRate,
  differentialOutcomeAudit,
  wellbeingOrSafetyBurden,
  humanEscalationSuccess,
  educatorWorkload,
  costAndComputeEfficiency,
  reliabilityAndRecoverability,
}

extension InstructionalOutcomeMetricWire on InstructionalOutcomeMetric {
  String get wireName => switch (this) {
    InstructionalOutcomeMetric.learningGain => 'learning-gain',
    InstructionalOutcomeMetric.delayedRetention => 'delayed-retention',
    InstructionalOutcomeMetric.transferOrGeneralization =>
      'transfer-or-generalization',
    InstructionalOutcomeMetric.misconceptionRecovery =>
      'misconception-recovery',
    InstructionalOutcomeMetric.timeToDemonstratedCriterion =>
      'time-to-demonstrated-criterion',
    InstructionalOutcomeMetric.robustnessAcrossRepresentations =>
      'robustness-across-representations',
    InstructionalOutcomeMetric.calibration => 'calibration',
    InstructionalOutcomeMetric.helpSeekingEffectiveness =>
      'help-seeking-effectiveness',
    InstructionalOutcomeMetric.strategyFlexibility => 'strategy-flexibility',
    InstructionalOutcomeMetric.learnerAgency => 'learner-agency',
    InstructionalOutcomeMetric.accessibilitySuccess => 'accessibility-success',
    InstructionalOutcomeMetric.barrierRate => 'barrier-rate',
    InstructionalOutcomeMetric.differentialOutcomeAudit =>
      'differential-outcome-audit',
    InstructionalOutcomeMetric.wellbeingOrSafetyBurden =>
      'wellbeing-or-safety-burden',
    InstructionalOutcomeMetric.humanEscalationSuccess =>
      'human-escalation-success',
    InstructionalOutcomeMetric.educatorWorkload => 'educator-workload',
    InstructionalOutcomeMetric.costAndComputeEfficiency =>
      'cost-and-compute-efficiency',
    InstructionalOutcomeMetric.reliabilityAndRecoverability =>
      'reliability-and-recoverability',
  };
}

class InstructionalEvidenceRecord {
  final String recordId;
  final String sourceId;
  final String? publicationId;
  final DateTime? publicationDate;
  final DateTime reviewDate;
  final InstructionalEvidenceLevel evidenceLevel;
  final String learnerStage;
  final String domain;
  final String setting;
  final String populationNotes;
  final String countryOrContext;
  final String language;
  final Set<InstructionalOutcomeMetric> measuredOutcomes;
  final double? effectEstimate;
  final String uncertaintyAndLimitations;
  final String independenceOrConflictNotes;
  final String applicabilityNotes;

  const InstructionalEvidenceRecord({
    required this.recordId,
    required this.sourceId,
    required this.publicationId,
    required this.publicationDate,
    required this.reviewDate,
    required this.evidenceLevel,
    required this.learnerStage,
    required this.domain,
    required this.setting,
    required this.populationNotes,
    required this.countryOrContext,
    required this.language,
    required this.measuredOutcomes,
    required this.effectEstimate,
    required this.uncertaintyAndLimitations,
    required this.independenceOrConflictNotes,
    required this.applicabilityNotes,
  });
}

class InstructionalStrategy {
  final String strategyId;
  final InstructionalStrategyKind kind;
  final Set<String> targetCompetencyIds;
  final Set<String> evidenceRecordIds;
  final String declaredUseCase;

  const InstructionalStrategy({
    required this.strategyId,
    required this.kind,
    required this.targetCompetencyIds,
    required this.evidenceRecordIds,
    required this.declaredUseCase,
  });

  bool get claimsUniversalBest => false;
}

class InstructionalOutcomeObservation {
  final String observationId;
  final String learnerSubjectId;
  final String competencyId;
  final String strategyId;
  final InstructionalOutcomeMetric metric;
  final double value;
  final String evidenceId;
  final DateTime observedAt;
  final Duration? delayFromInstruction;
  final Set<String> contextTags;

  const InstructionalOutcomeObservation({
    required this.observationId,
    required this.learnerSubjectId,
    required this.competencyId,
    required this.strategyId,
    required this.metric,
    required this.value,
    required this.evidenceId,
    required this.observedAt,
    required this.delayFromInstruction,
    this.contextTags = const <String>{},
  });

  bool get establishesDurableMasteryByItself => false;
}

class InstructionalStrategyCandidate {
  final InstructionalStrategy strategy;
  final bool privacyAllowed;
  final bool safetyAndReadinessAllowed;
  final bool accessibilityAllowed;

  const InstructionalStrategyCandidate({
    required this.strategy,
    required this.privacyAllowed,
    required this.safetyAndReadinessAllowed,
    required this.accessibilityAllowed,
  });
}

class InstructionalStrategyEligibilityDecision {
  final List<InstructionalStrategyCandidate> eligibleCandidates;
  final Map<String, String> excludedStrategyReasons;

  const InstructionalStrategyEligibilityDecision({
    required this.eligibleCandidates,
    required this.excludedStrategyReasons,
  });

  bool get performsEffectivenessRanking => false;

  bool get assumesSingleGlobalBestStrategy => false;
}

class InstructionalStrategyEligibilityFilter {
  const InstructionalStrategyEligibilityFilter();

  InstructionalStrategyEligibilityDecision filter({
    required String targetCompetencyId,
    required Iterable<InstructionalStrategyCandidate> candidates,
  }) {
    if (targetCompetencyId.trim().isEmpty) {
      throw const InstructionalEffectivenessException(
        'Target competency ID is required.',
      );
    }

    final eligible = <InstructionalStrategyCandidate>[];
    final excluded = <String, String>{};

    for (final candidate in candidates) {
      final strategy = candidate.strategy;
      if (!strategy.targetCompetencyIds.contains(targetCompetencyId)) {
        excluded[strategy.strategyId] = 'target-competency-mismatch';
        continue;
      }
      if (!candidate.privacyAllowed) {
        excluded[strategy.strategyId] = 'privacy-policy-denied';
        continue;
      }
      if (!candidate.safetyAndReadinessAllowed) {
        excluded[strategy.strategyId] = 'safety-or-readiness-denied';
        continue;
      }
      if (!candidate.accessibilityAllowed) {
        excluded[strategy.strategyId] = 'accessibility-requirement-unsatisfied';
        continue;
      }
      if (strategy.evidenceRecordIds.isEmpty) {
        excluded[strategy.strategyId] = 'missing-evidence-context';
        continue;
      }
      eligible.add(candidate);
    }

    return InstructionalStrategyEligibilityDecision(
      eligibleCandidates: List<InstructionalStrategyCandidate>.unmodifiable(
        eligible,
      ),
      excludedStrategyReasons: Map<String, String>.unmodifiable(excluded),
    );
  }
}

class InstructionalEffectivenessValidator {
  const InstructionalEffectivenessValidator();

  void validateEvidence(InstructionalEvidenceRecord record) {
    _requireIdentifier(record.recordId, 'Evidence record ID');
    _requireIdentifier(record.sourceId, 'Evidence source ID');
    if (record.publicationId != null) {
      _requireIdentifier(record.publicationId!, 'Publication ID');
    }
    if (record.publicationDate != null &&
        record.reviewDate.isBefore(record.publicationDate!)) {
      throw const InstructionalEffectivenessException(
        'Review date cannot predate the referenced publication date.',
      );
    }
    if (record.measuredOutcomes.isEmpty) {
      throw const InstructionalEffectivenessException(
        'Evidence must declare at least one measured outcome.',
      );
    }
    if (record.effectEstimate != null && !record.effectEstimate!.isFinite) {
      throw const InstructionalEffectivenessException(
        'Effect estimate must be finite when supplied.',
      );
    }
    if (record.uncertaintyAndLimitations.trim().isEmpty) {
      throw const InstructionalEffectivenessException(
        'Evidence must retain uncertainty and limitations.',
      );
    }
  }

  void validateStrategy(InstructionalStrategy strategy) {
    _requireIdentifier(strategy.strategyId, 'Strategy ID');
    if (strategy.targetCompetencyIds.isEmpty) {
      throw const InstructionalEffectivenessException(
        'Strategy must bind to at least one target competency.',
      );
    }
    if (strategy.declaredUseCase.trim().isEmpty) {
      throw const InstructionalEffectivenessException(
        'Strategy must declare its intended use case.',
      );
    }
  }

  void validateObservation(InstructionalOutcomeObservation observation) {
    _requireIdentifier(observation.observationId, 'Observation ID');
    _requireIdentifier(observation.learnerSubjectId, 'Learner subject ID');
    _requireIdentifier(observation.competencyId, 'Competency ID');
    _requireIdentifier(observation.strategyId, 'Strategy ID');
    _requireIdentifier(observation.evidenceId, 'Observation evidence ID');
    if (!observation.value.isFinite) {
      throw const InstructionalEffectivenessException(
        'Observed metric value must be finite.',
      );
    }
    if (observation.delayFromInstruction != null &&
        observation.delayFromInstruction!.isNegative) {
      throw const InstructionalEffectivenessException(
        'Observation delay cannot be negative.',
      );
    }
  }

  void _requireIdentifier(String value, String label) {
    if (value.trim().isEmpty) {
      throw InstructionalEffectivenessException('$label is required.');
    }
  }
}

class InstructionalEffectivenessBoundary {
  const InstructionalEffectivenessBoundary();

  bool immediateObservationAloneEstablishesDurableMastery() => false;

  bool genericEngagementIsLearningOutcome() => false;

  bool learnerPreferenceChangesCurriculumTruth() => false;

  bool maySilentlyPoolLearnersIntoPopulationExperiments() => false;

  bool get supportsDelayedEvidence => true;

  bool get supportsTransferEvidence => true;
}

class InstructionalEffectivenessException implements Exception {
  final String message;

  const InstructionalEffectivenessException(this.message);

  @override
  String toString() => 'InstructionalEffectivenessException: $message';
}
