# Governed Socratic Tutor v0 Design

## Purpose

Turn the already-merged Axiom Education model-routing policy and Claw Academy `aiSocraticDialogue` node type into one bounded learner-visible execution path without granting any model authority over curriculum, learner records, mastery, grades, credentials, policy, identity, or external effects.

## Scope

This slice implements:

- a provider-neutral Education inference request/result interface;
- an execution coordinator that must obtain an allowed `EducationModelRouteDecision` before provider invocation;
- exact learner/task/context/retention/budget enforcement through the existing `EducationModelRouter`;
- minimized usage receipts with no raw prompt or learner response by default;
- fail-closed provider errors and no silent provider substitution;
- one Socratic dialogue node in the existing fractions-equivalence Claw preview;
- a deterministic non-model fallback that preserves the same governed competency.

It does not activate a production provider, persist learner dialogue, create mastery evidence, grade work, mint credentials, infer diagnoses, expand context automatically, or create any network authority.

## Architecture

### 1. Routing remains authoritative for eligibility

`EducationModelRouter` remains the only candidate-selection component. The new executor accepts a route request, context grant, candidate set, and minimized materialized context. It invokes a provider only when the router returns an allowed candidate.

No provider may be invoked before the route decision.

### 2. Provider-neutral execution boundary

A new `EducationModelInferenceProvider` interface accepts only:

- the selected candidate identity;
- task class;
- exact learner-subject ID;
- exact requested/materialized context scopes;
- bounded instructional prompt/context fields;
- retention class;
- output-unit and wall-time limits.

The provider returns bounded text plus measured units/cost/latency. It cannot return authority-bearing learner state.

### 3. Minimized materialization

The execution request contains only context fields mapped to scopes already present in `EducationModelRouteRequest.requestedContextScopes`. The executor rejects undeclared context keys and does not fetch or infer additional learner context.

For the v0 Claw slice, materialized context is limited to:

- `targetCompetency`;
- `currentLearnerInput`.

### 4. Failure semantics

- denied routing => no provider call;
- no eligible provider => explicit unavailable result;
- provider exception => explicit provider-failure result;
- provider timeout/budget violation => explicit failure;
- no automatic retry;
- no silent candidate/provider substitution;
- the Claw experience routes to a reviewed deterministic fallback.

### 5. Usage receipts

Successful execution produces an `EducationModelUsageReceipt` containing provider/model/runtime/compute node identity, materialized scopes, retention class, egress class, units, cost, latency, and optional fallback reason. Raw prompt and raw learner-response contents are not included.

### 6. Claw integration

The fractions-equivalence graph gains one `aiSocraticDialogue` node with the same `math:fractions:equivalence` target and an explicit non-model fallback node.

The learner may enter a short response to a fixed Socratic prompt. The screen hands that response to a bounded tutor handler. If the handler is unavailable or execution fails, the player visibly offers/uses the deterministic fallback rather than inventing model output.

The model response is displayed as instructional text only. It never changes the competency target, writes learner evidence, or creates mastery/grade state.

## Security and authority invariants

- route denial causes zero provider calls;
- wrong learner, expired grant, ungranted task/scope/retention, remote-egress denial, missing capability, unhealthy/unadmitted candidate, or over-budget candidate causes zero provider calls;
- model output is data, not authority;
- a successful model response does not establish mastery, grade, credit, credential, policy, identity, or public/social effect;
- no raw prompt or raw learner response is written to the usage receipt;
- no provider substitution or retry occurs automatically;
- the non-model fallback preserves the governed target competency.

## Testing strategy

TDD first. Add executor tests before implementation and observe CI failure because the executor/provider boundary does not exist. Then implement the minimal executor until those tests pass.

Add Claw graph/widget tests before the UI implementation and observe failure because the Socratic node/handler is absent. Then add the minimal graph and renderer/screen wiring.

Final merge gate is exact-head repository CI across the existing Linux/Android, Windows, and Apple workflows. No production-readiness claim is made by this PR.
