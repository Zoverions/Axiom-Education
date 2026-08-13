# Axiom Education Product Definition

**Status:** Canonical rebuild definition  
**Current build:** `0.5.0-dev.0`  
**Canonical branch:** `main`  
**Repository rename target:** `Zoverions/Axiom-Education`  
**Archived baseline:** `archive/ontarioedai-pre-axiom-2026-07-30`  
**AXIOM compatibility target:** exact profile for `0.12.0-dev.3`; newer kernels require an explicit reviewed repin

## One-sentence definition

Axiom Education is a local-first, lifelong education platform that uses signed jurisdictional curriculum packs and separately governed education capabilities to support learning, assessment, learner records, classroom and experience synchronization, and portable evidence across age groups and life stages without granting any application, curriculum, institution, or provider ambient authority over a learner's data or device.

## Product scope

Axiom Education is not a high-school application, an Ontario-only application, or a single curriculum product. Those are deployable surfaces inside the broader education domain.

The platform is intended to support, through different curriculum packs and experience layers:

- early-years and elementary learning;
- secondary and home-learning pathways;
- post-secondary, apprenticeship, and professional learning;
- workplace training and reskilling;
- civic, hobby, project, and self-directed learning;
- later-life learning;
- movement between jurisdictions, institutions, programs, and experience providers without discarding governed learner history.

Ontario is the first supported jurisdiction. Ontario Kindergarten / Grades 1-8 and Ontario Secondary are separate curriculum tracks that share generic jurisdiction, curriculum-pack, learner, evidence, consent, portability, and provider infrastructure. MTH1W is the first deep secondary course vertical slice; it is an implementation priority, not the product definition.

## Product sequencing principle

The conventional educational platform comes first. A learner must be able to
open a course, learn from explicit instruction and worked examples, complete
guided and independent practice, receive understandable feedback, take
conventional assessments, and review prior material when no AI tutor is
configured. Adaptive scheduling and tutoring are optional, transparent,
reversible enhancement layers and cannot bypass curriculum, assessment,
evidence, privacy, or educator-review rules.

## Product boundary

Axiom Education remains an independently releasable Flutter application and education-domain repository. AXIOM-MESH remains the policy, capability, execution, evidence, consent, and portability substrate.

The intended governed effect path is:

```text
Axiom Education UI / experience layer
  -> AXIOM Gateway
  -> policy, consent, risk, and plan evaluation
  -> short-lived capability grant
  -> approved education, curriculum, or provider capsule
  -> bounded execution
  -> encrypted learner state and evidence in Grid
```

No learner-data mutation, external provider call, credential issuance, curriculum activation, or classroom synchronization effect may bypass that path in governed mode.

## Responsibilities retained by Axiom Education

- Flutter presentation and local interaction state.
- Course, lesson, workspace, canvas, progress, portfolio, and privacy interfaces.
- Pure education-domain models and pedagogical contracts.
- Jurisdiction and curriculum-pack presentation semantics.
- Age- and experience-appropriate shells over a portable learner substrate.
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

The education domain is divided into narrow capability surfaces:

1. `education.curriculum` — verify, query, install, and activate signed curriculum packs.
2. `education.tutor` — retrieve grounding and invoke an explicitly configured model provider.
3. `education.assessment` — generate, verify, record, and submit results for review.
4. `education.learner-record` — store purpose-bound learner events, preferences, accommodations, and progress.
5. `education.canvas` — process an explicitly selected image or stroke set under bounded retention.
6. `education.classroom-sync` — exchange signed classroom bundles through admitted nodes and causal synchronization.
7. `education.portfolio` — selectively export learner-owned work and evidence.
8. `education.credentials` — issue or verify achievements only after the AXIOM credential profile is approved.
9. `education.jurisdiction` — resolve effective-dated education contexts and active standards without encoding jurisdiction into permanent identity.
10. `education.experience-provider` — invoke bounded external digital or physical learning environments while preserving minimum disclosure, provenance, and verification boundaries.

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

These protections are a floor for minor-related use. Adult and lifelong-learning contexts may use different consent/controller relationships while retaining data minimization, bounded authority, provenance, portability, and correction rights.

## Current Ontario implementation tracks

### Ontario Elementary

The Kindergarten / Grades 1-8 track is building a reusable curriculum-capsule and jurisdiction foundation. It must progress through explicit source discovery, source capture/digesting, parsing, human review, deterministic build, signing, independent verification, staging, and governed activation. English- and French-language program families must remain separately accounted for rather than silently substituted.

### Ontario Secondary

The current runnable curriculum browser is secondary-focused because the inherited source corpus exists there. The first deep course vertical slice is `MTH1W`, Mathematics, Grade 9, De-streamed.

The current four-lesson Grade 9 Math Foundations Preview is not a complete
course: its preliminary local identifiers have known conflicts with the
official 2021 curriculum and are gated by
`config/curriculum-readiness.json`. MTH1W must exercise:

- a signed Ontario curriculum pack;
- a student-visible course, unit, and lesson sequence;
- explicit learning goals, prerequisites, direct instruction, and worked examples;
- deterministic arithmetic and algebra verification;
- generated practice linked to exact expectation identifiers;
- scaffolded hints;
- independent practice, lesson checks, quizzes, unit tests, and review;
- learner-event recording;
- uncertainty and evidence display;
- educator review and appeal;
- selective portfolio export;
- offline operation.

Only after that foundation passes its acceptance gates may the course require
evidence for an optional configured local tutor provider and adaptive review
recommendations. The conventional route must remain available when either is
disabled or unavailable.

Expansion to other secondary courses follows evidence gates, but completion of that sequence does not constrain Axiom Education to secondary education.

## Lifelong learner continuity

The durable learner substrate should allow the presentation layer and active curriculum/provider context to change while preserving only appropriately governed, portable history such as:

- goals and preferences;
- standards and curriculum context history;
- competency and assessment evidence;
- projects and portfolio objects;
- accessibility preferences and accommodations;
- correction, review, and appeal records;
- consent, provenance, and authority history.

A learner changing school, province, country, program, occupation, or life stage should not require a new education identity merely because the surrounding experience changes.

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

Until independently demonstrated, Axiom Education does not claim:

- production readiness;
- complete coverage or currency of every Ontario elementary or secondary curriculum family;
- that the current Grade 9 Math Foundations Preview or authored unit set is a complete MTH1W course, credit, grade, transcript, or Ministry-approved resource;
- validated psychometric IRT parameters;
- a complete local language-model tutor;
- secure classroom federation from UDP, TCP, Bluetooth, WebRTC, or Wi-Fi discovery alone;
- legal or regulatory compliance merely because processing is local;
- verified DIDs or educational credentials without an approved issuer and verifier profile;
- that generated explanations are correct unless their relevant claims are grounded and checked;
- that attention, engagement, sentience, emotion, disability, or diagnosis can be inferred from ordinary interaction traces;
- that one jurisdiction, grade band, course, application shell, or provider defines the scope of the education platform.

## Naming and compatibility

`OntarioEdAI` is a deprecated historical name. Ontario content remains a jurisdictional pack family. The internal Dart package identifier `ontarioedai` is a temporary compatibility shim scheduled for isolated migration before `0.6.0`; it does not define the product or contract identity.
