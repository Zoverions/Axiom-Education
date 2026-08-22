import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/instructional_effectiveness.dart';

void main() {
  group('instructional effectiveness contract parity', () {
    late Map<String, dynamic> contract;

    setUpAll(() {
      contract =
          jsonDecode(
                File(
                  'contracts/axiom-education-instructional-effectiveness.v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
    });

    test('runtime evidence levels match the contract exactly', () {
      final contractLevels = (contract['evidence_levels'] as List<dynamic>)
          .cast<String>();
      final runtimeLevels = InstructionalEvidenceLevel.values
          .map((level) => level.wireName)
          .toList(growable: false);

      expect(runtimeLevels, equals(contractLevels));
    });

    test('runtime strategy kinds match the contract exactly', () {
      final contractStrategies = (contract['strategy_classes'] as List<dynamic>)
          .cast<String>();
      final runtimeStrategies = InstructionalStrategyKind.values
          .map((strategy) => strategy.wireName)
          .toList(growable: false);

      expect(runtimeStrategies, equals(contractStrategies));
    });

    test('runtime outcome metrics cover every governed metric class', () {
      final contractMetrics = <String>{
        ...(contract['primary_learning_metrics'] as List<dynamic>)
            .cast<String>(),
        ...(contract['learner_regulation_metrics'] as List<dynamic>)
            .cast<String>(),
        ...(contract['access_safety_equity_metrics'] as List<dynamic>)
            .cast<String>(),
        ...(contract['system_efficiency_metrics'] as List<dynamic>)
            .cast<String>(),
      };
      final runtimeMetrics = InstructionalOutcomeMetric.values
          .map((metric) => metric.wireName)
          .toSet();

      expect(runtimeMetrics, equals(contractMetrics));
    });
  });

  group('instructional strategy eligibility', () {
    const filter = InstructionalStrategyEligibilityFilter();

    InstructionalStrategy strategy({
      required String id,
      Set<String> competencyIds = const <String>{'math:fractions:equivalence'},
      Set<String> evidenceIds = const <String>{'evidence:review:1'},
    }) {
      return InstructionalStrategy(
        strategyId: id,
        kind: InstructionalStrategyKind.workedExample,
        targetCompetencyIds: competencyIds,
        evidenceRecordIds: evidenceIds,
        declaredUseCase: 'Introduce fraction equivalence with a worked model.',
      );
    }

    InstructionalStrategyCandidate candidate({
      required String id,
      bool privacyAllowed = true,
      bool safetyAllowed = true,
      bool accessibilityAllowed = true,
      Set<String> competencyIds = const <String>{'math:fractions:equivalence'},
      Set<String> evidenceIds = const <String>{'evidence:review:1'},
    }) {
      return InstructionalStrategyCandidate(
        strategy: strategy(
          id: id,
          competencyIds: competencyIds,
          evidenceIds: evidenceIds,
        ),
        privacyAllowed: privacyAllowed,
        safetyAndReadinessAllowed: safetyAllowed,
        accessibilityAllowed: accessibilityAllowed,
      );
    }

    test('hard governance filters run before any effectiveness ranking', () {
      final decision = filter.filter(
        targetCompetencyId: 'math:fractions:equivalence',
        candidates: <InstructionalStrategyCandidate>[
          candidate(id: 'strategy:eligible'),
          candidate(id: 'strategy:privacy-denied', privacyAllowed: false),
          candidate(id: 'strategy:safety-denied', safetyAllowed: false),
          candidate(
            id: 'strategy:accessibility-denied',
            accessibilityAllowed: false,
          ),
          candidate(
            id: 'strategy:wrong-target',
            competencyIds: const <String>{'math:geometry:area'},
          ),
          candidate(id: 'strategy:no-evidence', evidenceIds: const <String>{}),
        ],
      );

      expect(decision.eligibleCandidates, hasLength(1));
      expect(
        decision.eligibleCandidates.single.strategy.strategyId,
        'strategy:eligible',
      );
      expect(
        decision.excludedStrategyReasons['strategy:privacy-denied'],
        'privacy-policy-denied',
      );
      expect(
        decision.excludedStrategyReasons['strategy:safety-denied'],
        'safety-or-readiness-denied',
      );
      expect(
        decision.excludedStrategyReasons['strategy:accessibility-denied'],
        'accessibility-requirement-unsatisfied',
      );
      expect(
        decision.excludedStrategyReasons['strategy:wrong-target'],
        'target-competency-mismatch',
      );
      expect(
        decision.excludedStrategyReasons['strategy:no-evidence'],
        'missing-evidence-context',
      );
      expect(decision.performsEffectivenessRanking, isFalse);
      expect(decision.assumesSingleGlobalBestStrategy, isFalse);
    });

    test('blank target fails before candidate evaluation', () {
      expect(
        () => filter.filter(
          targetCompetencyId: '   ',
          candidates: <InstructionalStrategyCandidate>[
            candidate(id: 'strategy:1'),
          ],
        ),
        throwsA(isA<InstructionalEffectivenessException>()),
      );
    });
  });

  group('evidence and outcome validation', () {
    const validator = InstructionalEffectivenessValidator();
    final now = DateTime.utc(2026, 8, 21, 20);

    InstructionalEvidenceRecord evidence({
      double? effectEstimate = 0.42,
      String limitations =
          'Context-specific estimate; transfer remains uncertain.',
      Set<InstructionalOutcomeMetric> outcomes =
          const <InstructionalOutcomeMetric>{
            InstructionalOutcomeMetric.learningGain,
          },
    }) {
      return InstructionalEvidenceRecord(
        recordId: 'evidence:1',
        sourceId: 'source:1',
        publicationId: 'publication:1',
        publicationDate: DateTime.utc(2026, 1, 1),
        reviewDate: now,
        evidenceLevel: InstructionalEvidenceLevel.randomizedControlledTrial,
        learnerStage: 'secondary',
        domain: 'mathematics',
        setting: 'classroom',
        populationNotes: 'Declared study population.',
        countryOrContext: 'multi-site',
        language: 'en',
        measuredOutcomes: outcomes,
        effectEstimate: effectEstimate,
        uncertaintyAndLimitations: limitations,
        independenceOrConflictNotes: 'No conflict information omitted.',
        applicabilityNotes:
            'Applicability must be checked for the local learner.',
      );
    }

    test('evidence retains measured outcome and uncertainty', () {
      final record = evidence();

      expect(() => validator.validateEvidence(record), returnsNormally);
      expect(
        record.measuredOutcomes,
        contains(InstructionalOutcomeMetric.learningGain),
      );
      expect(record.uncertaintyAndLimitations, isNotEmpty);
    });

    test('evidence without limitations fails closed', () {
      expect(
        () => validator.validateEvidence(evidence(limitations: '')),
        throwsA(isA<InstructionalEffectivenessException>()),
      );
    });

    test('evidence must declare at least one measured outcome', () {
      expect(
        () => validator.validateEvidence(
          evidence(outcomes: const <InstructionalOutcomeMetric>{}),
        ),
        throwsA(isA<InstructionalEffectivenessException>()),
      );
    });

    test('learner outcome is subject-bound and never mastery by itself', () {
      final observation = InstructionalOutcomeObservation(
        observationId: 'observation:1',
        learnerSubjectId: 'learner:1',
        competencyId: 'math:fractions:equivalence',
        strategyId: 'strategy:worked-example:1',
        metric: InstructionalOutcomeMetric.delayedRetention,
        value: 0.81,
        evidenceId: 'assessment:delayed:1',
        observedAt: now.add(const Duration(days: 7)),
        delayFromInstruction: const Duration(days: 7),
        contextTags: const <String>{'delayed-check'},
      );

      expect(() => validator.validateObservation(observation), returnsNormally);
      expect(observation.learnerSubjectId, 'learner:1');
      expect(observation.establishesDurableMasteryByItself, isFalse);
    });

    test('non-finite outcome evidence is rejected', () {
      final observation = InstructionalOutcomeObservation(
        observationId: 'observation:invalid',
        learnerSubjectId: 'learner:1',
        competencyId: 'math:fractions:equivalence',
        strategyId: 'strategy:1',
        metric: InstructionalOutcomeMetric.learningGain,
        value: double.nan,
        evidenceId: 'assessment:1',
        observedAt: now,
        delayFromInstruction: Duration.zero,
      );

      expect(
        () => validator.validateObservation(observation),
        throwsA(isA<InstructionalEffectivenessException>()),
      );
    });
  });

  test('runtime preserves non-engagement and research boundaries', () {
    const boundary = InstructionalEffectivenessBoundary();

    expect(
      boundary.immediateObservationAloneEstablishesDurableMastery(),
      isFalse,
    );
    expect(boundary.genericEngagementIsLearningOutcome(), isFalse);
    expect(boundary.learnerPreferenceChangesCurriculumTruth(), isFalse);
    expect(
      boundary.maySilentlyPoolLearnersIntoPopulationExperiments(),
      isFalse,
    );
    expect(boundary.supportsDelayedEvidence, isTrue);
    expect(boundary.supportsTransferEvidence, isTrue);
  });
}
