import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/authored_competency_pack.dart';
import 'package:ontarioedai/core/models/cross_cutting_competency_hook.dart';
import 'package:ontarioedai/core/models/cross_cutting_learning_evidence.dart';

void main() {
  AuthoredCompetencyPack pack() {
    final decoded = jsonDecode(
      File(AuthoredCompetencyPack.aiNativeAssetPath).readAsStringSync(),
    );
    return AuthoredCompetencyPack.fromJson(
      Map<String, Object?>.from(decoded as Map),
    );
  }

  const competencyId =
      'axiom:computational-literacy:verification:method-selection';
  const validator = CrossCuttingCompetencyHookValidator();

  CrossCuttingCompetencyHook hook({
    String id = competencyId,
    CrossCuttingActivityRole role = CrossCuttingActivityRole.elicitEvidence,
    String prompt = 'How could you check that this result must be correct?',
    CrossCuttingAiMode aiMode = CrossCuttingAiMode.absent,
    Set<CrossCuttingVerifierMethod> verifierMethods = const {
      CrossCuttingVerifierMethod.deterministicCalculator,
    },
    bool hasNonGenerativePath = true,
  }) => CrossCuttingCompetencyHook(
    competencyId: id,
    role: role,
    learnerFacingPrompt: prompt,
    aiMode: aiMode,
    verifierMethods: verifierMethods,
    hasNonGenerativePath: hasNonGenerativePath,
  );

  test('valid evidence hook is metadata only and preserves non-generative path', () {
    final value = hook();

    expect(() => validator.validate(hook: value, pack: pack()), returnsNormally);
    expect(value.createsOfficialCurriculumCoverage, isFalse);
    expect(value.createsLearnerEvidence, isFalse);
    expect(value.createsAuthority, isFalse);
    expect(value.persistsLearnerState, isFalse);
  });

  test('introduce hook may omit verifier methods', () {
    final value = hook(
      role: CrossCuttingActivityRole.introduce,
      verifierMethods: const <CrossCuttingVerifierMethod>{},
    );

    expect(() => validator.validate(hook: value, pack: pack()), returnsNormally);
  });

  test('unknown competency fails closed', () {
    final value = hook(id: 'axiom:computational-literacy:verification:unknown');

    expect(
      () => validator.validate(hook: value, pack: pack()),
      throwsA(isA<CrossCuttingCompetencyHookException>()),
    );
  });

  test('blank learner-facing prompt fails closed', () {
    final value = hook(prompt: '   ');

    expect(
      () => validator.validate(hook: value, pack: pack()),
      throwsA(isA<CrossCuttingCompetencyHookException>()),
    );
  });

  test('evidence hook requires at least one verifier method', () {
    final value = hook(verifierMethods: const <CrossCuttingVerifierMethod>{});

    expect(
      () => validator.validate(hook: value, pack: pack()),
      throwsA(isA<CrossCuttingCompetencyHookException>()),
    );
  });

  test('evidence hook requires a non-generative demonstration path', () {
    final value = hook(hasNonGenerativePath: false);

    expect(
      () => validator.validate(hook: value, pack: pack()),
      throwsA(isA<CrossCuttingCompetencyHookException>()),
    );
  });

  test('AI as part of task does not waive the non-generative path', () {
    final value = hook(
      aiMode: CrossCuttingAiMode.partOfTask,
      verifierMethods: const {
        CrossCuttingVerifierMethod.modelAssistedCritique,
      },
      hasNonGenerativePath: false,
    );

    expect(
      () => validator.validate(hook: value, pack: pack()),
      throwsA(isA<CrossCuttingCompetencyHookException>()),
    );
  });
}
