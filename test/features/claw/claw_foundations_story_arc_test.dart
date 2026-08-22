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

  test('first arc has no remote model or external launch dependency', () {
    final types = ClawFoundationsStoryArc.graph.nodes.values
        .map((node) => node.experienceType)
        .toSet();

    expect(types, isNot(contains(ClawExperienceNodeType.aiSocraticDialogue)));
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
