import 'package:flutter/material.dart';

import '../core/models/education_institution.dart';

/// A reusable, non-authorizing guardian preference surface.
///
/// The widget expresses pacing/content-timing preferences only. It does not
/// establish guardianship, persist a policy directive, remove curriculum, or
/// bypass the content-readiness resolver.
class GuardianLearningPreferencePanel extends StatelessWidget {
  final String learningAreaLabel;
  final GuardianPacingPreference pacing;
  final GuardianContentTimingPreference contentTiming;
  final ValueChanged<GuardianPacingPreference> onPacingChanged;
  final ValueChanged<GuardianContentTimingPreference> onContentTimingChanged;

  const GuardianLearningPreferencePanel({
    super.key,
    required this.learningAreaLabel,
    required this.pacing,
    required this.contentTiming,
    required this.onPacingChanged,
    required this.onContentTimingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: 'Guardian learning preferences for $learningAreaLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            learningAreaLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share what you think will help this learner. These preferences guide sequencing when allowed; they do not directly remove required learning or override learner rights, safeguarding, school policy, or jurisdiction rules.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text('Pacing', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _PacingChoices(value: pacing, onChanged: onPacingChanged),
          const SizedBox(height: 18),
          Text('Content timing', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _TimingChoices(
            value: contentTiming,
            onChanged: onContentTimingChanged,
          ),
        ],
      ),
    );
  }
}

class _PacingChoices extends StatelessWidget {
  final GuardianPacingPreference value;
  final ValueChanged<GuardianPacingPreference> onChanged;

  const _PacingChoices({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _ChoiceChip<GuardianPacingPreference>(
          label: 'No preference',
          value: GuardianPacingPreference.noPreference,
          selected: value,
          onChanged: onChanged,
        ),
        _ChoiceChip<GuardianPacingPreference>(
          label: 'Slow down when allowed',
          value: GuardianPacingPreference.slowDownWhenAllowed,
          selected: value,
          onChanged: onChanged,
        ),
        _ChoiceChip<GuardianPacingPreference>(
          label: 'Keep current pace',
          value: GuardianPacingPreference.maintain,
          selected: value,
          onChanged: onChanged,
        ),
        _ChoiceChip<GuardianPacingPreference>(
          label: 'Accelerate when ready',
          value: GuardianPacingPreference.accelerateWhenReady,
          selected: value,
          onChanged: onChanged,
        ),
        _ChoiceChip<GuardianPacingPreference>(
          label: 'Prioritize this area',
          value: GuardianPacingPreference.prioritize,
          selected: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TimingChoices extends StatelessWidget {
  final GuardianContentTimingPreference value;
  final ValueChanged<GuardianContentTimingPreference> onChanged;

  const _TimingChoices({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _ChoiceChip<GuardianContentTimingPreference>(
          label: 'No preference',
          value: GuardianContentTimingPreference.noPreference,
          selected: value,
          onChanged: onChanged,
        ),
        _ChoiceChip<GuardianContentTimingPreference>(
          label: 'Defer when allowed',
          value: GuardianContentTimingPreference.deferWhenAllowed,
          selected: value,
          onChanged: onChanged,
        ),
        _ChoiceChip<GuardianContentTimingPreference>(
          label: 'Prioritize when relevant',
          value: GuardianContentTimingPreference.prioritizeWhenRelevant,
          selected: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ChoiceChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final T selected;
  final ValueChanged<T> onChanged;

  const _ChoiceChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onChanged(value),
    );
  }
}
