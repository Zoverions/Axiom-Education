import 'package:flutter/material.dart';

import '../../core/models/claw_experience_presentation.dart';
import '../../widgets/claw_experience_renderer.dart';
import 'claw_foundations_story_arc.dart';

class ClawFoundationsPreviewScreen extends StatelessWidget {
  const ClawFoundationsPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    ClawExperiencePlayer(
                      key: const ValueKey('claw-foundations-player'),
                      graph: ClawFoundationsStoryArc.graph,
                      presentations: ClawFoundationsStoryArc.presentations,
                      availability: ClawFoundationsStoryArc.availability,
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
