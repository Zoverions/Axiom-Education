# C.L.A.W. legacy authoring → Claw v2 crosswalk

Status: design migration note. This maps the recovered legacy Story Builder / branching narrative / comic authoring ideas onto the current Claw experience graph. It does **not** port the old React runtime or database model.

## Why preserve this part

The recovered archive contains a fairly mature authoring concept:

- micro-stories inside one comic zone;
- page-level branching stories;
- multi-page epics with persistent story state;
- visual node/edge editing;
- node reachability/dead-end validation;
- choice conditions;
- templates;
- import/export;
- comic page/panel/hotspot editing.

That work is useful because current Claw already has a governed graph runtime. The old editor can become a **frontend idea for authoring the new graph** instead of a competing runtime.

## Core graph crosswalk

| Legacy authoring concept | Claw v2 target | Migration rule |
| --- | --- | --- |
| Story `id` / version | `graphId` / `graphVersion` | Version explicitly; do not overwrite historical graph identity |
| Start node | `entryNodeId` | Must resolve to an existing node |
| Scenario/scene node | `story-panel`, `comic-panel`, `learner-choice`, explanation or other valid node type | Choose node type by instructional function, not visual colour |
| Ending node | terminal graph node / reflection / transfer node | “Ending” does not imply educational success/failure |
| Choice edge | `ClawExperienceTransition` | Trigger must be explicit; target changes require governed reason |
| Choice condition | `conditionTag` plus future typed authoring condition | Conditions cannot bypass readiness/privacy/accessibility policy |
| “Another way” route | `learner-requests-another-way` | Must preserve target competencies |
| Help route | `learner-requests-human-help` | Availability explicit; no scarce token requirement |
| Resource/model/tool failure | `resource-unavailable`, `model-unavailable`, `tool-unavailable` | Author must define valid fallback where applicable |
| Accessibility fallback | `accessibility-unavailable` + fallback node | Equivalent curriculum target; not inferior/premium curriculum |
| Story variable | separate local narrative-state model | Never silently becomes learner evidence or a psychological trait |
| Path history | local learner-controlled story-state history | Not official learner record/mastery by default |
| Reflection prompt | `reflection-prompt` / `metacognition-prompt` | Reflection is not automatically evidence of mastery |
| Assessment/check | `retrieval-checkpoint`, `direct-response`, `evidence-candidate`, `transfer-challenge` | Must declare `expectedEvidenceKinds` and use current evidence boundary |
| Embedded game | `game-launch` / `simulation-launch` / build nodes | Educational purpose and fallback required |

## Legacy node types should not be copied literally

The old editor primarily differentiated `scene` and `ending`. Current Claw should expose the richer governed node vocabulary already in the runtime, including:

- story/comic;
- explanation/visual/worked example;
- learner choice/direct response/hint;
- resource/video/simulation/game;
- code/build/creative construction;
- real-world, peer/group and human-help tasks;
- AI Socratic dialogue;
- reflection/metacognition/retrieval/transfer/project/evidence nodes.

The authoring interface can group these into friendly palettes without collapsing their semantic differences in the exported graph.

## Story state versus learner evidence

The old branching system used variables such as:

- Trust
- Courage
- Wisdom
- empathy-like scores

and templates built around “high/low” variable gates.

These can be useful **fictional world-state variables** in some stories, but they must not be interpreted as stable traits of the learner.

Safe example:

```text
team_trust_in_story = 4
```

means the current fictional story state changed after a choice.

It does **not** mean:

```text
learner.trustworthiness = 4
learner.empathy = 72
learner.courage = low
```

A future authoring package should type story variables separately from all learner-evidence objects so the two cannot be confused accidentally.

## Remove positive/negative morality colouring from graph semantics

The legacy Story Builder colour-coded edges/ending types as positive, negative, neutral or mixed and included templates such as `Honest choice -> Good ending` versus `Dishonest choice -> Bad ending`.

Current authoring should instead support labels such as:

- consequence;
- trade-off;
- evidence-supported/unsupported where objectively warranted;
- safe/unsafe where a real safety rule applies;
- constructive alternatives;
- unresolved/uncertain;
- reflection-required.

A story can still depict harmful decisions and consequences. The authoring model simply should not force every social/ethical scenario into a one-dimensional morality score.

## Validation to preserve and strengthen

The legacy editor's strongest validation ideas should survive:

- start node exists;
- all referenced nodes exist;
- all intended nodes are reachable;
- no accidental dead ends;
- at least one legitimate completion/exit route;
- conditions reference known variables/state;
- unused variables produce warnings;
- duplicate IDs rejected.

Current Claw adds stronger validation:

- every node has target competency IDs;
- every node declares instructional strategies;
- evidence-producing nodes declare expected evidence;
- fallbacks reference valid nodes;
- alternate-presentation/failure fallbacks preserve competency;
- competency changes require explicit governed reasons;
- AI dialogue has a non-model fallback;
- device/accessibility/readiness constraints are explicit;
- availability filtering occurs before transition selection;
- authoring cannot promote grade/credit/credential/authority claims.

## Authoring package proposal

A future editor should export a reviewable package rather than mutate production state directly.

Conceptual package:

```text
claw_authoring_package
  manifest
    package_id
    version
    author/source provenance
    target graph contract version
    content assurance state
  graph
    ClawExperienceGraph
  presentations
    base presentations
    optional presentation-preset variants
  narrative_state_schema
    local fictional variables only
  media_refs
    content-addressed/versioned assets
    accessibility alternatives
  source_refs
    curriculum/resource/evidence provenance where applicable
  validation_report
  review/admission evidence
```

The package should move through current review/admission governance before becoming an official learner-facing experience.

## Comic authoring crosswalk

The archive's page/panel/polygon/hotspot tooling can become a renderer-specific authoring layer.

A hotspot should bind to an explicit action such as:

- reveal explanation;
- select evidence;
- make learner choice;
- open another representation;
- launch simulation/game;
- navigate to another story node.

Requirements:

- every meaningful hotspot has keyboard/switch/non-visual equivalent interaction;
- illustrated text is not the only accessible copy;
- polygon geometry is presentation data, never learning evidence;
- hotspot clicks/hover time are not mastery by default;
- unavailable media has a valid fallback representation.

## Generated-media integration

The old prompt-generator ideas can survive only under current generated-media boundaries:

```text
approved character spec + graph node + instructional intent
 -> structured scene plan
 -> readiness/accessibility/privacy checks
 -> renderer/model selection
 -> derivative media
 -> review/admission state
```

A model-generated image cannot establish a new canonical character fact, curriculum claim, or evidence rule.

## Recommended future implementation slices

1. define a JSON authoring-package contract around the existing Claw graph;
2. add a pure validator/importer with no UI;
3. add a simple node/edge editor against that contract;
4. add reachability/fallback/competency-boundary visualization;
5. add story-local variable schema;
6. add comic panel/hotspot authoring with accessible equivalent actions;
7. add versioned import/export and review/admission workflow;
8. only then consider richer generated-media authoring.

This approach preserves the old project's strongest creator tooling while making the **current governed Claw graph the only executable authority**.
