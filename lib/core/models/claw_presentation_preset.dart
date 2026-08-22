import 'claw_experience_presentation.dart';

enum ClawPresentationPreset { sprout, scout, explorer, analyst, scholar }

extension ClawPresentationPresetMetadata on ClawPresentationPreset {
  String get wireName => switch (this) {
    ClawPresentationPreset.sprout => 'sprout',
    ClawPresentationPreset.scout => 'scout',
    ClawPresentationPreset.explorer => 'explorer',
    ClawPresentationPreset.analyst => 'analyst',
    ClawPresentationPreset.scholar => 'scholar',
  };

  String get label => switch (this) {
    ClawPresentationPreset.sprout => 'Sprout',
    ClawPresentationPreset.scout => 'Scout',
    ClawPresentationPreset.explorer => 'Explorer',
    ClawPresentationPreset.analyst => 'Analyst',
    ClawPresentationPreset.scholar => 'Scholar',
  };

  String get supportSummary => switch (this) {
    ClawPresentationPreset.sprout =>
      'Light reading load, short prompts, and strong scaffolding.',
    ClawPresentationPreset.scout =>
      'Short sentences with explicit cause-and-effect support.',
    ClawPresentationPreset.explorer =>
      'Balanced story, explanation, and independent response.',
    ClawPresentationPreset.analyst =>
      'Denser reasoning with causes, invariants, and multiple steps.',
    ClawPresentationPreset.scholar =>
      'Explicit concepts, metacognitive language, and formal terms.',
  };

  bool get infersAgeOrAbility => false;

  bool get changesCompetencyTarget => false;

  bool get createsMasteryOrGrade => false;

  bool get requiresPayment => false;
}

class ClawPresentationVariant {
  final String? eyebrow;
  final String? title;
  final String? body;
  final String? supportingText;
  final List<String>? bullets;
  final String? continueLabel;

  const ClawPresentationVariant({
    this.eyebrow,
    this.title,
    this.body,
    this.supportingText,
    this.bullets,
    this.continueLabel,
  });

  ClawExperiencePresentation applyTo(ClawExperiencePresentation base) {
    return ClawExperiencePresentation(
      nodeId: base.nodeId,
      title: title ?? base.title,
      body: body ?? base.body,
      eyebrow: eyebrow ?? base.eyebrow,
      supportingText: supportingText ?? base.supportingText,
      bullets: bullets ?? base.bullets,
      choices: base.choices,
      continueLabel: continueLabel ?? base.continueLabel,
    );
  }
}

class ClawPresentationPresetResolver {
  const ClawPresentationPresetResolver();

  Map<String, ClawExperiencePresentation> resolve({
    required Map<String, ClawExperiencePresentation> basePresentations,
    required Map<String, Map<ClawPresentationPreset, ClawPresentationVariant>>
    variants,
    required ClawPresentationPreset preset,
  }) {
    return <String, ClawExperiencePresentation>{
      for (final entry in basePresentations.entries)
        entry.key:
            variants[entry.key]?[preset]?.applyTo(entry.value) ?? entry.value,
    };
  }
}
