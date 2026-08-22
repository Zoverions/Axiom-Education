enum ClawExperienceNodeType {
  storyPanel,
  comicPanel,
  textExplanation,
  diagramOrVisual,
  workedExample,
  learnerChoice,
  directResponse,
  adaptiveHint,
  resourceLaunch,
  videoLaunch,
  simulationLaunch,
  gameLaunch,
  codeOrBuildChallenge,
  creativeConstruction,
  realWorldObservation,
  peerTask,
  groupTask,
  educatorHelpRequest,
  humanTutorRequest,
  aiSocraticDialogue,
  reflectionPrompt,
  metacognitionPrompt,
  retrievalCheckpoint,
  transferChallenge,
  projectArtifact,
  evidenceCandidate,
}

extension ClawExperienceNodeTypeWire on ClawExperienceNodeType {
  String get wireName => switch (this) {
    ClawExperienceNodeType.storyPanel => 'story-panel',
    ClawExperienceNodeType.comicPanel => 'comic-panel',
    ClawExperienceNodeType.textExplanation => 'text-explanation',
    ClawExperienceNodeType.diagramOrVisual => 'diagram-or-visual',
    ClawExperienceNodeType.workedExample => 'worked-example',
    ClawExperienceNodeType.learnerChoice => 'learner-choice',
    ClawExperienceNodeType.directResponse => 'direct-response',
    ClawExperienceNodeType.adaptiveHint => 'adaptive-hint',
    ClawExperienceNodeType.resourceLaunch => 'resource-launch',
    ClawExperienceNodeType.videoLaunch => 'video-launch',
    ClawExperienceNodeType.simulationLaunch => 'simulation-launch',
    ClawExperienceNodeType.gameLaunch => 'game-launch',
    ClawExperienceNodeType.codeOrBuildChallenge => 'code-or-build-challenge',
    ClawExperienceNodeType.creativeConstruction => 'creative-construction',
    ClawExperienceNodeType.realWorldObservation => 'real-world-observation',
    ClawExperienceNodeType.peerTask => 'peer-task',
    ClawExperienceNodeType.groupTask => 'group-task',
    ClawExperienceNodeType.educatorHelpRequest => 'educator-help-request',
    ClawExperienceNodeType.humanTutorRequest => 'human-tutor-request',
    ClawExperienceNodeType.aiSocraticDialogue => 'ai-socratic-dialogue',
    ClawExperienceNodeType.reflectionPrompt => 'reflection-prompt',
    ClawExperienceNodeType.metacognitionPrompt => 'metacognition-prompt',
    ClawExperienceNodeType.retrievalCheckpoint => 'retrieval-checkpoint',
    ClawExperienceNodeType.transferChallenge => 'transfer-challenge',
    ClawExperienceNodeType.projectArtifact => 'project-artifact',
    ClawExperienceNodeType.evidenceCandidate => 'evidence-candidate',
  };
}

enum ClawTransitionTrigger {
  automatic,
  learnerChoice,
  learnerRequestsAnotherWay,
  learnerRequestsHumanHelp,
  evidenceSatisfied,
  evidenceInsufficient,
  resourceUnavailable,
  modelUnavailable,
  toolUnavailable,
  accessibilityUnavailable,
  contentReadinessDenied,
  explicitRetry,
}

extension ClawTransitionTriggerWire on ClawTransitionTrigger {
  String get wireName => switch (this) {
    ClawTransitionTrigger.automatic => 'automatic',
    ClawTransitionTrigger.learnerChoice => 'learner-choice',
    ClawTransitionTrigger.learnerRequestsAnotherWay =>
      'learner-requests-another-way',
    ClawTransitionTrigger.learnerRequestsHumanHelp =>
      'learner-requests-human-help',
    ClawTransitionTrigger.evidenceSatisfied => 'evidence-satisfied',
    ClawTransitionTrigger.evidenceInsufficient => 'evidence-insufficient',
    ClawTransitionTrigger.resourceUnavailable => 'resource-unavailable',
    ClawTransitionTrigger.modelUnavailable => 'model-unavailable',
    ClawTransitionTrigger.toolUnavailable => 'tool-unavailable',
    ClawTransitionTrigger.accessibilityUnavailable =>
      'accessibility-unavailable',
    ClawTransitionTrigger.contentReadinessDenied => 'content-readiness-denied',
    ClawTransitionTrigger.explicitRetry => 'explicit-retry',
  };
}

class ClawExperienceNode {
  final String nodeId;
  final Set<String> targetCompetencyIds;
  final ClawExperienceNodeType experienceType;
  final Set<String> instructionalStrategyIds;
  final Set<String> requiredDeviceCapabilities;
  final Set<String> requiredAccessibilityCapabilities;
  final Set<String> contentReadinessTags;
  final Set<String> expectedEvidenceKinds;
  final Set<String> fallbackNodeIds;

  const ClawExperienceNode({
    required this.nodeId,
    required this.targetCompetencyIds,
    required this.experienceType,
    required this.instructionalStrategyIds,
    this.requiredDeviceCapabilities = const <String>{},
    this.requiredAccessibilityCapabilities = const <String>{},
    this.contentReadinessTags = const <String>{},
    this.expectedEvidenceKinds = const <String>{},
    this.fallbackNodeIds = const <String>{},
  });
}

class ClawExperienceTransition {
  final String transitionId;
  final String fromNodeId;
  final String toNodeId;
  final ClawTransitionTrigger trigger;
  final String? conditionTag;
  final String? governedTargetChangeReason;

  const ClawExperienceTransition({
    required this.transitionId,
    required this.fromNodeId,
    required this.toNodeId,
    required this.trigger,
    this.conditionTag,
    this.governedTargetChangeReason,
  });
}

class ClawExperienceGraph {
  final String graphId;
  final String graphVersion;
  final String entryNodeId;
  final Map<String, ClawExperienceNode> nodes;
  final List<ClawExperienceTransition> transitions;

  ClawExperienceGraph({
    required this.graphId,
    required this.graphVersion,
    required this.entryNodeId,
    required Map<String, ClawExperienceNode> nodes,
    required List<ClawExperienceTransition> transitions,
  }) : nodes = Map<String, ClawExperienceNode>.unmodifiable(nodes),
       transitions = List<ClawExperienceTransition>.unmodifiable(transitions);
}

class ClawExperienceAvailability {
  final Set<String> deviceCapabilities;
  final Set<String> accessibilityCapabilities;
  final Set<String> deniedContentReadinessTags;
  final bool modelAvailable;
  final bool humanHelpAvailable;

  const ClawExperienceAvailability({
    this.deviceCapabilities = const <String>{},
    this.accessibilityCapabilities = const <String>{},
    this.deniedContentReadinessTags = const <String>{},
    this.modelAvailable = false,
    this.humanHelpAvailable = false,
  });
}

class ClawExperienceEligibilityDecision {
  final List<ClawExperienceTransition> eligibleTransitions;
  final Map<String, String> excludedTransitionReasons;

  const ClawExperienceEligibilityDecision({
    required this.eligibleTransitions,
    required this.excludedTransitionReasons,
  });

  bool get performsEngagementRanking => false;

  bool get changesGovernedCompetencyByInference => false;
}

class ClawExperienceGraphValidator {
  const ClawExperienceGraphValidator();

  void validate(
    ClawExperienceGraph graph, {
    Set<String>? knownCompetencyIds,
    Set<String>? knownInstructionalStrategyIds,
  }) {
    _requireIdentifier(graph.graphId, 'Graph ID');
    _requireIdentifier(graph.graphVersion, 'Graph version');
    _requireIdentifier(graph.entryNodeId, 'Entry node ID');
    if (!graph.nodes.containsKey(graph.entryNodeId)) {
      throw const ClawExperienceGraphException(
        'Entry node must exist in the graph.',
      );
    }
    if (graph.nodes.isEmpty) {
      throw const ClawExperienceGraphException(
        'Experience graph must contain at least one node.',
      );
    }

    final transitionIds = <String>{};
    for (final entry in graph.nodes.entries) {
      if (entry.key != entry.value.nodeId) {
        throw const ClawExperienceGraphException(
          'Node map keys must match node IDs.',
        );
      }
      _validateNode(
        entry.value,
        graph,
        knownCompetencyIds: knownCompetencyIds,
        knownInstructionalStrategyIds: knownInstructionalStrategyIds,
      );
    }

    for (final transition in graph.transitions) {
      _requireIdentifier(transition.transitionId, 'Transition ID');
      if (!transitionIds.add(transition.transitionId)) {
        throw ClawExperienceGraphException(
          'Duplicate transition ID: ${transition.transitionId}',
        );
      }
      final from = graph.nodes[transition.fromNodeId];
      final to = graph.nodes[transition.toNodeId];
      if (from == null || to == null) {
        throw const ClawExperienceGraphException(
          'Transition endpoints must exist in the graph.',
        );
      }
      if (_presentationFallbackTrigger(transition.trigger) &&
          !_sameTargets(from, to)) {
        throw const ClawExperienceGraphException(
          'Presentation fallback transitions must preserve target competencies.',
        );
      }
      if (!_sameTargets(from, to) &&
          (transition.governedTargetChangeReason == null ||
              transition.governedTargetChangeReason!.trim().isEmpty)) {
        throw const ClawExperienceGraphException(
          'Target competency changes require an explicit governed reason.',
        );
      }
    }
  }

  void _validateNode(
    ClawExperienceNode node,
    ClawExperienceGraph graph, {
    required Set<String>? knownCompetencyIds,
    required Set<String>? knownInstructionalStrategyIds,
  }) {
    _requireIdentifier(node.nodeId, 'Node ID');
    if (node.targetCompetencyIds.isEmpty) {
      throw const ClawExperienceGraphException(
        'Every node must bind to at least one target competency.',
      );
    }
    if (node.instructionalStrategyIds.isEmpty) {
      throw const ClawExperienceGraphException(
        'Every node must bind to at least one instructional strategy.',
      );
    }
    if (knownCompetencyIds != null &&
        !knownCompetencyIds.containsAll(node.targetCompetencyIds)) {
      throw const ClawExperienceGraphException(
        'Node references an unknown target competency.',
      );
    }
    if (knownInstructionalStrategyIds != null &&
        !knownInstructionalStrategyIds.containsAll(
          node.instructionalStrategyIds,
        )) {
      throw const ClawExperienceGraphException(
        'Node references an unknown instructional strategy.',
      );
    }
    for (final fallbackId in node.fallbackNodeIds) {
      if (fallbackId == node.nodeId) {
        throw const ClawExperienceGraphException(
          'A node cannot fall back to itself.',
        );
      }
      final fallback = graph.nodes[fallbackId];
      if (fallback == null) {
        throw const ClawExperienceGraphException(
          'Fallback node must exist in the graph.',
        );
      }
      if (!_sameTargets(node, fallback)) {
        throw const ClawExperienceGraphException(
          'Fallback nodes must preserve target competencies.',
        );
      }
    }
    if (node.experienceType == ClawExperienceNodeType.aiSocraticDialogue &&
        node.fallbackNodeIds.isEmpty) {
      throw const ClawExperienceGraphException(
        'AI Socratic dialogue requires a non-model fallback node.',
      );
    }
    if (_evidenceProducingType(node.experienceType) &&
        node.expectedEvidenceKinds.isEmpty) {
      throw const ClawExperienceGraphException(
        'Evidence-producing nodes must declare expected evidence kinds.',
      );
    }
  }

  bool _sameTargets(ClawExperienceNode a, ClawExperienceNode b) {
    return a.targetCompetencyIds.length == b.targetCompetencyIds.length &&
        a.targetCompetencyIds.containsAll(b.targetCompetencyIds);
  }

  bool _presentationFallbackTrigger(ClawTransitionTrigger trigger) {
    return switch (trigger) {
      ClawTransitionTrigger.learnerRequestsAnotherWay ||
      ClawTransitionTrigger.resourceUnavailable ||
      ClawTransitionTrigger.modelUnavailable ||
      ClawTransitionTrigger.toolUnavailable ||
      ClawTransitionTrigger.accessibilityUnavailable ||
      ClawTransitionTrigger.contentReadinessDenied => true,
      _ => false,
    };
  }

  bool _evidenceProducingType(ClawExperienceNodeType type) {
    return switch (type) {
      ClawExperienceNodeType.directResponse ||
      ClawExperienceNodeType.retrievalCheckpoint ||
      ClawExperienceNodeType.transferChallenge ||
      ClawExperienceNodeType.projectArtifact ||
      ClawExperienceNodeType.evidenceCandidate => true,
      _ => false,
    };
  }

  void _requireIdentifier(String value, String label) {
    if (value.trim().isEmpty) {
      throw ClawExperienceGraphException('$label is required.');
    }
  }
}

class ClawExperienceAdaptationSelector {
  const ClawExperienceAdaptationSelector();

  ClawExperienceEligibilityDecision eligibleTransitions({
    required ClawExperienceGraph graph,
    required String currentNodeId,
    required ClawTransitionTrigger trigger,
    required ClawExperienceAvailability availability,
  }) {
    if (!graph.nodes.containsKey(currentNodeId)) {
      throw const ClawExperienceGraphException(
        'Current node must exist in the graph.',
      );
    }

    final eligible = <ClawExperienceTransition>[];
    final excluded = <String, String>{};
    final candidates =
        graph.transitions
            .where(
              (transition) =>
                  transition.fromNodeId == currentNodeId &&
                  transition.trigger == trigger,
            )
            .toList(growable: false)
          ..sort((a, b) => a.transitionId.compareTo(b.transitionId));

    for (final transition in candidates) {
      final destination = graph.nodes[transition.toNodeId]!;
      final exclusion = _exclusionReason(destination, availability);
      if (exclusion != null) {
        excluded[transition.transitionId] = exclusion;
        continue;
      }
      eligible.add(transition);
    }

    return ClawExperienceEligibilityDecision(
      eligibleTransitions: List<ClawExperienceTransition>.unmodifiable(
        eligible,
      ),
      excludedTransitionReasons: Map<String, String>.unmodifiable(excluded),
    );
  }

  String? _exclusionReason(
    ClawExperienceNode node,
    ClawExperienceAvailability availability,
  ) {
    if (!availability.deviceCapabilities.containsAll(
      node.requiredDeviceCapabilities,
    )) {
      return 'required-device-capability-unavailable';
    }
    if (!availability.accessibilityCapabilities.containsAll(
      node.requiredAccessibilityCapabilities,
    )) {
      return 'required-accessibility-capability-unavailable';
    }
    if (node.contentReadinessTags.any(
      availability.deniedContentReadinessTags.contains,
    )) {
      return 'content-readiness-denied';
    }
    if (node.experienceType == ClawExperienceNodeType.aiSocraticDialogue &&
        !availability.modelAvailable) {
      return 'model-unavailable';
    }
    if ((node.experienceType == ClawExperienceNodeType.educatorHelpRequest ||
            node.experienceType == ClawExperienceNodeType.humanTutorRequest) &&
        !availability.humanHelpAvailable) {
      return 'human-help-unavailable';
    }
    return null;
  }
}

class ClawExperienceBoundary {
  const ClawExperienceBoundary();

  bool get engagementMayOverrideLearningEvidence => false;

  bool get modelOutputCreatesAuthority => false;

  bool get externalToolResultIsMasteryByDefault => false;

  bool get experienceMayCreateFinalGrade => false;

  bool get experienceMayCreateCredit => false;

  bool get experienceMayMintCredential => false;
}

class ClawExperienceGraphException implements Exception {
  final String message;

  const ClawExperienceGraphException(this.message);

  @override
  String toString() => 'ClawExperienceGraphException: $message';
}
