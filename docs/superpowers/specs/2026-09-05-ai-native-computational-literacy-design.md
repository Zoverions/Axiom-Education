# AI-Native Computational Literacy — Cross-Cutting Competency Design

**Status:** approved design; implementation not yet authorized  
**Date:** 2026-09-05  
**Repository:** `Zoverions/Axiom-Education`  
**Domain:** Axiom-authored cross-cutting competencies  

## Purpose

Axiom Education needs a durable way to teach the reasoning skills that become more important as AI lowers the cost of producing code, text, analysis, designs, and other artifacts.

The target is not "prompt engineering" and not a standalone AI course. The target is a cross-cutting competency family that helps learners:

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
6. **No second mastery engine.** Existing competency evidence states remain authoritative for this layer.
7. **No behavioural proxy scoring.** Prompt count, prompt length, response speed, retries, time-on-screen, engagement, and model usage frequency are not competence evidence.
8. **Subject evidence remains separate.** Cross-cutting reasoning evidence does not silently change subject grade, credit, transcript, or curriculum-completion state.
9. **Minimal learner data.** Evidence references the relevant artifact or governed record rather than copying raw prompts, conversations, essays, code, or other sensitive content into the competency record by default.
10. **Revisable evidence.** Contradictory evidence, correction, retraction, and later revision remain visible rather than collapsing into a permanent ability label.

## Scope

This design introduces:

- one versioned Axiom-authored competency family;
- a small initial competency graph under the four canonical dimensions;
- contextual subject/activity hooks;
- evidence-quality vocabulary describing independence, robustness, and transfer;
- verifier-method vocabulary;
- two initial learning proofs: one deterministic/no-AI and one AI-optional;
- learner-facing contextual presentation and optional canonical detail;
- fail-closed tests for authority, privacy, curriculum, and evidence boundaries.

This design does not:

- create an AI-literacy grade;
- create an aggregate learner "AI score";
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

The existing `CompetencyGraph` already provides:

- stable competency IDs;
- typed `prerequisite`, `supports`, `part-of`, and `extends` relationships;
- unique-ID validation;
- endpoint validation;
- prerequisite-cycle rejection;
- evidence states `unknown`, `attempted`, `emerging`, and `demonstrated`;
- bounded entry-diagnostic planning from current evidence instead of age or grade placement.

The existing learning-evidence model already provides:

- learner-subject binding;
- competency binding;
- consent-context binding;
- evidence references;
- corrections;
- retractions;
- explicit exclusion of clickstream, provider-account identifiers, advertising identifiers, and raw conversation logs;
- no claim that the local evidence object is itself an admitted Mesh learner event.

The existing model-routing and Socratic Tutor architecture already establishes that:

- model routing must pass governed eligibility before invocation;
- raw learner prompt/response content is excluded from minimized usage receipts by default;
- model output is instructional data, not authority;
- model failure must not synthesize success;
- deterministic reviewed fallback remains available;
- no provider or model is activated by default.

The existing curriculum architecture already separates Axiom-authored competencies and experiences from official jurisdictional curriculum and requires evidence-bound crosswalks before official-coverage claims.

## Canonical competency family

### Family identifier

The first pack should use a stable Axiom namespace, for example:

`axiom.competency.ai-native-computational-literacy.v1`

The human-readable family name is:

**AI-Native Computational Literacy**

The family name may evolve in presentation without changing durable competency IDs unnecessarily.

### Dimension 1: Intent

Initial nodes:

- `intent.problem-framing`
- `intent.goal-definition`
- `intent.constraint-recognition`
- `intent.non-goal-recognition`

Purpose:

- identify what problem is actually being solved;
- identify desired outcomes;
- identify stakeholders and relevant constraints;
- identify what should not happen or is intentionally out of scope.

### Dimension 2: Specification

Initial nodes:

- `specification.requirements`
- `specification.invariants`
- `specification.examples-and-counterexamples`
- `specification.edge-cases`

Purpose:

- translate intent into explicit requirements;
- define conditions that must remain true;
- provide examples and counterexamples that sharpen meaning;
- identify boundary and failure cases before construction.

### Dimension 3: Verification

Initial nodes:

- `verification.method-selection`
- `verification.test-design`
- `verification.source-and-evidence-checking`
- `verification.adversarial-checking`
- `verification.correction-and-retest`

Purpose:

- choose an appropriate way to check a claim or artifact;
- design evidence rather than merely inspect appearance;
- compare claims with sources, measurements, deterministic tools, or other relevant evidence;
- deliberately search for failure or contradiction;
- revise and re-test after discovering an error.

### Dimension 4: Systems Understanding

Initial nodes:

- `systems.components-and-boundaries`
- `systems.state-and-flow`
- `systems.dependencies-and-causality`
- `systems.failure-modes`
- `systems.tradeoffs-and-effects`

Purpose:

- identify components and trust/interface boundaries;
- understand changing state and information flow;
- reason about dependency and causality;
- anticipate failure modes;
- understand trade-offs, downstream consequences, and second-order effects.

## Graph semantics

The first pack should use the current `CompetencyGraph` instead of introducing a new graph type.

Every node must include tags sufficient to establish family and dimension, for example:

- `family:ai-native-computational-literacy`
- `dimension:intent`
- `authorship:axiom-extension`

The loader must fail closed on:

- duplicate IDs;
- unknown dimension tags;
- missing family tag;
- edge endpoints that do not exist;
- prerequisite cycles;
- malformed or unsupported authored-pack metadata.

The initial implementation should avoid speculative dense prerequisite edges. Only relationships that are pedagogically clear enough to survive review should be encoded. `supports` is preferred where dependency is useful but not strictly required. `prerequisite` should mean the target is not sensibly assessable without the source competency.

## Hybrid visibility model

The canonical competency vocabulary is machine-readable and available to educators, advanced learners, auditing tools, and detailed progress views.

Ordinary learner-facing experiences should use contextual language.

Examples:

### Mathematics

Canonical competency:

`verification.method-selection`

Learner-facing wording:

> How could you check that this result must be correct?

### Science

Canonical competency:

`verification.adversarial-checking`

Learner-facing wording:

> What observation would show that your explanation is wrong?

### Writing

Canonical competency:

`intent.goal-definition`

Learner-facing wording:

> What exactly are you trying to make the reader understand or believe?

### Programming

Canonical competency:

`specification.invariants`

Learner-facing wording:

> What must remain true even when the input is unusual?

### Civics or history

Canonical competency:

`systems.tradeoffs-and-effects`

Learner-facing wording:

> Who is affected by this decision, and what happens next if the rule changes?

The interface may expose the canonical label in an expandable detail view such as:

> Reasoning practiced: Verification → method selection

This preserves transparency without turning every lesson into framework jargon.

## Instructional model

### Subject learning remains primary

The learner should still experience a mathematics lesson as mathematics, a writing task as writing, and a science investigation as science.

Cross-cutting competencies deepen the task rather than replace the subject.

A learning resource or activity may declare which cross-cutting competencies it:

- introduces;
- practices;
- or intends to elicit evidence for.

The same competency may have many subject-specific presentations.

### Three learning environments

Where appropriate, learners should encounter the framework in three modes:

1. **Without AI** — demonstrate independent framing, specification, reasoning, and verification.
2. **With AI as a tool** — use a model to accelerate work while retaining judgment and responsibility.
3. **Against imperfect AI output** — inspect polished but incomplete, incorrect, misleading, or unsafe model output.

No core competency may require generative AI availability.

### Generate → interrogate → revise → verify

Generated artifacts should become objects for reasoning rather than endpoints.

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

Depending on domain, appropriate verification may use:

- arithmetic checking;
- symbolic mathematics;
- compilers;
- linters;
- unit tests;
- schema validators;
- simulators;
- measurement instruments;
- source/provenance comparison;
- deterministic rule engines;
- educator or expert review.

The pedagogical goal is not merely to receive a verification result. The learner should increasingly learn to choose the appropriate verifier.

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

The competency family continues to use:

- `unknown`;
- `attempted`;
- `emerging`;
- `demonstrated`.

These states are contextual and revisable. They are not permanent identity labels, grades, credits, or credentials.

No new numeric aggregate or parallel mastery engine is introduced.

### Evidence qualities

The following bounded vocabulary describes the character of an observation:

- `recognized`
- `supportedApplication`
- `independentApplication`
- `robustApplication`
- `transferObserved`

These values answer questions such as:

- Was the learner merely recognizing the pattern?
- Did the learner require scaffolding?
- Did the learner invoke the reasoning independently?
- Did the reasoning survive ambiguity, edge cases, or misleading output?
- Did the learner transfer the same reasoning to a different context?

Evidence qualities do **not** automatically compute the competency state.

### Evidence-quality representation

The preferred v0 design is a small typed companion object associated with a `LearningEvidenceEnvelope`, rather than changing the core evidence-state semantics or creating a second learner-state authority.

Conceptually:

```text
LearningEvidenceEnvelope
  evidenceId
  learnerSubjectId
  competencyId
  consentContextId
  evidenceRef
  ...

CrossCuttingEvidenceMetadata
  evidenceId
  qualities[]
  verifierMethods[]
  aiRole
  observationSource
```

The companion must bind to an existing evidence ID and must not exist as an independent mastery record.

A later implementation plan may decide whether this is represented as a field extension, companion model, or separately versioned schema, but the authority semantics are fixed by this design.

### Verifier-method vocabulary

Initial verifier types:

- `learnerReasoning`
- `deterministicCalculator`
- `symbolicSolver`
- `compilerOrTestRunner`
- `experimentOrMeasurement`
- `sourceOrProvenanceReview`
- `educatorReview`
- `peerReview`
- `modelAssistedCritique`
- `otherGovernedTool`

These identify *how the claim or artifact was checked*, not who deserves authority over the learner.

### AI role vocabulary

When AI participated, evidence may record only a minimized role classification such as:

- `absent`
- `optionalTool`
- `generatedCandidate`
- `critiqueAssistant`
- `socraticTutor`

This must not include raw prompt text or a detailed behavioral transcript.

### Strong evidence from errors

The system should allow an error-recovery sequence to provide useful evidence:

1. learner makes a plausible mistake;
2. learner detects inconsistency;
3. learner identifies the violated assumption or requirement;
4. learner revises the solution or specification;
5. learner verifies the correction.

A corrected failure may provide stronger evidence than an unexplained first-attempt success.

## Activity hook model

A bounded `CrossCuttingCompetencyHook` should allow selected activities to declare:

- competency ID;
- role: `introduce`, `practice`, or `elicitEvidence`;
- contextual learner-facing prompt or label;
- AI mode: `absent`, `optional`, or `partOfTask`;
- permitted/expected verifier-method classes;
- whether the activity has a valid non-generative path.

The hook is educational metadata. It does not create curriculum status, learner evidence, authority, or persistence by itself.

Any activity referencing an unknown competency must fail validation.

Any activity claiming official-curriculum coverage solely because it references an Axiom-authored competency must fail validation.

## Privacy boundary

Competency evidence must not become a surveillance layer.

The system must not infer competence from:

- prompt count;
- prompt length;
- response speed;
- retry count;
- session duration;
- clickstream;
- cursor or typing behavior;
- model-use frequency;
- generic engagement signals.

Raw generated output, learner prompts, conversations, essays, programs, experiment notes, and other artifacts stay outside the minimized competency evidence by default.

Where evidence depends on an artifact, the evidence record should use a governed reference.

Evidence metadata must preserve the existing subject, purpose, scope, consent, correction, retraction, and visibility rules.

## Authority boundary

### Model output

AI output may:

- explain;
- ask Socratic questions;
- critique;
- suggest tests;
- propose an evidence observation;
- recommend that a human or deterministic tool review something.

AI output may not independently:

- create a final grade;
- create credit;
- create transcript status;
- issue a credential;
- create institutional eligibility;
- mutate curriculum;
- change consent or policy;
- create a consequential mastery judgment;
- promote a cross-cutting competency to authoritative `demonstrated` state solely from its own assertion.

### Cross-cutting versus subject evidence

Cross-cutting competency evidence and subject-outcome evidence remain independently represented.

A learner may:

- solve a mathematics task incorrectly while demonstrating strong verification reasoning; or
- obtain the correct mathematics result while providing weak verification evidence.

Neither fact silently rewrites the other.

Any future policy that joins these evidence classes must be explicit, reviewed, versioned, and independently testable.

## Initial implementation slices

### Phase A — executable competency foundation

Add:

- versioned authored competency-pack data;
- loader and validator into the existing `CompetencyGraph`;
- the 18 initial competency nodes;
- conservative graph relationships;
- evidence-quality vocabulary;
- verifier-method vocabulary;
- AI-role vocabulary;
- activity-hook model;
- pure-model tests and malformed-fixture tests.

No new network, provider, learner-record, or Mesh authority is required.

### Phase B — deterministic/no-AI proof

Use one existing MTH1W learning/practice path.

Representative flow:

1. learner solves a bounded problem;
2. learner predicts or chooses a verification method;
3. existing deterministic math verification checks the result;
4. learner compares prediction and result;
5. learner explains any discrepancy;
6. the activity can emit a minimized evidence proposal bound to the relevant cross-cutting competency.

This phase proves that AI-native computational literacy does not depend on AI.

### Phase C — AI-optional proof

Use the governed Socratic Tutor surface once its exact-head implementation state is suitable for extension.

Representative flow:

1. tutor/model supplies or critiques a candidate explanation;
2. learner identifies what must be checked;
3. learner selects or constructs a verification method;
4. deterministic or reviewed fallback remains available;
5. model output remains instructional data;
6. no automatic learner-state authority is created.

The implementation must preserve all existing tutor routing, budget, context-minimization, provider-failure, no-retry, and deterministic-fallback boundaries.

### Phase D — contextual learner visibility

Add a small contextual result/reflection surface such as:

> How you checked it: substitution  
> Reasoning practiced: checking whether a result satisfies the requirement

An expanded view may show:

> Verification → method selection

Educator or advanced learner views may expose more canonical competency detail.

This phase should not require a full application navigation redesign.

## Capability status and claim boundary

The initial capability should be registered with a status such as:

`instruction.cross-cutting-computational-literacy` — `experimental`

It may be promoted only when the repository's normal implementation requirements are met.

The capability must not claim:

- validated psychometric measurement;
- improved learner outcomes merely from implementation;
- complete AI-literacy coverage;
- universal or final competency taxonomy;
- official Ontario recognition;
- production provider availability;
- consequential assessment authority.

## Acceptance and fail-closed tests

The implementation plan must include tests that reject at least:

1. duplicate competency IDs;
2. nonexistent graph-edge endpoints;
3. prerequisite cycles;
4. unknown or missing family/dimension tags;
5. activity references to unknown competencies;
6. an Axiom competency reference represented as official curriculum coverage without a reviewed crosswalk;
7. evidence for an unknown competency;
8. unsupported evidence-quality values;
9. unsupported verifier-method values;
10. behavioral telemetry represented as competency evidence;
11. raw prompt or generated-response text copied into minimized evidence metadata;
12. AI-generated feedback automatically promoting a competency state;
13. cross-cutting evidence automatically changing grade, credit, transcript, credential, or subject mastery;
14. provider absence making the core competency path unavailable;
15. contextual learner wording losing its canonical competency mapping;
16. correction or retraction losing evidence lineage;
17. one successful interaction represented as permanent competence;
18. a companion evidence-metadata record existing without its bound base evidence ID;
19. an AI-only activity claiming to be a valid core demonstration path when no non-generative alternative exists;
20. model or provider failure being converted into synthetic educational success.

## Repository boundary

The first implementation belongs entirely in `Zoverions/Axiom-Education`.

Axiom Education owns:

- competency taxonomy;
- pedagogy;
- contextual activity hooks;
- learner-facing presentation;
- education-domain evidence semantics.

AXIOM-MESH continues to own, where applicable:

- identity;
- consent;
- policy;
- capability grants;
- governed execution;
- durable encrypted state;
- evidence transport/persistence boundaries;
- portability and recovery.

No new Mesh primitive should be proposed merely because Education gains a new competency family. If implementation discovers a genuinely domain-neutral missing primitive, that should be proposed upstream separately with its own authority analysis.

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

The first successful implementation should prove that Axiom Education can teach and evidence the same high-value reasoning pattern in both a deterministic subject task and an AI-assisted task while preserving the existing curriculum, privacy, evidence, model-authority, and offline/non-AI boundaries.

The goal is not to teach learners how to make an AI produce an answer.

The goal is to teach learners how to express what must be true, use appropriate tools to construct or explore a solution, determine whether the result actually satisfies the problem, and understand the system well enough to challenge, repair, and transfer that reasoning elsewhere.
