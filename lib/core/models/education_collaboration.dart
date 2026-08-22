enum EducationCollaborationPurpose {
  assignmentDiscussion,
  peerHelp,
  groupProject,
  teacherAnnouncement,
  tutoring,
  officeHours,
  studyGroup,
  learnerSupport,
}

enum EducationCollaborationDataClass {
  sharedInstructional,
  assignmentContext,
  peerConversation,
  supportConversation,
  safeguardingRestricted,
}

enum EducationCollaborationPermission {
  read,
  contribute,
  moderate,
  manageMembership,
}

class EducationCollaborationSpace {
  final String spaceId;
  final String circleId;
  final EducationCollaborationPurpose purpose;
  final EducationCollaborationDataClass dataClass;
  final Set<String> participantActorIds;
  final String? assignmentId;
  final String? learningGroupId;

  const EducationCollaborationSpace({
    required this.spaceId,
    required this.circleId,
    required this.purpose,
    required this.dataClass,
    required this.participantActorIds,
    this.assignmentId,
    this.learningGroupId,
  });
}

/// Explicit authority to use one education collaboration space.
///
/// Descriptive labels such as guardian, teacher, counselor, or principal are
/// intentionally absent: those labels must be converted to evidenced authority
/// elsewhere before they can produce one of these grants.
class EducationCollaborationAccessGrant {
  final String grantId;
  final String actorId;
  final String spaceId;
  final Set<EducationCollaborationPermission> permissions;
  final Set<EducationCollaborationPurpose> allowedPurposes;
  final Set<String> evidenceIds;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool revoked;
  final bool safeguardingAuthority;
  final bool privilegedRead;

  const EducationCollaborationAccessGrant({
    required this.grantId,
    required this.actorId,
    required this.spaceId,
    required this.permissions,
    required this.allowedPurposes,
    required this.evidenceIds,
    required this.issuedAt,
    required this.expiresAt,
    this.revoked = false,
    this.safeguardingAuthority = false,
    this.privilegedRead = false,
  });
}

class EducationCollaborationAccessRequest {
  final String actorId;
  final EducationCollaborationPermission permission;
  final EducationCollaborationPurpose purpose;
  final DateTime requestedAt;
  final bool breakGlass;
  final String? reasonCode;
  final String? accessReceiptReservationId;

  const EducationCollaborationAccessRequest({
    required this.actorId,
    required this.permission,
    required this.purpose,
    required this.requestedAt,
    this.breakGlass = false,
    this.reasonCode,
    this.accessReceiptReservationId,
  });
}

class EducationCollaborationAccessDecision {
  final bool allowed;
  final String reason;
  final String? grantId;
  final bool accessReceiptRequired;
  final String? accessReceiptReservationId;

  const EducationCollaborationAccessDecision._({
    required this.allowed,
    required this.reason,
    required this.accessReceiptRequired,
    this.grantId,
    this.accessReceiptReservationId,
  });

  const EducationCollaborationAccessDecision.allow({
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

  const EducationCollaborationAccessDecision.deny(String reason)
    : this._(allowed: false, reason: reason, accessReceiptRequired: false);
}

class EducationCollaborationAccessEvaluator {
  const EducationCollaborationAccessEvaluator();

  EducationCollaborationAccessDecision evaluate({
    required EducationCollaborationSpace space,
    required EducationCollaborationAccessRequest request,
    required Iterable<EducationCollaborationAccessGrant> grants,
  }) {
    for (final grant in grants) {
      if (grant.actorId != request.actorId || grant.spaceId != space.spaceId) {
        continue;
      }
      if (grant.revoked) continue;
      if (grant.evidenceIds.isEmpty) continue;
      if (request.requestedAt.isBefore(grant.issuedAt) ||
          !request.requestedAt.isBefore(grant.expiresAt)) {
        continue;
      }
      if (!grant.permissions.contains(request.permission)) continue;
      if (!grant.allowedPurposes.contains(request.purpose) ||
          request.purpose != space.purpose) {
        continue;
      }

      final isRead =
          request.permission == EducationCollaborationPermission.read;
      final isSafeguardingRestricted =
          space.dataClass ==
          EducationCollaborationDataClass.safeguardingRestricted;
      final receiptRequired =
          isRead && (grant.privilegedRead || isSafeguardingRestricted);

      if (isSafeguardingRestricted) {
        if (!request.breakGlass || !grant.safeguardingAuthority) continue;
        if (request.reasonCode == null || request.reasonCode!.trim().isEmpty) {
          continue;
        }
      } else if (request.breakGlass) {
        // Break-glass semantics are reserved for the restricted safeguarding
        // path; they are not a shortcut around ordinary collaboration access.
        continue;
      }

      if (receiptRequired &&
          (request.accessReceiptReservationId == null ||
              request.accessReceiptReservationId!.trim().isEmpty)) {
        continue;
      }

      return EducationCollaborationAccessDecision.allow(
        grantId: grant.grantId,
        accessReceiptRequired: receiptRequired,
        accessReceiptReservationId: receiptRequired
            ? request.accessReceiptReservationId
            : null,
      );
    }

    return const EducationCollaborationAccessDecision.deny(
      'No current evidenced purpose-bound access grant authorizes this request.',
    );
  }
}

class EducationCollaborationAccessReceipt {
  final String receiptId;
  final String actorId;
  final String spaceId;
  final String grantId;
  final EducationCollaborationPermission permission;
  final EducationCollaborationPurpose purpose;
  final bool breakGlass;
  final String? reasonCode;
  final DateTime recordedAt;

  const EducationCollaborationAccessReceipt({
    required this.receiptId,
    required this.actorId,
    required this.spaceId,
    required this.grantId,
    required this.permission,
    required this.purpose,
    required this.breakGlass,
    required this.recordedAt,
    this.reasonCode,
  });
}

class EducationCollaborationPrivacyPolicy {
  const EducationCollaborationPrivacyPolicy();

  bool rawConversationIsOfficialLearnerRecord(
    EducationCollaborationSpace space,
  ) => false;

  bool rawConversationIsMasteryEvidence(EducationCollaborationSpace space) =>
      false;

  bool guardianRelationshipAloneAllowsTranscriptRead() => false;

  bool educatorRoleAloneAllowsTranscriptRead() => false;

  bool institutionMembershipAloneAllowsTranscriptRead() => false;

  bool publicAudienceAllowedByDefault() => false;
}
