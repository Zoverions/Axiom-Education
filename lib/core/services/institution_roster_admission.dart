import '../models/education_institution.dart';

enum ExternalRosterSubjectKind {
  learner,
  guardian,
  educator,
  administrator,
  counselor,
  support,
}

/// An identity/role/enrollment claim imported from an existing school system.
///
/// This is deliberately an untrusted candidate. Importing SIS/LMS data does
/// not create Mesh authority, prove a legal relationship, or make the source
/// the owner of the learner's sovereign record.
class ExternalRosterCandidate {
  final String sourceSystemId;
  final String externalSubjectId;
  final ExternalRosterSubjectKind subjectKind;
  final String institutionId;
  final Set<String> externalLearningGroupIds;
  final Set<String> assertedRoleLabels;
  final Set<String> sourceEvidenceIds;

  const ExternalRosterCandidate({
    required this.sourceSystemId,
    required this.externalSubjectId,
    required this.subjectKind,
    required this.institutionId,
    this.externalLearningGroupIds = const <String>{},
    this.assertedRoleLabels = const <String>{},
    this.sourceEvidenceIds = const <String>{},
  });
}

class RosterAdmissionDecision {
  final String localActorId;
  final String institutionId;
  final Set<EducationRole> descriptiveRoles;
  final Set<String> learningGroupIds;
  final Set<String> admissionEvidenceIds;

  const RosterAdmissionDecision({
    required this.localActorId,
    required this.institutionId,
    required this.descriptiveRoles,
    required this.learningGroupIds,
    required this.admissionEvidenceIds,
  });

  /// Roster admission establishes domain context only.
  bool get grantsMeshAuthority => false;
}

class RosterAdmissionException implements Exception {
  final String message;

  const RosterAdmissionException(this.message);

  @override
  String toString() => 'RosterAdmissionException: $message';
}

/// Converts a school-system claim into local Education context only after an
/// explicit identity binding and evidence-backed admission step.
class InstitutionRosterAdmissionService {
  const InstitutionRosterAdmissionService();

  RosterAdmissionDecision admit({
    required ExternalRosterCandidate candidate,
    required String localActorId,
    required Set<String> identityBindingEvidenceIds,
    required Set<String> admissionEvidenceIds,
    required Set<EducationRole> admittedRoles,
  }) {
    if (localActorId.trim().isEmpty) {
      throw const RosterAdmissionException('A local actor binding is required.');
    }
    if (identityBindingEvidenceIds.isEmpty) {
      throw const RosterAdmissionException(
        'Roster admission requires identity-binding evidence.',
      );
    }
    if (admissionEvidenceIds.isEmpty || candidate.sourceEvidenceIds.isEmpty) {
      throw const RosterAdmissionException(
        'Roster admission requires source and local admission evidence.',
      );
    }
    if (!_rolesFitSubject(candidate.subjectKind, admittedRoles)) {
      throw const RosterAdmissionException(
        'Admitted roles are incompatible with the imported subject kind.',
      );
    }

    return RosterAdmissionDecision(
      localActorId: localActorId,
      institutionId: candidate.institutionId,
      descriptiveRoles: Set<EducationRole>.unmodifiable(admittedRoles),
      learningGroupIds:
          Set<String>.unmodifiable(candidate.externalLearningGroupIds),
      admissionEvidenceIds: Set<String>.unmodifiable(<String>{
        ...candidate.sourceEvidenceIds,
        ...identityBindingEvidenceIds,
        ...admissionEvidenceIds,
      }),
    );
  }

  bool _rolesFitSubject(
    ExternalRosterSubjectKind subjectKind,
    Set<EducationRole> roles,
  ) {
    if (roles.isEmpty) return false;

    final allowed = switch (subjectKind) {
      ExternalRosterSubjectKind.learner => const <EducationRole>{
          EducationRole.learner,
        },
      ExternalRosterSubjectKind.guardian => const <EducationRole>{
          EducationRole.guardian,
        },
      ExternalRosterSubjectKind.educator => const <EducationRole>{
          EducationRole.teacher,
          EducationRole.assessor,
          EducationRole.mentor,
        },
      ExternalRosterSubjectKind.administrator => const <EducationRole>{
          EducationRole.principal,
          EducationRole.administrator,
        },
      ExternalRosterSubjectKind.counselor => const <EducationRole>{
          EducationRole.guidanceCounselor,
        },
      ExternalRosterSubjectKind.support => const <EducationRole>{
          EducationRole.supportWorker,
        },
    };

    return roles.every(allowed.contains);
  }
}
