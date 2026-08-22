import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _contract(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  test('institution contract keeps roles and guardian preferences non-authorizing', () {
    final contract = _contract('contracts/axiom-education-institution.v1.json');
    final boundary = contract['authority_boundary'] as Map<String, dynamic>;
    final guardian = contract['guardian_input'] as Map<String, dynamic>;

    expect(boundary['role_grants_authority'], isFalse);
    expect(boundary['relationship_grants_authority'], isFalse);
    expect(boundary['mesh_evidence_required_for_consequential_actions'], isTrue);
    expect(guardian['preference_is_authorization'], isFalse);
    expect(guardian['preference_is_unconditional_veto'], isFalse);
    expect(guardian['may_suppress_required_content_by_itself'], isFalse);
  });

  test('resource contract rejects engagement optimization and fixed learning styles', () {
    final contract =
        _contract('contracts/axiom-education-resource-intelligence.v1.json');
    final selection = contract['selection_inputs'] as Map<String, dynamic>;
    final forbidden = (selection['forbidden_optimization_targets'] as List<dynamic>)
        .cast<String>()
        .toSet();
    final feedback = contract['feedback_boundary'] as Map<String, dynamic>;
    final external = contract['external_resource_boundary'] as Map<String, dynamic>;

    expect(forbidden, contains('watch-time'));
    expect(forbidden, contains('click-through-rate'));
    expect(forbidden, contains('generic-engagement'));
    expect(feedback['permanent_learning_style_labels'], isFalse);
    expect(feedback['learner_feedback_changes_curriculum_truth'], isFalse);
    expect(external['youtube_is_generic_provider_not_platform_dependency'], isTrue);
  });
}
