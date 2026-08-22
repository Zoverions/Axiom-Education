import '../../core/models/claw_experience_graph.dart';
import '../../core/models/claw_experience_presentation.dart';
import '../../core/models/claw_presentation_preset.dart';

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

  static const presentationVariants = <
    String,
    Map<ClawPresentationPreset, ClawPresentationVariant>
  >{
    'arrival': <ClawPresentationPreset, ClawPresentationVariant>{
      ClawPresentationPreset.sprout: ClawPresentationVariant(
        title: 'The four-lantern bridge',
        body:
            'Two fraction pictures can show the same amount. Let’s find a matching pair.',
        continueLabel: 'Go to the bridge',
      ),
      ClawPresentationPreset.scout: ClawPresentationVariant(
        body:
            'The bridge needs two fractions that show the same amount. We will find out why two different-looking fractions can match.',
      ),
      ClawPresentationPreset.analyst: ClawPresentationVariant(
        body:
            'The bridge compares fraction representations. Your task is to identify an invariant: the amount can stay constant even when the numerator and denominator change together.',
      ),
      ClawPresentationPreset.scholar: ClawPresentationVariant(
        body:
            'The bridge tests fraction equivalence: different symbolic representations can denote the same rational value. Track what changes and what remains invariant.',
      ),
    },
    'worked': <ClawPresentationPreset, ClawPresentationVariant>{
      ClawPresentationPreset.sprout: ClawPresentationVariant(
        title: 'Make the same amount',
        body:
            'Start with 1/2. Double the top number and the bottom number. 1 becomes 2. 2 becomes 4. Now we have 2/4.',
        bullets: <String>['1/2 = 2/4.', 'The amount stayed the same.'],
      ),
      ClawPresentationPreset.scout: ClawPresentationVariant(
        body:
            'Start with 1/2. Multiply both numbers by 2. The top becomes 2 and the bottom becomes 4. So 1/2 and 2/4 show the same amount.',
      ),
      ClawPresentationPreset.analyst: ClawPresentationVariant(
        body:
            'Scale 1/2 by the factor 2/2. Because 2/2 equals 1, multiplying by it changes the representation but not the value: 1/2 × 2/2 = 2/4.',
        bullets: <String>[
          'The scaling factor is applied to numerator and denominator together.',
          'The representation changes while the ratio stays invariant.',
        ],
      ),
      ClawPresentationPreset.scholar: ClawPresentationVariant(
        body:
            'Fraction equivalence follows from multiplying by a form of 1. Since 2/2 = 1, (1/2)(2/2) = 2/4 without changing the represented rational number.',
        bullets: <String>[
          'Equivalent fractions are distinct representations of the same value.',
          'Scaling numerator and denominator by the same non-zero factor preserves the ratio.',
        ],
      ),
    },
    'visual': <ClawPresentationPreset, ClawPresentationVariant>{
      ClawPresentationPreset.sprout: ClawPresentationVariant(
        title: 'See the same amount',
        body:
            'Shade half of a shape. Now cut the same shape into 4 equal pieces. The shaded half covers 2 pieces. That is 2/4.',
        bullets: <String>['1 of 2 pieces.', '2 of 4 pieces.', 'Same shaded amount.'],
      ),
      ClawPresentationPreset.scout: ClawPresentationVariant(
        body:
            'Shade 1 of 2 equal parts. If each part is split in half again, there are 4 equal parts and 2 are shaded. The picture still shows the same amount.',
      ),
      ClawPresentationPreset.analyst: ClawPresentationVariant(
        body:
            'Partition the same whole more finely. Splitting each half into two equal subparts doubles both the total part count and the shaded part count, so the shaded proportion is unchanged.',
      ),
      ClawPresentationPreset.scholar: ClawPresentationVariant(
        body:
            'Refining the partition changes the unit of counting but preserves measure. One of two equal regions and two of four equal regions occupy the same proportion of the whole.',
      ),
    },
    'checkpoint': <ClawPresentationPreset, ClawPresentationVariant>{
      ClawPresentationPreset.sprout: ClawPresentationVariant(
        eyebrow: 'Quick check',
        title: 'Which one is the same as 1/2?',
        body: 'Pick the fraction that shows the same amount.',
      ),
      ClawPresentationPreset.scout: ClawPresentationVariant(
        eyebrow: 'Quick check',
        body: 'Choose the fraction that has the same value as 1/2.',
      ),
      ClawPresentationPreset.analyst: ClawPresentationVariant(
        eyebrow: 'Evidence checkpoint',
        body:
            'Choose the representation that preserves the ratio 1:2. The response only routes this local preview.',
      ),
      ClawPresentationPreset.scholar: ClawPresentationVariant(
        eyebrow: 'Evidence checkpoint',
        body:
            'Select the rational representation equivalent to 1/2. This single response is routing evidence, not a mastery inference.',
      ),
    },
    'retry': <ClawPresentationPreset, ClawPresentationVariant>{
      ClawPresentationPreset.sprout: ClawPresentationVariant(
        title: 'Try doubling both numbers',
        body: 'Double 1. Double 2. You get 2/4. Look for that choice.',
      ),
      ClawPresentationPreset.scout: ClawPresentationVariant(
        body:
            'Try the same change to both numbers. Multiply 1 by 2 and multiply 2 by 2. That makes 2/4.',
      ),
      ClawPresentationPreset.analyst: ClawPresentationVariant(
        body:
            'Use a common scaling factor. Multiplying numerator and denominator by 2 preserves the ratio and produces 2/4.',
      ),
      ClawPresentationPreset.scholar: ClawPresentationVariant(
        body:
            'Apply the identity factor 2/2. The product is 2/4, which is equivalent to 1/2 because multiplying by 1 preserves value.',
      ),
    },
    'complete': <ClawPresentationPreset, ClawPresentationVariant>{
      ClawPresentationPreset.sprout: ClawPresentationVariant(
        title: 'You found the match',
        body: '1/2 and 2/4 can show the same amount. Nice work checking the match.',
      ),
      ClawPresentationPreset.scout: ClawPresentationVariant(
        body:
            'You matched 1/2 with 2/4. The numbers look different, but the amount is the same.',
      ),
      ClawPresentationPreset.analyst: ClawPresentationVariant(
        body:
            'You recognized an invariant under scaling: 1/2 and 2/4 use different numbers but preserve the same ratio and value.',
      ),
      ClawPresentationPreset.scholar: ClawPresentationVariant(
        body:
            'You identified equivalent rational representations and the transformation that preserves their value. The presentation changed; the governed competency did not.',
      ),
    },
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
