# Curriculum and competency crosswalks

Axiom Education keeps **official jurisdictional standards** separate from **Axiom-authored competencies, pedagogy, missions, projects, and experience-layer goals**.

A crosswalk is derived metadata connecting those two layers. It is never part of the official curriculum record itself.

## Why a separate crosswalk layer

An activity can support critical thinking, systems thinking, collaboration, coding, ethical reasoning, numeracy, or another competency without automatically satisfying an Ontario expectation.

Likewise, an experience provider, CLAW mission, project, lesson, or assessment must not claim official curriculum coverage merely because someone can describe a plausible relationship.

The crosswalk therefore records the relationship explicitly and binds it to exact current curriculum evidence.

## Contract

Crosswalks use:

`schemas/curriculum-crosswalk.v1.schema.json`

Each mapping binds:

- a competency ID in a named source competency namespace;
- one canonical `axiom-curriculum-standard-record.v2` target;
- the target record ID and official expectation ID;
- the exact target `content_digest`;
- a relationship type;
- a coverage level;
- a rationale;
- review evidence references;
- human review status and findings.

Supported relationship types are:

- `equivalent` — the competency and official standard are judged equivalent for the bounded mapping scope;
- `supports` — the competency helps develop the official standard but is not equivalent;
- `partial` — only part of the official standard is addressed;
- `prerequisite` — the competency is useful or required before the official standard;
- `contextual` — the competency provides a context or application without itself constituting the official standard.

Coverage levels are deliberately separate:

- `none`;
- `supporting`;
- `direct`.

## Direct coverage is review-gated

A proposed or unreviewed mapping may never claim `direct` official coverage.

`direct` requires all of the following:

1. the exact current target curriculum record is content-addressed and valid;
2. the relationship is `equivalent`;
3. qualified human review status is `approved`;
4. review evidence references are present;
5. there are no open findings;
6. no major or critical finding remains unresolved.

If the target curriculum record changes, its content digest changes and the earlier mapping becomes stale.

## Crosswalk-wide non-claims

Even an individually approved direct mapping does **not** permit either of these crosswalk-wide claims:

- complete official curriculum coverage;
- learner mastery.

Both are hard-false fields in the contract.

Complete curriculum coverage would require a separately verified coverage analysis over the claimed scope. Learner mastery requires learner evidence and an approved assessment/review path, not a curriculum relationship alone.

## Human findings remain provenance

Crosswalk review states include:

- `required`;
- `approved`;
- `changes-required`;
- `rejected`.

Negative findings remain evidence. They are not removed merely to create a clean mapping set.

## Verify and seal

Verify an already sealed crosswalk:

```bash
python tools/curriculum_crosswalk.py verify path/to/crosswalk.json
```

Seal a prepared crosswalk by computing its deterministic digest and immediately verifying it:

```bash
python tools/curriculum_crosswalk.py seal \
  path/to/crosswalk.draft.json \
  path/to/crosswalk.json
```

The digest covers the complete mapping set and review metadata except the digest field itself.

## Relationship to CLAW and external experiences

CLAW, simulations, games, coding environments, robotics activities, projects, museums, virtual worlds, and other experience providers may define competencies and activities independently.

They can make an Ontario curriculum-coverage claim only through a verified crosswalk to the exact active jurisdictional standard records. An activity without a verified crosswalk remains enrichment or competency evidence, not official Ontario curriculum coverage.

This separation lets Axiom Education support novel pedagogy and lifelong competencies without rewriting or overstating jurisdictional standards.
