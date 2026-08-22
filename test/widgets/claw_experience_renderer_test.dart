import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/claw_experience_graph.dart';
import 'package:ontarioedai/core/models/claw_experience_presentation.dart';
import 'package:ontarioedai/features/claw/claw_foundations_story_arc.dart';
import 'package:ontarioedai/widgets/claw_experience_renderer.dart';

void main() {
  testWidgets('learner can request another representation without target drift', (
    tester,
  ) async {
    final evidence = <ClawLocalEvidenceCandidate>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClawExperiencePlayer(
              graph: ClawFoundationsStoryArc.graph,
              presentations: ClawFoundationsStoryArc.presentations,
              availability: ClawFoundationsStoryArc.availability,
              onEvidenceCandidate: evidence.add,
            ),
          ),
        ),
      ),
    );

    expect(find.text('The bridge with four lanterns'), findsOneWidget);
    expect(
      find.text(
        'Learning target: ${ClawFoundationsStoryArc.competencyId}',
      ),
      findsOneWidget,
    );

    await _tap(tester, const ValueKey('claw-continue'));
    expect(find.text('One half can wear another name'), findsOneWidget);

    await _tap(tester, const ValueKey('claw-another-way'));
    expect(find.text('Picture the same whole'), findsOneWidget);
    expect(
      find.text(
        'Learning target: ${ClawFoundationsStoryArc.competencyId}',
      ),
      findsOneWidget,
    );

    await _tap(tester, const ValueKey('claw-continue'));
    expect(find.text('Which fraction matches 1/2?'), findsOneWidget);

    await _tap(tester, const ValueKey('claw-choice-three-fourths'));
    expect(find.text('Keep the amount fixed'), findsOneWidget);
    expect(evidence, hasLength(1));
    expect(evidence.single.route, ClawLocalEvidenceRoute.insufficient);
    expect(evidence.single.createsMasteryClaim, isFalse);

    await _tap(tester, const ValueKey('claw-continue'));
    expect(find.text('Which fraction matches 1/2?'), findsOneWidget);

    await _tap(tester, const ValueKey('claw-choice-two-fourths'));
    expect(find.text('You found an equivalent fraction'), findsOneWidget);
    expect(evidence, hasLength(2));
    expect(evidence.last.route, ClawLocalEvidenceRoute.satisfied);
    expect(evidence.last.persistsLearnerRecord, isFalse);
  });

  testWidgets('missing presentation fails visibly without invented content', (
    tester,
  ) async {
    final graph = ClawExperienceGraph(
      graphId: 'claw:test:missing-presentation',
      graphVersion: '1.0.0',
      entryNodeId: 'missing',
      nodes: const <String, ClawExperienceNode>{
        'missing': ClawExperienceNode(
          nodeId: 'missing',
          targetCompetencyIds: <String>{'competency:test'},
          experienceType: ClawExperienceNodeType.textExplanation,
          instructionalStrategyIds: <String>{'strategy:test'},
        ),
      },
      transitions: const <ClawExperienceTransition>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClawExperiencePlayer(
            graph: graph,
            presentations: const <String, ClawExperiencePresentation>{},
            availability: const ClawExperienceAvailability(),
          ),
        ),
      ),
    );

    expect(find.text('Content unavailable'), findsOneWidget);
    expect(
      find.textContaining('no learner-facing presentation yet'),
      findsOneWidget,
    );
    expect(find.text('Learning target: competency:test'), findsOneWidget);
  });
}

Future<void> _tap(WidgetTester tester, ValueKey<String> key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
