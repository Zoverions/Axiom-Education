import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/education_institution.dart';
import 'package:ontarioedai/core/services/institution_roster_admission.dart';

void main() {
  const service = InstitutionRosterAdmissionService();

  ExternalRosterCandidate educatorCandidate() => const ExternalRosterCandidate(
        sourceSystemId: 'sis:school-board:1',
        externalSubjectId: 'teacher:external:27',
        subjectKind: ExternalRosterSubjectKind.educator,
        institutionId: 'school:1',
        externalLearningGroupIds: <String>{'class:math:1'},
        assertedRoleLabels: <String>{'Teacher'},
        sourceEvidenceIds: <String>{'source:roster:record:27'},
      );

  test('external school record cannot create local role without identity evidence', () {
    expect(
      () => service.admit(
        candidate: educatorCandidate(),
        localActorId: 'actor:teacher:1',
        identityBindingEvidenceIds: const <String>{},
        admissionEvidenceIds: const <String>{'admission:1'},
        admittedRoles: const <EducationRole>{EducationRole.teacher},
      ),
      throwsA(isA<RosterAdmissionException>()),
    );
  });

  test('admitted roster role remains descriptive and grants no Mesh authority', () {
    final decision = service.admit(
      candidate: educatorCandidate(),
      localActorId: 'actor:teacher:1',
      identityBindingEvidenceIds: const <String>{'identity:binding:1'},
      admissionEvidenceIds: const <String>{'admission:review:1'},
      admittedRoles: const <EducationRole>{EducationRole.teacher},
    );

    expect(decision.localActorId, 'actor:teacher:1');
    expect(decision.descriptiveRoles, contains(EducationRole.teacher));
    expect(decision.learningGroupIds, contains('class:math:1'));
    expect(decision.grantsMeshAuthority, isFalse);
    expect(decision.admissionEvidenceIds, contains('source:roster:record:27'));
    expect(decision.admissionEvidenceIds, contains('identity:binding:1'));
    expect(decision.admissionEvidenceIds, contains('admission:review:1'));
  });

  test('subject kind constrains admitted descriptive role', () {
    final learner = const ExternalRosterCandidate(
      sourceSystemId: 'sis:school:1',
      externalSubjectId: 'student:9',
      subjectKind: ExternalRosterSubjectKind.learner,
      institutionId: 'school:1',
      sourceEvidenceIds: <String>{'source:student:9'},
    );

    expect(
      () => service.admit(
        candidate: learner,
        localActorId: 'actor:student:9',
        identityBindingEvidenceIds: const <String>{'identity:student:9'},
        admissionEvidenceIds: const <String>{'admission:student:9'},
        admittedRoles: const <EducationRole>{EducationRole.principal},
      ),
      throwsA(isA<RosterAdmissionException>()),
    );
  });
}
