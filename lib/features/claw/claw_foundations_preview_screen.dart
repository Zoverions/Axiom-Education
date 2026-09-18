import 'package:flutter/material.dart';

import '../../core/models/claw_experience_graph.dart';
import '../../core/models/claw_experience_presentation.dart';
import '../../core/models/claw_presentation_preset.dart';
import '../../core/models/cross_cutting_learning_evidence.dart';
import '../../core/models/education_model_execution.dart';
import '../../core/models/education_model_routing.dart';
import '../../widgets/claw_experience_renderer.dart';
import '../../widgets/cross_cutting_reasoning_card.dart';
import 'claw_foundations_story_arc.dart';

class ClawFoundationsSocraticAuditMetadata extends ClawSocraticAuditMetadata {
  final String usageReceiptId;
  final String providerId;
  final String modelArtifactDigest;
  final String promptContractVersion;
  final String curriculumPackDigest;
  final Set<String> sourceExpectationIds;
  final String verifierState;

  const ClawFoundationsSocraticAuditMetadata({
    required this.usageReceiptId,
    required this.providerId,
    required this.modelArtifactDigest,
    required this.promptContractVersion,
    required this.curriculumPackDigest,
    required this.sourceExpectationIds,
    required this.verifierState,
  });

  bool get isComplete =>
      usageReceiptId.trim().isNotEmpty &&
      providerId.trim().isNotEmpty &&
      modelArtifactDigest.trim().isNotEmpty &&
      promptContractVersion.trim().isNotEmpty &&
      curriculumPackDigest.trim().isNotEmpty &&
      sourceExpectationIds.isNotEmpty &&
      sourceExpectationIds.every((id) => id.trim().isNotEmpty) &&
      verifierState.trim().isNotEmpty;
}

class ClawFoundationsSocraticExecutionBinding {
  static const _allowedScopes = <EducationModelContextScope>{
    EducationModelContextScope.targetCompetency,
    EducationModelContextScope.currentLearnerInput,
  };

  final EducationModelExecutor executor;
  final EducationModelRouteRequest routeRequest;
  final EducationModelContextGrant contextGrant;
  final List<EducationModelCandidate> candidates;
  final EducationModelResponseProvenance provenance;
  final DateTime Function() now;

  ClawFoundationsSocraticExecutionBinding({
    required this.executor,
    required this.routeRequest,
    required this.contextGrant,
    required List<EducationModelCandidate> candidates,
    required this.provenance,
    DateTime Function()? now,
  }) : candidates = List<EducationModelCandidate>.unmodifiable(candidates),
       now = now ?? _currentUtc;

  static DateTime _currentUtc() => DateTime.now().toUtc();

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
    if (!provenance.sourceExpectationIds.contains(
      ClawFoundationsStoryArc.competencyId,
    )) {
      return const ClawSocraticResult.failure('invalid-socratic-provenance');
    }

    final invocationRequest = EducationModelRouteRequest(
      learnerSubjectId: routeRequest.learnerSubjectId,
      taskClass: routeRequest.taskClass,
      requiredCapabilities: routeRequest.requiredCapabilities,
      requestedContextScopes: routeRequest.requestedContextScopes,
      retentionClass: routeRequest.retentionClass,
      requestedAt: now().toUtc(),
      budget: routeRequest.budget,
      localOnly: routeRequest.localOnly,
    );

    final execution = await executor.execute(
      request: invocationRequest,
      contextGrant: contextGrant,
      candidates: candidates,
      materializedContext: <EducationModelContextScope, String>{
        EducationModelContextScope.targetCompetency:
            ClawFoundationsStoryArc.competencyId,
        EducationModelContextScope.currentLearnerInput: learnerInput,
      },
      provenance: provenance,
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
    final receipt = execution.usageReceipt!;
    final auditMetadata = ClawFoundationsSocraticAuditMetadata(
      usageReceiptId: receipt.receiptId,
      providerId: receipt.providerId,
      modelArtifactDigest: receipt.modelArtifactDigest,
      promptContractVersion: receipt.promptContractVersion,
      curriculumPackDigest: receipt.curriculumPackDigest,
      sourceExpectationIds: receipt.sourceExpectationIds,
      verifierState: receipt.verifierState,
    );
    if (!auditMetadata.isComplete) {
      return const ClawSocraticResult.failure('incomplete-socratic-audit');
    }
    return ClawSocraticResult.success(output, auditMetadata: auditMetadata);
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
  final ValueChanged<ClawFoundationsSocraticAuditMetadata>?
  onSocraticAuditMetadata;

  const ClawFoundationsPreviewScreen({
    super.key,
    this.socraticBinding,
    this.onSocraticAuditMetadata,
  });

  @override
  State<ClawFoundationsPreviewScreen> createState() =>
      _ClawFoundationsPreviewScreenState();
}

class _ClawFoundationsPreviewScreenState
    extends State<ClawFoundationsPreviewScreen> {
  static const _resolver = ClawPresentationPresetResolver();

  ClawPresentationPreset _preset = ClawPresentationPreset.explorer;
  bool _showSocraticVerification = false;
  CrossCuttingVerifierMethod? _selectedSocraticVerifier;

  void _handleSocraticAuditMetadata(ClawSocraticAuditMetadata metadata) {
    if (metadata is! ClawFoundationsSocraticAuditMetadata ||
        !metadata.isComplete) {
      return;
    }
    setState(() {
      _showSocraticVerification = true;
      _selectedSocraticVerifier = null;
    });
    widget.onSocraticAuditMetadata?.call(metadata);
  }

  void _handleNodeChanged(String _) {
    if (!_showSocraticVerification && _selectedSocraticVerifier == null) {
      return;
    }
    setState(() {
      _showSocraticVerification = false;
      _selectedSocraticVerifier = null;
    });
  }

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
                      onSocraticAuditMetadata: _handleSocraticAuditMetadata,
                      onNodeChanged: _handleNodeChanged,
                      onEvidenceCandidate: (candidate) =>
                          _showEvidenceNotice(context, candidate),
                    ),
                    if (_showSocraticVerification) ...<Widget>[
                      const SizedBox(height: 16),
                      _SocraticVerificationCard(
                        selected: _selectedSocraticVerifier,
                        onSelected: (method) {
                          setState(() {
                            _selectedSocraticVerifier = method;
                          });
                        },
                      ),
                    ],
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

class _SocraticVerificationCard extends StatelessWidget {
  static const _methods = <CrossCuttingVerifierMethod>[
    CrossCuttingVerifierMethod.learnerReasoning,
    CrossCuttingVerifierMethod.deterministicCalculator,
    CrossCuttingVerifierMethod.educatorReview,
    CrossCuttingVerifierMethod.modelAssistedCritique,
  ];

  final CrossCuttingVerifierMethod? selected;
  final ValueChanged<CrossCuttingVerifierMethod> onSelected;

  const _SocraticVerificationCard({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('claw-socratic-verification'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const CrossCuttingReasoningCard(
          learnerFacingPrompt:
              'Before accepting it, how could you check the fraction claim?',
          dimensionLabel: 'Verification',
          competencyLabel: 'method selection',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final method in _methods)
              ChoiceChip(
                key: ValueKey('claw-socratic-verifier-${_keySuffix(method)}'),
                label: Text(_label(method)),
                selected: selected == method,
                onSelected: (_) => onSelected(method),
              ),
          ],
        ),
        if (selected != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            _status(selected!),
            key: const ValueKey('claw-socratic-verification-status'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  static String _keySuffix(CrossCuttingVerifierMethod method) {
    return switch (method) {
      CrossCuttingVerifierMethod.learnerReasoning => 'learner-reasoning',
      CrossCuttingVerifierMethod.deterministicCalculator =>
        'deterministic-calculator',
      CrossCuttingVerifierMethod.educatorReview => 'educator-review',
      CrossCuttingVerifierMethod.modelAssistedCritique =>
        'model-assisted-critique',
      _ => throw StateError('Unsupported Claw Socratic verifier method.'),
    };
  }

  static String _label(CrossCuttingVerifierMethod method) {
    return switch (method) {
      CrossCuttingVerifierMethod.learnerReasoning => 'Check the reasoning',
      CrossCuttingVerifierMethod.deterministicCalculator =>
        'Deterministic calculation',
      CrossCuttingVerifierMethod.educatorReview => 'Educator review',
      CrossCuttingVerifierMethod.modelAssistedCritique =>
        'Model critique (not verification)',
      _ => throw StateError('Unsupported Claw Socratic verifier method.'),
    };
  }

  static String _status(CrossCuttingVerifierMethod method) {
    if (method == CrossCuttingVerifierMethod.modelAssistedCritique) {
      return 'Model critique may suggest a check, but the model cannot verify its own claim or create learner-state authority.';
    }
    if (method == CrossCuttingVerifierMethod.deterministicCalculator) {
      return 'Selected: deterministic calculation. This choice is temporary and creates no evidence, mastery, or grade state.';
    }
    if (method == CrossCuttingVerifierMethod.educatorReview) {
      return 'Selected: educator review. This choice is temporary and creates no evidence, mastery, or grade state.';
    }
    return 'Selected: learner reasoning. This choice is temporary and creates no evidence, mastery, or grade state.';
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
