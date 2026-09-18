import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/cross_cutting_learning_evidence.dart';
import 'package:ontarioedai/core/models/learning_evidence.dart';

void main() {
  final now = DateTime.utc(2026, 9, 5, 18);

  LearningEvidenceEnvelope baseEvidence({
    String evidenceId = 'evidence:1',
    String competencyId =
        'axiom:computational-literacy:verification:method-selection',
  }) => LearningEvidenceEnvelope(
        evidenceId: evidenceId,
        recordType: LearningEvidenceRecordType.outcomeObservation,
        learnerSubjectId: 'learner:1',
        competencyId: competencyId,
        consentContextId: 'consent:pedagogy:1',
        occurredAt: now,
        confidenceBefore: 0.4,
        confidenceAfter: 0.6,
        evidenceRef: 'artifact:verification:1',
      );

  CrossCuttingEvidenceMetadata metadata({
    String evidenceId = 'evidence:1',
    Set<CrossCuttingEvidenceQuality> qualities = const {
      CrossCuttingEvidenceQuality.independentApplication,
    },
    Set<CrossCuttingVerifierMethod> verifierMethods = const {
      CrossCuttingVerifierMethod.deterministicCalculator,
    },
    String observationSource = 'mth1w-deterministic-practice',
  }) => CrossCuttingEvidenceMetadata(
    evidenceId: evidenceId,
    qualities: qualities,
    verifierMethods: verifierMethods,
    aiRole: CrossCuttingAiRole.absent,
    observationSource: observationSource,
  );

  test('metadata is an in-memory companion and creates no authority', () {
    final aggregate = CrossCuttingLearningEvidence(
      base: baseEvidence(),
      metadata: metadata(),
    );

    expect(
      () => const CrossCuttingEvidenceValidator().validate(aggregate),
      returnsNormally,
    );
    expect(aggregate.canPersistCrossCuttingMetadata, isFalse);
    expect(aggregate.canExportCrossCuttingMetadata, isFalse);
    expect(aggregate.createsMasteryState, isFalse);
    expect(aggregate.changesSubjectGrade, isFalse);
    expect(aggregate.base.evidenceId, aggregate.metadata.evidenceId);
  });

  test('metadata evidence ID must match the base evidence exactly', () {
    final aggregate = CrossCuttingLearningEvidence(
      base: baseEvidence(),
      metadata: metadata(evidenceId: 'evidence:other'),
    );

    expect(
      () => const CrossCuttingEvidenceValidator().validate(aggregate),
      throwsA(isA<CrossCuttingEvidenceException>()),
    );
  });

  test('unknown authored competency fails closed', () {
    final aggregate = CrossCuttingLearningEvidence(
      base: baseEvidence(
        competencyId:
            'axiom:computational-literacy:verification:unknown-competency',
      ),
      metadata: metadata(),
    );

    expect(
      () => const CrossCuttingEvidenceValidator().validate(aggregate),
      throwsA(isA<CrossCuttingEvidenceException>()),
    );
  });

  test('observation source must be a bounded governed identifier', () {
    final invalidSources = <String>[
      '   ',
      'raw prompt: solve 2 + 2',
      'unreviewed-source',
      List<String>.filled(65, 'a').join(),
    ];

    for (final observationSource in invalidSources) {
      final aggregate = CrossCuttingLearningEvidence(
        base: baseEvidence(),
        metadata: metadata(observationSource: observationSource),
      );

      expect(
        () => const CrossCuttingEvidenceValidator().validate(aggregate),
        throwsA(isA<CrossCuttingEvidenceException>()),
        reason: 'Rejected source: $observationSource',
      );
    }
  });

  test('evidence quality is required', () {
    final aggregate = CrossCuttingLearningEvidence(
      base: baseEvidence(),
      metadata: metadata(qualities: const <CrossCuttingEvidenceQuality>{}),
    );

    expect(
      () => const CrossCuttingEvidenceValidator().validate(aggregate),
      throwsA(isA<CrossCuttingEvidenceException>()),
    );
  });

  test('at least one verifier method is required', () {
    final aggregate = CrossCuttingLearningEvidence(
      base: baseEvidence(),
      metadata: metadata(verifierMethods: const <CrossCuttingVerifierMethod>{}),
    );

    expect(
      () => const CrossCuttingEvidenceValidator().validate(aggregate),
      throwsA(isA<CrossCuttingEvidenceException>()),
    );
  });
}
