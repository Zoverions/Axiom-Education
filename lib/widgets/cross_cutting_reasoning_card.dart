import 'package:flutter/material.dart';

/// Learner-facing context for one cross-cutting reasoning competency.
///
/// The contextual prompt is always visible. Canonical competency terminology is
/// available on demand so the learning experience does not require jargon to be
/// useful. This widget is presentation-only: it performs no scoring, evidence
/// creation, model invocation, curriculum claim, or persistence.
class CrossCuttingReasoningCard extends StatelessWidget {
  const CrossCuttingReasoningCard({
    super.key,
    required this.learnerFacingPrompt,
    required this.dimensionLabel,
    required this.competencyLabel,
  });

  final String learnerFacingPrompt;
  final String dimensionLabel;
  final String competencyLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                learnerFacingPrompt,
                key: const ValueKey('cross-cutting-reasoning-prompt'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ExpansionTile(
              key: const ValueKey('cross-cutting-reasoning-details'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: const Text('Reasoning details'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$dimensionLabel → $competencyLabel',
                    key: const ValueKey('cross-cutting-reasoning-canonical-label'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
