import '../../core/models/claw_experience_graph.dart';
import '../../core/models/claw_experience_presentation.dart';

class ClawFoundationsStoryArc {
  static const competencyId = 'math:fractions:equivalence';

  static const workedExampleStrategyId =
      'strategy:worked-example:fractions-equivalence';
  static const visualStrategyId =
      'strategy:multiple-representations:fractions-equivalence';
  static const retrievalStrategyId =
      'strategy:retrieval-with-feedback:fractions-equivalence';
  static const storyStrategyId = 'strategy:story:fractions-equivalence';

  static final graph = ClawExperienceGraph(
    graphId: 'claw:foundations:fractions-equivalence',
    graphVersion: '1.0.0-preview',
    entryNodeId: 'arrival',
    nodes: <String, ClawExperienceNode>{
      'arrival': const ClawExperienceNode(
        nodeId: 'arrival',
        targetCompetencyIds: <String>{competencyId},
        experienceType: ClawExperienceNodeType.storyPanel,
        instructionalStrategyIds: <String>{storyStrategyId},
      ),
      'worked': const ClawExperienceNode(
        nodeId: 'worked',
        targetCompetencyIds: <String>{competencyId},
        experienceType: ClawExperienceNodeType.workedExample,
        instructionalStrategyIds: <String>{workedExampleStrategyId},
        fallbackNodeIds: <String>{'visual'},
      ),
      'visual': const ClawExperienceNode(
        nodeId: 'visual',
        targetCompetencyIds: <String>{competencyId},
        experienceType: ClawExperienceNodeType.diagramOrVisual,
        instructionalStrategyIds: <String>{visualStrategyId},
      ),
      'checkpoint': const ClawExperienceNode(
        nodeId: 'checkpoint',
        targetCompetencyIds: <String>{competencyId},
        experienceType: ClawExperienceNodeType.retrievalCheckpoint,
        instructionalStrategyIds: <String>{retrievalStrategyId},
        expectedEvidenceKinds: <String>{'local-choice-response'},
      ),
      'retry': const ClawExperienceNode(
        nodeId: 'retry',
        targetCompetencyIds: <String>{competencyId},
        experienceType: ClawExperienceNodeType.adaptiveHint,
        instructionalStrategyIds: <String>{workedExampleStrategyId},
      ),
      'complete': const ClawExperienceNode(
        nodeId: 'complete',
        targetCompetencyIds: <String>{competencyId},
        experienceType: ClawExperienceNodeType.reflectionPrompt,
        instructionalStrategyIds: <String>{storyStrategyId},
      ),
    },
    transitions: const <ClawExperienceTransition>[
      ClawExperienceTransition(
        transitionId: 'arrival-to-worked',
        fromNodeId: 'arrival',
        toNodeId: 'worked',
        trigger: ClawTransitionTrigger.automatic,
      ),
      ClawExperienceTransition(
        transitionId: 'worked-to-checkpoint',
        fromNodeId: 'worked',
        toNodeId: 'checkpoint',
        trigger: ClawTransitionTrigger.automatic,
      ),
      ClawExperienceTransition(
        transitionId: 'worked-to-visual',
        fromNodeId: 'worked',
        toNodeId: 'visual',
        trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
      ),
      ClawExperienceTransition(
        transitionId: 'visual-to-checkpoint',
        fromNodeId: 'visual',
        toNodeId: 'checkpoint',
        trigger: ClawTransitionTrigger.automatic,
      ),
      ClawExperienceTransition(
        transitionId: 'checkpoint-to-complete',
        fromNodeId: 'checkpoint',
        toNodeId: 'complete',
        trigger: ClawTransitionTrigger.evidenceSatisfied,
      ),
      ClawExperienceTransition(
        transitionId: 'checkpoint-to-retry',
        fromNodeId: 'checkpoint',
        toNodeId: 'retry',
        trigger: ClawTransitionTrigger.evidenceInsufficient,
      ),
      ClawExperienceTransition(
        transitionId: 'retry-to-checkpoint',
        fromNodeId: 'retry',
        toNodeId: 'checkpoint',
        trigger: ClawTransitionTrigger.automatic,
      ),
      ClawExperienceTransition(
        transitionId: 'retry-to-visual',
        fromNodeId: 'retry',
        toNodeId: 'visual',
        trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
      ),
    ],
  );

  static const presentations = <String, ClawExperiencePresentation>{
    'arrival': ClawExperiencePresentation(
      nodeId: 'arrival',
      eyebrow: 'Claw Academy preview',
      title: 'The bridge with four lanterns',
      body:
          'A bridge opens only when two lantern patterns represent the same amount. '
          'Your first task is to notice when two fractions are equivalent.',
      supportingText:
          'This preview adapts the explanation path locally. Nothing here is saved '
          'as an official learner record, grade, or mastery result.',
      continueLabel: 'Enter the bridge',
    ),
    'worked': ClawExperiencePresentation(
      nodeId: 'worked',
      eyebrow: 'Worked example',
      title: 'One half can wear another name',
      body:
          'Start with 1/2. Multiply the numerator and denominator by the same '
          'number: 1 × 2 = 2 and 2 × 2 = 4. That gives 2/4.',
      bullets: <String>[
        '1/2 and 2/4 name the same amount.',
        'Changing both parts by the same factor keeps the value unchanged.',
      ],
      supportingText:
          'If this representation does not click, you can ask for another way '
          'without changing the competency you are working on.',
      continueLabel: 'Try a quick check',
    ),
    'visual': ClawExperiencePresentation(
      nodeId: 'visual',
      eyebrow: 'Another way',
      title: 'Picture the same whole',
      body:
          'Imagine one rectangle split into 2 equal parts with 1 shaded. Now split '
          'that same rectangle into 4 equal parts. The same shaded region covers 2 '
          'of those 4 parts.',
      bullets: <String>[
        '1 shaded part out of 2 = 1/2.',
        '2 shaded parts out of 4 = 2/4.',
        'The number of pieces changed; the shaded amount did not.',
      ],
      continueLabel: 'Try the check',
    ),
    'checkpoint': ClawExperiencePresentation(
      nodeId: 'checkpoint',
      eyebrow: 'Local evidence checkpoint',
      title: 'Which fraction matches 1/2?',
      body:
          'Choose the fraction that represents the same amount. Your choice is used '
          'only to route this preview.',
      choices: <ClawExperienceChoicePresentation>[
        ClawExperienceChoicePresentation(
          choiceId: 'two-fourths',
          label: '2/4',
          evidenceRoute: ClawLocalEvidenceRoute.satisfied,
        ),
        ClawExperienceChoicePresentation(
          choiceId: 'three-fourths',
          label: '3/4',
          evidenceRoute: ClawLocalEvidenceRoute.insufficient,
        ),
        ClawExperienceChoicePresentation(
          choiceId: 'one-fourth',
          label: '1/4',
          evidenceRoute: ClawLocalEvidenceRoute.insufficient,
        ),
      ],
      supportingText:
          'A correct response here is not a mastery decision. A wrong response is '
          'not a permanent ability label.',
    ),
    'retry': ClawExperiencePresentation(
      nodeId: 'retry',
      eyebrow: 'Adaptive hint',
      title: 'Keep the amount fixed',
      body:
          'Look for a fraction made by multiplying both 1 and 2 by the same number. '
          'Multiplying both by 2 gives 2/4.',
      supportingText:
          'You can return to the check or ask to see the visual explanation instead.',
      continueLabel: 'Try again',
    ),
    'complete': ClawExperiencePresentation(
      nodeId: 'complete',
      eyebrow: 'Preview complete',
      title: 'You found an equivalent fraction',
      body:
          'The path adapted, but the target stayed the same: recognizing equivalent '
          'fractions. A future Claw lesson can extend this into practice, transfer, '
          'human help, or a reviewed tool without changing that rule.',
      supportingText:
          'This preview creates no grade, credit, credential, or saved learner record.',
    ),
  };

  static const availability = ClawExperienceAvailability();

  static const knownCompetencyIds = <String>{competencyId};

  static const knownInstructionalStrategyIds = <String>{
    workedExampleStrategyId,
    visualStrategyId,
    retrievalStrategyId,
    storyStrategyId,
  };
}
