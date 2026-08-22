enum CurriculumAssuranceLevel {
  /// Material has been collected or generated but has no alignment claim.
  unverified,

  /// Sources are identified and the capsule is intended to align to them, but
  /// no independent qualified human review is claimed.
  sourceAlignedDemonstration,

  /// Automated checks have validated declared source/version/provenance and
  /// internal coverage rules. This is still not human or institutional review.
  machineAudited,

  /// A qualified human reviewer has explicitly attested the reviewed scope.
  humanReviewed,

  /// An authorized institution has approved the reviewed scope for its use.
  institutionApproved,

  /// A jurisdictional authority has explicitly approved the reviewed scope.
  jurisdictionApproved,

  /// The applicable authorized body has explicitly recognized the course or
  /// credential as accredited/credit-bearing for the declared purpose.
  accredited,
}

class CurriculumAssuranceRecord {
  final String curriculumContextId;
  final CurriculumAssuranceLevel level;
  final Set<String> sourceEvidenceIds;
  final Set<String> reviewEvidenceIds;
  final String claimText;
  final DateTime recordedAt;
  final String? supersedesRecordId;

  const CurriculumAssuranceRecord({
    required this.curriculumContextId,
    required this.level,
    required this.sourceEvidenceIds,
    required this.reviewEvidenceIds,
    required this.claimText,
    required this.recordedAt,
    this.supersedesRecordId,
  });

  bool get claimsAlignment => level != CurriculumAssuranceLevel.unverified;

  bool get claimsHumanReview =>
      level.index >= CurriculumAssuranceLevel.humanReviewed.index;

  bool get claimsInstitutionApproval =>
      level.index >= CurriculumAssuranceLevel.institutionApproved.index;

  bool get claimsJurisdictionApproval =>
      level.index >= CurriculumAssuranceLevel.jurisdictionApproved.index;

  bool get claimsAccreditation => level == CurriculumAssuranceLevel.accredited;

  bool get evidenceIsSufficientForClaim {
    if (claimsAlignment && sourceEvidenceIds.isEmpty) return false;
    if (claimsHumanReview && reviewEvidenceIds.isEmpty) return false;
    return true;
  }
}

class CurriculumAssuranceException implements Exception {
  final String message;

  const CurriculumAssuranceException(this.message);

  @override
  String toString() => 'CurriculumAssuranceException: $message';
}

class CurriculumAssuranceValidator {
  const CurriculumAssuranceValidator();

  void validate(CurriculumAssuranceRecord record) {
    if (!record.evidenceIsSufficientForClaim) {
      throw const CurriculumAssuranceException(
        'Curriculum assurance claim is not backed by the required evidence.',
      );
    }

    if (record.level == CurriculumAssuranceLevel.sourceAlignedDemonstration &&
        record.reviewEvidenceIds.isNotEmpty) {
      // Review evidence may exist for individual artifacts, but callers should
      // promote the declared assurance level only when that evidence covers the
      // scope represented by this record. Keeping this level is conservative.
      return;
    }
  }
}
