import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/claw_experience_graph.dart';

void main() {
  late Map<String, dynamic> contract;

  setUpAll(() {
    contract =
        jsonDecode(
              File(
                'contracts/claw-academy-experience.v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
  });

  test('transition triggers match the Claw contract exactly', () {
    final contractTriggers = (contract['transition_triggers'] as List<dynamic>)
        .cast<String>();
    final runtimeTriggers = ClawTransitionTrigger.values
        .map((trigger) => trigger.wireName)
        .toList(growable: false);

    expect(runtimeTriggers, equals(contractTriggers));
  });

  test('contract preserves graph governance and non-ranking boundaries', () {
    final invariants = contract['graph_invariants'] as Map<String, dynamic>;

    expect(invariants['entry_node_must_exist'], isTrue);
    expect(invariants['transition_endpoints_must_exist'], isTrue);
    expect(
      invariants['presentation_fallback_preserves_target_competency'],
      isTrue,
    );
    expect(invariants['fallback_node_preserves_target_competency'], isTrue);
    expect(
      invariants['target_competency_change_requires_governed_reason'],
      isTrue,
    );
    expect(
      invariants['ai_socratic_dialogue_requires_non_model_fallback'],
      isTrue,
    );
    expect(
      invariants['evidence_producing_nodes_declare_expected_evidence'],
      isTrue,
    );
    expect(
      invariants['availability_filter_runs_before_path_selection'],
      isTrue,
    );
    expect(invariants['transition_selection_uses_engagement_ranking'], isFalse);
  });
}
