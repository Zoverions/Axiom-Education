enum EducationInstitutionKind {
  school,
  schoolBoard,
  district,
  homeschool,
  postSecondary,
  trainingProvider,
  communityProgram,
  other,
}

enum EducationRole {
  learner,
  guardian,
  teacher,
  principal,
  guidanceCounselor,
  supportWorker,
  administrator,
  assessor,
  mentor,
}

enum EducationRelationshipKind {
  enrollment,
  guardianOf,
  teacherOf,
  principalOf,
  counselorOf,
  supportOf,
  assessorOf,
  mentorOf,
}

enum EducationAuthorityScopeKind {
  institution,
  learningGroup,
  learner,
  assignment,
  competency,
  reporting,
  support,
}

enum GuardianPacingPreference {
  noPreference,
  slowDownWhenAllowed,
  maintain,
  accelerateWhenReady,
  prioritize,
}

enum GuardianContentTimingPreference {
  noPreference,
  deferWhenAllowed,
  prioritizeWhenRelevant,
}

class EducationInstitution {
  final String institutionId;
  final String displayName;
  final EducationInstitutionKind kind;
  final String? jurisdictionId;

  const EducationInstitution({
    required this.institutionId,
    required this.displayName,
    required this.kind,
    this.jurisdictionId,
  });
}

class EducationLearningGroup {
  final String learningGroupId;
  final String institutionId;
  final String displayName;
  final String? courseId;
  final String? curriculumContextId;

  const EducationLearningGroup({
    required this.learningGroupId,
    required this.institutionId,
    required this.displayName,
    this.courseId,
    this.curriculumContextId,
  });
}

/// A descriptive relationship backed by evidence.
///
/// Relationship and role vocabulary never grants authority by itself. Actions
/// still require an applicable Mesh capability/delegation and policy decision.
class EducationRelationship {
  final String relationshipId;
  final String subjectActorId;
  final String relatedActorId;
  final EducationRelationshipKind kind;
  final Set<String> evidenceIds;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime? revokedAt;

  const EducationRelationship({
    required this.relationshipId,
    required this.subjectActorId,
    required this.relatedActorId,
    required this.kind,
    required this.evidenceIds,
    required this.validFrom,
    this.validUntil,
    this.revokedAt,
  });

  bool isActiveAt(DateTime at) {
    if (at.isBefore(validFrom)) return false;
    if (revokedAt != null && !at.isBefore(revokedAt!)) return false;
    if (validUntil != null && !at.isBefore(validUntil!)) return false;
    return true;
  }
}

/// A role assertion is UI/domain context, not an authorization primitive.
class EducationRoleAssignment {
  final String assignmentId;
  final String actorId;
  final String institutionId;
  final Set<EducationRole> roles;
  final Set<String> evidenceIds;

  const EducationRoleAssignment({
    required this.assignmentId,
    required this.actorId,
    required this.institutionId,
    required this.roles,
    this.evidenceIds = const <String>{},
  });

  bool get hasEvidence => evidenceIds.isNotEmpty;

  /// Explicitly false so consumers cannot mistake role membership for power.
  bool get grantsAuthority => false;
}

/// A resolved, evidenced delegation/capability projection for education.
///
/// The source of truth remains the Mesh authority system. This object is a
/// domain projection used to make scope checks explicit inside Education.
class EducationAuthorityGrant {
  final String grantId;
  final String actorId;
  final String institutionId;
  final EducationAuthorityScopeKind scopeKind;
  final Set<String> scopeIds;
  final Set<String> capabilityIds;
  final Set<String> evidenceIds;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime? revokedAt;

  const EducationAuthorityGrant({
    required this.grantId,
    required this.actorId,
    required this.institutionId,
    required this.scopeKind,
    required this.scopeIds,
    required this.capabilityIds,
    required this.evidenceIds,
    required this.validFrom,
    this.validUntil,
    this.revokedAt,
  });

  bool get isEvidenceBacked => evidenceIds.isNotEmpty;

  bool permits({
    required String capabilityId,
    required String scopeId,
    required DateTime at,
  }) {
    if (!isEvidenceBacked) return false;
    if (at.isBefore(validFrom)) return false;
    if (revokedAt != null && !at.isBefore(revokedAt!)) return false;
    if (validUntil != null && !at.isBefore(validUntil!)) return false;
    if (!capabilityIds.contains(capabilityId)) return false;
    return scopeIds.contains(scopeId);
  }
}

/// Guardian input into adaptive sequencing.
///
/// This is intentionally advisory. It does not authorize access, suppress
/// required curriculum, or override learner rights, safeguarding obligations,
/// institutional policy, or jurisdiction policy.
class GuardianLearningPreference {
  final String preferenceId;
  final String guardianActorId;
  final String learnerSubjectId;
  final Set<String> competencyIds;
  final GuardianPacingPreference pacing;
  final GuardianContentTimingPreference contentTiming;
  final Set<String> authorityEvidenceIds;
  final DateTime recordedAt;
  final DateTime? expiresAt;

  const GuardianLearningPreference({
    required this.preferenceId,
    required this.guardianActorId,
    required this.learnerSubjectId,
    required this.competencyIds,
    required this.pacing,
    required this.contentTiming,
    required this.authorityEvidenceIds,
    required this.recordedAt,
    this.expiresAt,
  });

  bool get isAuthorityRelationshipEvidenced => authorityEvidenceIds.isNotEmpty;
  bool get grantsAuthority => false;
  bool get canSuppressRequiredContent => false;

  bool isCurrentAt(DateTime at) {
    if (at.isBefore(recordedAt)) return false;
    return expiresAt == null || at.isBefore(expiresAt!);
  }
}
