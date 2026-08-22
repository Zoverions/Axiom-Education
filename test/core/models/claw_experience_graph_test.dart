import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/claw_experience_graph.dart';

void main() {
  const competency = 'math:fractions:equivalence';
  const strategy = 'strategy:worked-example:fractions';

  ClawExperienceNode node({
    required String id,
    required ClawExperienceNodeType type,
    Set<String> targets = const <String>{competency},
    Set<String> strategies = const <String>{strategy},
    Set<String> devices = const <String>{},
    Set<String> accessibility = const <String>{},
    Set<String> readiness = const <String>{},
    Set<String> evidence = const <String>{},
    Set<String> fallbacks = const <String>{},
  }) {
    return ClawExperienceNode(
      nodeId: id,
      targetCompetencyIds: targets,
      experienceType: type,
      instructionalStrategyIds: strategies,
      requiredDeviceCapabilities: devices,
      requiredAccessibilityCapabilities: accessibility,
      contentReadinessTags: readiness,
      expectedEvidenceKinds: evidence,
      fallbackNodeIds: fallbacks,
    );
  }

  ClawExperienceGraph graph({
    required List<ClawExperienceNode> nodes,
    List<ClawExperienceTransition> transitions = const <ClawExperienceTransition>[],
    String entry = 'intro',
  }) {
    return ClawExperienceGraph(
      graphId: 'claw:test:fractions',
      graphVersion: '1.0.0',
      entryNodeId: entry,
      nodes: <String, ClawExperienceNode>{
        for (final value in nodes) value.nodeId: value,
      },
      transitions: transitions,
    );
  }

  group('contract parity', () {
    test('runtime node types match the contract exactly', () {
      final contract = jsonDecode(
        File('contracts/claw-academy-experience.v1.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final contractTypes = (contract['experience_node_types'] as List<dynamic>)
          .cast<String>();
      final runtimeTypes = ClawExperienceNodeType.values
          .map((type) => type.wireName)
          .toList(growable: false);

      expect(runtimeTypes, equals(contractTypes));
    });
  });

  group('graph validation', () {
    const validator = ClawExperienceGraphValidator();

    test('valid graph preserves competency across alternate presentation', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(id: 'intro', type: ClawExperienceNodeType.storyPanel),
          node(id: 'visual', type: ClawExperienceNodeType.diagramOrVisual),
        ],
        transitions: const <ClawExperienceTransition>[
          ClawExperienceTransition(
            transitionId: 'another-way',
            fromNodeId: 'intro',
            toNodeId: 'visual',
            trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
          ),
        ],
      );

      expect(
        () => validator.validate(
          value,
          knownCompetencyIds: const <String>{competency},
          knownInstructionalStrategyIds: const <String>{strategy},
        ),
        returnsNormally,
      );
    });

    test('presentation fallback cannot silently change competency', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(id: 'intro', type: ClawExperienceNodeType.storyPanel),
          node(
            id: 'other',
            type: ClawExperienceNodeType.textExplanation,
            targets: const <String>{'math:geometry:area'},
          ),
        ],
        transitions: const <ClawExperienceTransition>[
          ClawExperienceTransition(
            transitionId: 'another-way',
            fromNodeId: 'intro',
            toNodeId: 'other',
            trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
            governedTargetChangeReason: 'Should not make this legal.',
          ),
        ],
      );

      expect(
        () => validator.validate(value),
        throwsA(isA<ClawExperienceGraphException>()),
      );
    });

    test('normal target change requires explicit governed reason', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(id: 'intro', type: ClawExperienceNodeType.storyPanel),
          node(
            id: 'next-competency',
            type: ClawExperienceNodeType.storyPanel,
            targets: const <String>{'math:fractions:ordering'},
          ),
        ],
        transitions: const <ClawExperienceTransition>[
          ClawExperienceTransition(
            transitionId: 'advance',
            fromNodeId: 'intro',
            toNodeId: 'next-competency',
            trigger: ClawTransitionTrigger.evidenceSatisfied,
          ),
        ],
      );

      expect(
        () => validator.validate(value),
        throwsA(isA<ClawExperienceGraphException>()),
      );
    });

    test('governed competency progression is representable', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(id: 'intro', type: ClawExperienceNodeType.storyPanel),
          node(
            id: 'next-competency',
            type: ClawExperienceNodeType.storyPanel,
            targets: const <String>{'math:fractions:ordering'},
          ),
        ],
        transitions: const <ClawExperienceTransition>[
          ClawExperienceTransition(
            transitionId: 'advance',
            fromNodeId: 'intro',
            toNodeId: 'next-competency',
            trigger: ClawTransitionTrigger.evidenceSatisfied,
            governedTargetChangeReason:
                'Prerequisite evidence satisfied; curriculum sequence advanced.',
          ),
        ],
      );

      expect(() => validator.validate(value), returnsNormally);
    });

    test('AI dialogue requires a non-model fallback', () {
      final value = graph(
        entry: 'ai',
        nodes: <ClawExperienceNode>[
          node(id: 'ai', type: ClawExperienceNodeType.aiSocraticDialogue),
        ],
      );

      expect(
        () => validator.validate(value),
        throwsA(isA<ClawExperienceGraphException>()),
      );
    });

    test('AI dialogue accepts a same-competency fallback', () {
      final value = graph(
        entry: 'ai',
        nodes: <ClawExperienceNode>[
          node(
            id: 'ai',
            type: ClawExperienceNodeType.aiSocraticDialogue,
            fallbacks: const <String>{'worked'},
          ),
          node(id: 'worked', type: ClawExperienceNodeType.workedExample),
        ],
      );

      expect(() => validator.validate(value), returnsNormally);
    });

    test('fallback cannot silently redirect to another competency', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(
            id: 'intro',
            type: ClawExperienceNodeType.storyPanel,
            fallbacks: const <String>{'other'},
          ),
          node(
            id: 'other',
            type: ClawExperienceNodeType.textExplanation,
            targets: const <String>{'science:matter:states'},
          ),
        ],
      );

      expect(
        () => validator.validate(value),
        throwsA(isA<ClawExperienceGraphException>()),
      );
    });

    test('evidence-producing nodes must declare expected evidence', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(id: 'intro', type: ClawExperienceNodeType.directResponse),
        ],
      );

      expect(
        () => validator.validate(value),
        throwsA(isA<ClawExperienceGraphException>()),
      );
    });

    test('unknown competencies and strategies fail closed', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(id: 'intro', type: ClawExperienceNodeType.storyPanel),
        ],
      );

      expect(
        () => validator.validate(
          value,
          knownCompetencyIds: const <String>{'different'},
          knownInstructionalStrategyIds: const <String>{strategy},
        ),
        throwsA(isA<ClawExperienceGraphException>()),
      );
      expect(
        () => validator.validate(
          value,
          knownCompetencyIds: const <String>{competency},
          knownInstructionalStrategyIds: const <String>{'different'},
        ),
        throwsA(isA<ClawExperienceGraphException>()),
      );
    });
  });

  group('adaptation selection', () {
    const selector = ClawExperienceAdaptationSelector();

    test('another-way request filters on device, accessibility, and readiness', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(id: 'intro', type: ClawExperienceNodeType.textExplanation),
          node(
            id: 'diagram',
            type: ClawExperienceNodeType.diagramOrVisual,
            accessibility: const <String>{'alt-text'},
          ),
          node(
            id: 'simulation',
            type: ClawExperienceNodeType.simulationLaunch,
            devices: const <String>{'pointer-input'},
          ),
          node(
            id: 'mature-story',
            type: ClawExperienceNodeType.storyPanel,
            readiness: const <String>{'sensitive-topic'},
          ),
        ],
        transitions: const <ClawExperienceTransition>[
          ClawExperienceTransition(
            transitionId: 'a-diagram',
            fromNodeId: 'intro',
            toNodeId: 'diagram',
            trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
          ),
          ClawExperienceTransition(
            transitionId: 'b-simulation',
            fromNodeId: 'intro',
            toNodeId: 'simulation',
            trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
          ),
          ClawExperienceTransition(
            transitionId: 'c-story',
            fromNodeId: 'intro',
            toNodeId: 'mature-story',
            trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
          ),
        ],
      );

      final decision = selector.eligibleTransitions(
        graph: value,
        currentNodeId: 'intro',
        trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
        availability: const ClawExperienceAvailability(
          accessibilityCapabilities: <String>{'alt-text'},
          deniedContentReadinessTags: <String>{'sensitive-topic'},
        ),
      );

      expect(
        decision.eligibleTransitions.map((value) => value.transitionId),
        <String>['a-diagram'],
      );
      expect(
        decision.excludedTransitionReasons['b-simulation'],
        'required-device-capability-unavailable',
      );
      expect(
        decision.excludedTransitionReasons['c-story'],
        'content-readiness-denied',
      );
      expect(decision.performsEngagementRanking, isFalse);
      expect(decision.changesGovernedCompetencyByInference, isFalse);
    });

    test('AI and human help availability are explicit', () {
      final value = graph(
        nodes: <ClawExperienceNode>[
          node(id: 'intro', type: ClawExperienceNodeType.textExplanation),
          node(
            id: 'ai',
            type: ClawExperienceNodeType.aiSocraticDialogue,
            fallbacks: const <String>{'worked'},
          ),
          node(id: 'worked', type: ClawExperienceNodeType.workedExample),
          node(
            id: 'human',
            type: ClawExperienceNodeType.humanTutorRequest,
          ),
        ],
        transitions: const <ClawExperienceTransition>[
          ClawExperienceTransition(
            transitionId: 'ai-help',
            fromNodeId: 'intro',
            toNodeId: 'ai',
            trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
          ),
          ClawExperienceTransition(
            transitionId: 'human-help',
            fromNodeId: 'intro',
            toNodeId: 'human',
            trigger: ClawTransitionTrigger.learnerRequestsHumanHelp,
          ),
        ],
      );

      final aiDecision = selector.eligibleTransitions(
        graph: value,
        currentNodeId: 'intro',
        trigger: ClawTransitionTrigger.learnerRequestsAnotherWay,
        availability: const ClawExperienceAvailability(),
      );
      final humanDecision = selector.eligibleTransitions(
        graph: value,
        currentNodeId: 'intro',
        trigger: ClawTransitionTrigger.learnerRequestsHumanHelp,
        availability: const ClawExperienceAvailability(),
      );

      expect(aiDecision.eligibleTransitions, isEmpty);
      expect(
        aiDecision.excludedTransitionReasons['ai-help'],
        'model-unavailable',
      );
      expect(humanDecision.eligibleTransitions, isEmpty);
      expect(
        humanDecision.excludedTransitionReasons['human-help'],
        'human-help-unavailable',
      );
    });
  });

  test('experience boundary cannot promote educational authority', () {
    const boundary = ClawExperienceBoundary();

    expect(boundary.engagementMayOverrideLearningEvidence, isFalse);
    expect(boundary.modelOutputCreatesAuthority, isFalse);
    expect(boundary.externalToolResultIsMasteryByDefault, isFalse);
    expect(boundary.experienceMayCreateFinalGrade, isFalse);
    expect(boundary.experienceMayCreateCredit, isFalse);
    expect(boundary.experienceMayMintCredential, isFalse);
  });
}
