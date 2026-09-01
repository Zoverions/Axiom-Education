import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/claw_experience_graph.dart';
import 'package:ontarioedai/core/models/claw_experience_presentation.dart';
import 'package:ontarioedai/features/claw/claw_foundations_story_arc.dart';

void main() {
  test(
    'foundations arc validates against admitted competency and strategies',
    () {
      const validator = ClawExperienceGraphValidator();

      expect(
        () => validator.validate(
          ClawFoundationsStoryArc.graph,
          knownCompetencyIds: ClawFoundationsStoryArc.knownCompetencyIds,
          knownInstructionalStrategyIds:
              ClawFoundationsStoryArc.knownInstructionalStrategyIds,
        ),
        returnsNormally,
      );
    },
  );

  test('every story node preserves the same governed target competency', () {
    for (final node in ClawFoundationsStoryArc.graph.nodes.values) {
      expect(node.targetCompetencyIds, const <String>{
        ClawFoundationsStoryArc.competencyId,
      });
    }
  });

  test('every graph node has an explicit learner-facing presentation', () {
    expect(
      ClawFoundationsStoryArc.presentations.keys.toSet(),
      ClawFoundationsStoryArc.graph.nodes.keys.toSet(),
    );
  });

  test('optional Socratic node has an explicit non-model fallback', () {
    final socraticNodes = ClawFoundationsStoryArc.graph.nodes.values
        .where(
          (node) =>
              node.experienceType == ClawExperienceNodeType.aiSocraticDialogue,
        )
        .toList(growable: false);

    expect(socraticNodes, hasLength(1));
    final socratic = socraticNodes.single;
    expect(
      socratic.targetCompetencyIds,
      const <String>{ClawFoundationsStoryArc.competencyId},
    );
    expect(socratic.fallbackNodeIds, contains('visual'));

    expect(
      ClawFoundationsStoryArc.graph.transitions,
      contains(
        isA<ClawExperienceTransition>()
            .having(
              (transition) => transition.fromNodeId,
              'from node',
              'worked',
            )
            .having(
              (transition) => transition.toNodeId,
              'to node',
              socratic.nodeId,
            )
            .having(
              (transition) => transition.trigger,
              'trigger',
              ClawTransitionTrigger.learnerChoice,
            ),
      ),
    );
    expect(
      ClawFoundationsStoryArc.graph.transitions,
      contains(
        isA<ClawExperienceTransition>()
            .having(
              (transition) => transition.fromNodeId,
              'from node',
              socratic.nodeId,
            )
            .having(
              (transition) => transition.toNodeId,
              'to node',
              'visual',
            )
            .having(
              (transition) => transition.trigger,
              'trigger',
              ClawTransitionTrigger.modelUnavailable,
            ),
      ),
    );
  });

  test('model path is opt-in and unavailable by default', () {
    expect(ClawFoundationsStoryArc.availability.modelAvailable, isFalse);
  });

  test('first arc has no external launch dependency', () {
    final types = ClawFoundationsStoryArc.graph.nodes.values
        .map((node) => node.experienceType)
        .toSet();

    expect(types, isNot(contains(ClawExperienceNodeType.resourceLaunch)));
    expect(types, isNot(contains(ClawExperienceNodeType.videoLaunch)));
    expect(types, isNot(contains(ClawExperienceNodeType.simulationLaunch)));
    expect(types, isNot(contains(ClawExperienceNodeType.gameLaunch)));
  });

  test('local evidence candidate cannot create authority claims', () {
    const candidate = ClawLocalEvidenceCandidate(
      nodeId: 'checkpoint',
      choiceId: 'two-fourths',
      route: ClawLocalEvidenceRoute.satisfied,
    );

    expect(candidate.createsMasteryClaim, isFalse);
    expect(candidate.createsGrade, isFalse);
    expect(candidate.persistsLearnerRecord, isFalse);
  });
}
