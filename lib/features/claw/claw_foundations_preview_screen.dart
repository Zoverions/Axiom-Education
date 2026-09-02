import 'package:flutter/material.dart';

import '../../core/models/claw_experience_graph.dart';
import '../../core/models/claw_experience_presentation.dart';
import '../../core/models/claw_presentation_preset.dart';
import '../../core/models/education_model_execution.dart';
import '../../core/models/education_model_routing.dart';
import '../../widgets/claw_experience_renderer.dart';
import 'claw_foundations_story_arc.dart';

class ClawFoundationsSocraticExecutionBinding {
  static const _allowedScopes = <EducationModelContextScope>{
    EducationModelContextScope.targetCompetency,
    EducationModelContextScope.currentLearnerInput,
  };

  final EducationModelExecutor executor;
  final EducationModelRouteRequest routeRequest;
  final EducationModelContextGrant contextGrant;
  final List<EducationModelCandidate> candidates;

  ClawFoundationsSocraticExecutionBinding({
    required this.executor,
    required this.routeRequest,
    required this.contextGrant,
    required List<EducationModelCandidate> candidates,
  }) : candidates = List<EducationModelCandidate>.unmodifiable(candidates);

  Future<ClawSocraticResult> handle(ClawSocraticRequest request) async {
    final learnerInput = request.learnerInput.trim();
    if (request.nodeId != 'socratic' ||
        learnerInput.isEmpty ||
        learnerInput.length > 280 ||
        !_sameStrings(request.targetCompetencyIds, const <String>{
          ClawFoundationsStoryArc.competencyId,
        }) ||
        routeRequest.taskClass != EducationModelTaskClass.socraticTutor ||
        !_sameScopes(routeRequest.requestedContextScopes, _allowedScopes)) {
      return const ClawSocraticResult.failure('invalid-socratic-request');
    }

    final execution = await executor.execute(
      request: routeRequest,
      contextGrant: contextGrant,
      candidates: candidates,
      materializedContext: <EducationModelContextScope, String>{
        EducationModelContextScope.targetCompetency:
            ClawFoundationsStoryArc.competencyId,
        EducationModelContextScope.currentLearnerInput: learnerInput,
      },
    );

    if (!execution.succeeded) {
      return ClawSocraticResult.failure(
        execution.failureReason ?? 'model-execution-failed',
      );
    }

    final output = execution.outputText?.trim();
    if (output == null || output.isEmpty) {
      return const ClawSocraticResult.failure('empty-model-output');
    }
    return ClawSocraticResult.success(output);
  }

  static bool _sameStrings(Set<String> left, Set<String> right) {
    return left.length == right.length && left.containsAll(right);
  }

  static bool _sameScopes(
    Set<EducationModelContextScope> left,
    Set<EducationModelContextScope> right,
  ) {
    return left.length == right.length && left.containsAll(right);
  }
}

class ClawFoundationsPreviewScreen extends StatefulWidget {
  final ClawFoundationsSocraticExecutionBinding? socraticBinding;

  const ClawFoundationsPreviewScreen({super.key, this.socraticBinding});

  @override
  State<ClawFoundationsPreviewScreen> createState() =>
      _ClawFoundationsPreviewScreenState();
}

class _ClawFoundationsPreviewScreenState
    extends State<ClawFoundationsPreviewScreen> {
  static const _resolver = ClawPresentationPresetResolver();

  ClawPresentationPreset _preset = ClawPresentationPreset.explorer;

  @override
  Widget build(BuildContext context) {
    final resolvedPresentations = _resolver.resolve(
      basePresentations: ClawFoundationsStoryArc.presentations,
      variants: ClawFoundationsStoryArc.presentationVariants,
      preset: _preset,
    );
    final baseAvailability = ClawFoundationsStoryArc.availability;
    final availability = ClawExperienceAvailability(
      deviceCapabilities: baseAvailability.deviceCapabilities,
      accessibilityCapabilities: baseAvailability.accessibilityCapabilities,
      deniedContentReadinessTags: baseAvailability.deniedContentReadinessTags,
      modelAvailable: widget.socraticBinding != null,
      humanHelpAvailable: baseAvailability.humanHelpAvailable,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Claw Academy Preview')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _PreviewBoundaryCard(),
                    const SizedBox(height: 16),
                    _PresentationPresetCard(
                      selected: _preset,
                      onSelected: (preset) {
                        setState(() {
                          _preset = preset;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ClawExperiencePlayer(
                      key: const ValueKey('claw-foundations-player'),
                      graph: ClawFoundationsStoryArc.graph,
                      presentations: resolvedPresentations,
                      availability: availability,
                      socraticHandler: widget.socraticBinding?.handle,
                      onEvidenceCandidate: (candidate) =>
                          _showEvidenceNotice(context, candidate),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showEvidenceNotice(
    BuildContext context,
    ClawLocalEvidenceCandidate candidate,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            candidate.route == ClawLocalEvidenceRoute.satisfied
                ? 'Response used to choose the next preview step. It was not saved as mastery or a grade.'
                : 'Response used to choose another explanation. It was not saved as an ability label.',
          ),
        ),
      );
  }
}

class _PresentationPresetCard extends StatelessWidget {
  final ClawPresentationPreset selected;
  final ValueChanged<ClawPresentationPreset> onSelected;

  const _PresentationPresetCard({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Presentation support',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose how the explanation is presented. This does not set age, ability, grade, mastery, or curriculum level.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final preset in ClawPresentationPreset.values)
                  ChoiceChip(
                    key: ValueKey('claw-preset-${preset.wireName}'),
                    label: Text(preset.label),
                    selected: preset == selected,
                    onSelected: (_) => onSelected(preset),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              label: 'Selected presentation support',
              child: Text(
                '${selected.label}: ${selected.supportSummary}',
                key: const ValueKey('claw-preset-summary'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBoundaryCard extends StatelessWidget {
  const _PreviewBoundaryCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.shield_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This is a local adaptive preview. It can change the explanation path, but it cannot change curriculum truth, create a grade or credit, or write an official learner record.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
