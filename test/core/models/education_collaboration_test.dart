import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/education_collaboration.dart';

void main() {
  const evaluator = EducationCollaborationAccessEvaluator();
  const privacy = EducationCollaborationPrivacyPolicy();
  final now = DateTime.utc(2026, 8, 21, 20, 50);

  const peerSpace = EducationCollaborationSpace(
    spaceId: 'space:peer:1',
    circleId: 'circle:class:1',
    purpose: EducationCollaborationPurpose.peerHelp,
    dataClass: EducationCollaborationDataClass.peerConversation,
    participantActorIds: <String>{'learner:1', 'learner:2'},
    learningGroupId: 'group:math:1',
  );

  test('relationship or institution labels alone never authorize transcript access', () {
    expect(privacy.guardianRelationshipAloneAllowsTranscriptRead(), isFalse);
    expect(privacy.educatorRoleAloneAllowsTranscriptRead(), isFalse);
    expect(privacy.institutionMembershipAloneAllowsTranscriptRead(), isFalse);
    expect(privacy.publicAudienceAllowedByDefault(), isFalse);
  });

  test('current evidenced purpose-bound grant authorizes exact space and purpose', () {
    final grant = EducationCollaborationAccessGrant(
      grantId: 'grant:1',
      actorId: 'learner:1',
      spaceId: peerSpace.spaceId,
      permissions: const <EducationCollaborationPermission>{
        EducationCollaborationPermission.read,
        EducationCollaborationPermission.contribute,
      },
      allowedPurposes: const <EducationCollaborationPurpose>{
        EducationCollaborationPurpose.peerHelp,
      },
      evidenceIds: const <String>{'membership-evidence:1'},
      issuedAt: now.subtract(const Duration(hours: 1)),
      expiresAt: now.add(const Duration(days: 1)),
    );

    final decision = evaluator.evaluate(
      space: peerSpace,
      request: EducationCollaborationAccessRequest(
        actorId: 'learner:1',
        permission: EducationCollaborationPermission.read,
        purpose: EducationCollaborationPurpose.peerHelp,
        requestedAt: now,
      ),
      grants: <EducationCollaborationAccessGrant>[grant],
    );

    expect(decision.allowed, isTrue);
    expect(decision.grantId, equals('grant:1'));
  });

  test('grant for another purpose cannot be reused to browse conversation', () {
    final grant = EducationCollaborationAccessGrant(
      grantId: 'grant:wrong-purpose',
      actorId: 'teacher:1',
      spaceId: peerSpace.spaceId,
      permissions: const <EducationCollaborationPermission>{
        EducationCollaborationPermission.read,
      },
      allowedPurposes: const <EducationCollaborationPurpose>{
        EducationCollaborationPurpose.assignmentDiscussion,
      },
      evidenceIds: const <String>{'teacher-authority:1'},
      issuedAt: now.subtract(const Duration(hours: 1)),
      expiresAt: now.add(const Duration(hours: 1)),
    );

    final decision = evaluator.evaluate(
      space: peerSpace,
      request: EducationCollaborationAccessRequest(
        actorId: 'teacher:1',
        permission: EducationCollaborationPermission.read,
        purpose: EducationCollaborationPurpose.peerHelp,
        requestedAt: now,
      ),
      grants: <EducationCollaborationAccessGrant>[grant],
    );

    expect(decision.allowed, isFalse);
  });

  test('expired or unevidenced grants fail closed', () {
    final expired = EducationCollaborationAccessGrant(
      grantId: 'grant:expired',
      actorId: 'principal:1',
      spaceId: peerSpace.spaceId,
      permissions: const <EducationCollaborationPermission>{
        EducationCollaborationPermission.read,
      },
      allowedPurposes: const <EducationCollaborationPurpose>{
        EducationCollaborationPurpose.peerHelp,
      },
      evidenceIds: const <String>{'principal-delegation:1'},
      issuedAt: now.subtract(const Duration(days: 2)),
      expiresAt: now.subtract(const Duration(days: 1)),
    );
    final unevidenced = EducationCollaborationAccessGrant(
      grantId: 'grant:unevidenced',
      actorId: 'principal:1',
      spaceId: peerSpace.spaceId,
      permissions: const <EducationCollaborationPermission>{
        EducationCollaborationPermission.read,
      },
      allowedPurposes: const <EducationCollaborationPurpose>{
        EducationCollaborationPurpose.peerHelp,
      },
      evidenceIds: const <String>{},
      issuedAt: now.subtract(const Duration(hours: 1)),
      expiresAt: now.add(const Duration(hours: 1)),
    );

    final decision = evaluator.evaluate(
      space: peerSpace,
      request: EducationCollaborationAccessRequest(
        actorId: 'principal:1',
        permission: EducationCollaborationPermission.read,
        purpose: EducationCollaborationPurpose.peerHelp,
        requestedAt: now,
      ),
      grants: <EducationCollaborationAccessGrant>[expired, unevidenced],
    );

    expect(decision.allowed, isFalse);
  });

  test('safeguarding break-glass requires explicit authority reason and receipt', () {
    const space = EducationCollaborationSpace(
      spaceId: 'space:safeguarding:1',
      circleId: 'circle:support:1',
      purpose: EducationCollaborationPurpose.learnerSupport,
      dataClass: EducationCollaborationDataClass.safeguardingRestricted,
      participantActorIds: <String>{'learner:1', 'support:1'},
    );
    final grant = EducationCollaborationAccessGrant(
      grantId: 'grant:safeguarding:1',
      actorId: 'safeguarding:officer:1',
      spaceId: space.spaceId,
      permissions: const <EducationCollaborationPermission>{
        EducationCollaborationPermission.read,
      },
      allowedPurposes: const <EducationCollaborationPurpose>{
        EducationCollaborationPurpose.learnerSupport,
      },
      evidenceIds: const <String>{'safeguarding-authority:1'},
      issuedAt: now.subtract(const Duration(minutes: 5)),
      expiresAt: now.add(const Duration(minutes: 30)),
      safeguardingAuthority: true,
    );

    final missingReceipt = evaluator.evaluate(
      space: space,
      request: EducationCollaborationAccessRequest(
        actorId: 'safeguarding:officer:1',
        permission: EducationCollaborationPermission.read,
        purpose: EducationCollaborationPurpose.learnerSupport,
        requestedAt: now,
        breakGlass: true,
        reasonCode: 'immediate-safety-review',
      ),
      grants: <EducationCollaborationAccessGrant>[grant],
    );
    expect(missingReceipt.allowed, isFalse);

    final authorized = evaluator.evaluate(
      space: space,
      request: EducationCollaborationAccessRequest(
        actorId: 'safeguarding:officer:1',
        permission: EducationCollaborationPermission.read,
        purpose: EducationCollaborationPurpose.learnerSupport,
        requestedAt: now,
        breakGlass: true,
        reasonCode: 'immediate-safety-review',
        accessReceiptId: 'receipt:access:1',
      ),
      grants: <EducationCollaborationAccessGrant>[grant],
    );
    expect(authorized.allowed, isTrue);
  });

  test('raw collaboration logs are not learner records or mastery evidence', () {
    expect(privacy.rawConversationIsOfficialLearnerRecord(peerSpace), isFalse);
    expect(privacy.rawConversationIsMasteryEvidence(peerSpace), isFalse);
  });
}
