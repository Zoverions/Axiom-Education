enum PersonalInsightSensitivity {
  ordinaryPreference,
  educationalSensitive,
  psychologicalSensitive,
  clinicalHealthRestricted,
}

extension PersonalInsightSensitivityWire on PersonalInsightSensitivity {
  String get wireName => switch (this) {
    PersonalInsightSensitivity.ordinaryPreference => 'ordinary-preference',
    PersonalInsightSensitivity.educationalSensitive => 'educational-sensitive',
    PersonalInsightSensitivity.psychologicalSensitive =>
      'psychological-sensitive',
    PersonalInsightSensitivity.clinicalHealthRestricted =>
      'clinical-health-restricted',
  };
}

enum PersonalInsightSourceType {
  learnerSelfReport,
  guardianObservation,
  educatorObservation,
  taskEvidence,
  structuredAssessment,
  clinicianProvided,
  modelHypothesis,
}

extension PersonalInsightSourceTypeWire on PersonalInsightSourceType {
  String get wireName => switch (this) {
    PersonalInsightSourceType.learnerSelfReport => 'learner-self-report',
    PersonalInsightSourceType.guardianObservation => 'guardian-observation',
    PersonalInsightSourceType.educatorObservation => 'educator-observation',
    PersonalInsightSourceType.taskEvidence => 'task-evidence',
    PersonalInsightSourceType.structuredAssessment => 'structured-assessment',
    PersonalInsightSourceType.clinicianProvided => 'clinician-provided',
    PersonalInsightSourceType.modelHypothesis => 'model-hypothesis',
  };
}

enum PersonalInsightPurpose {
  presentationAdaptation,
  instructionalStrategy,
  metacognitiveFeedback,
  learnerSelfReflection,
  accessibilitySupport,
  wellbeingSupport,
  educatorSupport,
  guardianSupport,
  clinicalAccommodation,
}

extension PersonalInsightPurposeWire on PersonalInsightPurpose {
  String get wireName => switch (this) {
    PersonalInsightPurpose.presentationAdaptation => 'presentation-adaptation',
    PersonalInsightPurpose.instructionalStrategy => 'instructional-strategy',
    PersonalInsightPurpose.metacognitiveFeedback => 'metacognitive-feedback',
    PersonalInsightPurpose.learnerSelfReflection => 'learner-self-reflection',
    PersonalInsightPurpose.accessibilitySupport => 'accessibility-support',
    PersonalInsightPurpose.wellbeingSupport => 'wellbeing-support',
    PersonalInsightPurpose.educatorSupport => 'educator-support',
    PersonalInsightPurpose.guardianSupport => 'guardian-support',
    PersonalInsightPurpose.clinicalAccommodation => 'clinical-accommodation',
  };
}

enum PersonalInsightPermission {
  read,
  use,
  proposeRevision,
  confirm,
  dispute,
  correct,
  revoke,
}

extension PersonalInsightPermissionWire on PersonalInsightPermission {
  String get wireName => switch (this) {
    PersonalInsightPermission.read => 'read',
    PersonalInsightPermission.use => 'use',
    PersonalInsightPermission.proposeRevision => 'propose-revision',
    PersonalInsightPermission.confirm => 'confirm',
    PersonalInsightPermission.dispute => 'dispute',
    PersonalInsightPermission.correct => 'correct',
    PersonalInsightPermission.revoke => 'revoke',
  };
}

enum PersonalInsightRevisionType { confirm, dispute, correct, revoke }

extension PersonalInsightRevisionTypeWire on PersonalInsightRevisionType {
  String get wireName => switch (this) {
    PersonalInsightRevisionType.confirm => 'confirm',
    PersonalInsightRevisionType.dispute => 'dispute',
    PersonalInsightRevisionType.correct => 'correct',
    PersonalInsightRevisionType.revoke => 'revoke',
  };
}

class PersonalInsightRecord {
  final String insightId;
  final String learnerSubjectId;
  final String claimType;
  final String statement;
  final PersonalInsightSensitivity sensitivity;
  final PersonalInsightSourceType sourceType;
  final String? sourceActorId;
  final Set<String> evidenceIds;
  final Set<String> domainScopes;
  final double? confidence;
  final String limitations;
  final DateTime createdAt;
  final DateTime reviewAt;
  final DateTime expiresAt;
  final bool clinicalDiagnosisClaim;

  PersonalInsightRecord({
    required this.insightId,
    required this.learnerSubjectId,
    required this.claimType,
    required this.statement,
    required this.sensitivity,
    required this.sourceType,
    required this.evidenceIds,
    required this.domainScopes,
    required this.limitations,
    required this.createdAt,
    required this.reviewAt,
    required this.expiresAt,
    this.sourceActorId,
    this.confidence,
    this.clinicalDiagnosisClaim = false,
  }) : evidenceIds = Set<String>.unmodifiable(evidenceIds),
       domainScopes = Set<String>.unmodifiable(domainScopes);

  bool isCurrentAt(DateTime at) =>
      !at.isBefore(createdAt) && at.isBefore(expiresAt);

  bool get establishesMastery => false;

  bool get establishesGradeOrCredit => false;

  bool get createsCredential => false;

  bool get isPublicProfile => false;
}

class PersonalInsightRevision {
  final String revisionId;
  final String insightId;
  final String learnerSubjectId;
  final String actorId;
  final PersonalInsightRevisionType type;
  final DateTime occurredAt;
  final Set<String> evidenceIds;
  final String reason;
  final String? replacementStatement;
  final double? replacementConfidence;

  PersonalInsightRevision({
    required this.revisionId,
    required this.insightId,
    required this.learnerSubjectId,
    required this.actorId,
    required this.type,
    required this.occurredAt,
    required this.evidenceIds,
    required this.reason,
    this.replacementStatement,
    this.replacementConfidence,
  }) : evidenceIds = Set<String>.unmodifiable(evidenceIds);
}

class PersonalInsightEffectiveView {
  final PersonalInsightRecord original;
  final String statement;
  final double? confidence;
  final bool learnerConfirmed;
  final bool disputed;
  final bool revoked;
  final List<PersonalInsightRevision> appliedRevisions;

  PersonalInsightEffectiveView({
    required this.original,
    required this.statement,
    required this.confidence,
    required this.learnerConfirmed,
    required this.disputed,
    required this.revoked,
    required List<PersonalInsightRevision> appliedRevisions,
  }) : appliedRevisions =
           List<PersonalInsightRevision>.unmodifiable(appliedRevisions);
}

class PersonalInsightRevisionProjector {
  const PersonalInsightRevisionProjector();

  PersonalInsightEffectiveView project({
    required PersonalInsightRecord record,
    required Iterable<PersonalInsightRevision> revisions,
  }) {
    final ordered = revisions
        .where(
          (revision) =>
              revision.insightId == record.insightId &&
              revision.learnerSubjectId == record.learnerSubjectId,
        )
        .toList(growable: false)
      ..sort((a, b) {
        final time = a.occurredAt.compareTo(b.occurredAt);
        if (time != 0) return time;
        return a.revisionId.compareTo(b.revisionId);
      });

    var statement = record.statement;
    var confidence = record.confidence;
    var confirmed = false;
    var disputed = false;
    var revoked = false;

    for (final revision in ordered) {
      switch (revision.type) {
        case PersonalInsightRevisionType.confirm:
          confirmed = true;
          disputed = false;
        case PersonalInsightRevisionType.dispute:
          disputed = true;
          confirmed = false;
        case PersonalInsightRevisionType.correct:
          statement = revision.replacementStatement!;
          confidence = revision.replacementConfidence ?? confidence;
          disputed = false;
        case PersonalInsightRevisionType.revoke:
          revoked = true;
      }
    }

    return PersonalInsightEffectiveView(
      original: record,
      statement: statement,
      confidence: confidence,
      learnerConfirmed: confirmed,
      disputed: disputed,
      revoked: revoked,
      appliedRevisions: ordered,
    );
  }
}

class PersonalInsightAccessGrant {
  final String grantId;
  final String actorId;
  final String learnerSubjectId;
  final Set<PersonalInsightPurpose> allowedPurposes;
  final Set<PersonalInsightPermission> permissions;
  final Set<PersonalInsightSensitivity> allowedSensitivities;
  final Set<String> allowedDomainScopes;
  final Set<String> evidenceIds;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool revoked;

  PersonalInsightAccessGrant({
    required this.grantId,
    required this.actorId,
    required this.learnerSubjectId,
    required this.allowedPurposes,
    required this.permissions,
    required this.allowedSensitivities,
    required this.allowedDomainScopes,
    required this.evidenceIds,
    required this.issuedAt,
    required this.expiresAt,
    this.revoked = false,
  }) : allowedPurposes = Set<PersonalInsightPurpose>.unmodifiable(
         allowedPurposes,
       ),
       permissions = Set<PersonalInsightPermission>.unmodifiable(permissions),
       allowedSensitivities = Set<PersonalInsightSensitivity>.unmodifiable(
         allowedSensitivities,
       ),
       allowedDomainScopes = Set<String>.unmodifiable(allowedDomainScopes),
       evidenceIds = Set<String>.unmodifiable(evidenceIds);

  bool isCurrentAt(DateTime at) =>
      !revoked && !at.isBefore(issuedAt) && at.isBefore(expiresAt);
}

class PersonalInsightAccessRequest {
  final String actorId;
  final String learnerSubjectId;
  final String insightId;
  final PersonalInsightPurpose purpose;
  final PersonalInsightPermission permission;
  final PersonalInsightSensitivity sensitivity;
  final String domainScope;
  final DateTime requestedAt;
  final String? accessReceiptReservationId;

  const PersonalInsightAccessRequest({
    required this.actorId,
    required this.learnerSubjectId,
    required this.insightId,
    required this.purpose,
    required this.permission,
    required this.sensitivity,
    required this.domainScope,
    required this.requestedAt,
    this.accessReceiptReservationId,
  });
}

class PersonalInsightAccessDecision {
  final bool allowed;
  final String reason;
  final String? grantId;
  final bool accessReceiptRequired;
  final String? accessReceiptReservationId;

  const PersonalInsightAccessDecision._({
    required this.allowed,
    required this.reason,
    required this.accessReceiptRequired,
    this.grantId,
    this.accessReceiptReservationId,
  });

  const PersonalInsightAccessDecision.allow({
    required String grantId,
    required bool accessReceiptRequired,
    String? accessReceiptReservationId,
  }) : this._(
         allowed: true,
         reason: 'authorized',
         grantId: grantId,
         accessReceiptRequired: accessReceiptRequired,
         accessReceiptReservationId: accessReceiptReservationId,
       );

  const PersonalInsightAccessDecision.deny(String reason)
    : this._(allowed: false, reason: reason, accessReceiptRequired: false);
}

class PersonalInsightAccessEvaluator {
  const PersonalInsightAccessEvaluator();

  PersonalInsightAccessDecision evaluate({
    required PersonalInsightRecord record,
    required PersonalInsightAccessRequest request,
    required Iterable<PersonalInsightAccessGrant> grants,
  }) {
    if (record.insightId != request.insightId ||
        record.learnerSubjectId != request.learnerSubjectId) {
      return const PersonalInsightAccessDecision.deny(
        'Insight access request does not match the exact learner subject and insight.',
      );
    }
    if (!record.domainScopes.contains(request.domainScope) ||
        record.sensitivity != request.sensitivity) {
      return const PersonalInsightAccessDecision.deny(
        'Insight access request does not match the record scope or sensitivity.',
      );
    }
    if (!record.isCurrentAt(request.requestedAt)) {
      return const PersonalInsightAccessDecision.deny(
        'Insight is expired or not yet active.',
      );
    }

    final sensitiveUse =
        request.permission == PersonalInsightPermission.read ||
        request.permission == PersonalInsightPermission.use;
    final receiptRequired =
        sensitiveUse &&
        request.sensitivity != PersonalInsightSensitivity.ordinaryPreference;

    for (final grant in grants) {
      if (grant.actorId != request.actorId ||
          grant.learnerSubjectId != request.learnerSubjectId) {
        continue;
      }
      if (!grant.isCurrentAt(request.requestedAt)) continue;
      if (grant.evidenceIds.isEmpty) continue;
      if (!grant.allowedPurposes.contains(request.purpose)) continue;
      if (!grant.permissions.contains(request.permission)) continue;
      if (!grant.allowedSensitivities.contains(request.sensitivity)) continue;
      if (!grant.allowedDomainScopes.contains(request.domainScope)) continue;

      if (receiptRequired &&
          (request.accessReceiptReservationId == null ||
              request.accessReceiptReservationId!.trim().isEmpty)) {
        continue;
      }

      return PersonalInsightAccessDecision.allow(
        grantId: grant.grantId,
        accessReceiptRequired: receiptRequired,
        accessReceiptReservationId: receiptRequired
            ? request.accessReceiptReservationId
            : null,
      );
    }

    return const PersonalInsightAccessDecision.deny(
      'No current evidenced purpose-bound insight grant authorizes this request.',
    );
  }
}

class PersonalInsightAccessReceipt {
  final String receiptId;
  final String actorId;
  final String learnerSubjectId;
  final String insightId;
  final String grantId;
  final PersonalInsightPurpose purpose;
  final PersonalInsightPermission permission;
  final PersonalInsightSensitivity sensitivity;
  final String domainScope;
  final DateTime recordedAt;

  const PersonalInsightAccessReceipt({
    required this.receiptId,
    required this.actorId,
    required this.learnerSubjectId,
    required this.insightId,
    required this.grantId,
    required this.purpose,
    required this.permission,
    required this.sensitivity,
    required this.domainScope,
    required this.recordedAt,
  });
}

class PersonalInsightValidator {
  const PersonalInsightValidator();

  void validateRecord(PersonalInsightRecord record) {
    _requireIdentifier(record.insightId, 'Insight ID');
    _requireIdentifier(record.learnerSubjectId, 'Learner subject ID');
    _requireIdentifier(record.claimType, 'Claim type');
    if (record.statement.trim().isEmpty) {
      throw const PersonalInsightException('Insight statement is required.');
    }
    if (record.domainScopes.isEmpty) {
      throw const PersonalInsightException(
        'At least one domain scope is required.',
      );
    }
    if (record.evidenceIds.isEmpty) {
      throw const PersonalInsightException(
        'Every insight requires provenance evidence.',
      );
    }
    if (record.limitations.trim().isEmpty) {
      throw const PersonalInsightException(
        'Every insight must state uncertainty or limitations.',
      );
    }
    if (!record.createdAt.isBefore(record.reviewAt) ||
        record.reviewAt.isAfter(record.expiresAt)) {
      throw const PersonalInsightException(
        'Insight review and expiry times are invalid.',
      );
    }
    final confidence = record.confidence;
    if (confidence != null &&
        (!confidence.isFinite || confidence < 0 || confidence > 1)) {
      throw const PersonalInsightException(
        'Insight confidence must be finite and between zero and one.',
      );
    }
    if (record.sourceType == PersonalInsightSourceType.modelHypothesis &&
        confidence == null) {
      throw const PersonalInsightException(
        'Model hypotheses require explicit confidence.',
      );
    }
    if (record.clinicalDiagnosisClaim &&
        record.sourceType != PersonalInsightSourceType.clinicianProvided) {
      throw const PersonalInsightException(
        'Only clinician-provided records may carry a clinical diagnosis claim.',
      );
    }
    if (record.sourceType == PersonalInsightSourceType.modelHypothesis &&
        record.clinicalDiagnosisClaim) {
      throw const PersonalInsightException(
        'A model hypothesis cannot create a clinical diagnosis claim.',
      );
    }
  }

  void validateRevision(
    PersonalInsightRevision revision, {
    required PersonalInsightRecord record,
  }) {
    _requireIdentifier(revision.revisionId, 'Revision ID');
    _requireIdentifier(revision.actorId, 'Revision actor ID');
    if (revision.insightId != record.insightId ||
        revision.learnerSubjectId != record.learnerSubjectId) {
      throw const PersonalInsightException(
        'Revision must target the exact insight and learner subject.',
      );
    }
    if (revision.reason.trim().isEmpty) {
      throw const PersonalInsightException('Revision reason is required.');
    }
    if (revision.occurredAt.isBefore(record.createdAt)) {
      throw const PersonalInsightException(
        'Revision cannot predate the original insight.',
      );
    }
    if (revision.type == PersonalInsightRevisionType.correct &&
        (revision.replacementStatement == null ||
            revision.replacementStatement!.trim().isEmpty)) {
      throw const PersonalInsightException(
        'Correction revisions require replacement text.',
      );
    }
    final confidence = revision.replacementConfidence;
    if (confidence != null &&
        (!confidence.isFinite || confidence < 0 || confidence > 1)) {
      throw const PersonalInsightException(
        'Replacement confidence must be finite and between zero and one.',
      );
    }
  }

  static void _requireIdentifier(String value, String label) {
    if (value.trim().isEmpty) {
      throw PersonalInsightException('$label is required.');
    }
  }
}

class PersonalInsightPolicyBoundary {
  const PersonalInsightPolicyBoundary();

  bool vaultGrantAloneAuthorizesModelMaterialization() => false;

  bool separateModelContextGrantRequired() => true;

  bool modelHypothesisMayCreateClinicalDiagnosis() => false;

  bool insightMayCreateMastery() => false;

  bool insightMayCreateGradeOrCredit() => false;

  bool insightMayMintCredential() => false;

  bool insightMayCreatePublicProfileByDefault() => false;

  bool insightMayFederateAcrossServicesByDefault() => false;

  bool sensitiveInsightMayBeUsedForCommercialTargeting() => false;

  bool descriptiveRoleAloneCreatesAccess() => false;

  bool learnerCorrectionRewritesOriginalProvenance() => false;

  bool correctionsAreAppendOnly() => true;
}

class PersonalInsightException implements Exception {
  final String message;

  const PersonalInsightException(this.message);

  @override
  String toString() => 'PersonalInsightException: $message';
}
