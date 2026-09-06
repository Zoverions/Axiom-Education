# AI-Native Computational Literacy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the approved cross-cutting Intent → Specification → Verification → Systems Understanding competency family, prove it in one deterministic MTH1W path and one AI-optional Claw path, and expose it without creating a second mastery, grading, persistence, or authority system.

**Architecture:** Keep the current `CompetencyGraph`, `LearningEvidenceEnvelope`, deterministic MTH1W verifier, and governed Socratic Tutor boundaries authoritative. Add one versioned authored competency pack plus pure companion metadata/hook models, then layer contextual learner UI over existing subject experiences; no new Mesh capability or learner-record route is introduced.

**Tech Stack:** Dart 3.11.x, Flutter 3.41.1, Flutter/Riverpod, bundled JSON assets, existing Axiom Education competency/evidence models, existing deterministic MTH1W verifier, existing governed Socratic Tutor branch/PR #177, Python 3.12 repository verification, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-05-ai-native-computational-literacy-design.md`

## Global Constraints

- Canonical pack schema: `axiom-education-authored-competency-pack.v1`.
- Canonical family ID: `axiom.education.competency.ai-native-computational-literacy`.
- Canonical family version: `1.0.0`.
- Authorship: `axiom-extension`; jurisdictional authority: `none`.
- Exactly 18 v1 competency nodes; v1 contains no prerequisite/support edges.
- Existing competency states `unknown`, `attempted`, `emerging`, `demonstrated` remain primary and revisable.
- Do not create an aggregate AI-literacy score, psychometric claim, grade, credit, transcript state, credential, curriculum status, or institutional eligibility.
- Every core competency must retain a non-generative learning and evidence path.
- Model output remains instructional data, never authority; it cannot promote a competency to consequential `demonstrated` state by itself.
- Cross-cutting evidence remains independent from subject correctness and subject grade/credit state.
- `CrossCuttingEvidenceMetadata` is in-memory only in v0: no persistence, export, new Gateway action, new Grid record kind, or Mesh capability.
- Raw prompts, raw model output, essays, code, conversations, clickstream, prompt counts, timing, retry counts, typing behavior, engagement, and model-use frequency are not stored in cross-cutting metadata.
- Existing `LearningEvidenceEnvelope` correction/retraction semantics remain unchanged.
- Public capability status is `experimental` until executable evidence and claim parity exist.
- Toolchain stays pinned to Flutter `3.41.1`, Dart `3.11.x`, Python `3.12`, and the repository lockfiles.
- Phase C must not recreate or cherry-pick the governed tutor implementation. It starts only from the exact merged successor of PR #177, or from PR #177 head while explicitly stacked on it.

---

## File Structure

### New files

- `assets/competencies/ai_native_computational_literacy.v1.json` — canonical authored pack data; exactly 18 nodes, no edges.
- `lib/core/models/authored_competency_pack.dart` — pure parser/validator and conversion to existing `CompetencyGraph`.
- `lib/core/services/authored_competency_pack_loader.dart` — bounded `AssetBundle` I/O only; no education authority logic.
- `lib/core/models/cross_cutting_learning_evidence.dart` — evidence-quality/verifier/AI-role vocabulary, metadata, in-memory wrapper, validator.
- `lib/core/models/cross_cutting_competency_hook.dart` — activity-hook vocabulary and validation against the loaded authored pack.
- `lib/widgets/cross_cutting_reasoning_card.dart` — reusable contextual learner-facing prompt with expandable canonical detail.
- `lib/core/practice/mth1w_cross_cutting_verification.dart` — the deterministic MTH1W hook and bounded verification-method-choice model.
- `test/core/models/authored_competency_pack_test.dart` — pack parsing and fail-closed mutation tests.
- `test/core/services/authored_competency_pack_loader_test.dart` — bundled-asset loading test.
- `test/core/models/cross_cutting_learning_evidence_test.dart` — metadata/evidence authority and privacy tests.
- `test/core/models/cross_cutting_competency_hook_test.dart` — hook validation and non-generative-path tests.
- `test/widgets/cross_cutting_reasoning_card_test.dart` — hybrid-visibility/accessibility tests.
- `test/core/practice/mth1w_cross_cutting_verification_test.dart` — deterministic proof model tests.

### Existing files modified

- `pubspec.yaml` — register the competency asset.
- `lib/features/practice/mth1w_practice_screen.dart` — add the no-AI verification-method reasoning step without changing deterministic answer authority.
- `test/features/practice/mth1w_practice_screen_test.dart` — prove the contextual flow, no persistence, and verifier failure semantics.
- `lib/widgets/claw_experience_renderer.dart` — after PR #177, expose a post-response verification prompt without letting model output emit evidence.
- `lib/features/claw/claw_foundations_preview_screen.dart` — provide the cross-cutting hook/detail and preserve non-model fallback.
- `test/widgets/claw_experience_renderer_test.dart` — prove AI output remains instructional and verification reasoning remains available.
- `test/features/claw/claw_foundations_preview_screen_test.dart` — prove optional-AI and no-provider paths.
- `config/capabilities.json` — add `instruction.cross-cutting-computational-literacy` as `experimental` only after both proof slices exist.
- `README.md` — describe the feature and explicit non-claims without calling it official curriculum or validated assessment.
- `CHANGELOG.md` — record the experimental cross-cutting competency foundation.

---

### Task 1: Canonical authored competency pack and loader

**Files:**
- Create: `assets/competencies/ai_native_computational_literacy.v1.json`
- Create: `lib/core/models/authored_competency_pack.dart`
- Create: `lib/core/services/authored_competency_pack_loader.dart`
- Create: `test/core/models/authored_competency_pack_test.dart`
- Create: `test/core/services/authored_competency_pack_loader_test.dart`
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: existing `CompetencyNode`, `CompetencyEdge`, and `CompetencyGraph` from `lib/core/models/competency_graph.dart`.
- Produces: `AuthoredCompetencyPack.fromJson(Map<String, Object?>)`, `AuthoredCompetencyPack.toGraph()`, `AuthoredCompetencyPack.containsCompetency(String)`, and `AuthoredCompetencyPackLoader.load(AssetBundle)`.
- Constants: `AuthoredCompetencyPack.aiNativeFamilyId == 'axiom.education.competency.ai-native-computational-literacy'` and `AuthoredCompetencyPack.aiNativeAssetPath == 'assets/competencies/ai_native_computational_literacy.v1.json'`.

- [ ] **Step 1: Write the RED pack tests.**

Create `test/core/models/authored_competency_pack_test.dart` with tests that assert the exact schema/family/version/authorship/authority, exactly 18 unique nodes, all three required tags, one valid dimension tag per node, zero edges, and conversion to the existing graph.

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/authored_competency_pack.dart';

void main() {
  Map<String, Object?> fixture() =>
      jsonDecode(File(AuthoredCompetencyPack.aiNativeAssetPath).readAsStringSync())
          as Map<String, Object?>;

  test('canonical pack contains exactly 18 Axiom-authored nodes and no edges', () {
    final pack = AuthoredCompetencyPack.fromJson(fixture());

    expect(pack.schema, 'axiom-education-authored-competency-pack.v1');
    expect(pack.familyId, AuthoredCompetencyPack.aiNativeFamilyId);
    expect(pack.familyVersion, '1.0.0');
    expect(pack.authorship, 'axiom-extension');
    expect(pack.jurisdictionalAuthority, 'none');
    expect(pack.graph.nodes, hasLength(18));
    expect(pack.graph.edges, isEmpty);
  });
}
```

Add mutation tests by cloning the decoded map and changing one field at a time. They must reject: unsupported schema/version, duplicate node ID, malformed non-`axiom:computational-literacy:` ID, missing/wrong family tag, zero or two dimension tags, unknown dimension tag, missing authorship tag, and a future edge with a missing endpoint.

- [ ] **Step 2: Run the targeted test and verify RED.**

Run:

```bash
flutter test test/core/models/authored_competency_pack_test.dart --reporter expanded
```

Expected: compile failure because `authored_competency_pack.dart` and the asset do not exist.

- [ ] **Step 3: Add the canonical JSON asset.**

Use this top-level shape and all 18 durable IDs from the spec:

```json
{
  "schema": "axiom-education-authored-competency-pack.v1",
  "family_id": "axiom.education.competency.ai-native-computational-literacy",
  "family_version": "1.0.0",
  "name": "AI-Native Computational Literacy",
  "authorship": "axiom-extension",
  "jurisdictional_authority": "none",
  "nodes": [
    {
      "competency_id": "axiom:computational-literacy:intent:problem-framing",
      "title": "Frame the actual problem",
      "tags": [
        "family:ai-native-computational-literacy",
        "dimension:intent",
        "authorship:axiom-extension"
      ]
    }
  ],
  "edges": []
}
```

The full `nodes` array must contain the 4 Intent + 4 Specification + 5 Verification + 5 Systems Understanding IDs from the approved spec, with exactly one dimension tag and the same family/authorship tags on every node.

- [ ] **Step 4: Implement the minimal pure parser/validator.**

`lib/core/models/authored_competency_pack.dart` must expose a focused immutable type and throw `AuthoredCompetencyPackException` on malformed input before constructing `CompetencyGraph`.

```dart
class AuthoredCompetencyPack {
  static const aiNativeFamilyId =
      'axiom.education.competency.ai-native-computational-literacy';
  static const aiNativeAssetPath =
      'assets/competencies/ai_native_computational_literacy.v1.json';

  final String schema;
  final String familyId;
  final String familyVersion;
  final String name;
  final String authorship;
  final String jurisdictionalAuthority;
  final CompetencyGraph graph;

  factory AuthoredCompetencyPack.fromJson(Map<String, Object?> json) {
    // Parse only the v1 fields above; reject unknown schema/version semantics,
    // invalid tags/IDs, duplicate IDs, and malformed edge definitions.
  }

  bool containsCompetency(String id) => graph.nodes.containsKey(id);
  CompetencyGraph toGraph() => graph;
}
```

Do not add a second graph class. Delegate endpoint/self-edge/prerequisite-cycle checks to the existing `CompetencyGraph` after pack-specific validation.

- [ ] **Step 5: Register and load the asset through a narrow service.**

Add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/competencies/ai_native_computational_literacy.v1.json
```

Create `lib/core/services/authored_competency_pack_loader.dart`:

```dart
class AuthoredCompetencyPackLoader {
  const AuthoredCompetencyPackLoader();

  Future<AuthoredCompetencyPack> load(AssetBundle bundle) async {
    final raw = await bundle.loadString(AuthoredCompetencyPack.aiNativeAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const AuthoredCompetencyPackException('Pack root must be an object.');
    }
    return AuthoredCompetencyPack.fromJson(decoded);
  }
}
```

- [ ] **Step 6: Add the asset-loader test.**

Use `rootBundle` under `flutter_test` and assert the loaded pack has 18 nodes and zero edges.

- [ ] **Step 7: Run focused and regression tests.**

Run:

```bash
flutter test test/core/models/authored_competency_pack_test.dart test/core/services/authored_competency_pack_loader_test.dart test/core/models/competency_graph_test.dart --reporter expanded
```

Expected: PASS; existing competency graph semantics unchanged.

- [ ] **Step 8: Commit.**

```bash
git add assets/competencies/ai_native_computational_literacy.v1.json pubspec.yaml lib/core/models/authored_competency_pack.dart lib/core/services/authored_competency_pack_loader.dart test/core/models/authored_competency_pack_test.dart test/core/services/authored_competency_pack_loader_test.dart
git commit -m "feat: add AI-native competency pack"
```

---

### Task 2: Cross-cutting evidence companion and activity hooks

**Files:**
- Create: `lib/core/models/cross_cutting_learning_evidence.dart`
- Create: `lib/core/models/cross_cutting_competency_hook.dart`
- Create: `test/core/models/cross_cutting_learning_evidence_test.dart`
- Create: `test/core/models/cross_cutting_competency_hook_test.dart`
- Regression: `test/core/models/learning_evidence_test.dart`

**Interfaces:**
- Consumes: `LearningEvidenceEnvelope` and `AuthoredCompetencyPack`.
- Produces: `CrossCuttingEvidenceQuality`, `CrossCuttingVerifierMethod`, `CrossCuttingAiRole`, `CrossCuttingEvidenceMetadata`, `CrossCuttingLearningEvidence`, `CrossCuttingActivityRole`, `CrossCuttingAiMode`, `CrossCuttingCompetencyHook`, `CrossCuttingEvidenceValidator`, and `CrossCuttingCompetencyHookValidator`.

- [ ] **Step 1: Write RED evidence tests.**

Create tests proving metadata binds to the exact base `evidenceId`, contains only the approved vocabularies, exposes no mastery/grade/persistence authority, and preserves the base envelope as the only learner evidence object.

```dart
final base = LearningEvidenceEnvelope(
  evidenceId: 'evidence:verification:1',
  recordType: LearningEvidenceRecordType.outcomeObservation,
  learnerSubjectId: 'learner:1',
  competencyId: 'axiom:computational-literacy:verification:method-selection',
  consentContextId: 'consent:pedagogy:1',
  occurredAt: DateTime.utc(2026, 9, 5),
  confidenceBefore: 0.4,
  confidenceAfter: 0.6,
  evidenceRef: 'artifact:math-check:1',
);

final metadata = CrossCuttingEvidenceMetadata(
  evidenceId: base.evidenceId,
  qualities: const {CrossCuttingEvidenceQuality.independentApplication},
  verifierMethods: const {CrossCuttingVerifierMethod.deterministicCalculator},
  aiRole: CrossCuttingAiRole.absent,
  observationSource: 'mth1w-deterministic-practice',
);

final aggregate = CrossCuttingLearningEvidence(base: base, metadata: metadata);
expect(aggregate.canPersistCrossCuttingMetadata, isFalse);
expect(aggregate.createsMasteryState, isFalse);
expect(aggregate.changesSubjectGrade, isFalse);
```

Add negative tests for mismatched `evidenceId`, blank `observationSource`, empty qualities, empty verifier methods for an evidence observation, and any attempt to treat companion metadata as an admitted Mesh event.

- [ ] **Step 2: Run and verify RED.**

```bash
flutter test test/core/models/cross_cutting_learning_evidence_test.dart --reporter expanded
```

Expected: compile failure because the types do not exist.

- [ ] **Step 3: Implement the exact v1 enums and in-memory wrapper.**

```dart
enum CrossCuttingEvidenceQuality {
  recognized,
  supportedApplication,
  independentApplication,
  robustApplication,
  transferObserved,
}

enum CrossCuttingVerifierMethod {
  learnerReasoning,
  deterministicCalculator,
  symbolicSolver,
  compilerOrTestRunner,
  experimentOrMeasurement,
  sourceOrProvenanceReview,
  educatorReview,
  peerReview,
  modelAssistedCritique,
  otherGovernedTool,
}

enum CrossCuttingAiRole {
  absent,
  optionalTool,
  generatedCandidate,
  critiqueAssistant,
  socraticTutor,
}
```

`CrossCuttingEvidenceMetadata` must have only `evidenceId`, `qualities`, `verifierMethods`, `aiRole`, and `observationSource`. `CrossCuttingLearningEvidence` must hold one existing `LearningEvidenceEnvelope` plus one matching metadata object. It must expose fixed `false` getters for persistence/export/mastery/grade authority rather than introducing any write path.

- [ ] **Step 4: Write RED hook tests.**

Tests must prove: unknown competency fails; blank prompt fails; `introduce` may have no verifier; `elicitEvidence` requires at least one verifier; every `elicitEvidence` hook requires `hasNonGenerativePath == true`; `aiMode == partOfTask` does not bypass that rule; hook construction does not create evidence/curriculum authority.

- [ ] **Step 5: Implement the pure hook types and validator.**

```dart
enum CrossCuttingActivityRole { introduce, practice, elicitEvidence }
enum CrossCuttingAiMode { absent, optional, partOfTask }

class CrossCuttingCompetencyHook {
  final String competencyId;
  final CrossCuttingActivityRole role;
  final String learnerFacingPrompt;
  final CrossCuttingAiMode aiMode;
  final Set<CrossCuttingVerifierMethod> verifierMethods;
  final bool hasNonGenerativePath;
  // immutable constructor only
}
```

`CrossCuttingCompetencyHookValidator.validate(hook, pack)` must fail closed using `pack.containsCompetency(...)` and the exact rules above. It must not import curriculum-provider, learner-record, Gateway, or persistence code.

- [ ] **Step 6: Run focused and existing evidence tests.**

```bash
flutter test test/core/models/cross_cutting_learning_evidence_test.dart test/core/models/cross_cutting_competency_hook_test.dart test/core/models/learning_evidence_test.dart --reporter expanded
```

Expected: PASS; `LearningEvidenceEnvelope` remains byte-for-source unchanged unless a compile-only import adjustment is strictly required (prefer no modification).

- [ ] **Step 7: Commit.**

```bash
git add lib/core/models/cross_cutting_learning_evidence.dart lib/core/models/cross_cutting_competency_hook.dart test/core/models/cross_cutting_learning_evidence_test.dart test/core/models/cross_cutting_competency_hook_test.dart
git commit -m "feat: add cross-cutting evidence metadata"
```

---

### Task 3: Reusable hybrid-visibility reasoning card

**Files:**
- Create: `lib/widgets/cross_cutting_reasoning_card.dart`
- Create: `test/widgets/cross_cutting_reasoning_card_test.dart`

**Interfaces:**
- Consumes: a validated `CrossCuttingCompetencyHook` plus explicit human-readable canonical `dimensionLabel` and `competencyLabel`; it does not load curriculum or evidence itself.
- Produces: `CrossCuttingReasoningCard` with contextual prompt always visible and canonical detail behind an `ExpansionTile`.

- [ ] **Step 1: Write the RED widget test.**

```dart
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: CrossCuttingReasoningCard(
        learnerFacingPrompt: 'How could you check that this result must be correct?',
        dimensionLabel: 'Verification',
        competencyLabel: 'method selection',
      ),
    ),
  ),
);

expect(find.text('How could you check that this result must be correct?'), findsOneWidget);
expect(find.text('Reasoning details'), findsOneWidget);
expect(find.textContaining('Verification → method selection'), findsNothing);
```

Then tap `Reasoning details` and require the canonical label to appear. Add a semantics test that the contextual prompt remains readable at text scale and the expanded detail is not the only accessible label.

- [ ] **Step 2: Run and verify RED.**

```bash
flutter test test/widgets/cross_cutting_reasoning_card_test.dart --reporter expanded
```

- [ ] **Step 3: Implement the minimal presentation widget.**

The widget must contain no scoring, model, provider, evidence, curriculum, or persistence code. It should follow the existing cards/`ExpansionTile` pattern already used by MTH1W practice.

- [ ] **Step 4: Run the widget test and formatter.**

```bash
flutter test test/widgets/cross_cutting_reasoning_card_test.dart --reporter expanded
dart format --output=none --set-exit-if-changed lib/widgets/cross_cutting_reasoning_card.dart test/widgets/cross_cutting_reasoning_card_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib/widgets/cross_cutting_reasoning_card.dart test/widgets/cross_cutting_reasoning_card_test.dart
git commit -m "feat: add contextual reasoning card"
```

---

### Task 4: Deterministic MTH1W no-AI proof

**Files:**
- Create: `lib/core/practice/mth1w_cross_cutting_verification.dart`
- Create: `test/core/practice/mth1w_cross_cutting_verification_test.dart`
- Modify: `lib/features/practice/mth1w_practice_screen.dart`
- Modify: `test/features/practice/mth1w_practice_screen_test.dart`

**Interfaces:**
- Consumes: `CrossCuttingCompetencyHook`, `CrossCuttingVerifierMethod`, `MathAnswerVerifier`, and `CrossCuttingReasoningCard`.
- Produces: `mth1wVerificationMethodHook`, `Mth1wVerificationChoice`, and `Mth1wVerificationChoicePolicy`.
- Canonical competency: `axiom:computational-literacy:verification:method-selection`.
- The existing `MathAnswerVerifier.verify(...)` remains the sole authority for correct/incorrect answers.

- [ ] **Step 1: Write RED pure-model tests for method selection.**

Define three learner choices:

```dart
enum Mth1wVerificationChoice { exactCalculation, estimateOnly, modelOpinion }
```

The policy must map only `exactCalculation` to `CrossCuttingVerifierMethod.deterministicCalculator` as sufficient for the exact-answer check. `estimateOnly` and `modelOpinion` remain educational alternatives but must never mark the math answer verified.

```dart
expect(
  const Mth1wVerificationChoicePolicy()
      .isSufficient(Mth1wVerificationChoice.exactCalculation),
  isTrue,
);
expect(
  const Mth1wVerificationChoicePolicy()
      .isSufficient(Mth1wVerificationChoice.modelOpinion),
  isFalse,
);
```

The exported hook must be `role: elicitEvidence`, `aiMode: absent`, verifier methods `{deterministicCalculator}`, and `hasNonGenerativePath: true`.

- [ ] **Step 2: Run and verify RED.**

```bash
flutter test test/core/practice/mth1w_cross_cutting_verification_test.dart --reporter expanded
```

- [ ] **Step 3: Implement the pure MTH1W verification-choice model.**

Keep it separate from `MathAnswerVerifier`; it teaches verifier selection but does not alter answer checking.

- [ ] **Step 4: Add RED widget assertions to the existing practice-screen test.**

Before the existing `Check answer` action can run, require the learner to answer the contextual question:

> How should we check an exact answer here?

Expose three `ChoiceChip` or radio choices with stable keys:

- `mth1w-verifier-exact`
- `mth1w-verifier-estimate`
- `mth1w-verifier-model`

The test must prove:

1. `Check answer` is disabled until the answer is nonblank **and** `exactCalculation` is selected.
2. Choosing `estimateOnly` shows a short explanation that estimation is useful but insufficient for an exact result.
3. Choosing `modelOpinion` shows that model output is not an exact verifier.
4. Choosing `exactCalculation` enables the existing deterministic check.
5. Correct/incorrect result comes only from `MathAnswerVerifier`.
6. Existing session summary still says nothing is saved to a learner record.
7. The reasoning-card detail exposes `Verification → method selection` only when expanded.
8. `verifier == null` still fails closed and does not treat the learner's method choice as correctness evidence.

- [ ] **Step 5: Implement the minimal MTH1W UI change.**

Add ephemeral state:

```dart
Mth1wVerificationChoice? _verificationChoice;
```

Reset it in `_clearResponse()`. Change `canCheck` to require the exact-calculation choice in addition to the current verifier/answer checks. Render `CrossCuttingReasoningCard` plus the bounded choices immediately before the Check button. Do not create `LearningEvidenceEnvelope`, `CrossCuttingEvidenceMetadata`, or any persistence call in this proof.

- [ ] **Step 6: Run the deterministic proof tests and MTH1W regressions.**

```bash
flutter test test/core/practice/mth1w_cross_cutting_verification_test.dart test/features/practice/mth1w_practice_screen_test.dart test/core/practice/math_answer_verifier_test.dart test/core/practice/math_practice_generator_test.dart --reporter expanded
```

Expected: PASS. In particular, verifier-unavailable remains explicit and no AI dependency is introduced.

- [ ] **Step 7: Commit.**

```bash
git add lib/core/practice/mth1w_cross_cutting_verification.dart lib/features/practice/mth1w_practice_screen.dart test/core/practice/mth1w_cross_cutting_verification_test.dart test/features/practice/mth1w_practice_screen_test.dart
git commit -m "feat: teach verifier selection in MTH1W practice"
```

---

### Task 5: AI-optional Claw proof, stacked only after governed tutor readiness

**Dependency gate:** PR #177 (`Governed Socratic Tutor v0`) currently supplies `EducationModelExecutor`, the `aiSocraticDialogue` node, bounded 280-character learner input, minimized usage receipts, and deterministic fallback. Before this task, resolve one of these states:

1. **Preferred:** PR #177 has passed exact-head Linux/Android, Windows, and Apple checks and is merged; rebase the implementation branch onto that merged `main`.
2. **Stacked:** if #177 remains unmerged but exact-head green and deliberately stackable, rebase this work onto its exact head and make the new PR base/dependency explicit.

Do not copy its implementation into this feature branch.

**Files after the dependency gate:**
- Modify: `lib/widgets/claw_experience_renderer.dart`
- Modify: `lib/features/claw/claw_foundations_preview_screen.dart`
- Modify: `test/widgets/claw_experience_renderer_test.dart`
- Modify: `test/features/claw/claw_foundations_preview_screen_test.dart`

**Interfaces:**
- Consumes: PR #177 `ClawSocraticRequest`, `ClawSocraticResult`, `ClawFoundationsSocraticExecutionBinding`, model-unavailable fallback, and `CrossCuttingReasoningCard`.
- Produces: a post-response verification-method prompt bound to `axiom:computational-literacy:verification:method-selection` with `aiMode: optional`; no model response becomes evidence.

- [ ] **Step 1: Add RED renderer tests for AI output interrogation.**

Extend the existing successful Socratic test so that after instructional text appears, the learner also sees:

> Before accepting it, how could you check the fraction claim?

Require a stable `claw-socratic-verification` container and choices that include exact arithmetic (`deterministicCalculator`) and model opinion. Verify that the model's own response cannot count as its own verifier.

The test must keep the existing assertion:

```dart
expect(evidence, isEmpty);
```

before and after the verification-method interaction.

- [ ] **Step 2: Add RED no-provider/failure tests.**

When `socraticBinding == null`, the existing non-model Claw route must remain usable and the same canonical Verification competency must still have a non-generative path. When the handler fails and the player routes to the reviewed fallback, no cross-cutting evidence or mastery callback may be emitted automatically.

- [ ] **Step 3: Implement the minimal renderer state.**

Keep Socratic output as plain instructional text. Add an ephemeral `CrossCuttingVerifierMethod?` selection after successful model output. Reuse `CrossCuttingReasoningCard`; do not write the selection to learner storage. The generic renderer must still not import provider-routing internals.

- [ ] **Step 4: Bind the screen to the canonical hook without widening context.**

The screen may supply the validated hook/presentation metadata, but `ClawFoundationsSocraticExecutionBinding` must retain exactly the existing context scopes: `targetCompetency` and `currentLearnerInput`. Do not send the cross-cutting selection to the model in v0.

- [ ] **Step 5: Run Claw and tutor regressions.**

```bash
flutter test test/widgets/claw_experience_renderer_test.dart test/features/claw/claw_foundations_preview_screen_test.dart test/core/models/education_model_execution_test.dart test/core/models/education_model_routing_test.dart --reporter expanded
```

Expected: PASS; provider denial/failure retains deterministic fallback, model text emits no evidence, and no provider is activated by default.

- [ ] **Step 6: Commit.**

```bash
git add lib/widgets/claw_experience_renderer.dart lib/features/claw/claw_foundations_preview_screen.dart test/widgets/claw_experience_renderer_test.dart test/features/claw/claw_foundations_preview_screen_test.dart
git commit -m "feat: add verification reasoning to Socratic preview"
```

---

### Task 6: Capability claim parity, privacy/authority regression gate, and exact-head verification

**Files:**
- Modify: `config/capabilities.json`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `test/core/models/cross_cutting_learning_evidence_test.dart` only to add any final authority-regression assertions discovered during integration.
- Modify: `test/core/models/cross_cutting_competency_hook_test.dart` only to add final curriculum/non-generative-path regressions.

**Interfaces:**
- Produces public capability `instruction.cross-cutting-computational-literacy` with status `experimental` and exact evidence paths.
- Does not modify `contracts/axiom-education.v1.json`, AXIOM-MESH compatibility pins, learner-event actions, or credential contracts.

- [ ] **Step 1: Add the capability entry only after Tasks 1–5 are executable.**

Use wording no stronger than:

```json
{
  "id": "instruction.cross-cutting-computational-literacy",
  "family": "instruction",
  "status": "experimental",
  "summary": "A versioned Axiom-authored cross-cutting competency family now represents Intent, Specification, Verification, and Systems Understanding through 18 non-jurisdictional competency nodes. One deterministic MTH1W proof and one optional governed-Socratic proof expose contextual verification reasoning without creating a new mastery, grade, learner-record, persistence, or model-authority path.",
  "evidence": [
    "assets/competencies/ai_native_computational_literacy.v1.json",
    "lib/core/models/authored_competency_pack.dart",
    "lib/core/models/cross_cutting_learning_evidence.dart",
    "lib/core/models/cross_cutting_competency_hook.dart",
    "lib/core/practice/mth1w_cross_cutting_verification.dart",
    "lib/features/practice/mth1w_practice_screen.dart",
    "lib/widgets/cross_cutting_reasoning_card.dart",
    "test/core/models/authored_competency_pack_test.dart",
    "test/core/models/cross_cutting_learning_evidence_test.dart",
    "test/core/models/cross_cutting_competency_hook_test.dart",
    "test/features/practice/mth1w_practice_screen_test.dart",
    "test/widgets/claw_experience_renderer_test.dart"
  ]
}
```

Keep explicit non-claims in README/CHANGELOG: not official Ontario curriculum, not validated psychometrics, no AI-literacy score, no model required, no automatic mastery/grade effect.

- [ ] **Step 2: Run the 24 fail-closed acceptance checks as targeted tests.**

The focused suite must cover, at minimum:

1. duplicate competency IDs rejected;
2. malformed competency ID rejected;
3. missing family tag rejected;
4. wrong family tag rejected;
5. missing authorship tag rejected;
6. unknown dimension rejected;
7. multiple dimensions rejected;
8. unsupported pack schema/version rejected;
9. absent future-edge endpoint rejected;
10. prerequisite cycles still rejected by existing graph logic;
11. hook unknown competency rejected;
12. blank learner prompt rejected;
13. evidence hook without verifier rejected;
14. evidence hook without non-generative path rejected;
15. AI-part-of-task does not waive non-generative demonstration;
16. metadata/base `evidenceId` mismatch rejected;
17. raw prompt/model-response fields are impossible in metadata because the type has no such fields;
18. companion metadata exposes no persistence/export authority;
19. companion metadata does not calculate/promote competency state;
20. model output does not emit Claw evidence/mastery callbacks;
21. cross-cutting MTH1W selection does not determine math correctness;
22. missing deterministic verifier remains unavailable, not synthetic success;
23. AI/provider absence leaves a valid non-generative path;
24. official curriculum coverage is never inferred from an Axiom competency hook.

Run:

```bash
flutter test test/core/models/authored_competency_pack_test.dart test/core/models/cross_cutting_learning_evidence_test.dart test/core/models/cross_cutting_competency_hook_test.dart test/core/practice/mth1w_cross_cutting_verification_test.dart test/features/practice/mth1w_practice_screen_test.dart test/widgets/cross_cutting_reasoning_card_test.dart test/widgets/claw_experience_renderer_test.dart test/features/claw/claw_foundations_preview_screen_test.dart --reporter expanded
```

Expected: PASS.

- [ ] **Step 3: Run capability and canonical repository verification.**

```bash
python tools/check_capabilities.py
python tools/verify.py
```

Expected: `Axiom Education verification passed.` The canonical verifier also runs pinned dependency setup, complete Python tests, Dart formatting, Flutter analysis, and the complete Flutter test suite.

- [ ] **Step 4: Run exact-head platform CI.**

Push the exact implementation head and require the repository's existing Linux/Android, Windows, and Apple workflow matrix to pass. Do not describe the feature as ready from an older green commit.

- [ ] **Step 5: Inspect the final diff against the execution base.**

```bash
git diff --stat <execution-base>...HEAD
git diff --name-only <execution-base>...HEAD
```

The changed-file set must be limited to the files in this plan plus any formatter-only changes inside those files. `contracts/axiom-education.v1.json`, AXIOM-MESH compatibility profiles, learner persistence routes, credential contracts, and unrelated curriculum content must be unchanged.

- [ ] **Step 6: Commit claim parity.**

```bash
git add config/capabilities.json README.md CHANGELOG.md
git commit -m "docs: register experimental computational literacy capability"
```

- [ ] **Step 7: Prepare the implementation PR.**

The PR body must state:

- exact implementation head SHA;
- exact base SHA;
- whether it is stacked on or follows merged PR #177;
- exact green workflow runs;
- 18-node/no-edge authored-pack boundary;
- deterministic MTH1W proof;
- optional Socratic proof and non-model fallback;
- no persistence/export/new Mesh authority;
- no official curriculum, psychometric, grade, credit, credential, or production-provider claim.

---

## Execution Order and Landing Strategy

1. Tasks 1–4 are independent of PR #177 and can be implemented/reviewed from the approved design base.
2. Do not begin Task 5 until the PR #177 dependency gate is satisfied.
3. If #177 is still not safely landable when Tasks 1–4 are green, open a first implementation PR containing only Tasks 1–4 and keep its claim limited to the deterministic/foundation slice. Do **not** add the final capability summary claiming both proofs.
4. After #177 lands, rebase and execute Task 5, then Task 6, either as the continuation of an unmerged stack or as a second narrowly dependent PR.
5. Branch cleanup and merges follow the repository's existing convergence policy; preserve superseded provenance rather than hiding dependency history.

## Final Success Criteria

The feature is ready for review only when:

- the canonical JSON pack loads to exactly 18 `CompetencyNode`s and zero edges;
- all malformed-pack and hook/evidence negative tests fail closed;
- no existing competency/evidence semantics are replaced;
- MTH1W visibly teaches verifier selection while `MathAnswerVerifier` alone decides correctness;
- Claw visibly teaches that a model answer must be checked while model output still creates no learner evidence;
- both MTH1W and Claw retain valid no-AI paths;
- no new learner-data persistence/export or Mesh authority exists;
- capability wording is `experimental` and matches executable evidence;
- `python tools/verify.py` passes on the exact head;
- Linux/Android, Windows, and Apple protected workflows pass on that same exact head.
