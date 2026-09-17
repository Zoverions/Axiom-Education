import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/cross_cutting_competency_hook.dart';
import 'package:ontarioedai/core/models/cross_cutting_learning_evidence.dart';
import 'package:ontarioedai/core/practice/mth1w_cross_cutting_verification.dart';

void main() {
  test(
    'only exact calculation is sufficient for exact-answer verification',
    () {
      const policy = Mth1wVerificationChoicePolicy();

      expect(
        policy.isSufficient(Mth1wVerificationChoice.exactCalculation),
        isTrue,
      );
      expect(
        policy.isSufficient(Mth1wVerificationChoice.estimateOnly),
        isFalse,
      );
      expect(
        policy.isSufficient(Mth1wVerificationChoice.modelOpinion),
        isFalse,
      );
    },
  );

  test('insufficient methods explain why they do not establish exactness', () {
    const policy = Mth1wVerificationChoicePolicy();

    expect(
      policy.explanation(Mth1wVerificationChoice.estimateOnly),
      contains('cannot establish an exact answer'),
    );
    expect(
      policy.explanation(Mth1wVerificationChoice.modelOpinion),
      contains('not an authoritative verifier'),
    );
  });

  test('MTH1W hook is non-generative deterministic evidence elicitation', () {
    final hook = mth1wVerificationMethodSelectionHook;

    expect(
      hook.competencyId,
      'axiom:computational-literacy:verification:method-selection',
    );
    expect(hook.role, CrossCuttingActivityRole.elicitEvidence);
    expect(hook.aiMode, CrossCuttingAiMode.absent);
    expect(hook.verifierMethods, {
      CrossCuttingVerifierMethod.deterministicCalculator,
    });
    expect(hook.hasNonGenerativePath, isTrue);
    expect(hook.createsLearnerEvidence, isFalse);
    expect(hook.persistsLearnerState, isFalse);
    expect(hook.createsAuthority, isFalse);
  });
}
