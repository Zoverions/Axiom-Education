import 'package:flutter/material.dart';

import '../core/models/claw_experience_graph.dart';
import '../core/models/claw_experience_presentation.dart';

typedef ClawEvidenceCandidateCallback =
    void Function(ClawLocalEvidenceCandidate candidate);
typedef ClawSocraticHandler =
    Future<ClawSocraticResult> Function(ClawSocraticRequest request);

class ClawSocraticRequest {
  final String nodeId;
  final Set<String> targetCompetencyIds;
  final String learnerInput;

  ClawSocraticRequest({
    required this.nodeId,
    required Set<String> targetCompetencyIds,
    required this.learnerInput,
  }) : targetCompetencyIds = Set<String>.unmodifiable(targetCompetencyIds);
}

class ClawSocraticResult {
  final String? instructionalText;
  final String? failureReason;

  const ClawSocraticResult.success(String text)
    : instructionalText = text,
      failureReason = null;

  const ClawSocraticResult.failure(String reason)
    : instructionalText = null,
      failureReason = reason;

  bool get succeeded =>
      failureReason == null && instructionalText?.trim().isNotEmpty == true;
}

class ClawExperiencePlayer extends StatefulWidget {
  final ClawExperienceGraph graph;
  final Map<String, ClawExperiencePresentation> presentations;
  final ClawExperienceAvailability availability;
  final ClawSocraticHandler? socraticHandler;
  final ClawEvidenceCandidateCallback? onEvidenceCandidate;
  final ValueChanged<String>? onNodeChanged;

  const ClawExperiencePlayer({
    super.key,
    required this.graph,
    required this.presentations,
    required this.availability,
    this.socraticHandler,
    this.onEvidenceCandidate,
    this.onNodeChanged,
  });

  @override
  State<ClawExperiencePlayer> createState() => _ClawExperiencePlayerState();
}

class _ClawExperiencePlayerState extends State<ClawExperiencePlayer> {
  static const _selector = ClawExperienceAdaptationSelector();
  static const _socraticFailureMessage =
      'Tutor unavailable. Showing the reviewed non-model explanation.';

  late String _currentNodeId;
  String? _statusMessage;
  String _socraticInput = '';
  String? _socraticInstructionalText;
  bool _socraticLoading = false;

  @override
  void initState() {
    super.initState();
    _currentNodeId = widget.graph.entryNodeId;
  }

  @override
  void didUpdateWidget(covariant ClawExperiencePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph &&
        !widget.graph.nodes.containsKey(_currentNodeId)) {
      _currentNodeId = widget.graph.entryNodeId;
      _statusMessage = null;
      _resetSocraticState();
    }
  }

  Set<ClawTransitionTrigger> get _availableTriggers {
    return widget.graph.transitions
        .where((transition) => transition.fromNodeId == _currentNodeId)
        .map((transition) => transition.trigger)
        .toSet();
  }

  void _resetSocraticState() {
    _socraticInput = '';
    _socraticInstructionalText = null;
    _socraticLoading = false;
  }

  void _transition(
    ClawTransitionTrigger trigger, {
    String? statusMessage,
  }) {
    final decision = _selector.eligibleTransitions(
      graph: widget.graph,
      currentNodeId: _currentNodeId,
      trigger: trigger,
      availability: widget.availability,
    );

    if (decision.eligibleTransitions.isEmpty) {
      setState(() {
        _statusMessage = statusMessage ?? 'That path is not available right now.';
      });
      return;
    }

    final next = decision.eligibleTransitions.first.toNodeId;
    setState(() {
      _currentNodeId = next;
      _statusMessage = statusMessage;
      _resetSocraticState();
    });
    widget.onNodeChanged?.call(next);
  }

  void _handleChoice(ClawExperienceChoicePresentation choice) {
    final route = choice.evidenceRoute;
    if (route == null) {
      _transition(ClawTransitionTrigger.learnerChoice);
      return;
    }

    widget.onEvidenceCandidate?.call(
      ClawLocalEvidenceCandidate(
        nodeId: _currentNodeId,
        choiceId: choice.choiceId,
        route: route,
      ),
    );

    _transition(switch (route) {
      ClawLocalEvidenceRoute.satisfied =>
        ClawTransitionTrigger.evidenceSatisfied,
      ClawLocalEvidenceRoute.insufficient =>
        ClawTransitionTrigger.evidenceInsufficient,
    });
  }

  Future<void> _submitSocratic() async {
    final handler = widget.socraticHandler;
    final learnerInput = _socraticInput.trim();
    final node = widget.graph.nodes[_currentNodeId];
    if (handler == null ||
        learnerInput.isEmpty ||
        node?.experienceType != ClawExperienceNodeType.aiSocraticDialogue ||
        _socraticLoading) {
      return;
    }

    final submittedNodeId = _currentNodeId;
    setState(() {
      _socraticLoading = true;
      _socraticInstructionalText = null;
    });

    ClawSocraticResult result;
    try {
      result = await handler(
        ClawSocraticRequest(
          nodeId: submittedNodeId,
          targetCompetencyIds: node!.targetCompetencyIds,
          learnerInput: learnerInput,
        ),
      );
    } catch (_) {
      result = const ClawSocraticResult.failure('handler-failure');
    }

    if (!mounted || _currentNodeId != submittedNodeId) {
      return;
    }

    if (!result.succeeded) {
      _transition(
        ClawTransitionTrigger.modelUnavailable,
        statusMessage: _socraticFailureMessage,
      );
      return;
    }

    setState(() {
      _socraticLoading = false;
      _socraticInstructionalText = result.instructionalText!.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.graph.nodes[_currentNodeId]!;
    final presentation = widget.presentations[_currentNodeId];
    final triggers = _availableTriggers;
    final learnerChoiceDecision = _selector.eligibleTransitions(
      graph: widget.graph,
      currentNodeId: _currentNodeId,
      trigger: ClawTransitionTrigger.learnerChoice,
      availability: widget.availability,
    );
    final socraticChoiceAvailable =
        widget.socraticHandler != null &&
        learnerChoiceDecision.eligibleTransitions.any(
          (transition) =>
              widget.graph.nodes[transition.toNodeId]?.experienceType ==
              ClawExperienceNodeType.aiSocraticDialogue,
        );

    return Semantics(
      container: true,
      label: 'Claw Academy learning experience',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_statusMessage != null) ...<Widget>[
            _ClawStatusMessage(message: _statusMessage!),
            const SizedBox(height: 12),
          ],
          ClawExperienceNodeRenderer(
            key: ValueKey('claw-node-$_currentNodeId'),
            node: node,
            presentation: presentation,
            onContinue: triggers.contains(ClawTransitionTrigger.automatic)
                ? () => _transition(ClawTransitionTrigger.automatic)
                : null,
            onAnotherWay:
                triggers.contains(
                  ClawTransitionTrigger.learnerRequestsAnotherWay,
                )
                ? () => _transition(
                    ClawTransitionTrigger.learnerRequestsAnotherWay,
                  )
                : null,
            onHumanHelp:
                triggers.contains(
                  ClawTransitionTrigger.learnerRequestsHumanHelp,
                )
                ? () => _transition(
                    ClawTransitionTrigger.learnerRequestsHumanHelp,
                  )
                : null,
            onSocraticChoice: socraticChoiceAvailable
                ? () => _transition(ClawTransitionTrigger.learnerChoice)
                : null,
            onSocraticInputChanged: node.experienceType ==
                    ClawExperienceNodeType.aiSocraticDialogue
                ? (value) {
                    setState(() {
                      _socraticInput = value;
                    });
                  }
                : null,
            onSocraticSubmit:
                node.experienceType == ClawExperienceNodeType.aiSocraticDialogue &&
                    widget.socraticHandler != null &&
                    _socraticInput.trim().isNotEmpty &&
                    !_socraticLoading
                ? _submitSocratic
                : null,
            socraticLoading: _socraticLoading,
            socraticInstructionalText: _socraticInstructionalText,
            onChoice: presentation?.choices.isNotEmpty == true
                ? _handleChoice
                : null,
          ),
        ],
      ),
    );
  }
}

class ClawExperienceNodeRenderer extends StatelessWidget {
  final ClawExperienceNode node;
  final ClawExperiencePresentation? presentation;
  final VoidCallback? onContinue;
  final VoidCallback? onAnotherWay;
  final VoidCallback? onHumanHelp;
  final VoidCallback? onSocraticChoice;
  final ValueChanged<String>? onSocraticInputChanged;
  final VoidCallback? onSocraticSubmit;
  final bool socraticLoading;
  final String? socraticInstructionalText;
  final ValueChanged<ClawExperienceChoicePresentation>? onChoice;

  const ClawExperienceNodeRenderer({
    super.key,
    required this.node,
    required this.presentation,
    this.onContinue,
    this.onAnotherWay,
    this.onHumanHelp,
    this.onSocraticChoice,
    this.onSocraticInputChanged,
    this.onSocraticSubmit,
    this.socraticLoading = false,
    this.socraticInstructionalText,
    this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = presentation;
    final isSocratic =
        node.experienceType == ClawExperienceNodeType.aiSocraticDialogue;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  child: Icon(_iconFor(node.experienceType)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        value?.eyebrow ?? _typeLabel(node.experienceType),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value?.title ?? 'Content unavailable',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value?.body ??
                  'This experience node has no learner-facing presentation yet. '
                      'The governed graph remains intact and no substitute content '
                      'will be invented automatically.',
              style: theme.textTheme.bodyLarge,
            ),
            if (value?.bullets.isNotEmpty == true) ...<Widget>[
              const SizedBox(height: 14),
              for (final bullet in value!.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: Icon(Icons.circle, size: 7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(bullet)),
                    ],
                  ),
                ),
            ],
            if (value?.supportingText != null) ...<Widget>[
              const SizedBox(height: 14),
              Text(value!.supportingText!, style: theme.textTheme.bodySmall),
            ],
            if (isSocratic) ...<Widget>[
              const SizedBox(height: 18),
              TextField(
                key: const ValueKey('claw-socratic-input'),
                enabled: !socraticLoading,
                maxLength: 280,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What do you notice?',
                  border: OutlineInputBorder(),
                ),
                onChanged: onSocraticInputChanged,
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('claw-socratic-submit'),
                onPressed: socraticLoading ? null : onSocraticSubmit,
                child: Text(socraticLoading ? 'Thinking…' : 'Ask the tutor'),
              ),
              if (socraticInstructionalText != null) ...<Widget>[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  label: 'Tutor response',
                  child: Text(
                    socraticInstructionalText!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ],
            if (value?.choices.isNotEmpty == true) ...<Widget>[
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final choice in value!.choices)
                    FilledButton.tonal(
                      key: ValueKey('claw-choice-${choice.choiceId}'),
                      onPressed: onChoice == null
                          ? null
                          : () => onChoice!(choice),
                      child: Text(choice.label),
                    ),
                ],
              ),
            ],
            if (onContinue != null ||
                onAnotherWay != null ||
                onHumanHelp != null ||
                onSocraticChoice != null) ...<Widget>[
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  if (onContinue != null)
                    FilledButton.icon(
                      key: const ValueKey('claw-continue'),
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(value?.continueLabel ?? 'Continue'),
                    ),
                  if (onSocraticChoice != null)
                    OutlinedButton.icon(
                      key: const ValueKey('claw-socratic-choice'),
                      onPressed: onSocraticChoice,
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('Ask the tutor'),
                    ),
                  if (onAnotherWay != null)
                    OutlinedButton.icon(
                      key: const ValueKey('claw-another-way'),
                      onPressed: onAnotherWay,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Show me another way'),
                    ),
                  if (onHumanHelp != null)
                    OutlinedButton.icon(
                      key: const ValueKey('claw-human-help'),
                      onPressed: onHumanHelp,
                      icon: const Icon(Icons.support_agent_rounded),
                      label: const Text('Ask for human help'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _CompetencyBoundary(node: node),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(ClawExperienceNodeType type) {
    return switch (type) {
      ClawExperienceNodeType.storyPanel ||
      ClawExperienceNodeType.comicPanel => Icons.auto_stories_rounded,
      ClawExperienceNodeType.diagramOrVisual => Icons.image_outlined,
      ClawExperienceNodeType.workedExample => Icons.functions_rounded,
      ClawExperienceNodeType.retrievalCheckpoint ||
      ClawExperienceNodeType.directResponse ||
      ClawExperienceNodeType.evidenceCandidate => Icons.fact_check_outlined,
      ClawExperienceNodeType.adaptiveHint => Icons.lightbulb_outline_rounded,
      ClawExperienceNodeType.aiSocraticDialogue => Icons.smart_toy_outlined,
      ClawExperienceNodeType.educatorHelpRequest ||
      ClawExperienceNodeType.humanTutorRequest => Icons.support_agent_rounded,
      ClawExperienceNodeType.simulationLaunch ||
      ClawExperienceNodeType.gameLaunch => Icons.extension_outlined,
      _ => Icons.school_outlined,
    };
  }

  static String _typeLabel(ClawExperienceNodeType type) {
    return type.wireName.replaceAll('-', ' ');
  }
}

class _CompetencyBoundary extends StatelessWidget {
  final ClawExperienceNode node;

  const _CompetencyBoundary({required this.node});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Current learning target',
      child: Text(
        'Learning target: ${node.targetCompetencyIds.join(', ')}',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _ClawStatusMessage extends StatelessWidget {
  final String message;

  const _ClawStatusMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.info_outline_rounded),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
