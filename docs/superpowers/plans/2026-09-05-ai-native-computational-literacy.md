# AI-Native Computational Literacy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the approved Intent → Specification → Verification → Systems Understanding competency family, prove it in one deterministic MTH1W path and one AI-optional Claw path, and expose it without creating a second mastery, grading, persistence, or authority system.

**Architecture:** Reuse the existing `CompetencyGraph`, `LearningEvidenceEnvelope`, deterministic `MathAnswerVerifier`, and governed Socratic Tutor boundaries. Add one versioned Axiom-authored competency pack plus pure companion metadata/hook models, then layer contextual learner UI over existing subject experiences; no new Mesh capability or learner-record route is introduced.

**Tech Stack:** Dart 3.11.x, Flutter 3.41.1, Flutter/Riverpod, bundled JSON assets, Python 3.12 repository verification, existing MTH1W deterministic verifier, existing governed Socratic Tutor PR #177, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-05-ai-native-computational-literacy-design.md`

## Global Constraints

- Pack schema: `axiom-education-authored-competency-pack.v1`.
- Family ID: `axiom.education.competency.ai-native-computational-literacy`.
- Family version: `1.0.0`.
- Authorship: `axiom-extension`; jurisdictional authority: `none`.
- Exactly 18 v1 competency nodes and zero edges.
- Existing evidence states `unknown`, `attempted`, `emerging`, `demonstrated` remain primary and revisable.
- No aggregate AI-literacy score, psychometric claim, grade, credit, transcript state, credential, curriculum status, or institutional eligibility.
- Every core competency retains a non-generative learning and evidence path.
- Model output remains instructional data, never authority.
- Cross-cutting evidence remains independent from subject correctness and subject grade/credit state.
- `CrossCuttingEvidenceMetadata` is in-memory only in v0: no persistence, export, new Gateway action, new Grid record kind, or Mesh capability.
- Raw prompts, model output, essays, code, conversations, clickstream, prompt counts, timing, retry counts, typing behavior, engagement, and model-use frequency are not stored in cross-cutting metadata.
- Existing `LearningEvidenceEnvelope` correction/retraction semantics remain unchanged.
- Public capability status remains `experimental` until executable evidence and claim parity exist.
- Toolchain stays pinned to Flutter `3.41.1`, Dart `3.11.x`, Python `3.12`, and repository lockfiles.
- The Claw AI-optional task must consume PR #177 after it is exact-head green; do not recreate or cherry-pick its governed tutor implementation.

---

## File Structure

**Create**

- `assets/competencies/ai_native_computational_literacy.v1.json` — canonical 18-node authored pack.
- `lib/core/models/authored_competency_pack.dart` — pure v1 parser/validator and conversion to `CompetencyGraph`.
- `lib/core/services/authored_competency_pack_loader.dart` — `AssetBundle` loading only.
- `lib/core/models/cross_cutting_learning_evidence.dart` — evidence-quality/verifier/AI-role vocabulary and in-memory wrapper.
- `lib/core/models/cross_cutting_competency_hook.dart` — activity-hook vocabulary and validation.
- `lib/widgets/cross_cutting_reasoning_card.dart` — contextual prompt with expandable canonical detail.
- `lib/core/practice/mth1w_cross_cutting_verification.dart` — deterministic MTH1W verifier-selection teaching model.
- Corresponding focused tests under `test/core/models/`, `test/core/services/`, `test/core/practice/`, and `test/widgets/`.

**Modify**

- `pubspec.yaml` — register the competency asset.
- `lib/features/practice/mth1w_practice_screen.dart` and its widget test — deterministic/no-AI proof.
- After PR #177 dependency gate: `lib/widgets/claw_experience_renderer.dart`, `lib/features/claw/claw_foundations_preview_screen.dart`, and their tests — AI-optional proof.
- `config/capabilities.json`, `README.md`, `CHANGELOG.md` — claim parity after both proofs exist.

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
- Consumes: `CompetencyNode` and `CompetencyGraph` from `competency_graph.dart`.
- Produces: `AuthoredCompetencyPack.fromJson(Map<String, Object?>)`, `toGraph()`, `containsCompetency(String)`, and `AuthoredCompetencyPackLoader.load(AssetBundle)`.

- [ ] **Step 1: Write the failing canonical-pack test.**

```dart
final pack = AuthoredCompetencyPack.fromJson(fixture());
expect(pack.schema, 'axiom-education-authored-competency-pack.v1');
expect(pack.familyId, AuthoredCompetencyPack.aiNativeFamilyId);
expect(pack.familyVersion, '1.0.0');
expect(pack.authorship, 'axiom-extension');
expect(pack.jurisdictionalAuthority, 'none');
expect(pack.graph.nodes, hasLength(18));
expect(pack.graph.edges, isEmpty);
```

Add mutation tests for unsupported schema/version, duplicate IDs, malformed IDs, missing/wrong family tag, zero/two/unknown dimension tags, missing authorship tag, and non-empty v1 `edges`.

- [ ] **Step 2: Run it and confirm RED.**

```bash
flutter test test/core/models/authored_competency_pack_test.dart --reporter expanded
```

Expected: compile failure because the pack types and asset do not exist.

- [ ] **Step 3: Add the canonical JSON asset with all 18 spec IDs.**

Every node uses this exact shape:

```json
{
  "competency_id": "axiom:computational-literacy:intent:problem-framing",
  "title": "Frame the actual problem",
  "tags": [
    "family:ai-native-computational-literacy",
    "dimension:intent",
    "authorship:axiom-extension"
  ]
}
```

The root contains the exact schema/family/version/authorship/authority fields from Global Constraints, all 18 approved IDs, and `"edges": []`.

- [ ] **Step 4: Implement the pure v1 parser.**

Use this validation structure in `authored_competency_pack.dart`:

```dart
class AuthoredCompetencyPackException implements Exception {
  final String message;
  const AuthoredCompetencyPackException(this.message);
}

class AuthoredCompetencyPack {
  static const aiNativeFamilyId =
      'axiom.education.competency.ai-native-computational-literacy';
  static const aiNativeAssetPath =
      'assets/competencies/ai_native_computational_literacy.v1.json';
  static const _schema = 'axiom-education-authored-competency-pack.v1';
  static const _dimensions = {
    'dimension:intent',
    'dimension:specification',
    'dimension:verification',
    'dimension:systems',
  };

  final String schema;
  final String familyId;
  final String familyVersion;
  final String name;
  final String authorship;
  final String jurisdictionalAuthority;
  final CompetencyGraph graph;

  AuthoredCompetencyPack._({
    required this.schema,
    required this.familyId,
    required this.familyVersion,
    required this.name,
    required this.authorship,
    required this.jurisdictionalAuthority,
    required this.graph,
  });

  factory AuthoredCompetencyPack.fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw AuthoredCompetencyPackException('$key must be a non-empty string.');
      }
      return value;
    }

    final schema = requiredString('schema');
    final familyId = requiredString('family_id');
    final version = requiredString('family_version');
    final authorship = requiredString('authorship');
    final authority = requiredString('jurisdictional_authority');
    if (schema != _schema || familyId != aiNativeFamilyId ||
        version != '1.0.0' || authorship != 'axiom-extension' ||
        authority != 'none') {
      throw const AuthoredCompetencyPackException('Unsupported authored competency pack identity.');
    }

    final rawNodes = json['nodes'];
    final rawEdges = json['edges'];
    if (rawNodes is! List || rawEdges is! List || rawEdges.isNotEmpty) {
      throw const AuthoredCompetencyPackException('v1 requires a node list and zero edges.');
    }

    final seen = <String>{};
    final nodes = <CompetencyNode>[];
    for (final raw in rawNodes) {
      if (raw is! Map) {
        throw const AuthoredCompetencyPackException('Each node must be an object.');
      }
      final node = Map<String, Object?>.from(raw);
      final id = node['competency_id'];
      final title = node['title'];
      final rawTags = node['tags'];
      if (id is! String ||
          !RegExp(r'^axiom:computational-literacy:[a-z-]+:[a-z-]+$').hasMatch(id) ||
          !seen.add(id) || title is! String || title.trim().isEmpty || rawTags is! List) {
        throw const AuthoredCompetencyPackException('Invalid competency node.');
      }
      final tags = rawTags.whereType<String>().toSet();
      final dimensions = tags.intersection(_dimensions);
      if (tags.length != rawTags.length ||
          !tags.contains('family:ai-native-computational-literacy') ||
          !tags.contains('authorship:axiom-extension') ||
          dimensions.length != 1) {
        throw const AuthoredCompetencyPackException('Invalid competency node tags.');
      }
      nodes.add(CompetencyNode(competencyId: id, title: title, tags: tags));
    }
    if (nodes.length != 18) {
      throw const AuthoredCompetencyPackException('v1 requires exactly 18 competency nodes.');
    }

    return AuthoredCompetencyPack._(
      schema: schema,
      familyId: familyId,
      familyVersion: version,
      name: requiredString('name'),
      authorship: authorship,
      jurisdictionalAuthority: authority,
      graph: CompetencyGraph(nodes: nodes, edges: const <CompetencyEdge>[]),
    );
  }

  bool containsCompetency(String id) => graph.nodes.containsKey(id);
  CompetencyGraph toGraph() => graph;
}
```

- [ ] **Step 5: Register/load the asset and test the bundle path.**

Add `assets/competencies/ai_native_computational_literacy.v1.json` to `flutter.assets`. `AuthoredCompetencyPackLoader.load(bundle)` loads that path, JSON-decodes it, rejects a non-object root, and calls `AuthoredCompetencyPack.fromJson`.

- [ ] **Step 6: Run focused regressions.**

```bash
flutter test test/core/models/authored_competency_pack_test.dart test/core/services/authored_competency_pack_loader_test.dart test/core/models/competency_graph_test.dart --reporter expanded
```

Expected: PASS.

- [ ] **Step 7: Commit.**

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
- Consumes: `LearningEvidenceEnvelope`, `AuthoredCompetencyPack`.
- Produces the exact v1 evidence-quality/verifier/AI-role and activity-hook vocabularies from the spec.

- [ ] **Step 1: Write failing evidence-companion tests.**

```dart
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

Negative tests: mismatched `evidenceId`, blank `observationSource`, empty qualities, and empty verifier methods must fail validation.

- [ ] **Step 2: Run and confirm RED.**

```bash
flutter test test/core/models/cross_cutting_learning_evidence_test.dart --reporter expanded
```

- [ ] **Step 3: Implement exact enums and immutable wrapper.**

```dart
enum CrossCuttingEvidenceQuality {
  recognized, supportedApplication, independentApplication,
  robustApplication, transferObserved,
}

enum CrossCuttingVerifierMethod {
  learnerReasoning, deterministicCalculator, symbolicSolver,
  compilerOrTestRunner, experimentOrMeasurement,
  sourceOrProvenanceReview, educatorReview, peerReview,
  modelAssistedCritique, otherGovernedTool,
}

enum CrossCuttingAiRole {
  absent, optionalTool, generatedCandidate, critiqueAssistant, socraticTutor,
}
```

`CrossCuttingEvidenceMetadata` contains only `evidenceId`, `qualities`, `verifierMethods`, `aiRole`, and `observationSource`. `CrossCuttingLearningEvidence` holds one existing base envelope plus one matching metadata object and exposes fixed `false` getters for persistence, export, mastery creation, and subject-grade mutation.

- [ ] **Step 4: Write failing hook tests.**

Prove unknown competency fails; blank prompt fails; `introduce` may omit a verifier; `elicitEvidence` requires a verifier and `hasNonGenerativePath == true`; `aiMode == partOfTask` does not waive the non-generative rule.

- [ ] **Step 5: Implement the hook contract.**

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
  const CrossCuttingCompetencyHook({
    required this.competencyId,
    required this.role,
    required this.learnerFacingPrompt,
    required this.aiMode,
    required this.verifierMethods,
    required this.hasNonGenerativePath,
  });
}
```

The validator calls `pack.containsCompetency`, checks the exact rules above, and contains no curriculum-provider, Gateway, persistence, grade, or credential code.

- [ ] **Step 6: Run evidence/hook regressions.**

```bash
flutter test test/core/models/cross_cutting_learning_evidence_test.dart test/core/models/cross_cutting_competency_hook_test.dart test/core/models/learning_evidence_test.dart --reporter expanded
```

Expected: PASS; existing `LearningEvidenceEnvelope` semantics remain unchanged.

- [ ] **Step 7: Commit.**

```bash
git add lib/core/models/cross_cutting_learning_evidence.dart lib/core/models/cross_cutting_competency_hook.dart test/core/models/cross_cutting_learning_evidence_test.dart test/core/models/cross_cutting_competency_hook_test.dart
git commit -m "feat: add cross-cutting evidence metadata"
```

---

### Task 3: Hybrid-visibility reasoning card

**Files:**
- Create: `lib/widgets/cross_cutting_reasoning_card.dart`
- Create: `test/widgets/cross_cutting_reasoning_card_test.dart`

**Interfaces:**
- Produces `CrossCuttingReasoningCard({learnerFacingPrompt, dimensionLabel, competencyLabel})`.

- [ ] **Step 1: Write the failing widget test.**

```dart
expect(find.text('How could you check that this result must be correct?'), findsOneWidget);
expect(find.text('Reasoning details'), findsOneWidget);
expect(find.textContaining('Verification → method selection'), findsNothing);
```

Tap `Reasoning details`; then require `Verification → method selection`. Add a text-scaling/semantics assertion so contextual wording is never hidden behind canonical jargon.

- [ ] **Step 2: Run and confirm RED.**

```bash
flutter test test/widgets/cross_cutting_reasoning_card_test.dart --reporter expanded
```

- [ ] **Step 3: Implement a pure presentation widget.**

Use the existing Card + `ExpansionTile` pattern. The widget contains no scoring, model, evidence, curriculum, or persistence logic.

- [ ] **Step 4: Run test and format check.**

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
- Canonical competency: `axiom:computational-literacy:verification:method-selection`.
- `MathAnswerVerifier.verify(...)` remains the only correct/incorrect authority.

- [ ] **Step 1: Write failing pure-model tests.**

```dart
enum Mth1wVerificationChoice { exactCalculation, estimateOnly, modelOpinion }

expect(const Mth1wVerificationChoicePolicy()
    .isSufficient(Mth1wVerificationChoice.exactCalculation), isTrue);
expect(const Mth1wVerificationChoicePolicy()
    .isSufficient(Mth1wVerificationChoice.modelOpinion), isFalse);
```

Require the exported hook to be `elicitEvidence`, `aiMode: absent`, verifier `{deterministicCalculator}`, and `hasNonGenerativePath: true`.

- [ ] **Step 2: Run and confirm RED.**

```bash
flutter test test/core/practice/mth1w_cross_cutting_verification_test.dart --reporter expanded
```

- [ ] **Step 3: Implement the pure choice policy and hook.**

Only `exactCalculation` maps to a sufficient verifier for the exact-answer check. `estimateOnly` and `modelOpinion` are explanatory alternatives and never mark an answer verified.

- [ ] **Step 4: Add failing MTH1W widget assertions.**

Add a contextual prompt “How should we check an exact answer here?” with stable choices `mth1w-verifier-exact`, `mth1w-verifier-estimate`, and `mth1w-verifier-model`. Prove:

- `Check answer` needs nonblank input **and** exact calculation;
- estimate/model choices explain why they are insufficient for exact verification;
- exact calculation enables the existing deterministic checker;
- result status still comes only from `MathAnswerVerifier`;
- session summary still says nothing is saved;
- expanded detail shows `Verification → method selection`;
- `verifier == null` remains unavailable even after selecting a method.

- [ ] **Step 5: Implement ephemeral UI state.**

Add `Mth1wVerificationChoice? _verificationChoice;`, reset it in `_clearResponse()`, and include the exact-calculation requirement in `canCheck`. Do not create `LearningEvidenceEnvelope` or persistence calls in this proof.

- [ ] **Step 6: Run deterministic proof regressions.**

```bash
flutter test test/core/practice/mth1w_cross_cutting_verification_test.dart test/features/practice/mth1w_practice_screen_test.dart test/core/practice/math_answer_verifier_test.dart test/core/practice/math_practice_generator_test.dart --reporter expanded
```

Expected: PASS.

- [ ] **Step 7: Commit.**

```bash
git add lib/core/practice/mth1w_cross_cutting_verification.dart lib/features/practice/mth1w_practice_screen.dart test/core/practice/mth1w_cross_cutting_verification_test.dart test/features/practice/mth1w_practice_screen_test.dart
git commit -m "feat: teach verifier selection in MTH1W practice"
```

---

### Task 5: AI-optional Claw proof after governed tutor readiness

**Dependency gate:** PR #177 supplies `EducationModelExecutor`, `aiSocraticDialogue`, bounded learner input, minimized usage receipts, and deterministic fallback. Start this task only after one of these exact states is true:

1. Preferred: PR #177 is exact-head green on Linux/Android, Windows, and Apple and has merged; rebase on current `main`.
2. Deliberate stack: PR #177 is exact-head green but remains unmerged; base this work on `origin/feature/governed-socratic-tutor-v0-20260901` and state that dependency in the PR.

**Files:**
- Modify: `lib/widgets/claw_experience_renderer.dart`
- Modify: `lib/features/claw/claw_foundations_preview_screen.dart`
- Modify: `test/widgets/claw_experience_renderer_test.dart`
- Modify: `test/features/claw/claw_foundations_preview_screen_test.dart`

- [ ] **Step 1: Write failing renderer tests.**

After successful Socratic text appears, require “Before accepting it, how could you check the fraction claim?” and a stable `claw-socratic-verification` surface. Keep the existing `expect(evidence, isEmpty);` assertion before and after method selection. A model response cannot select itself as an authoritative verifier.

- [ ] **Step 2: Write failing no-provider/failure tests.**

With no `socraticBinding`, the existing non-model route remains usable. On provider failure, deterministic fallback remains visible and no cross-cutting evidence/mastery callback is emitted automatically.

- [ ] **Step 3: Implement ephemeral post-response verification selection.**

Reuse `CrossCuttingReasoningCard` and `CrossCuttingVerifierMethod`. Keep model text plain instructional content. Do not persist the method selection and do not pass it back into the model.

- [ ] **Step 4: Preserve the existing model-context boundary.**

`ClawFoundationsSocraticExecutionBinding` continues to materialize only `targetCompetency` and `currentLearnerInput`. No new context scope or provider authority is added.

- [ ] **Step 5: Run Claw/tutor regressions.**

```bash
flutter test test/widgets/claw_experience_renderer_test.dart test/features/claw/claw_foundations_preview_screen_test.dart test/core/models/education_model_execution_test.dart test/core/models/education_model_routing_test.dart --reporter expanded
```

Expected: PASS; failure still routes to reviewed non-model content and no provider is activated by default.

- [ ] **Step 6: Commit.**

```bash
git add lib/widgets/claw_experience_renderer.dart lib/features/claw/claw_foundations_preview_screen.dart test/widgets/claw_experience_renderer_test.dart test/features/claw/claw_foundations_preview_screen_test.dart
git commit -m "feat: add verification reasoning to Socratic preview"
```

---

### Task 6: Claim parity and exact-head verification

**Files:**
- Modify: `config/capabilities.json`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Adds `instruction.cross-cutting-computational-literacy` with status `experimental`.
- Does not modify `contracts/axiom-education.v1.json`, AXIOM-MESH compatibility pins, learner-event actions, or credential contracts.

- [ ] **Step 1: Add the capability entry only after both proofs exist.**

Use this claim boundary:

```json
{
  "id": "instruction.cross-cutting-computational-literacy",
  "family": "instruction",
  "status": "experimental",
  "summary": "A versioned Axiom-authored cross-cutting competency family represents Intent, Specification, Verification, and Systems Understanding through 18 non-jurisdictional competency nodes. One deterministic MTH1W proof and one optional governed-Socratic proof expose contextual verification reasoning without creating a new mastery, grade, learner-record, persistence, or model-authority path."
}
```

Add exact implementation/test paths to `evidence`. README/CHANGELOG must explicitly say: not official Ontario curriculum, not validated psychometrics, no AI-literacy score, no model requirement, and no automatic mastery/grade effect.

- [ ] **Step 2: Run the focused fail-closed matrix.**

The tests must cover all of these boundaries: duplicate/malformed IDs; missing/wrong family/authorship tags; zero/two/unknown dimensions; unsupported schema/version; non-empty v1 edges; unknown hook competency; blank hook prompt; evidence hook without verifier; evidence hook without non-generative path; AI-part-of-task cannot waive non-generative demonstration; evidence-ID mismatch; companion metadata has no raw-content fields or persistence/export authority; metadata cannot calculate/promote competency state; model output cannot emit Claw evidence/mastery; MTH1W method choice cannot determine math correctness; missing deterministic verifier remains unavailable; AI/provider absence retains a non-generative path; Axiom competency hooks never imply official curriculum coverage. Existing `CompetencyGraph` tests continue to cover missing edge endpoints and prerequisite cycles for graph infrastructure.

Run:

```bash
flutter test test/core/models/authored_competency_pack_test.dart test/core/models/cross_cutting_learning_evidence_test.dart test/core/models/cross_cutting_competency_hook_test.dart test/core/practice/mth1w_cross_cutting_verification_test.dart test/features/practice/mth1w_practice_screen_test.dart test/widgets/cross_cutting_reasoning_card_test.dart test/widgets/claw_experience_renderer_test.dart test/features/claw/claw_foundations_preview_screen_test.dart test/core/models/competency_graph_test.dart --reporter expanded
```

Expected: PASS.

- [ ] **Step 3: Run capability and canonical repository verification.**

```bash
python tools/check_capabilities.py
python tools/verify.py
```

Expected final line: `Axiom Education verification passed.`

- [ ] **Step 4: Run exact-head platform CI.**

Push the exact implementation head and require the repository's existing Linux/Android, Windows, and Apple workflows to pass on that same SHA. Do not reuse green evidence from an older commit.

- [ ] **Step 5: Inspect the final diff against the correct base.**

If PR #177 has merged:

```bash
BASE_REF=origin/main
BASE_SHA=$(git rev-parse "$BASE_REF")
git diff --stat "$BASE_SHA"...HEAD
git diff --name-only "$BASE_SHA"...HEAD
```

If this work is deliberately stacked on the unmerged tutor branch:

```bash
BASE_REF=origin/feature/governed-socratic-tutor-v0-20260901
BASE_SHA=$(git rev-parse "$BASE_REF")
git diff --stat "$BASE_SHA"...HEAD
git diff --name-only "$BASE_SHA"...HEAD
```

The changed-file set is limited to this plan's files plus formatter-only changes inside those files. `contracts/axiom-education.v1.json`, AXIOM-MESH compatibility profiles, learner persistence routes, credential contracts, and unrelated curriculum content remain unchanged.

- [ ] **Step 6: Commit claim parity.**

```bash
git add config/capabilities.json README.md CHANGELOG.md
git commit -m "docs: register experimental computational literacy capability"
```

- [ ] **Step 7: Prepare the implementation PR.**

Record exact implementation head SHA, exact base SHA, whether PR #177 is merged or stacked, exact green workflow run IDs, the 18-node/no-edge boundary, deterministic MTH1W proof, optional Socratic proof/fallback, and all non-claims above.

---

## Landing Strategy

1. Tasks 1–4 are independent of PR #177 and can be implemented/reviewed from the approved design base.
2. Task 5 waits for the explicit PR #177 dependency gate.
3. If #177 is not safely landable when Tasks 1–4 are green, open a first implementation PR containing only Tasks 1–4. Its claim is limited to the competency foundation plus deterministic MTH1W proof; do not claim the AI-optional proof or add the final two-proof capability summary.
4. After #177 lands, execute Task 5 and then Task 6 as either the continuation of an intentionally stacked branch or a second narrow PR.

## Final Success Criteria

- Canonical pack loads to exactly 18 `CompetencyNode`s and zero edges.
- Malformed pack/hook/evidence inputs fail closed.
- Existing competency/evidence semantics are not replaced.
- MTH1W teaches verifier selection while `MathAnswerVerifier` alone decides correctness.
- Claw teaches that a model answer must be checked while model output creates no learner evidence.
- MTH1W and Claw retain valid no-AI paths.
- No new learner-data persistence/export or Mesh authority exists.
- Capability wording is `experimental` and matches executable evidence.
- `python tools/verify.py` passes on the exact head.
- Linux/Android, Windows, and Apple protected workflows pass on that same exact head.
