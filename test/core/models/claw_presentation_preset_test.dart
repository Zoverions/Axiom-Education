import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/claw_experience_presentation.dart';
import 'package:ontarioedai/core/models/claw_presentation_preset.dart';

void main() {
  group('presentation preset authority boundary', () {
    for (final preset in ClawPresentationPreset.values) {
      test('${preset.name} is presentation-only', () {
        expect(preset.infersAgeOrAbility, isFalse);
        expect(preset.changesCompetencyTarget, isFalse);
        expect(preset.createsMasteryOrGrade, isFalse);
        expect(preset.requiresPayment, isFalse);
      });
    }
  });

  test('variant changes language while preserving node and evidence choices', () {
    const base = ClawExperiencePresentation(
      nodeId: 'checkpoint',
      title: 'Base title',
      body: 'Base body',
      choices: <ClawExperienceChoicePresentation>[
        ClawExperienceChoicePresentation(
          choiceId: 'correct',
          label: 'A',
          evidenceRoute: ClawLocalEvidenceRoute.satisfied,
        ),
        ClawExperienceChoicePresentation(
          choiceId: 'retry',
          label: 'B',
          evidenceRoute: ClawLocalEvidenceRoute.insufficient,
        ),
      ],
    );

    const resolver = ClawPresentationPresetResolver();
    final resolved = resolver.resolve(
      basePresentations: const <String, ClawExperiencePresentation>{
        'checkpoint': base,
      },
      variants: const <
        String,
        Map<ClawPresentationPreset, ClawPresentationVariant>
      >{
        'checkpoint': <ClawPresentationPreset, ClawPresentationVariant>{
          ClawPresentationPreset.sprout: ClawPresentationVariant(
            title: 'Short title',
            body: 'Short body',
          ),
        },
      },
      preset: ClawPresentationPreset.sprout,
    );

    final value = resolved['checkpoint']!;
    expect(value.nodeId, base.nodeId);
    expect(value.title, 'Short title');
    expect(value.body, 'Short body');
    expect(
      value.choices.map((choice) => choice.choiceId),
      base.choices.map((choice) => choice.choiceId),
    );
    expect(
      value.choices.map((choice) => choice.evidenceRoute),
      base.choices.map((choice) => choice.evidenceRoute),
    );
  });

  test('missing preset variant falls back to the reviewed base presentation', () {
    const base = ClawExperiencePresentation(
      nodeId: 'arrival',
      title: 'Reviewed base',
      body: 'Reviewed body',
    );

    const resolver = ClawPresentationPresetResolver();
    final resolved = resolver.resolve(
      basePresentations: const <String, ClawExperiencePresentation>{
        'arrival': base,
      },
      variants: const <
        String,
        Map<ClawPresentationPreset, ClawPresentationVariant>
      >{},
      preset: ClawPresentationPreset.scholar,
    );

    expect(resolved['arrival']!.title, 'Reviewed base');
    expect(resolved['arrival']!.body, 'Reviewed body');
  });
}
