import 'learning_evidence.dart';

enum CrossCuttingEvidenceQuality {
  recognized,
  supportedApplication,
  independentApplication,
  robustApplication,
  transferObserved,
}

enum CrossCuttingVerifierMethod {
  learnerReasoning,
  deterministicCalculator,
  symbolicSolver,
  compilerOrTestRunner,
  experimentOrMeasurement,
  sourceOrProvenanceReview,
  educatorReview,
  peerReview,
  modelAssistedCritique,
  otherGovernedTool,
}

enum CrossCuttingAiRole {
  absent,
  optionalTool,
  generatedCandidate,
  critiqueAssistant,
  socraticTutor,
}

class CrossCuttingEvidenceException implements Exception {
  final String message;

  const CrossCuttingEvidenceException(this.message);

  @override
  String toString() => 'CrossCuttingEvidenceException: $message';
}

class CrossCuttingEvidenceMetadata {
  final String evidenceId;
  final Set<CrossCuttingEvidenceQuality> qualities;
  final Set<CrossCuttingVerifierMethod> verifierMethods;
  final CrossCuttingAiRole aiRole;
  final String observationSource;

  CrossCuttingEvidenceMetadata({
    required this.evidenceId,
    required Set<CrossCuttingEvidenceQuality> qualities,
    required Set<CrossCuttingVerifierMethod> verifierMethods,
    required this.aiRole,
    required this.observationSource,
  }) : qualities = Set<CrossCuttingEvidenceQuality>.unmodifiable(qualities),
       verifierMethods = Set<CrossCuttingVerifierMethod>.unmodifiable(
         verifierMethods,
       );
}

class CrossCuttingLearningEvidence {
  final LearningEvidenceEnvelope base;
  final CrossCuttingEvidenceMetadata metadata;

  const CrossCuttingLearningEvidence({
    required this.base,
    required this.metadata,
  });

  bool get canPersistCrossCuttingMetadata => false;

  bool get canExportCrossCuttingMetadata => false;

  bool get createsMasteryState => false;

  bool get changesSubjectGrade => false;
}

class CrossCuttingEvidenceValidator {
  const CrossCuttingEvidenceValidator();

  void validate(CrossCuttingLearningEvidence evidence) {
    const LearningEvidenceValidator().validate(evidence.base);

    final metadata = evidence.metadata;
    if (metadata.evidenceId.trim().isEmpty ||
        metadata.evidenceId != evidence.base.evidenceId) {
      throw const CrossCuttingEvidenceException(
        'Cross-cutting metadata must bind to the exact base evidence ID.',
      );
    }
    if (metadata.observationSource.trim().isEmpty) {
      throw const CrossCuttingEvidenceException(
        'Cross-cutting evidence requires a bounded observation source.',
      );
    }
    if (metadata.qualities.isEmpty) {
      throw const CrossCuttingEvidenceException(
        'Cross-cutting evidence requires at least one evidence quality.',
      );
    }
    if (metadata.verifierMethods.isEmpty) {
      throw const CrossCuttingEvidenceException(
        'Cross-cutting evidence requires at least one verifier method.',
      );
    }
  }
}
