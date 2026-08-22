import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/competency_graph.dart';

void main() {
  final now = DateTime.utc(2026, 8, 21, 20, 55);

  CompetencyGraph buildGraph() => CompetencyGraph(
    nodes: const <CompetencyNode>[
      CompetencyNode(
        competencyId: 'pattern:basic',
        title: 'Recognize a simple pattern',
      ),
      CompetencyNode(
        competencyId: 'number:count',
        title: 'Count small quantities',
      ),
      CompetencyNode(
        competencyId: 'fraction:part-whole',
        title: 'Understand part and whole',
      ),
      CompetencyNode(
        competencyId: 'fraction:equivalent',
        title: 'Recognize equivalent fractions',
      ),
    ],
    edges: const <CompetencyEdge>[
      CompetencyEdge(
        fromCompetencyId: 'number:count',
        toCompetencyId: 'fraction:part-whole',
        type: CompetencyEdgeType.prerequisite,
      ),
      CompetencyEdge(
        fromCompetencyId: 'fraction:part-whole',
        toCompetencyId: 'fraction:equivalent',
        type: CompetencyEdgeType.prerequisite,
      ),
    ],
  );

  test('graph rejects prerequisite cycles', () {
    expect(
      () => CompetencyGraph(
        nodes: const <CompetencyNode>[
          CompetencyNode(competencyId: 'a', title: 'A'),
          CompetencyNode(competencyId: 'b', title: 'B'),
        ],
        edges: const <CompetencyEdge>[
          CompetencyEdge(
            fromCompetencyId: 'a',
            toCompetencyId: 'b',
            type: CompetencyEdgeType.prerequisite,
          ),
          CompetencyEdge(
            fromCompetencyId: 'b',
            toCompetencyId: 'a',
            type: CompetencyEdgeType.prerequisite,
          ),
        ],
      ),
      throwsA(isA<CompetencyGraphException>()),
    );
  });

  test('diagnostic starts from unresolved prerequisites rather than grade', () {
    final graph = buildGraph();
    final plan = const EntryDiagnosticPlanner().plan(
      graph: graph,
      learnerSubjectId: 'learner:1',
      targetCompetencyId: 'fraction:equivalent',
      evidence: const <CompetencyEvidence>[],
      itemBudget: 3,
    );

    expect(plan.learnerSubjectId, equals('learner:1'));
    expect(
      plan.competencyIdsToProbe,
      equals(<String>[
        'number:count',
        'fraction:part-whole',
        'fraction:equivalent',
      ]),
    );
  });

  test('demonstrated prerequisite is skipped but emerging evidence is rechecked', () {
    final graph = buildGraph();
    final plan = const EntryDiagnosticPlanner().plan(
      graph: graph,
      learnerSubjectId: 'learner:1',
      targetCompetencyId: 'fraction:equivalent',
      evidence: <CompetencyEvidence>[
        CompetencyEvidence(
          learnerSubjectId: 'learner:1',
          competencyId: 'number:count',
          state: CompetencyEvidenceState.demonstrated,
          confidence: 0.9,
          evidenceId: 'evidence:count:1',
          observedAt: now,
        ),
        CompetencyEvidence(
          learnerSubjectId: 'learner:1',
          competencyId: 'fraction:part-whole',
          state: CompetencyEvidenceState.emerging,
          confidence: 0.8,
          evidenceId: 'evidence:fraction:1',
          observedAt: now,
        ),
      ],
    );

    expect(
      plan.competencyIdsToProbe,
      equals(<String>['fraction:part-whole', 'fraction:equivalent']),
    );
  });

  test('evidence from another learner cannot suppress diagnostic probes', () {
    final graph = buildGraph();
    final plan = const EntryDiagnosticPlanner().plan(
      graph: graph,
      learnerSubjectId: 'learner:1',
      targetCompetencyId: 'fraction:equivalent',
      evidence: <CompetencyEvidence>[
        CompetencyEvidence(
          learnerSubjectId: 'learner:2',
          competencyId: 'number:count',
          state: CompetencyEvidenceState.demonstrated,
          confidence: 1,
          evidenceId: 'evidence:other-learner',
          observedAt: now,
        ),
      ],
      itemBudget: 3,
    );

    expect(
      plan.competencyIdsToProbe,
      equals(<String>[
        'number:count',
        'fraction:part-whole',
        'fraction:equivalent',
      ]),
    );
  });

  test('newer weaker evidence causes a previously demonstrated skill to be rechecked', () {
    final graph = buildGraph();
    final plan = const EntryDiagnosticPlanner().plan(
      graph: graph,
      learnerSubjectId: 'learner:1',
      targetCompetencyId: 'fraction:equivalent',
      evidence: <CompetencyEvidence>[
        CompetencyEvidence(
          learnerSubjectId: 'learner:1',
          competencyId: 'number:count',
          state: CompetencyEvidenceState.demonstrated,
          confidence: 0.95,
          evidenceId: 'evidence:old-demonstrated',
          observedAt: now.subtract(const Duration(days: 30)),
        ),
        CompetencyEvidence(
          learnerSubjectId: 'learner:1',
          competencyId: 'number:count',
          state: CompetencyEvidenceState.emerging,
          confidence: 0.8,
          evidenceId: 'evidence:new-emerging',
          observedAt: now,
        ),
      ],
      itemBudget: 3,
    );

    expect(plan.competencyIdsToProbe.first, equals('number:count'));
  });

  test('target with strong demonstrated evidence produces no diagnostic probe', () {
    final graph = buildGraph();
    final plan = const EntryDiagnosticPlanner().plan(
      graph: graph,
      learnerSubjectId: 'learner:1',
      targetCompetencyId: 'fraction:equivalent',
      evidence: <CompetencyEvidence>[
        CompetencyEvidence(
          learnerSubjectId: 'learner:1',
          competencyId: 'fraction:equivalent',
          state: CompetencyEvidenceState.demonstrated,
          confidence: 0.95,
          evidenceId: 'evidence:equivalent:1',
          observedAt: now,
        ),
      ],
    );

    expect(plan.isEmpty, isTrue);
  });

  test('diagnostic plan respects bounded item budget', () {
    final graph = buildGraph();
    final plan = const EntryDiagnosticPlanner().plan(
      graph: graph,
      learnerSubjectId: 'learner:1',
      targetCompetencyId: 'fraction:equivalent',
      evidence: const <CompetencyEvidence>[],
      itemBudget: 2,
    );

    expect(plan.competencyIdsToProbe.length, equals(2));
    expect(
      plan.competencyIdsToProbe,
      equals(<String>['number:count', 'fraction:part-whole']),
    );
  });
}
