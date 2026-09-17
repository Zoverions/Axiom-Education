# Governed Socratic Tutor v0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one governed, provider-neutral Socratic tutor execution path to the existing Claw fractions-equivalence preview with fail-closed non-model fallback.

**Architecture:** Reuse `EducationModelRouter` as the sole eligibility/selection layer. Add a small executor/provider interface that materializes only explicitly granted context and returns instructional text plus a minimized usage receipt; then wire one `aiSocraticDialogue` Claw node through a handler without allowing model output to become learner authority.

**Tech Stack:** Dart 3.11.x, Flutter 3.41.1, existing Axiom Education model-routing contracts/runtime, Flutter widget tests, GitHub Actions exact-head verification.

**Spec:** `docs/superpowers/specs/2026-09-01-governed-socratic-tutor-v0-design.md`

## Global Constraints

- No production provider activation.
- No learner dialogue persistence in this slice.
- No model-created grade, mastery, credit, credential, identity, policy, or external effect.
- No provider invocation before an allowed `EducationModelRouteDecision`.
- No silent provider substitution or automatic retry.
- No raw prompt or learner response in usage receipts.
- Socratic and fallback nodes must preserve `math:fractions:equivalence`.
- Existing non-model Claw path must remain usable when no model is available.

---

### Task 1: Governed inference executor

**Files:**
- Create: `lib/core/models/education_model_execution.dart`
- Create: `test/core/models/education_model_execution_test.dart`

**Interfaces:**
- Consumes: `EducationModelRouter`, `EducationModelRouteRequest`, `EducationModelContextGrant`, `EducationModelCandidate`, `EducationModelUsageReceipt`.
- Produces: `EducationModelInferenceProvider`, `EducationModelExecutionRequest`, `EducationModelExecutionResult`, `EducationModelExecutor.execute(...)`.

- [ ] **Step 1: Write failing tests** proving an expired/wrong-subject/ungranted/remote-denied/over-budget route makes zero provider calls; a successful route invokes exactly the selected candidate; undeclared materialized scopes fail before provider invocation; provider exceptions remain explicit failures; successful receipts contain no raw prompt/learner-response state and cannot establish mastery.
- [ ] **Step 2: Run exact-head CI and verify RED** because `education_model_execution.dart` and its symbols do not yet exist.
- [ ] **Step 3: Implement minimal executor** with one provider invocation, no retry/substitution, exact scope-key validation, bounded success metrics, and minimized receipt construction.
- [ ] **Step 4: Run exact-head CI and verify GREEN** for executor tests plus existing routing tests.
- [ ] **Step 5: Commit** executor implementation.

### Task 2: Claw Socratic graph and deterministic fallback

**Files:**
- Modify: `lib/features/claw/claw_foundations_story_arc.dart`
- Modify: `test/widgets/claw_experience_renderer_test.dart`
- Modify or create focused graph test under `test/core/models/` only if needed.

**Interfaces:**
- Consumes: existing `ClawExperienceNodeType.aiSocraticDialogue`, `ClawTransitionTrigger.modelUnavailable`, graph validator fallback invariant.
- Produces: a Socratic node and explicit non-model fallback transition preserving the existing competency.

- [ ] **Step 1: Write failing graph/widget assertions** for a Socratic node bound to `math:fractions:equivalence`, a non-model fallback, and unchanged competency targets.
- [ ] **Step 2: Run exact-head CI and verify RED** because the node is absent.
- [ ] **Step 3: Add the minimal graph/presentation changes** without altering evidence semantics or existing completion claims.
- [ ] **Step 4: Run exact-head CI and verify GREEN**.
- [ ] **Step 5: Commit** graph/presentation changes.

### Task 3: Learner-visible Socratic interaction

**Files:**
- Modify: `lib/widgets/claw_experience_renderer.dart`
- Modify: `lib/features/claw/claw_foundations_preview_screen.dart`
- Modify: `test/widgets/claw_experience_renderer_test.dart`
- Modify or create: `test/features/claw/claw_foundations_preview_screen_test.dart`

**Interfaces:**
- Produces: a bounded async Socratic handler accepting current node, learner input, and target competency, returning instructional text or explicit unavailable/failure status.
- The generic renderer must not import provider/model-routing internals; the screen owns the Education execution adapter.

- [ ] **Step 1: Write failing widget tests** proving the learner can enter a bounded response on the Socratic node; successful handler text is displayed only as instructional content; unavailable/failure produces the deterministic fallback path; empty input does not call the handler; no evidence/mastery callback is emitted by model text.
- [ ] **Step 2: Run exact-head CI and verify RED** because the interaction surface/handler is absent.
- [ ] **Step 3: Implement the minimal renderer and screen adapter** with explicit loading/error state and no persistent dialogue.
- [ ] **Step 4: Run exact-head CI and verify GREEN**.
- [ ] **Step 5: Commit** learner-visible integration.

### Task 4: Capability/claim parity and final verification

**Files:**
- Modify: `config/capabilities.json`
- Modify: `README.md` only if current capability wording would otherwise be false or incomplete.

**Interfaces:**
- Capability status remains `experimental`; local Phi-3 binding remains `disabled`; no production provider claim is introduced.

- [ ] **Step 1: Add a failing parity expectation if capability verification requires an explicit governed Socratic execution capability.**
- [ ] **Step 2: Update capability wording minimally** to distinguish provider-neutral governed execution from production model availability.
- [ ] **Step 3: Run exact-head Linux/Android, Windows, and Apple workflows** and inspect every failing job if any.
- [ ] **Step 4: Compare branch to `main`** and verify only planned files changed.
- [ ] **Step 5: Open a PR against `main`** with exact-head verification evidence and explicit non-claims.
