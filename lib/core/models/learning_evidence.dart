import 'learning_resource.dart';

enum LearningEvidenceRecordType {
  resourceFeedback,
  outcomeObservation,
  correction,
  retraction,
}

class LearningEvidenceException implements Exception {
  final String message;

  const LearningEvidenceException(this.message);

  @override
  String toString() => 'LearningEvidenceException: $message';
}

/// Minimal learner-controlled evidence used for pedagogical personalization.
///
/// This object deliberately excludes watch history, clickstream, provider
/// account identifiers, advertising identifiers, and raw conversation logs.
/// It is not an admitted AXIOM-MESH learner event by itself.
class LearningEvidenceEnvelope {
  static const String proposedMemoryKind = 'education.learning-evidence';

  final String evidenceId;
  final LearningEvidenceRecordType recordType;
  final String learnerSubjectId;
  final String competencyId;
  final String consentContextId;
  final DateTime occurredAt;
  final String? resourceId;
  final Set<LearningFeedbackSignal> feedbackSignals;
  final double? confidenceBefore;
  final double? confidenceAfter;
  final String? evidenceRef;
  final String? actorAttestationId;
  final String? supersedesEvidenceId;
  final String? retractsEvidenceId;

  const LearningEvidenceEnvelope({
    required this.evidenceId,
    required this.recordType,
    required this.learnerSubjectId,
    required this.competencyId,
    required this.consentContextId,
    required this.occurredAt,
    this.resourceId,
    this.feedbackSignals = const <LearningFeedbackSignal>{},
    this.confidenceBefore,
    this.confidenceAfter,
    this.evidenceRef,
    this.actorAttestationId,
    this.supersedesEvidenceId,
    this.retractsEvidenceId,
  });

  bool get isSubjectOwned => true;

  bool get meshEventIsAdmitted => false;

  bool get canReportOfficialPersistence => false;

  String get proposedEventType => switch (recordType) {
    LearningEvidenceRecordType.resourceFeedback => 'resource.feedback.recorded',
    LearningEvidenceRecordType.outcomeObservation =>
      'learning.outcome.recorded',
    LearningEvidenceRecordType.correction => 'learning.evidence.corrected',
    LearningEvidenceRecordType.retraction => 'learning.evidence.retracted',
  };
}

class LearningEvidenceValidator {
  const LearningEvidenceValidator();

  void validate(LearningEvidenceEnvelope evidence) {
    if (evidence.evidenceId.trim().isEmpty ||
        evidence.learnerSubjectId.trim().isEmpty ||
        evidence.competencyId.trim().isEmpty ||
        evidence.consentContextId.trim().isEmpty) {
      throw const LearningEvidenceException(
        'Learning evidence requires non-empty identity, competency, and consent fields.',
      );
    }

    switch (evidence.recordType) {
      case LearningEvidenceRecordType.resourceFeedback:
        if (evidence.resourceId == null ||
            evidence.resourceId!.trim().isEmpty ||
            evidence.feedbackSignals.isEmpty) {
          throw const LearningEvidenceException(
            'Resource feedback requires a resource and at least one explicit signal.',
          );
        }
        _requireNoRevisionPointers(evidence);
        return;
      case LearningEvidenceRecordType.outcomeObservation:
        if (evidence.evidenceRef == null ||
            evidence.evidenceRef!.trim().isEmpty ||
            evidence.confidenceBefore == null ||
            evidence.confidenceAfter == null) {
          throw const LearningEvidenceException(
            'Outcome observations require evidence reference and before/after confidence.',
          );
        }
        _requireUnitInterval(evidence.confidenceBefore!);
        _requireUnitInterval(evidence.confidenceAfter!);
        _requireNoRevisionPointers(evidence);
        return;
      case LearningEvidenceRecordType.correction:
        if (evidence.supersedesEvidenceId == null ||
            evidence.supersedesEvidenceId!.trim().isEmpty ||
            evidence.retractsEvidenceId != null) {
          throw const LearningEvidenceException(
            'Corrections must reference exactly one superseded evidence record.',
          );
        }
        return;
      case LearningEvidenceRecordType.retraction:
        if (evidence.retractsEvidenceId == null ||
            evidence.retractsEvidenceId!.trim().isEmpty ||
            evidence.supersedesEvidenceId != null) {
          throw const LearningEvidenceException(
            'Retractions must reference exactly one retracted evidence record.',
          );
        }
        return;
    }
  }

  void _requireNoRevisionPointers(LearningEvidenceEnvelope evidence) {
    if (evidence.supersedesEvidenceId != null ||
        evidence.retractsEvidenceId != null) {
      throw const LearningEvidenceException(
        'Base evidence records cannot carry correction or retraction pointers.',
      );
    }
  }

  void _requireUnitInterval(double value) {
    if (value < 0 || value > 1) {
      throw const LearningEvidenceException(
        'Outcome confidence values must be within the closed interval 0..1.',
      );
    }
  }
}
