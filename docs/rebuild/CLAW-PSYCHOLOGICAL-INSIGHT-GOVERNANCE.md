# C.L.A.W. / Axiom Education psychological insight governance

Status: superseding clarification for the legacy-archive migration lane. This document narrows earlier language that could be read as prohibiting psychological or health-informed personalization altogether.

## Clarification

Psychology-informed personalization is **not prohibited**.

What is prohibited from direct legacy migration is the old pattern of uncontrolled or weakly-evidenced profiling: public-by-ID profile reads, permanent unsupported learning-style labels, unexplained synthetic scores, unrelated cross-site federation, public child comparison, or use of sensitive learner data for commercial engagement optimization.

The modern replacement is a **governed Personal Insight Vault**.

## Core rule

A psychologically relevant observation may be stored and used when it is:

- bound to the exact learner subject;
- attributed to an explicit source;
- marked with sensitivity and confidence/verification status;
- accompanied by evidence/provenance and limitations where applicable;
- scoped to explicit educational, self-reflection, support, or accommodation purposes;
- accessible only through current evidenced grants;
- inspectable by the learner where policy permits;
- challengeable, correctable, and revocable without silently rewriting provenance;
- reviewed or expired rather than silently becoming permanent identity truth;
- prevented from becoming a public profile, commercial targeting segment, grade, credential, or mastery result by inference alone.

## Supported source classes

The modern system may distinguish at least:

- learner self-report;
- guardian observation;
- educator observation;
- task-performance evidence;
- standardized or structured assessment;
- clinician-provided or clinician-verified information;
- model-generated hypothesis.

These sources do not have equal authority. A model hypothesis is not a diagnosis. A learner self-report is valuable first-person evidence but is not silently relabeled as clinician-verified. An educator observation may inform support without becoming a clinical claim.

## Sensitivity classes

At minimum:

1. **ordinary preference** — presentation or story preferences with low sensitivity;
2. **educational-sensitive** — learning-strategy, confidence, calibration, help-seeking, or metacognitive observations;
3. **psychological-sensitive** — personality, motivation, emotional-regulation, ambiguity-tolerance, or similar psychologically revealing context;
4. **clinical/health restricted** — health, diagnosis, treatment, disability/accommodation, or clinician-supplied information requiring the strongest access boundary.

Sensitivity controls access and materialization; it does not imply that the claim is more true.

## Inference rule

The system may generate useful psychological hypotheses, but must preserve uncertainty.

Good pattern:

> Working hypothesis: explicit counterexamples appear to improve calibration in this domain. Confidence: moderate. Based on eight comparable tasks. Review after additional evidence.

Rejected pattern:

> This learner is a visual learner.

The first is contextual, testable, revisable, and evidence-linked. The second turns a limited observation into a permanent identity label.

## Clinical boundary

A model may summarize, organize, or use authorized clinical/health context for permitted support tasks, but a model-generated inference must not silently create a clinical diagnosis or clinician-verified status.

Clinical/health information may enter the vault through appropriately attributed sources and remain useful for accommodations or authorized support. Its presence does not give every educator, guardian, model, or institution access.

## Access model

Vault access should reuse current Axiom/Mesh patterns:

- exact learner subject;
- exact actor;
- explicit purpose;
- explicit permissions;
- evidenced grant;
- issue and expiry timestamps;
- revocation;
- sensitivity/domain scope;
- access receipt for sensitive reads/uses;
- no role-name shortcut (for example, `teacher`, `parent`, or `counselor` alone is not sufficient authority).

## AI/model materialization requires two gates

A vault grant does **not** itself authorize remote or local model access.

To materialize an insight into an AI task, the system must satisfy both:

1. a current Personal Insight Vault grant authorizing that actor/purpose/sensitivity/domain; and
2. a current Education Model Context Grant authorizing the learner subject, task class, context scope, retention class, and any remote egress.

This prevents a broad "AI can see my profile" switch.

## Learner agency

Where applicable, the learner should be able to:

- inspect an insight and its source;
- see whether it is self-report, observation, assessment, clinician-provided information, or model hypothesis;
- see confidence/limitations where relevant;
- confirm it;
- dispute it;
- propose a correction;
- revoke future use;
- see who accessed or used sensitive information through receipts;
- export governed records where supported.

Corrections should be append-only revisions rather than silent mutation of the historical claim.

## Useful feedback the vault should enable

The purpose is not merely storage. The vault can power high-value private feedback such as:

- strategies that repeatedly improve transfer for this learner;
- confidence/calibration patterns;
- recurring assumptions or anchoring tendencies;
- help-seeking effectiveness;
- persistence and strategy-switching patterns;
- which representations help in which domains;
- how reasoning patterns change over time;
- learner-reported motivation or emotional-regulation needs;
- authorized accommodation context;
- metacognitive summaries that distinguish observation from inference.

These are feedback opportunities, not permanent character judgments.

## Still prohibited from direct migration

The following legacy patterns remain blocked:

- public psychological/learning profiles by numeric user ID;
- permanent V/A/K learning-style identity labels;
- generic 0-100 empathy, morality, personality, or critical-thinking scores without validated semantics;
- automatic cross-site psychological federation;
- unrelated social-reputation boosts from learner psychology;
- public child psychological rankings;
- commercial advertising/retention targeting from sensitive learner context;
- converting model inference into diagnosis, grade, mastery, credential, or authority;
- granting access merely because an actor has a descriptive role label.

## Migration classification change

Earlier archive-audit wording that could be read as `psychological profiles = do not port` is superseded by this more precise rule:

> **Uncontrolled psychological profiling is retired. Governed, consented, evidence-bound psychological insight is reinterpreted and rebuilt through the Personal Insight Vault.**

The legacy archive remains evidence about the old product. This clarification changes the migration decision, not the historical record of what the archive contained.
