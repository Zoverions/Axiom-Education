import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/personal_insight_vault.dart';

void main() {
  late Map<String, dynamic> contract;

  setUpAll(() {
    contract =
        jsonDecode(
              File(
                'contracts/axiom-education-personal-insight-vault.v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
  });

  test('runtime sensitivity classes match contract exactly', () {
    final expected = (contract['sensitivity_classes'] as List<dynamic>)
        .cast<String>();
    final actual = PersonalInsightSensitivity.values
        .map((value) => value.wireName)
        .toList(growable: false);

    expect(actual, equals(expected));
  });

  test('runtime source classes match contract exactly', () {
    final expected = (contract['source_types'] as List<dynamic>).cast<String>();
    final actual = PersonalInsightSourceType.values
        .map((value) => value.wireName)
        .toList(growable: false);

    expect(actual, equals(expected));
  });

  test('runtime purposes and permissions match contract exactly', () {
    final expectedPurposes = (contract['purposes'] as List<dynamic>)
        .cast<String>();
    final expectedPermissions = (contract['permissions'] as List<dynamic>)
        .cast<String>();

    expect(
      PersonalInsightPurpose.values.map((value) => value.wireName).toList(),
      equals(expectedPurposes),
    );
    expect(
      PersonalInsightPermission.values.map((value) => value.wireName).toList(),
      equals(expectedPermissions),
    );
  });

  test('runtime revision classes match contract exactly', () {
    final expected = (contract['revision_types'] as List<dynamic>)
        .cast<String>();
    final actual = PersonalInsightRevisionType.values
        .map((value) => value.wireName)
        .toList(growable: false);

    expect(actual, equals(expected));
  });

  test('contract pins the merged Mesh sovereign vault parents', () {
    final parents = contract['mesh_parent_contracts'] as Map<String, dynamic>;
    final pins = (parents['contracts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(parents['repository'], 'Zoverions/AXIOM-MESH');
    expect(parents['source_sha'], '057433be99fe0b2b7c5c6a1c34316e119f45b46b');
    expect(
      parents['adoption_status'],
      'documentation-readiness-only-no-runtime-authority',
    );
    expect(
      pins,
      equals([
        {
          'id': 'axiom-sovereign-vault.v1',
          'path': 'docs/architecture/contracts/sovereign-vault.v1.schema.json',
          'sha256':
              '02e062e6281e0ffd29920d6973cd0108daeb9644ce80313e31511699824ce6c2',
        },
        {
          'id': 'axiom-context-capsule.v1',
          'path': 'docs/architecture/contracts/context-capsule.v1.schema.json',
          'sha256':
              '31d2d1a2594b968407604466462cbf537d7490b4bdb9cf22002bd98717c24a17',
        },
      ]),
    );
  });

  test('Education cannot weaken Mesh vault or context capsule authority', () {
    final boundary =
        contract['mesh_inheritance_invariants'] as Map<String, dynamic>;

    expect(
      boundary['education_profile_may_weaken_parent_vault_invariants'],
      isFalse,
    );
    expect(boundary['direct_external_vault_access'], isFalse);
    expect(boundary['local_companion_access_requires_mesh_lease'], isTrue);
    expect(
      boundary['future_external_materialization_requires_context_capsule'],
      isTrue,
    );
    expect(boundary['context_capsule_grants_vault_access'], isFalse);
    expect(boundary['context_capsule_grants_execution_authority'], isFalse);
    expect(boundary['contract_presence_grants_runtime_authority'], isFalse);
  });

  test('contract requires two-gate model materialization', () {
    final boundary =
        contract['model_materialization_boundary'] as Map<String, dynamic>;

    expect(
      boundary['vault_grant_alone_authorizes_model_materialization'],
      isFalse,
    );
    expect(boundary['separate_education_model_context_grant_required'], isTrue);
    expect(
      boundary['remote_egress_requires_separate_model_context_authority'],
      isTrue,
    );
    expect(
      boundary['retention_requires_separate_model_context_authority'],
      isTrue,
    );
  });

  test('contract preserves learner agency and non-authority boundaries', () {
    final agency = contract['learner_agency'] as Map<String, dynamic>;
    final authority =
        contract['non_authority_invariants'] as Map<String, dynamic>;

    expect(agency['confirm'], isTrue);
    expect(agency['dispute'], isTrue);
    expect(agency['correct'], isTrue);
    expect(agency['revoke_future_use'], isTrue);
    expect(authority['insight_establishes_mastery'], isFalse);
    expect(authority['insight_creates_grade_or_credit'], isFalse);
    expect(authority['insight_mints_credential'], isFalse);
    expect(authority['insight_creates_public_profile_by_default'], isFalse);
    expect(authority['insight_federates_across_services_by_default'], isFalse);
    expect(
      authority['sensitive_insight_may_be_used_for_commercial_targeting'],
      isFalse,
    );
  });
}
