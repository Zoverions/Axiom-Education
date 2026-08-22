import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/personal_insight_vault.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 22, 12);
  final reviewAt = DateTime.utc(2026, 9, 22, 12);
  final expiresAt = DateTime.utc(2026, 10, 22, 12);
  final requestedAt = DateTime.utc(2026, 8, 23, 12);

  PersonalInsightRecord modelHypothesis({
    String learnerSubjectId = 'learner:1',
    PersonalInsightSensitivity sensitivity =
        PersonalInsightSensitivity.psychologicalSensitive,
    bool clinicalDiagnosisClaim = false,
  }) {
    return PersonalInsightRecord(
      insightId: 'insight:1',
      learnerSubjectId: learnerSubjectId,
      claimType: 'reasoning.calibration.counterexample-response',
      statement:
          'Explicit counterexamples appear to improve calibration in this domain.',
      sensitivity: sensitivity,
      sourceType: PersonalInsightSourceType.modelHypothesis,
      evidenceIds: const {'evidence:task-series-1'},
      domainScopes: const {'mathematics'},
      confidence: 0.66,
      limitations: 'Eight comparable tasks; review after additional evidence.',
      createdAt: createdAt,
      reviewAt: reviewAt,
      expiresAt: expiresAt,
      clinicalDiagnosisClaim: clinicalDiagnosisClaim,
    );
  }

  PersonalInsightAccessGrant grant({
    String actorId = 'actor:tutor',
    String learnerSubjectId = 'learner:1',
    Set<PersonalInsightPermission> permissions = const {
      PersonalInsightPermission.read,
      PersonalInsightPermission.use,
    },
    Set<PersonalInsightSensitivity> sensitivities = const {
      PersonalInsightSensitivity.psychologicalSensitive,
    },
  }) {
    return PersonalInsightAccessGrant(
      grantId: 'grant:1',
      actorId: actorId,
      learnerSubjectId: learnerSubjectId,
      allowedPurposes: const {PersonalInsightPurpose.metacognitiveFeedback},
      permissions: permissions,
      allowedSensitivities: sensitivities,
      allowedDomainScopes: const {'mathematics'},
      evidenceIds: const {'authority:1'},
      issuedAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  PersonalInsightAccessRequest request({
    String actorId = 'actor:tutor',
    String learnerSubjectId = 'learner:1',
    PersonalInsightPermission permission = PersonalInsightPermission.use,
    PersonalInsightSensitivity sensitivity =
        PersonalInsightSensitivity.psychologicalSensitive,
    String? receipt = 'receipt-reservation:1',
  }) {
    return PersonalInsightAccessRequest(
      actorId: actorId,
      learnerSubjectId: learnerSubjectId,
      insightId: 'insight:1',
      purpose: PersonalInsightPurpose.metacognitiveFeedback,
      permission: permission,
      sensitivity: sensitivity,
      domainScope: 'mathematics',
      requestedAt: requestedAt,
      accessReceiptReservationId: receipt,
    );
  }

  test('model hypothesis is contextual evidence, never mastery or grade', () {
    final record = modelHypothesis();
    const validator = PersonalInsightValidator();

    validator.validateRecord(record);

    expect(record.establishesMastery, isFalse);
    expect(record.establishesGradeOrCredit, isFalse);
    expect(record.createsCredential, isFalse);
    expect(record.isPublicProfile, isFalse);
  });

  test('model hypothesis requires confidence and limitations', () {
    const validator = PersonalInsightValidator();
    final record = PersonalInsightRecord(
      insightId: 'insight:missing-confidence',
      learnerSubjectId: 'learner:1',
      claimType: 'strategy.response',
      statement: 'Worked examples may help here.',
      sensitivity: PersonalInsightSensitivity.educationalSensitive,
      sourceType: PersonalInsightSourceType.modelHypothesis,
      evidenceIds: const {'evidence:1'},
      domainScopes: const {'mathematics'},
      limitations: 'Preliminary pattern.',
      createdAt: createdAt,
      reviewAt: reviewAt,
      expiresAt: expiresAt,
    );

    expect(
      () => validator.validateRecord(record),
      throwsA(isA<PersonalInsightException>()),
    );
  });

  test('model hypothesis cannot create a clinical diagnosis claim', () {
    const validator = PersonalInsightValidator();

    expect(
      () => validator.validateRecord(
        modelHypothesis(
          sensitivity: PersonalInsightSensitivity.clinicalHealthRestricted,
          clinicalDiagnosisClaim: true,
        ),
      ),
      throwsA(isA<PersonalInsightException>()),
    );
  });

  test('clinician diagnosis claim requires attributed clinician source', () {
    const validator = PersonalInsightValidator();
    final missingActor = PersonalInsightRecord(
      insightId: 'insight:clinical',
      learnerSubjectId: 'learner:1',
      claimType: 'clinical.documented-diagnosis',
      statement: 'Clinician-documented information supplied for accommodation.',
      sensitivity: PersonalInsightSensitivity.clinicalHealthRestricted,
      sourceType: PersonalInsightSourceType.clinicianProvided,
      evidenceIds: const {'clinical-document:1'},
      domainScopes: const {'accessibility'},
      limitations: 'Use only for authorized accommodation/support purposes.',
      createdAt: createdAt,
      reviewAt: reviewAt,
      expiresAt: expiresAt,
      clinicalDiagnosisClaim: true,
    );

    expect(
      () => validator.validateRecord(missingActor),
      throwsA(isA<PersonalInsightException>()),
    );

    final attributed = PersonalInsightRecord(
      insightId: 'insight:clinical',
      learnerSubjectId: 'learner:1',
      claimType: 'clinical.documented-diagnosis',
      statement: 'Clinician-documented information supplied for accommodation.',
      sensitivity: PersonalInsightSensitivity.clinicalHealthRestricted,
      sourceType: PersonalInsightSourceType.clinicianProvided,
      sourceActorId: 'actor:clinician:1',
      evidenceIds: const {'clinical-document:1'},
      domainScopes: const {'accessibility'},
      limitations: 'Use only for authorized accommodation/support purposes.',
      createdAt: createdAt,
      reviewAt: reviewAt,
      expiresAt: expiresAt,
      clinicalDiagnosisClaim: true,
    );

    validator.validateRecord(attributed);
  });

  test('sensitive read or use requires an access receipt reservation', () {
    const evaluator = PersonalInsightAccessEvaluator();
    const projector = PersonalInsightRevisionProjector();
    final view = projector.project(record: modelHypothesis(), revisions: const []);

    final denied = evaluator.evaluate(
      view: view,
      request: request(receipt: null),
      grants: [grant()],
    );
    expect(denied.allowed, isFalse);

    final allowed = evaluator.evaluate(
      view: view,
      request: request(),
      grants: [grant()],
    );
    expect(allowed.allowed, isTrue);
    expect(allowed.accessReceiptRequired, isTrue);
    expect(allowed.grantId, 'grant:1');
  });

  test('ordinary presentation preference can be read without sensitive receipt', () {
    const evaluator = PersonalInsightAccessEvaluator();
    const projector = PersonalInsightRevisionProjector();
    final record = PersonalInsightRecord(
      insightId: 'insight:1',
      learnerSubjectId: 'learner:1',
      claimType: 'presentation.story-theme',
      statement: 'Learner selected space exploration as a preferred story theme.',
      sensitivity: PersonalInsightSensitivity.ordinaryPreference,
      sourceType: PersonalInsightSourceType.learnerSelfReport,
      evidenceIds: const {'preference-event:1'},
      domainScopes: const {'presentation'},
      limitations: 'Preference is revisable and not a learning-style claim.',
      createdAt: createdAt,
      reviewAt: reviewAt,
      expiresAt: expiresAt,
    );
    final view = projector.project(record: record, revisions: const []);
    final ordinaryGrant = PersonalInsightAccessGrant(
      grantId: 'grant:ordinary',
      actorId: 'actor:tutor',
      learnerSubjectId: 'learner:1',
      allowedPurposes: const {PersonalInsightPurpose.presentationAdaptation},
      permissions: const {PersonalInsightPermission.read},
      allowedSensitivities: const {
        PersonalInsightSensitivity.ordinaryPreference,
      },
      allowedDomainScopes: const {'presentation'},
      evidenceIds: const {'authority:ordinary'},
      issuedAt: createdAt,
      expiresAt: expiresAt,
    );
    final ordinaryRequest = PersonalInsightAccessRequest(
      actorId: 'actor:tutor',
      learnerSubjectId: 'learner:1',
      insightId: 'insight:1',
      purpose: PersonalInsightPurpose.presentationAdaptation,
      permission: PersonalInsightPermission.read,
      sensitivity: PersonalInsightSensitivity.ordinaryPreference,
      domainScope: 'presentation',
      requestedAt: requestedAt,
    );

    final decision = evaluator.evaluate(
      view: view,
      request: ordinaryRequest,
      grants: [ordinaryGrant],
    );

    expect(decision.allowed, isTrue);
    expect(decision.accessReceiptRequired, isFalse);
  });

  test('access grant is exact-subject, exact-purpose, and exact-scope', () {
    const evaluator = PersonalInsightAccessEvaluator();
    const projector = PersonalInsightRevisionProjector();
    final view = projector.project(record: modelHypothesis(), revisions: const []);

    final wrongSubject = evaluator.evaluate(
      view: view,
      request: request(learnerSubjectId: 'learner:2'),
      grants: [grant(learnerSubjectId: 'learner:2')],
    );
    expect(wrongSubject.allowed, isFalse);

    final wrongActor = evaluator.evaluate(
      view: view,
      request: request(actorId: 'actor:other'),
      grants: [grant()],
    );
    expect(wrongActor.allowed, isFalse);
  });

  test('dispute blocks use while preserving read access for review', () {
    const projector = PersonalInsightRevisionProjector();
    const evaluator = PersonalInsightAccessEvaluator();
    final record = modelHypothesis();
    final dispute = PersonalInsightRevision(
      revisionId: 'revision:dispute',
      insightId: record.insightId,
      learnerSubjectId: record.learnerSubjectId,
      actorId: 'learner-actor:1',
      type: PersonalInsightRevisionType.dispute,
      occurredAt: requestedAt,
      evidenceIds: const {'learner-feedback:1'},
      reason: 'This does not match my experience.',
    );
    final view = projector.project(record: record, revisions: [dispute]);

    expect(view.disputed, isTrue);
    expect(
      evaluator
          .evaluate(view: view, request: request(), grants: [grant()])
          .allowed,
      isFalse,
    );
    expect(
      evaluator
          .evaluate(
            view: view,
            request: request(permission: PersonalInsightPermission.read),
            grants: [grant()],
          )
          .allowed,
      isTrue,
    );
  });

  test('correction is append-only and revocation blocks future use', () {
    const projector = PersonalInsightRevisionProjector();
    const evaluator = PersonalInsightAccessEvaluator();
    final record = modelHypothesis();
    final correction = PersonalInsightRevision(
      revisionId: 'revision:correct',
      insightId: record.insightId,
      learnerSubjectId: record.learnerSubjectId,
      actorId: 'learner-actor:1',
      type: PersonalInsightRevisionType.correct,
      occurredAt: requestedAt,
      evidenceIds: const {'learner-feedback:2'},
      reason: 'The effect is stronger with worked counterexamples.',
      replacementStatement:
          'Worked counterexamples help more than brief counterexample prompts.',
      replacementConfidence: 0.8,
    );
    final revocation = PersonalInsightRevision(
      revisionId: 'revision:revoke',
      insightId: record.insightId,
      learnerSubjectId: record.learnerSubjectId,
      actorId: 'learner-actor:1',
      type: PersonalInsightRevisionType.revoke,
      occurredAt: requestedAt.add(const Duration(minutes: 1)),
      evidenceIds: const {'learner-feedback:3'},
      reason: 'Do not use this insight for future adaptation.',
    );

    final view = projector.project(
      record: record,
      revisions: [correction, revocation],
    );

    expect(record.statement, contains('Explicit counterexamples'));
    expect(view.statement, contains('Worked counterexamples'));
    expect(view.confidence, 0.8);
    expect(view.revoked, isTrue);
    expect(view.appliedRevisions, hasLength(2));
    expect(
      evaluator
          .evaluate(view: view, request: request(), grants: [grant()])
          .allowed,
      isFalse,
    );
  });

  test('grant validator rejects unevidenced or unscoped authority', () {
    const validator = PersonalInsightValidator();
    final invalid = PersonalInsightAccessGrant(
      grantId: 'grant:bad',
      actorId: 'actor:tutor',
      learnerSubjectId: 'learner:1',
      allowedPurposes: const {PersonalInsightPurpose.metacognitiveFeedback},
      permissions: const {PersonalInsightPermission.read},
      allowedSensitivities: const {
        PersonalInsightSensitivity.educationalSensitive,
      },
      allowedDomainScopes: const {},
      evidenceIds: const {},
      issuedAt: createdAt,
      expiresAt: expiresAt,
    );

    expect(
      () => validator.validateGrant(invalid),
      throwsA(isA<PersonalInsightException>()),
    );
  });

  test('policy requires a second model-context gate and forbids public/commercial authority', () {
    const boundary = PersonalInsightPolicyBoundary();

    expect(boundary.vaultGrantAloneAuthorizesModelMaterialization(), isFalse);
    expect(boundary.separateModelContextGrantRequired(), isTrue);
    expect(boundary.modelHypothesisMayCreateClinicalDiagnosis(), isFalse);
    expect(boundary.insightMayCreateMastery(), isFalse);
    expect(boundary.insightMayCreateGradeOrCredit(), isFalse);
    expect(boundary.insightMayMintCredential(), isFalse);
    expect(boundary.insightMayCreatePublicProfileByDefault(), isFalse);
    expect(boundary.insightMayFederateAcrossServicesByDefault(), isFalse);
    expect(boundary.sensitiveInsightMayBeUsedForCommercialTargeting(), isFalse);
    expect(boundary.descriptiveRoleAloneCreatesAccess(), isFalse);
    expect(boundary.learnerCorrectionRewritesOriginalProvenance(), isFalse);
    expect(boundary.correctionsAreAppendOnly(), isTrue);
  });
}
