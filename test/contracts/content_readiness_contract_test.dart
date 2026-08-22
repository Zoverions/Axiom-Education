import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _contract() {
  return jsonDecode(
    File('contracts/axiom-education-content-readiness.v1.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
}

void main() {
  test('content readiness contract does not hard-code role authority', () {
    final contract = _contract();
    final authority = contract['authority_boundary'] as Map<String, dynamic>;
    final resolution = contract['resolution'] as Map<String, dynamic>;

    expect(authority['source_role_alone_defines_strength'], isFalse);
    expect(authority['source_role_alone_defines_priority'], isFalse);
    expect(authority['self_asserted_binding_policy_allowed'], isFalse);
    expect(authority['binding_directive_requires_evidence'], isTrue);
    expect(
      resolution['policy_priority_is_supplied_by_governed_policy_not_hardcoded_role_hierarchy'],
      isTrue,
    );
  });

  test('advisory preferences sequence but do not override binding policy', () {
    final contract = _contract();
    final authority = contract['authority_boundary'] as Map<String, dynamic>;

    expect(authority['advisory_preference_grants_authority'], isFalse);
    expect(authority['advisory_preference_may_adjust_sequence'], isTrue);
    expect(
      authority['advisory_preference_may_override_stronger_binding_policy'],
      isFalse,
    );
  });

  test('conflict and denial fail closed instead of silently guessing', () {
    final contract = _contract();
    final authority = contract['authority_boundary'] as Map<String, dynamic>;
    final recommender = contract['recommender_boundary'] as Map<String, dynamic>;

    expect(authority['strongest_applicable_binding_denial_fails_closed'], isTrue);
    expect(
      authority['equally_strong_controlling_conflict_requires_review'],
      isTrue,
    );
    expect(recommender['resource_recommender_resolves_governance'], isFalse);
    expect(recommender['denied_or_review_required_content_is_presented'], isFalse);
  });

  test('age is not treated as a complete maturity or capacity model', () {
    final contract = _contract();
    final readiness = contract['readiness_boundary'] as Map<String, dynamic>;

    expect(readiness['chronological_age_is_complete_maturity_model'], isFalse);
    expect(readiness['fixed_global_maturity_score_required'], isFalse);
    expect(readiness['system_infers_legal_capacity_from_age_alone'], isFalse);
  });
}
