# OntarioEdAI Product Definition

**Status:** Canonical rebuild definition  
**Current build:** `0.5.0-dev.0`  
**Rebuild branch:** `rebuild/axiom-education-v0.5`  
**Archived baseline:** `archive/ontarioedai-pre-axiom-2026-07-30`  
**AXIOM target:** `0.12.0-dev.0` or later

## One-sentence definition

OntarioEdAI is a local-first adaptive education application that uses signed curriculum packs and separately governed education capabilities to provide tutoring, assessment, learner records, classroom synchronization, and portable evidence without granting the application ambient authority over a learner's data or device.

## Product boundary

OntarioEdAI remains an independently releasable Flutter application and education-domain repository. AXIOM-MESH remains the policy, capability, execution, evidence, consent, and portability substrate.

The intended governed effect path is:

```text
OntarioEdAI UI
  -> AXIOM Gateway
  -> policy, consent, risk, and plan evaluation
  -> short-lived capability grant
  -> approved education or provider capsule
  -> bounded execution
  -> encrypted learner state and evidence in Grid
```

No learner-data mutation, external provider call, credential issuance, curriculum activation, or classroom synchronization effect may bypass that path in governed mode.

## Responsibilities retained by OntarioEdAI

- Flutter presentation and local interaction state.
- Course, lesson, workspace, canvas, progress, portfolio, and privacy interfaces.
- Pure education-domain models and pedagogical contracts.
- Accessibility behavior and alternate input modes.
- Rendering of curriculum provenance, uncertainty, consent, and evidence.
- Development-only adapters used by tests and local prototyping.

## Responsibilities delegated to AXIOM-MESH

- Principal and service identity.
- Deny-dominant policy and risk evaluation.
- Purpose- and scope-bound consent.
- Short-lived, audience-, intent-, tool-, and resource-bound grants.
- Provider and capsule registration, revocation, and provenance.
- Bounded execution with no ambient authority.
- Encrypted durable learner records and hash-linked evidence.
- Selective export, import, backup, recovery, and causal synchronization.
- Independent approval for high-risk effects.

## Initial capability pack

The education domain will be divided into narrow capability surfaces:

1. `education.curriculum` — verify, query, install, and activate signed curriculum packs.
2. `education.tutor` — retrieve grounding and invoke an explicitly configured model provider.
3. `education.assessment` — generate, verify, record, and submit results for review.
4. `education.learner-record` — store purpose-bound learner events, preferences, accommodations, and progress.
5. `education.canvas` — process an explicitly selected image or stroke set under bounded retention.
6. `education.classroom-sync` — exchange signed classroom bundles through admitted nodes and causal synchronization.
7. `education.portfolio` — selectively export learner-owned work and evidence.
8. `education.credentials` — issue or verify achievements only after the AXIOM credential profile is approved.

## Minor-data policy floor

Every minor-related capability defaults to:

- local processing;
- minimum necessary data;
- explicit subject, controller, purpose, scope, expiry, and revocation;
- no advertising or behavioural targeting;
- no covert attention or emotion monitoring;
- no inferred diagnosis or protected trait from ordinary learning behaviour;
- no provider egress unless separately authorized;
- visible uncertainty and provenance;
- human review and appeal;
- selective export and deletion or tombstoning;
- fail-closed behavior when identity, policy, consent, provider, or evidence state is unavailable.

## First supported vertical slice

The first complete course experience will be `MTH1W`.

It must exercise:

- a signed Ontario curriculum pack;
- deterministic arithmetic and algebra verification;
- a configured local tutor provider;
- generated practice linked to exact expectation identifiers;
- scaffolded hints;
- learner-event recording;
- uncertainty and evidence display;
- educator review and appeal;
- selective portfolio export;
- offline operation.

Expansion to other courses follows only after this slice passes its acceptance gates.

## Rebuild acceptance rule

A capability is `implemented` only when all are present:

1. production-path behavior with no synthetic-success fallback;
2. versioned input and output schemas;
3. fail-closed authorization and negative-path tests;
4. data-minimization and consent enforcement where learner data is involved;
5. durable evidence from an executable verification command;
6. accessibility checks for the exposed interface;
7. operator and learner documentation matching actual behavior;
8. current status tied to a commit in `config/capabilities.json`.

Anything else is `experimental`, `adapter_required`, `specified`, or `disabled`.

## Deliberate non-claims

Until independently demonstrated, OntarioEdAI does not claim:

- production readiness;
- complete coverage or currency of every Ontario secondary course;
- validated psychometric IRT parameters;
- a complete local language-model tutor;
- secure classroom federation from UDP, TCP, Bluetooth, WebRTC, or Wi-Fi discovery alone;
- legal or regulatory compliance merely because processing is local;
- verified DIDs or educational credentials without an approved issuer and verifier profile;
- that generated explanations are correct unless their relevant claims are grounded and checked;
- that attention, engagement, sentience, emotion, disability, or diagnosis can be inferred from ordinary interaction traces.
