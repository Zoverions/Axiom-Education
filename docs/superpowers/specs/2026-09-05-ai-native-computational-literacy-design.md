# AI-Native Computational Literacy — Cross-Cutting Competency Design

**Status:** approved design; implementation plan pending written-spec review  
**Date:** 2026-09-05  
**Repository:** `Zoverions/Axiom-Education`  
**Domain:** Axiom-authored cross-cutting competencies

## Purpose

Axiom Education needs a durable way to teach the reasoning skills that become more important as AI lowers the cost of producing code, text, analysis, designs, and other artifacts.

The target is not prompt engineering and not a standalone AI course. The target is a cross-cutting competency family that helps learners:

1. identify the real problem and desired outcome;
2. make requirements and constraints explicit;
3. determine whether an output is actually correct, sufficient, safe, or supported;
4. understand the system, dependencies, state, failure modes, and consequences involved.

The canonical four dimensions are:

**Intent → Specification → Verification → Systems Understanding**

They are Axiom-authored competencies, not jurisdictional curriculum. They may be crosswalked to official standards only through the existing reviewed evidence-bound curriculum-crosswalk machinery.

## Governing principles

1. **Cross-cutting, not standalone by default.** These competencies appear inside mathematics, science, writing, history, civics, software, projects, trades, research, and other contexts.
2. **Hybrid visibility.** The canonical structure is explicit and inspectable, while ordinary learner-facing language stays contextual and age-appropriate.
3. **Reasoning over output.** A high-quality artifact does not by itself prove learner competence.
4. **AI optional.** Every core competency must remain learnable and demonstrable without generative AI.
5. **Model output is not authority.** AI may tutor, critique, or propose observations but cannot independently create consequential mastery, grade, credit, credential, or learner-state authority.
6. **No second mastery engine.** Existing competency evidence states remain primary for this layer.
7. **No behavioural proxy scoring.** Prompt count, prompt length, response speed, retries, time-on-screen, engagement, and model-usage frequency are not competence evidence.
8. **Subject evidence remains separate.** Cross-cutting reasoning evidence does not silently change subject grade, credit, transcript, or curriculum-completion state.
9. **Minimal learner data.** Evidence references the relevant artifact or governed record rather than copying raw prompts, conversations, essays, code, or other sensitive content into the competency record by default.
10. **Revisable evidence.** Contradictory evidence, correction, retraction, and later revision remain visible rather than collapsing into a permanent ability label.

## Scope

This design introduces:

- one versioned Axiom-authored competency family;
- 18 initial competency nodes under four canonical dimensions;
- contextual subject/activity hooks;
- evidence-quality vocabulary describing independence, robustness, and transfer;
- verifier-method vocabulary;
- minimized AI-role vocabulary;
- two initial learning proofs: one deterministic/no-AI and one AI-optional;
- contextual learner presentation with optional canonical detail;
- fail-closed tests for authority, privacy, curriculum, and evidence boundaries.

This design does not:

- create an AI-literacy grade;
- create an aggregate learner AI score;
- claim validated psychometrics;
- claim official Ontario recognition;
- require a production model provider;
- make model use mandatory;
- promote any Mesh capability;
- create a new learner-record authority path;
- allow an AI tutor to assess its own authority;
- merge cross-cutting evidence into subject grades without a later explicit reviewed policy.

## Existing architecture reused

The design extends the current Education substrate rather than creating a parallel subsystem.

The existing `CompetencyGraph` already provides stable competency IDs, typed relationships, unique-ID validation, endpoint validation, prerequisite-cycle rejection, evidence states `unknown`, `attempted`, `emerging`, and `demonstrated`, and bounded entry-diagnostic planning from current evidence instead of age or grade placement.

The existing learning-evidence model already provides learner-subject binding, competency binding, consent-context binding, evidence references, corrections, retractions, explicit exclusion of clickstream/provider-account/advertising identifiers and raw conversation logs, and no claim that the local evidence object is itself an admitted Mesh learner event.

The existing model-routing and Socratic Tutor architecture already establishes governed eligibility before invocation, minimized usage receipts, model-output non-authority, fail-closed provider failure, deterministic fallback, and no provider/model activation by default.

The existing curriculum architecture already separates Axiom-authored competencies and experiences from official jurisdictional curriculum and requires reviewed evidence-bound crosswalks before official-coverage claims.

## Canonical authored pack

The first pack is identified by:

- schema: `axiom-education-authored-competency-pack.v1`;
- family ID: `axiom.education.competency.ai-native-computational-literacy`;
- family version: `1.0.0`;
- human-readable name: **AI-Native Computational Literacy**;
- authorship: `axiom-extension`;
- jurisdictional authority: `none`.

The human-readable family name may evolve in presentation. The family ID and competency IDs are durable identifiers and must not be changed merely for branding.

### Dimension 1: Intent

Initial nodes:

- `axiom:computational-literacy:intent:problem-framing`
- `axiom:computational-literacy:intent:goal-definition`
- `axiom:computational-literacy:intent:constraint-recognition`
- `axiom:computational-literacy:intent:non-goal-recognition`

Purpose:

- identify what problem is actually being solved;
- identify desired outcomes;
- identify stakeholders and relevant constraints;
- identify what should not happen or is intentionally out of scope.

### Dimension 2: Specification

Initial nodes:

- `axiom:computational-literacy:specification:requirements`
- `axiom:computational-literacy:specification:invariants`
- `axiom:computational-literacy:specification:examples-and-counterexamples`
- `axiom:computational-literacy:specification:edge-cases`

Purpose:

- translate intent into explicit requirements;
- define conditions that must remain true;
- provide examples and counterexamples that sharpen meaning;
- identify boundary and failure cases before construction.

### Dimension 3: Verification

Initial nodes:

- `axiom:computational-literacy:verification:method-selection`
- `axiom:computational-literacy:verification:test-design`
- `axiom:computational-literacy:verification:source-and-evidence-checking`
- `axiom:computational-literacy:verification:adversarial-checking`
- `axiom:computational-literacy:verification:correction-and-retest`

Purpose:

- choose an appropriate way to check a claim or artifact;
- design evidence rather than merely inspect appearance;
- compare claims with sources, measurements, deterministic tools, or other relevant evidence;
- deliberately search for failure or contradiction;
- revise and re-test after discovering an error.

### Dimension 4: Systems Understanding

Initial nodes:

- `axiom:computational-literacy:systems:components-and-boundaries`
- `axiom:computational-literacy:systems:state-and-flow`
- `axiom:computational-literacy:systems:dependencies-and-causality`
- `axiom:computational-literacy:systems:failure-modes`
- `axiom:computational-literacy:systems:tradeoffs-and-effects`

Purpose:

- identify components and trust/interface boundaries;
- understand changing state and information flow;
- reason about dependency and causality;
- anticipate failure modes;
- understand trade-offs, downstream consequences, and second-order effects.

## Graph semantics

The first pack uses the current `CompetencyGraph`; it does not introduce a second graph type.

Every node must carry exactly one family tag, one valid dimension tag, and the Axiom-extension authorship tag:

- `family:ai-native-computational-literacy`;
- one of `dimension:intent`, `dimension:specification`, `dimension:verification`, `dimension:systems`;
- `authorship:axiom-extension`.

The v1 pack intentionally contains **no prerequisite or support edges**. The current graph infrastructure remains available for later reviewed pack revisions, but this design does not invent dependency relationships before pedagogical evidence supports them.

The loader must fail closed on duplicate IDs, malformed IDs, unknown or multiple dimension tags, missing/wrong family tags, missing authorship tags, unsupported pack versions, and any future edge whose endpoint is absent or whose prerequisite relation introduces a cycle.

## Hybrid visibility model

The canonical competency vocabulary is machine-readable and available to educators, advanced learners, auditing tools, and detailed progress views.

Ordinary learner-facing experiences use contextual language.

Examples:

- Mathematics — canonical `...:verification:method-selection`; learner wording: **How could you check that this result must be correct?**
- Science — canonical `...:verification:adversarial-checking`; learner wording: **What observation would show that your explanation is wrong?**
- Writing — canonical `...:intent:goal-definition`; learner wording: **What exactly are you trying to make the reader understand or believe?**
- Programming — canonical `...:specification:invariants`; learner wording: **What must remain true even when the input is unusual?**
- Civics/history — canonical `...:systems:tradeoffs-and-effects`; learner wording: **Who is affected by this decision, and what happens next if the rule changes?**

An expandable detail view may expose the canonical structure, for example:

> Reasoning practiced: Verification → method selection

## Instructional model

### Subject learning remains primary

The learner should still experience a mathematics lesson as mathematics, a writing task as writing, and a science investigation as science. Cross-cutting competencies deepen the task rather than replace the subject.

A learning activity may declare that it `introduces`, `practices`, or `elicitsEvidenceFor` a cross-cutting competency. The same competency may have many subject-specific presentations.

### Three learning environments

Where appropriate, learners encounter the framework in three modes:

1. **Without AI** — demonstrate independent framing, specification, reasoning, and verification.
2. **With AI as a tool** — use a model to accelerate work while retaining judgment and responsibility.
3. **Against imperfect AI output** — inspect polished but incomplete, incorrect, misleading, or unsafe model output.

No core competency may require generative AI availability.

### Generate → interrogate → revise → verify

A representative AI-assisted task flow is:

1. learner frames intent;
2. learner states constraints and acceptance conditions;
3. model or other tool generates an artifact;
4. learner identifies assumptions and missing requirements;
5. learner selects or designs a verification method;
6. learner runs checks;
7. learner revises the specification or artifact;
8. learner re-tests;
9. learner explains why the final result is more trustworthy.

### Deterministic tools are first-class

Appropriate verification may use arithmetic checking, symbolic mathematics, compilers, linters, unit tests, schema validators, simulators, measurement instruments, source/provenance comparison, deterministic rule engines, or educator/expert review.

The pedagogical goal is not merely to receive verification. The learner should increasingly learn to choose the appropriate verifier.

### Socratic support should return agency

A model tutor may ask questions such as:

- What result are you trying to guarantee?
- Which requirement is unstated?
- How could this fail?
- What evidence would convince you?
- Can you construct an input that breaks the claim?
- Which component controls this behaviour?
- Is there a deterministic way to check it?

Support should reduce as the learner demonstrates stronger independent reasoning.

## Evidence model

### Existing evidence state remains primary

The family continues to use `unknown`, `attempted`, `emerging`, and `demonstrated`. These states are contextual and revisable. They are not permanent identity labels, grades, credits, or credentials.

No new numeric aggregate or parallel mastery engine is introduced.

### Evidence qualities

The bounded v1 vocabulary is:

- `recognized`;
- `supportedApplication`;
- `independentApplication`;
- `robustApplication`;
- `transferObserved`.

Evidence qualities describe why an observation is useful. They do not automatically compute or promote the competency state.

### Verifier methods

The bounded v1 vocabulary is:

- `learnerReasoning`;
- `deterministicCalculator`;
- `symbolicSolver`;
- `compilerOrTestRunner`;
- `experimentOrMeasurement`;
- `sourceOrProvenanceReview`;
- `educatorReview`;
- `peerReview`;
- `modelAssistedCritique`;
- `otherGovernedTool`.

These identify how the claim or artifact was checked. They do not confer authority on the verifier over the learner.

### AI role

The bounded v1 vocabulary is:

- `absent`;
- `optionalTool`;
- `generatedCandidate`;
- `critiqueAssistant`;
- `socraticTutor`.

This classification must not include raw prompt text or a behavioral transcript.

### Exact v0 representation

The first implementation uses a typed companion model named `CrossCuttingEvidenceMetadata` and does **not** add new fields to `CompetencyEvidence` or make `LearningEvidenceEnvelope` carry a second mastery state.

`CrossCuttingEvidenceMetadata` contains only:

- `evidenceId`;
- `qualities`;
- `verifierMethods`;
- `aiRole`;
- `observationSource`.

It is valid only when paired in the same in-memory evidence aggregate with an existing `LearningEvidenceEnvelope` whose `evidenceId` exactly matches. It must not be persisted, exported, or treated as an admitted Mesh learner event in the initial implementation slice.

The initial implementation may define a pure wrapper such as `CrossCuttingLearningEvidence` containing the existing base envelope plus this companion metadata. No separate evidence database, persistence route, or authority path is introduced.

Any future persistence/export design is a separate review boundary.

### Strong evidence from errors

The system may treat a correction sequence as useful evidence when the learner detects inconsistency, identifies the violated assumption or requirement, revises the solution/specification, and verifies the correction. A corrected failure may be stronger evidence than an unexplained first-attempt success.

## Activity hook model

The first implementation defines a pure `CrossCuttingCompetencyHook` with these fields:

- `competencyId`;
- `role`, one of `introduce`, `practice`, `elicitEvidence`;
- `learnerFacingPrompt`;
- `aiMode`, one of `absent`, `optional`, `partOfTask`;
- `verifierMethods`, using the bounded v1 verifier vocabulary;
- `hasNonGenerativePath`, boolean.

Validation rules:

- `competencyId` must exist in the loaded authored pack;
- `learnerFacingPrompt` must be non-empty;
- `verifierMethods` may be empty for `introduce` activities but must be non-empty for `elicitEvidence`;
- every core-competency `elicitEvidence` hook must have `hasNonGenerativePath == true`;
- `aiMode == partOfTask` does not waive the non-generative demonstration requirement; the activity may teach AI-specific use while a separate valid non-generative evidence path must exist for the same competency;
- a hook is educational metadata only and cannot create official curriculum coverage, learner evidence, authority, or persistence by itself.

## Privacy boundary

Competency evidence must not become a surveillance layer.

The system must not infer competence from prompt count, prompt length, response speed, retry count, session duration, clickstream, cursor/typing behavior, model-use frequency, or generic engagement signals.

Raw generated output, learner prompts, conversations, essays, programs, experiment notes, and other artifacts remain outside minimized competency evidence by default. Where evidence depends on an artifact, the base evidence envelope uses a governed reference.

The initial companion metadata contains no raw learner content.

## Authority boundary

### Model output

AI output may explain, ask Socratic questions, critique, suggest tests, propose an evidence observation, or recommend a human/deterministic review.

AI output may not independently create a final grade, credit, transcript status, credential, institutional eligibility, curriculum mutation, consent/policy change, consequential mastery judgment, or authoritative promotion to `demonstrated` solely from its own assertion.

### Cross-cutting versus subject evidence

Cross-cutting competency evidence and subject-outcome evidence remain independently represented.

A learner may solve a mathematics task incorrectly while demonstrating strong verification reasoning, or obtain the correct mathematics result while providing weak verification evidence. Neither fact silently rewrites the other.

Any future policy that joins these evidence classes must be explicit, reviewed, versioned, and independently testable.

## Initial implementation slices

### Phase A — executable competency foundation

Add:

- the versioned authored competency pack with exactly the 18 nodes above and no edges;
- loader/validator into the existing `CompetencyGraph`;
- evidence-quality enum;
- verifier-method enum;
- AI-role enum;
- `CrossCuttingEvidenceMetadata` and in-memory wrapper;
- `CrossCuttingCompetencyHook`;
- pure-model tests and malformed-fixture tests.

No new network, provider, learner-record, persistence, export, or Mesh authority is required.

### Phase B — deterministic/no-AI proof

Use one existing MTH1W deterministic practice path.

Representative flow:

1. learner solves a bounded problem;
2. learner predicts or chooses a verification method;
3. existing deterministic math verification checks the result;
4. learner compares prediction and result;
5. learner explains any discrepancy;
6. the UI may construct a local, non-persisted evidence proposal using the existing envelope plus cross-cutting metadata.

This phase proves that AI-native computational literacy does not depend on AI.

### Phase C — AI-optional proof

Use the governed Socratic Tutor surface only after its exact-head implementation is independently suitable for extension.

Representative flow:

1. tutor/model supplies or critiques a candidate explanation;
2. learner identifies what must be checked;
3. learner selects or constructs a verification method;
4. deterministic/reviewed fallback remains available;
5. model output remains instructional data;
6. no automatic learner-state authority is created.

This phase must preserve all existing tutor routing, budget, context-minimization, provider-failure, no-retry, and deterministic-fallback boundaries.

### Phase D — contextual learner visibility

Add a small contextual result/reflection component such as:

> How you checked it: substitution  
> Reasoning practiced: checking whether a result satisfies the requirement

An expanded view may show:

> Verification → method selection

Educator or advanced learner views may expose more canonical competency detail. This phase does not require a full navigation redesign.

## Capability status and claim boundary

The initial capability is registered as:

`instruction.cross-cutting-computational-literacy` — `experimental`

It may be promoted only when the repository's normal implementation requirements are met.

The capability must not claim validated psychometric measurement, improved learner outcomes merely from implementation, complete AI-literacy coverage, a universal/final competency taxonomy, official Ontario recognition, production provider availability, or consequential assessment authority.

## Acceptance and fail-closed tests

The implementation plan must include tests that reject at least:

1. duplicate competency IDs;
2. malformed competency IDs;
3. nonexistent graph-edge endpoints in any later pack revision;
4. prerequisite cycles in any later pack revision;
5. unknown, missing, or multiple family/dimension/authorship tags;
6. unsupported pack/schema versions;
7. activity references to unknown competencies;
8. an Axiom competency reference represented as official curriculum coverage without a reviewed crosswalk;
9. evidence for an unknown competency;
10. unsupported evidence-quality values;
11. unsupported verifier-method values;
12. unsupported AI-role values;
13. behavioral telemetry represented as competency evidence;
14. raw prompt or generated-response text copied into minimized cross-cutting metadata;
15. AI-generated feedback automatically promoting a competency state;
16. cross-cutting evidence automatically changing grade, credit, transcript, credential, or subject mastery;
17. provider absence making the core competency path unavailable;
18. contextual learner wording losing its canonical competency mapping;
19. correction or retraction losing base evidence lineage;
20. one successful interaction represented as permanent competence;
21. companion metadata existing without an exactly matching base evidence ID;
22. companion metadata persisted/exported in the initial slice;
23. an evidence-eliciting hook without a valid non-generative path;
24. model/provider failure being converted into synthetic educational success.

## Repository boundary

The first implementation belongs entirely in `Zoverions/Axiom-Education`.

Axiom Education owns competency taxonomy, pedagogy, contextual activity hooks, learner-facing presentation, and education-domain evidence semantics.

AXIOM-MESH continues to own, where applicable, identity, consent, policy, capability grants, governed execution, durable encrypted state, evidence transport/persistence boundaries, portability, and recovery.

No new Mesh primitive should be proposed merely because Education gains a new competency family. If implementation discovers a genuinely domain-neutral missing primitive, that becomes a separate upstream proposal with its own authority analysis.

## Design invariants

The implementation must preserve all of the following:

1. **Intent → Specification → Verification → Systems Understanding** is a cross-cutting Axiom-authored competency family.
2. The family is embedded contextually across subjects rather than taught as mandatory prompt engineering.
3. Evidence reflects reasoning, independence, robustness, and transfer rather than AI-usage behavior.
4. AI may assist learning and propose observations but cannot create consequential education authority.
5. Every core competency has at least one valid non-generative learning and evidence path.
6. Subject achievement and cross-cutting reasoning evidence remain separate unless an explicit reviewed policy joins them.
7. Existing competency evidence states remain primary; no second mastery engine is introduced.
8. Competency evidence remains minimal, consent-bound, correctable, retractable, and reference-oriented rather than transcript-oriented.
9. Official curriculum claims require the existing reviewed crosswalk path.
10. Any unavailable dependency, provider, consent, verifier, or authority must fail closed rather than creating synthetic success.

## Success criterion

The first successful implementation proves that Axiom Education can teach and evidence the same high-value reasoning pattern in both a deterministic subject task and an AI-assisted task while preserving existing curriculum, privacy, evidence, model-authority, and offline/non-AI boundaries.

The goal is not to teach learners how to make an AI produce an answer.

The goal is to teach learners how to express what must be true, use appropriate tools to construct or explore a solution, determine whether the result actually satisfies the problem, and understand the system well enough to challenge, repair, and transfer that reasoning elsewhere.
