import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _contract(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  test(
    'institution contract keeps roles and guardian preferences non-authorizing',
    () {
      final contract = _contract(
        'contracts/axiom-education-institution.v1.json',
      );
      final boundary = contract['authority_boundary'] as Map<String, dynamic>;
      final guardian = contract['guardian_input'] as Map<String, dynamic>;

      expect(boundary['role_grants_authority'], isFalse);
      expect(boundary['relationship_grants_authority'], isFalse);
      expect(
        boundary['mesh_evidence_required_for_consequential_actions'],
        isTrue,
      );
      expect(guardian['preference_is_authorization'], isFalse);
      expect(guardian['preference_is_unconditional_veto'], isFalse);
      expect(guardian['may_suppress_required_content_by_itself'], isFalse);
    },
  );

  test(
    'resource contract rejects engagement optimization and fixed learning styles',
    () {
      final contract = _contract(
        'contracts/axiom-education-resource-intelligence.v1.json',
      );
      final selection = contract['selection_inputs'] as Map<String, dynamic>;
      final forbidden =
          (selection['forbidden_optimization_targets'] as List<dynamic>)
              .cast<String>()
              .toSet();
      final feedback = contract['feedback_boundary'] as Map<String, dynamic>;
      final external =
          contract['external_resource_boundary'] as Map<String, dynamic>;

      expect(forbidden, contains('watch-time'));
      expect(forbidden, contains('click-through-rate'));
      expect(forbidden, contains('generic-engagement'));
      expect(feedback['permanent_learning_style_labels'], isFalse);
      expect(feedback['learner_feedback_changes_curriculum_truth'], isFalse);
      expect(
        external['youtube_is_generic_provider_not_platform_dependency'],
        isTrue,
      );
    },
  );

  test('learning evidence contract does not pretend Mesh event admission', () {
    final contract = _contract(
      'contracts/axiom-education-learning-evidence.v1.json',
    );
    final boundary =
        contract['mesh_admission_boundary'] as Map<String, dynamic>;
    final minimization = contract['minimization'] as Map<String, dynamic>;

    expect(boundary['existing_profile_is_modified'], isFalse);
    expect(boundary['mesh_event_admission_currently_claimed'], isFalse);
    expect(
      boundary['application_may_report_official_persistence_before_mesh_admission'],
      isFalse,
    );
    expect(minimization['raw_video_watch_history_required'], isFalse);
    expect(minimization['clickstream_required'], isFalse);
  });

  test('collaboration contract keeps transcripts need-to-know', () {
    final contract = _contract(
      'contracts/axiom-education-collaboration-privacy.v1.json',
    );
    final access = contract['access_invariants'] as Map<String, dynamic>;
    final guardian = contract['guardian_boundary'] as Map<String, dynamic>;

    expect(access['role_label_alone_grants_access'], isFalse);
    expect(access['institution_membership_alone_grants_access'], isFalse);
    expect(access['purpose_bound_access_required'], isTrue);
    expect(access['access_receipt_required_for_privileged_reads'], isTrue);
    expect(guardian['automatic_peer_chat_transcript_access'], isFalse);
  });

  test(
    'entry assessment does not convert missing hardware into learner failure',
    () {
      final contract = _contract(
        'contracts/axiom-education-entry-assessment.v1.json',
      );
      final selection =
          contract['selection_invariants'] as Map<String, dynamic>;
      final evidence = contract['evidence_boundary'] as Map<String, dynamic>;

      expect(selection['camera_is_never_assumed'], isTrue);
      expect(selection['microphone_is_never_assumed'], isTrue);
      expect(selection['literacy_is_never_assumed'], isTrue);
      expect(
        selection['missing_modality_is_not_negative_ability_evidence'],
        isTrue,
      );
      expect(evidence['device_failure_is_not_learner_failure'], isTrue);
    },
  );

  test(
    'model routing contract hard-filters privacy before quality and cost ranking',
    () {
      final contract = _contract(
        'contracts/axiom-education-model-routing.v1.json',
      );
      final dependency = contract['mesh_dependency'] as Map<String, dynamic>;
      final context = contract['context_invariants'] as Map<String, dynamic>;
      final authority =
          contract['education_authority_boundary'] as Map<String, dynamic>;

      expect(dependency['model_output_is_data_not_authority'], isTrue);
      expect(
        context['full_longitudinal_learner_profile_sent_by_default'],
        isFalse,
      );
      expect(
        context['only_explicitly_granted_context_scopes_may_be_materialized'],
        isTrue,
      );
      expect(authority['model_may_create_grade_or_credit'], isFalse);
      expect(authority['model_may_expand_its_own_context_scope'], isFalse);
      expect(
        authority['consequential_assessment_requires_separate_evidence_and_verification'],
        isTrue,
      );
    },
  );
}
