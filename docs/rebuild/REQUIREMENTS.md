# Axiom Education Rebuild Requirements

**Current build:** `0.5.0-dev.0`  
**Updated:** 2026-08-01

The machine-readable status in `config/capabilities.json` is authoritative. A missing dependency, provider, permission, consent, source, verifier, or model artifact must produce an explicit unavailable or denied result, never synthetic success.

## Architecture and AXIOM integration

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-ARCH-01 | Axiom Education MUST remain independently releasable and MUST NOT become part of the AXIOM trusted kernel. | Repository and dependency-boundary tests. |
| EDU-ARCH-02 | Governed learner-data and externally visible effects MUST follow Axiom Education UI → AXIOM Gateway → Hypervisor → Sandbox → Grid. | End-to-end bypass rejection tests. |
| EDU-ARCH-03 | Flutter presentation, pure education-domain logic, and provider implementations MUST be separate packages or modules. | Import-boundary tests and domain-only test command. |
| EDU-ARCH-04 | Interfaces MUST be versioned and incompatible capsule, curriculum, provider, or record schemas MUST fail closed. | Compatibility fixtures. |
| EDU-ARCH-05 | Development adapters and mocks MUST be impossible to select in release or governed builds. | Build-mode negative tests. |
| EDU-ARCH-06 | Current product, repository, contract, package, and branch identifiers MUST be declared; deprecated identifiers MUST be documented and MUST NOT be used as current claim authority. | Documentation parity and repository migration checks. |

## Curriculum and provenance

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-CUR-01 | Every curriculum record MUST identify jurisdiction, authority, official-or-extension status, source, source digest, publication/effective dates when known, ingestion date, parser version, licence, review state, content digest, and supersession. | Schema and fixture validation. |
| EDU-CUR-02 | Official jurisdictional curriculum, Axiom Education extensions, and third-party OER MUST use separate namespaces. | Collision and presentation tests. |
| EDU-CUR-03 | Curriculum builds MUST be reproducible from pinned inputs and tools. | Two clean builds produce identical manifest and record digests. |
| EDU-CUR-04 | Curriculum activation MUST require a valid signed manifest and MUST preserve the prior active pack for rollback. | Tamper, signer, downgrade, activation, and rollback tests. |
| EDU-CUR-05 | Retrieval indexes MUST be disposable derived artifacts and MUST NOT replace authoritative curriculum records. | Rebuild and corruption tests. |
| EDU-CUR-06 | Custom course codes MUST be visibly marked as Axiom Education extensions and MUST NOT imply jurisdictional authority recognition. | UI and export snapshot tests. |
| EDU-CUR-07 | A known conflict between a local curriculum record and an official source MUST block course-complete, curriculum-aligned, credit, grade, transcript, approval, and school-equivalency claims until the full source and review gates pass. | `config/curriculum-readiness.json`, source audit, fail-closed checker, and student-facing boundary tests. |

## High-school instructional core

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-CORE-01 | Every supported course MUST remain teachable and practicable when tutor, adaptive, network, and learner-record capabilities are unavailable. | Provider-absence end-to-end course test. |
| EDU-CORE-02 | The student surface MUST organize curriculum into a visible course → unit → lesson → practice → assessment sequence rather than exposing an expectation database as the complete learning experience. | Navigation and course-completion tests. |
| EDU-CORE-03 | Every lesson MUST identify its curriculum binding, learning goals, prerequisite knowledge, direct instruction, at least one worked example, at least two valid reasoning routes and connected representations where the subject permits them, independent practice, and expected scope. | Lesson-contract validation and UI tests. |
| EDU-CORE-04 | Instruction MUST move from modelling to graduated support to independent work; generated exercises alone MUST NOT be represented as a complete lesson. | Content review and lesson-state tests. |
| EDU-CORE-05 | Deterministic feedback MUST address the task or answer, allow another attempt, and MUST NOT turn an isolated response into a grade, mastery claim, diagnosis, or ability label. | Feedback, retry, and prohibited-claim tests. |
| EDU-CORE-06 | Supported courses MUST provide conventional lesson checks, quizzes, unit assessments, cumulative review, transparent scoring rules, and educator-correctable outcomes. | Assessment lifecycle and correction tests. |
| EDU-CORE-07 | Learners MUST be able to plan, monitor, explain, and reflect within subject lessons without covert attention, emotion, disability, motivation, or diagnosis inference. | UI prompts, schema gates, and prohibited-inference tests. |
| EDU-CORE-08 | High-school interfaces MUST use age-respectful language, clear structure, meaningful choice, and accessible alternatives without manipulative streaks, artificial urgency, or unvalidated competitive ranking. | Content review, accessibility audit, and dark-pattern gate. |
| EDU-CORE-09 | Educators MUST be able to assign, inspect, correct, accommodate, return, and review governed student work before the product claims a complete school workflow. | Educator end-to-end workflow and rights tests. |

## Tutor and deterministic verification

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-AI-01 | A tutor response MUST identify the provider, model artifact digest, prompt-contract version, curriculum pack digest, source expectation IDs, and verifier state. | Response-schema tests. |
| EDU-AI-02 | Missing or failed model providers MUST return `capability_unavailable`; placeholder or simulated text MUST NOT be returned as a tutor answer. | Provider-absence and inference-failure tests. |
| EDU-AI-03 | Deterministically solvable mathematics and science claims MUST be checked by an approved tool before being represented as verified. | Correct, incorrect, timeout, and unavailable verifier tests. |
| EDU-AI-04 | Model output MUST be treated as untrusted content and MUST NOT directly mutate learner records, policy, consent, credentials, curriculum, or assessment results. | Injection and direct-effect rejection tests. |
| EDU-AI-05 | Generation MUST have bounded input, context, output, time, memory, cancellation, and retry budgets. | Resource-exhaustion and cancellation tests. |
| EDU-AI-06 | Cached outputs MUST bind curriculum, provider, model, policy, consent, learner-context, and verifier versions. | Cache invalidation tests. |

## Learner data and consent

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-DATA-01 | Learner records MUST be encrypted at rest and separated by owner. | Storage inspection, wrong-key, and cross-owner tests. |
| EDU-DATA-02 | Every read or mutation MUST be purpose-, scope-, controller-, subject-, expiry-, and revocation-bound. | Consent negative-path suite. |
| EDU-DATA-03 | Raw canvas images, audio, camera data, and detailed strokes MUST be ephemeral by default and retained only under explicit scoped consent. | Retention and deletion tests. |
| EDU-DATA-04 | The system MUST NOT infer diagnosis, disability, emotion, protected traits, or sentience from ordinary interaction traces. | Schema, model-output, and terminology gates. |
| EDU-DATA-05 | Learners or authorized guardians MUST be able to inspect, correct, appeal, revoke, and selectively export supported records. | End-to-end rights workflow. |
| EDU-DATA-06 | Logs and evidence MUST exclude raw prompts, raw student work, credentials, and other sensitive content by default. | Redaction tests. |

## Assessment and adaptation

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-ASMT-01 | Existing mock IRT values MUST be labelled heuristics and MUST NOT be presented as calibrated psychometrics. | Schema and UI tests. |
| EDU-ASMT-02 | Assessment generation MUST bind exact curriculum expectations, difficulty source, generator version, answer contract, and verifier. | Generation fixtures. |
| EDU-ASMT-03 | Automated assessment results MUST preserve uncertainty and permit human review and appeal. | Review lifecycle tests. |
| EDU-ASMT-04 | Calibrated IRT MUST remain disabled until a named model, representative dataset, uncertainty analysis, differential-item-functioning review, and versioned calibration evidence exist. | Capability status and release gate. |
| EDU-ASMT-05 | Accommodations MUST be explicit learner or educator settings and MUST NOT be silently inferred from mistakes or response speed. | Adaptation policy tests. |

## Canvas and input safety

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-IN-01 | Image bytes, decoded dimensions, pixel count, frame count, and processing time MUST be bounded before expensive processing. | Decompression-bomb and oversized-input tests. |
| EDU-IN-02 | One production Watcher implementation MUST exist behind one interface; duplicate implementations MUST be removed. | Import and source-duplication gate. |
| EDU-IN-03 | Classifier outputs MUST include confidence and label-map version and MUST NOT be represented as parsed mathematics without a grammar or verifier. | Output-schema and false-positive tests. |
| EDU-IN-04 | Stylus, keyboard, touch, and accessible alternatives MUST be supported for required learning actions. | Accessibility interaction tests. |

## Classroom synchronization

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-SYNC-01 | The legacy UDP/TCP mesh MUST be disabled in governed and release builds until its transport and authority requirements are met. | Build-mode and startup tests. |
| EDU-SYNC-02 | Classroom participants MUST use admitted, expiring, revocable node identities rather than a shared classroom secret as the sole trust root. | Wrong-key, copied-key, expiry, and quarantine tests. |
| EDU-SYNC-03 | Updates MUST be signed, replay-resistant, owner-bound, causally ordered, conflict-visible, and bounded. | Replay, equivocation, partition, and conflict tests. |
| EDU-SYNC-04 | Receiving a classroom bundle MUST NOT automatically authorize application to learner records. | Destination approval and consent tests. |
| EDU-SYNC-05 | Network failure MUST produce an explicit offline or degraded state and MUST NOT simulate successful global connectivity. | Failure-injection tests. |

## Accessibility, safety, and operations

| ID | Requirement | Acceptance evidence |
|---|---|---|
| EDU-OPS-01 | Release interfaces MUST support keyboard operation, screen readers, text scaling, contrast, reduced motion, focus visibility, and accessible exports. | Automated and manual accessibility report. |
| EDU-OPS-02 | One documented clean-setup command MUST install exact dependencies with scripts controlled and run the full verification suite. | `python tools/verify.py` and protected clean-checkout CI. |
| EDU-OPS-03 | Releases MUST include SBOM, provenance, curriculum manifest, model/provider inventory, migration and rollback plan, status registry, and evidence timestamps. | Release verifier. |
| EDU-OPS-04 | Secrets, model binaries, generated indexes, databases containing learner data, caches, and build artifacts MUST NOT be tracked. | Repository hygiene gate. |
| EDU-OPS-05 | Security, privacy, curriculum, accessibility, recovery, and model-evaluation findings MUST be tied to an owner and disposition. | Findings-ledger verifier. |
| EDU-OPS-06 | Public claims MUST be generated or checked against `config/capabilities.json`. | Documentation parity test. |
| EDU-OPS-07 | `main` MUST be the default branch and repository automation MUST NOT target a retired feature branch. | GitHub settings and protected workflow inspection. |
