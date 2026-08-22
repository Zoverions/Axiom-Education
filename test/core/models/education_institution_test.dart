import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/education_institution.dart';

void main() {
  group('education institutional authority boundary', () {
    test('role assignment never grants authority by itself', () {
      const role = EducationRoleAssignment(
        assignmentId: 'role:teacher:1',
        actorId: 'actor:teacher:1',
        institutionId: 'school:1',
        roles: <EducationRole>{EducationRole.teacher},
        evidenceIds: <String>{'evidence:employment:1'},
      );

      expect(role.hasEvidence, isTrue);
      expect(role.grantsAuthority, isFalse);
    });

    test('authority projection fails closed without evidence and outside scope', () {
      final now = DateTime.utc(2026, 8, 21, 20);
      final unevidenced = EducationAuthorityGrant(
        grantId: 'grant:1',
        actorId: 'actor:teacher:1',
        institutionId: 'school:1',
        scopeKind: EducationAuthorityScopeKind.learningGroup,
        scopeIds: const <String>{'class:math:1'},
        capabilityIds: const <String>{'education.assignment.create'},
        evidenceIds: const <String>{},
        validFrom: now.subtract(const Duration(days: 1)),
      );

      expect(
        unevidenced.permits(
          capabilityId: 'education.assignment.create',
          scopeId: 'class:math:1',
          at: now,
        ),
        isFalse,
      );

      final evidenced = EducationAuthorityGrant(
        grantId: 'grant:2',
        actorId: 'actor:teacher:1',
        institutionId: 'school:1',
        scopeKind: EducationAuthorityScopeKind.learningGroup,
        scopeIds: const <String>{'class:math:1'},
        capabilityIds: const <String>{'education.assignment.create'},
        evidenceIds: const <String>{'mesh:delegation:1'},
        validFrom: now.subtract(const Duration(days: 1)),
        validUntil: now.add(const Duration(days: 30)),
      );

      expect(
        evidenced.permits(
          capabilityId: 'education.assignment.create',
          scopeId: 'class:math:1',
          at: now,
        ),
        isTrue,
      );
      expect(
        evidenced.permits(
          capabilityId: 'education.assignment.create',
          scopeId: 'class:science:2',
          at: now,
        ),
        isFalse,
      );
      expect(
        evidenced.permits(
          capabilityId: 'education.grade.finalize',
          scopeId: 'class:math:1',
          at: now,
        ),
        isFalse,
      );
    });

    test('guardian learning preference is input, not a veto or capability', () {
      final now = DateTime.utc(2026, 8, 21, 20);
      final preference = GuardianLearningPreference(
        preferenceId: 'preference:1',
        guardianActorId: 'actor:guardian:1',
        learnerSubjectId: 'learner:1',
        competencyIds: const <String>{'health:topic:1'},
        pacing: GuardianPacingPreference.slowDownWhenAllowed,
        contentTiming: GuardianContentTimingPreference.deferWhenAllowed,
        authorityEvidenceIds: const <String>{'relationship:guardian:1'},
        recordedAt: now,
      );

      expect(preference.isAuthorityRelationshipEvidenced, isTrue);
      expect(preference.grantsAuthority, isFalse);
      expect(preference.canSuppressRequiredContent, isFalse);
      expect(preference.isCurrentAt(now.add(const Duration(days: 1))), isTrue);
    });
  });
}
