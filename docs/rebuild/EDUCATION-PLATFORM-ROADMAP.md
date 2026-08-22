# Axiom Education platform roadmap

Axiom Education is a **general, lifelong education platform and education-domain layer**, not a high-school application with later extensions.

Ontario Secondary is one implementation track. Ontario Elementary is another. Jurisdiction, learner continuity, educator workflow, accessibility, portability, provider integration, and governance boundaries are platform tracks that serve both and later life stages.

## Roadmap rule

No course-specific delivery sequence is the global Axiom Education roadmap.

For example, the current MTH1W readiness declaration contains a secondary-course sequence equivalent to:

```text
complete and verify MTH1W
  -> remaining Grade 9 courses
  -> later secondary grades
```

That sequence governs **Ontario Secondary course rollout only**. It does not block Ontario Elementary, early-years work, platform infrastructure, post-secondary architecture, apprenticeship/professional learning, or lifelong-learning capabilities from advancing in parallel.

## Integration discipline

Axiom Education consumes AXIOM-MESH through the narrowest reviewed semantic authority seam rather than binding runtime compatibility to every unrelated Mesh repository change.

For the current governed Education runtime, the binding surface is the reviewed Education-facing `POST /v1/intents` behavior, exact required Education contracts, learner-memory profile, and the `Gateway -> Hypervisor -> Sandbox -> Grid` authority path. A reviewed Mesh repository head and the full Gateway contract remain useful provenance, but they are not by themselves runtime authority.

Consequences:

- unrelated additive social, agent, observability, or read routes do not silently broaden Education authority;
- unrelated Mesh repository commits do not automatically invalidate an otherwise unchanged Education semantic seam;
- a change to the Education intent seam, a required contract, or an authority-bearing path still fails closed until explicitly reviewed;
- merged Mesh features such as Assurance Graph, provider observation, and checkout freshness remain readiness-only until Education deliberately adopts them with evidence;
- draft delegated-human-authority and host profiles remain non-production inputs and grant no Education authority merely by existing.

Cross-platform delivery evidence is also a compatibility boundary rather than a product-completeness claim. Linux/Android, Windows, macOS, and iOS no-codesign lanes should continue to exercise the same learner and evidence code paths. Apple signing, notarization, App Store readiness, physical-device support, Apple Silicon support, and production accessibility remain separate claims requiring their own evidence.

## Parallel workstreams

### 1. Education-domain substrate

Build once and reuse across ages, jurisdictions, courses, and experience layers:

- portable effective-dated jurisdiction context;
- signed/verifiable curriculum capsule factory;
- curriculum source and provenance evidence;
- standards/competency crosswalks;
- governed learner-event and learner-record semantics;
- educator assignment/review/correction/appeal workflow;
- selective portfolio export;
- accessibility and alternate delivery transforms;
- provider/capsule admission and revocation;
- classroom causal synchronization through AXIOM-MESH;
- credential issuance/verification only after an approved profile exists;
- evidence-bound human review and correction.

### 2. Ontario Elementary and Kindergarten

Ontario Elementary is a first-class jurisdictional curriculum track, not a derivative of the secondary product.

Sequence evidence per source/program family:

```text
C0 source discovery
  -> C1 exact-byte source lock
  -> C2 normalized records
  -> C3 human/source review
  -> C4 reproducible pack
  -> C5 external signature
  -> C6 independent verification
  -> C7 staging
  -> C8 governed activation
```

English-language and French-language Ontario school program families remain separate where their official curriculum/program structures differ. Shared-looking subject names never justify silent cross-stream substitution.

Kindergarten is tracked separately from Grades 1-8 where its program structure and effective versions differ.

CLAW and other child-facing experience layers may consume verified standards/crosswalks, but their authored pedagogy stays separately inspectable from official Ontario curriculum.

### 3. Ontario Secondary

Use MTH1W as the first deep end-to-end secondary proof because it already has the most mature authored/evidence surface.

MTH1W promotion requires more than complete lesson slots:

- exact official-source binding;
- reviewed instructional coverage;
- cultural/context review where applicable;
- licensing/redistribution evidence;
- cumulative assessment validity/scoring review;
- accessible/printable/offline alternatives plus human usability/accessibility review;
- governed learner records;
- educator correction and appeal;
- no automatic mastery, grade, credit, transcript, or Ministry-equivalence inference.

The current nine-unit authored draft covers all planned lesson slots but accounts for 3,825 primary-lesson minutes inside a 6,600-minute planning envelope. The remaining 2,775 minutes must be allocated only where instruction, practice, consolidation, assessment, or other pedagogical structure actually requires them; lesson durations must not be inflated merely to manufacture a 110-hour claim.

After MTH1W passes its own gates, secondary content can expand through the remaining Grade 9 courses and later grades without redefining the platform around that sequence.

### 4. Learner experience and accessibility

The primary product surface should remain understandable without exposing internal evidence plumbing as navigation.

The current direction is:

```text
learner home
  -> focused learning hub / lesson
  -> bounded local practice
  -> curriculum reference when needed
  -> family/support tools when needed
```

The larger source-mapped draft-unit explorer remains secondary until its review gates mature.

Learner-facing design should continue to:

- use clear next actions rather than internal architecture terms;
- keep technical digests and verifier identifiers available but collapsible;
- prevent blank or invalid submissions before they become misleading attempts;
- distinguish attempts from distinct questions checked and distinct questions answered correctly;
- avoid repeated checks inflating apparent progress;
- avoid intentional text truncation where larger system text should reflow;
- expose loading, empty, retry, unavailable, and fail-closed states explicitly;
- avoid displaying synthetic study time, grades, mastery, streaks, or completion state when no governed evidence supports them.

### 5. Learner continuity across life stages

The learner-facing shell may change substantially with age while governed continuity can preserve selected, portable state such as:

- goals and learning plans;
- standards/competency history;
- reviewed evidence and projects;
- portfolio objects;
- preferences and accessibility settings;
- correction/appeal provenance;
- consent and authority history where appropriate.

The architecture should support movement across early years, elementary, secondary, post-secondary, apprenticeship, professional learning, employment/reskilling, civic learning, hobbies/projects, and later-life learning without permanently encoding one jurisdiction or institution into identity.

### 6. External learning experiences

Coding environments, simulations, robotics/maker tools, museums/libraries, virtual worlds, OER/video systems, physical activities, creative tools, apprenticeships, and employer learning can become bounded experience providers.

Provider success is never automatically learner mastery. Standards coverage requires a verified crosswalk, and publishing/sharing an artifact is a separate authority event from creating it.

## Cross-cutting promotion rules

A capability moves to `implemented` only when its actual production path has executable evidence and no synthetic-success fallback.

Across all workstreams:

- installation grants no authority;
- missing identity, consent, policy, provider, source, verifier, or evidence fails closed;
- raw learner work is not copied into logs/evidence merely for convenience;
- minor-related data remains minimum-necessary and purpose-bound;
- machine-generated structure never substitutes for qualified human review where judgement is required;
- public availability never substitutes for licensing/redistribution evidence;
- negative findings remain provenance;
- historical evidence is not rewritten when later stages are reached;
- current claims are derived from current evidence rather than optimistic roadmap language.

## Priority model

Priorities should be chosen by **shared leverage and evidence maturity**, not age-group branding.

A practical order is:

1. preserve and continuously verify the narrow Education/AXIOM-MESH semantic authority seam and cross-platform portability;
2. finish reusable substrate primitives that unblock multiple tracks;
3. keep improving the primary learner-facing shell, accessibility, and honest feedback without creating unsupported progress claims;
4. deepen the most evidence-ready vertical slices (currently Ontario Elementary source pipeline and MTH1W secondary);
5. convert human-review bottlenecks into reproducible evidence workflows without manufacturing approval;
6. allocate the remaining MTH1W program time only through defensible instructional/assessment design, then finish the educator, licensing, accessibility, and cumulative-assessment gates;
7. expand subject/grade coverage only after the source/verification factory survives multiple structurally different slices;
8. add jurisdictions by reusing the same evidence machinery rather than copying Ontario assumptions;
9. broaden lifelong/provider experiences on the same governed learner substrate.

This keeps Axiom Education coherent as one education platform while allowing elementary, secondary, and lifelong capabilities to mature at different speeds.
