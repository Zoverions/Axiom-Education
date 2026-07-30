import 'dart:collection';

abstract final class AxiomEducationContract {
  static const schema = 'axiom-domain-contract.v1';
  static const brand = 'Axiom Education';
  static const id = 'axiom.education';
  static const version = '1.0.0';
  static const sha256 =
      'a20e191a05308ef85bdc1cc74bfa0d54b98a176818f8030a172b4c3709a28fa2';
  static const controller = 'capsule:axiom.education';
  static const curriculumPackProfile = 'jurisdictional';
  static const gatewayPath = '/v1/intents';
  static const idempotencyHeader = 'idempotency-key';

  static const curriculumPackInspect =
      'education.curriculum.pack.inspect';
  static const curriculumPackStage = 'education.curriculum.pack.stage';
  static const curriculumPackActivate =
      'education.curriculum.pack.activate';
  static const curriculumQuery = 'education.curriculum.query';
  static const tutorRespond = 'education.tutor.respond';
  static const learnerEventAppend = 'education.learner.event.append';
  static const learnerProgressRead = 'education.learner.progress.read';
  static const portfolioExport = 'education.portfolio.export';

  static final Map<String, AxiomEducationActionDefinition> actions =
      UnmodifiableMapView({
    curriculumPackInspect: const AxiomEducationActionDefinition(
      risk: AxiomEducationRisk.low,
      requiredInput: {
        'pack_manifest_sha256',
        'pack_signature_sha256',
        'signer_key_id',
      },
      optionalInput: {'expected_pack_id', 'expected_pack_version'},
    ),
    curriculumPackStage: const AxiomEducationActionDefinition(
      risk: AxiomEducationRisk.medium,
      mutation: true,
      requiredInput: {
        'pack_manifest_sha256',
        'pack_signature_sha256',
        'signer_key_id',
        'pack_bundle_sha256',
      },
      optionalInput: {'expected_pack_id', 'expected_pack_version'},
    ),
    curriculumPackActivate: const AxiomEducationActionDefinition(
      risk: AxiomEducationRisk.high,
      mutation: true,
      requiresConfirmation: true,
      requiresIndependentApproval: true,
      requiredInput: {
        'staged_pack_id',
        'target_pack_manifest_sha256',
        'expected_current_pack_manifest_sha256',
      },
      optionalInput: {'rollback_pack_manifest_sha256'},
    ),
    curriculumQuery: const AxiomEducationActionDefinition(
      risk: AxiomEducationRisk.low,
      requiredInput: {'active_pack_manifest_sha256', 'course_code'},
      optionalInput: {'strand_id', 'expectation_ids', 'query', 'limit'},
    ),
    tutorRespond: const AxiomEducationActionDefinition(
      risk: AxiomEducationRisk.medium,
      consentPurpose: 'personalized-local-tutoring',
      requiredInput: {
        'subject_id',
        'consent_id',
        'purpose',
        'active_pack_manifest_sha256',
        'expectation_ids',
        'prompt',
      },
      optionalInput: {
        'learner_context_object_ids',
        'max_output_tokens',
        'deadline_ms',
      },
    ),
    learnerEventAppend: const AxiomEducationActionDefinition(
      risk: AxiomEducationRisk.medium,
      mutation: true,
      consentPurpose: 'learning-progress-recording',
      requiredInput: {
        'subject_id',
        'consent_id',
        'purpose',
        'event_id',
        'event_type',
        'occurred_at',
        'payload_digest',
        'memory_object_id',
      },
      optionalInput: {
        'active_pack_manifest_sha256',
        'course_code',
        'expectation_ids',
        'review_state',
      },
    ),
    learnerProgressRead: const AxiomEducationActionDefinition(
      risk: AxiomEducationRisk.medium,
      consentPurpose: 'learning-progress-review',
      requiredInput: {'subject_id', 'consent_id', 'purpose', 'course_code'},
      optionalInput: {'expectation_ids', 'as_of'},
    ),
    portfolioExport: const AxiomEducationActionDefinition(
      risk: AxiomEducationRisk.high,
      mutation: true,
      consentPurpose: 'learner-controlled-portfolio-export',
      requiresConfirmation: true,
      requiresIndependentApproval: true,
      requiredInput: {
        'subject_id',
        'consent_id',
        'purpose',
        'selectors',
        'recipient_public_key',
      },
      optionalInput: {'active_pack_manifest_sha256', 'expires_at'},
    ),
  });
}

enum AxiomEducationRisk { low, medium, high, critical }

class AxiomEducationActionDefinition {
  final AxiomEducationRisk risk;
  final bool mutation;
  final String? consentPurpose;
  final bool requiresConfirmation;
  final bool requiresIndependentApproval;
  final Set<String> requiredInput;
  final Set<String> optionalInput;

  const AxiomEducationActionDefinition({
    required this.risk,
    this.mutation = false,
    this.consentPurpose,
    this.requiresConfirmation = false,
    this.requiresIndependentApproval = false,
    required this.requiredInput,
    required this.optionalInput,
  });

  bool get requiresConsent => consentPurpose != null;

  Set<String> get allowedInput => {
        'contract_id',
        'contract_version',
        'contract_sha256',
        ...requiredInput,
        ...optionalInput,
      };
}
