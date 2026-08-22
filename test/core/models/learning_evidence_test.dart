import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/learning_evidence.dart';
import 'package:ontarioedai/core/models/learning_resource.dart';

void main() {
  const validator = LearningEvidenceValidator();
  final now = DateTime.utc(2026, 8, 21, 20, 45);

  test('resource feedback is learner-owned but not a Mesh-admitted event', () {
    final evidence = LearningEvidenceEnvelope(
      evidenceId: 'evidence:feedback:1',
      recordType: LearningEvidenceRecordType.resourceFeedback,
      learnerSubjectId: 'learner:1',
      competencyId: 'competency:fractions',
      consentContextId: 'consent:pedagogy:1',
      occurredAt: now,
      resourceId: 'resource:video:1',
      feedbackSignals: const <LearningFeedbackSignal>{
        LearningFeedbackSignal.helpful,
        LearningFeedbackSignal.likedExample,
      },
    );

    expect(() => validator.validate(evidence), returnsNormally);
    expect(evidence.isSubjectOwned, isTrue);
    expect(evidence.meshEventIsAdmitted, isFalse);
    expect(evidence.canReportOfficialPersistence, isFalse);
    expect(
      evidence.proposedEventType,
      equals('resource.feedback.recorded'),
    );
    expect(
      LearningEvidenceEnvelope.proposedMemoryKind,
      equals('education.learning-evidence'),
    );
  });

  test('resource feedback requires explicit signal and resource', () {
    final evidence = LearningEvidenceEnvelope(
      evidenceId: 'evidence:feedback:2',
      recordType: LearningEvidenceRecordType.resourceFeedback,
      learnerSubjectId: 'learner:1',
      competencyId: 'competency:fractions',
      consentContextId: 'consent:pedagogy:1',
      occurredAt: now,
    );

    expect(
      () => validator.validate(evidence),
      throwsA(isA<LearningEvidenceException>()),
    );
  });

  test('outcome observation requires bounded confidence and evidence ref', () {
    final valid = LearningEvidenceEnvelope(
      evidenceId: 'evidence:outcome:1',
      recordType: LearningEvidenceRecordType.outcomeObservation,
      learnerSubjectId: 'learner:1',
      competencyId: 'competency:fractions',
      consentContextId: 'consent:pedagogy:1',
      occurredAt: now,
      confidenceBefore: 0.35,
      confidenceAfter: 0.72,
      evidenceRef: 'assessment-evidence:1',
      actorAttestationId: 'attestation:educator:1',
    );

    expect(() => validator.validate(valid), returnsNormally);

    final invalid = LearningEvidenceEnvelope(
      evidenceId: 'evidence:outcome:2',
      recordType: LearningEvidenceRecordType.outcomeObservation,
      learnerSubjectId: 'learner:1',
      competencyId: 'competency:fractions',
      consentContextId: 'consent:pedagogy:1',
      occurredAt: now,
      confidenceBefore: -0.1,
      confidenceAfter: 0.9,
      evidenceRef: 'assessment-evidence:2',
    );

    expect(
      () => validator.validate(invalid),
      throwsA(isA<LearningEvidenceException>()),
    );
  });

  test('correction is append-only and references superseded evidence', () {
    final correction = LearningEvidenceEnvelope(
      evidenceId: 'evidence:correction:1',
      recordType: LearningEvidenceRecordType.correction,
      learnerSubjectId: 'learner:1',
      competencyId: 'competency:fractions',
      consentContextId: 'consent:pedagogy:1',
      occurredAt: now,
      supersedesEvidenceId: 'evidence:feedback:1',
    );

    expect(() => validator.validate(correction), returnsNormally);
    expect(
      correction.proposedEventType,
      equals('learning.evidence.corrected'),
    );
  });

  test('retraction cannot also masquerade as a correction', () {
    final invalid = LearningEvidenceEnvelope(
      evidenceId: 'evidence:retraction:1',
      recordType: LearningEvidenceRecordType.retraction,
      learnerSubjectId: 'learner:1',
      competencyId: 'competency:fractions',
      consentContextId: 'consent:pedagogy:1',
      occurredAt: now,
      retractsEvidenceId: 'evidence:feedback:1',
      supersedesEvidenceId: 'evidence:feedback:2',
    );

    expect(
      () => validator.validate(invalid),
      throwsA(isA<LearningEvidenceException>()),
    );
  });
}
