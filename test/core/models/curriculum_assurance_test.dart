import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/curriculum_assurance.dart';

void main() {
  const validator = CurriculumAssuranceValidator();
  final now = DateTime.utc(2026, 8, 21, 20);

  test('source-aligned demonstration requires source evidence but no human review', () {
    final record = CurriculumAssuranceRecord(
      curriculumContextId: 'ontario:demo:secondary:2026',
      level: CurriculumAssuranceLevel.sourceAlignedDemonstration,
      sourceEvidenceIds: const <String>{'source:ontario:curriculum:1'},
      reviewEvidenceIds: const <String>{},
      claimText: 'Source-aligned demonstration; not human reviewed or accredited.',
      recordedAt: now,
    );

    expect(() => validator.validate(record), returnsNormally);
    expect(record.claimsHumanReview, isFalse);
    expect(record.claimsInstitutionApproval, isFalse);
    expect(record.claimsJurisdictionApproval, isFalse);
    expect(record.claimsAccreditation, isFalse);
  });

  test('human reviewed claim fails without explicit review evidence', () {
    final record = CurriculumAssuranceRecord(
      curriculumContextId: 'curriculum:1',
      level: CurriculumAssuranceLevel.humanReviewed,
      sourceEvidenceIds: const <String>{'source:1'},
      reviewEvidenceIds: const <String>{},
      claimText: 'Human reviewed.',
      recordedAt: now,
    );

    expect(
      () => validator.validate(record),
      throwsA(isA<CurriculumAssuranceException>()),
    );
  });

  test('accreditation is never implied by lower assurance levels', () {
    for (final level in CurriculumAssuranceLevel.values.where(
      (value) => value != CurriculumAssuranceLevel.accredited,
    )) {
      final record = CurriculumAssuranceRecord(
        curriculumContextId: 'curriculum:${level.name}',
        level: level,
        sourceEvidenceIds: const <String>{'source:1'},
        reviewEvidenceIds: level.index >= CurriculumAssuranceLevel.humanReviewed.index
            ? const <String>{'review:1'}
            : const <String>{},
        claimText: level.name,
        recordedAt: now,
      );

      expect(record.claimsAccreditation, isFalse);
    }
  });
}
