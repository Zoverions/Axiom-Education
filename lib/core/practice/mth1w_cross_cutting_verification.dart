import '../models/cross_cutting_competency_hook.dart';
import '../models/cross_cutting_learning_evidence.dart';

enum Mth1wVerificationChoice { exactCalculation, estimateOnly, modelOpinion }

class Mth1wVerificationChoicePolicy {
  const Mth1wVerificationChoicePolicy();

  bool isSufficient(Mth1wVerificationChoice choice) =>
      choice == Mth1wVerificationChoice.exactCalculation;

  String explanation(Mth1wVerificationChoice choice) {
    return switch (choice) {
      Mth1wVerificationChoice.exactCalculation =>
        'Exact calculation can check an exact-answer item with the deterministic calculator.',
      Mth1wVerificationChoice.estimateOnly =>
        'An estimate can be useful for a reasonableness check, but it cannot establish an exact answer.',
      Mth1wVerificationChoice.modelOpinion =>
        'A model opinion is instructional input, not an authoritative verifier for an exact answer.',
    };
  }
}

const mth1wVerificationMethodSelectionCompetencyId =
    'axiom:computational-literacy:verification:method-selection';

final CrossCuttingCompetencyHook mth1wVerificationMethodSelectionHook =
    CrossCuttingCompetencyHook(
      competencyId: mth1wVerificationMethodSelectionCompetencyId,
      role: CrossCuttingActivityRole.elicitEvidence,
      learnerFacingPrompt: 'How should we check an exact answer here?',
      aiMode: CrossCuttingAiMode.absent,
      verifierMethods: const {
        CrossCuttingVerifierMethod.deterministicCalculator,
      },
      hasNonGenerativePath: true,
    );
