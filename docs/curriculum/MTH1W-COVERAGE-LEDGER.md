# MTH1W Coverage Ledger

**Status:** official inventory and complete course blueprint verified; 1 of 9 units authored as a machine-verified draft
**Source audit date:** 2026-08-01
**Course-complete claim:** blocked

## Inventory baseline

The digest-pinned inventory at
`curriculum/official/ontario-mth1w-2021.inventory.json` records the complete
official hierarchy from the 222-page Ontario Ministry of Education source:

- 7 strands;
- 14 overall expectations;
- 43 specific expectations; and
- 57 expectation references in total.

Each reference stores its identifier, kind, strand, parent, official page,
title, normalized description length, and description SHA-256. The inventory
does not redistribute the verbatim expectation descriptions. Run:

```bash
python tools/mth1w_official_inventory.py verify \
  --inventory curriculum/official/ontario-mth1w-2021.inventory.json
```

Supplying the exact source PDF with `--source-pdf` additionally proves that the
checked-in inventory can be reproduced from the pinned document.

## Course blueprint and authored milestone

The machine-verified blueprint at
`curriculum/courses/ontario-mth1w-2021.course.json` specifies the conventional
no-AI path before adaptive features:

- 9 ordered units and 110 estimated hours;
- 43 primary lessons, covering each of the 43 specific expectations exactly
  once;
- all 14 overall expectations plus the course-wide AA1, A1, and A2 practices;
- at least two task-appropriate method routes and two representations in every
  lesson specification;
- unit quizzes and performance tasks; and
- cumulative diagnostic, checkpoint, final assessment, accessibility, and
  offline-delivery plans.

Unit 1 is now delivered from the bundled offline content file
`curriculum/content/mth1w/u1-number-systems.v1.json`. It contains 3 lessons, 6
worked examples, 33 guided/independent/retrieval practice items, a 10-item unit
quiz, and a performance task. Its student surface is clearly labelled as a
draft preview; constructed responses and the complete unit still require
qualified educator and cultural review.

Run the evidence checks with:

```bash
python tools/check_mth1w_course_blueprint.py
python tools/check_mth1w_unit_content.py
```

## Base-coverage matrix

"Inventory verified" means only that the official reference is present and
source-pinned. It is not a lesson-coverage or course-completion claim.

| Strand | Overall expectations | Specific expectations | Inventory | Reviewed teaching coverage |
|---|---|---|---|---|
| AA — Social-Emotional Learning Skills in Mathematics | `AA1` | none | verified | not started |
| A — Mathematical Thinking and Making Connections | `A1`, `A2` | none | verified | not started |
| B — Number | `B1`, `B2`, `B3` | `B1.1`–`B1.3`, `B2.1`–`B2.2`, `B3.1`–`B3.5` | verified | not started |
| C — Algebra | `C1`, `C2`, `C3`, `C4` | `C1.1`–`C1.5`, `C2.1`–`C2.3`, `C3.1`–`C3.3`, `C4.1`–`C4.4` | verified | not started |
| D — Data | `D1`, `D2` | `D1.1`–`D1.3`, `D2.1`–`D2.5` | verified | not started |
| E — Geometry and Measurement | `E1` | `E1.1`–`E1.6` | verified | not started |
| F — Financial Literacy | `F1` | `F1.1`–`F1.4` | verified | not started |

The four existing foundation lessons use preliminary local topic identifiers.
They remain useful for study, but they do not mark any row above as covered
until their exact official bindings and instructional interpretations pass
educator review.

The newer Unit 1 content binds to official inventory identifiers B1.1 through
B1.3 and passes structural and answer-contract verification. It is authored
coverage, but is not marked reviewed teaching coverage until the required
human review evidence is recorded.

## Evidence required per specific expectation

Before an expectation can be marked covered, its ledger entry must identify:

- reviewed official binding and source location;
- unit and lesson identifiers;
- learning goals, prerequisites, vocabulary, and scope;
- explicit instruction, worked examples, multiple valid reasoning routes, and
  connected representations;
- guided, independent, retrieval, and mixed practice with answer rationales;
- lesson-check and assessment evidence;
- accessible and printable/offline alternatives;
- educator reviewer, review date, and unresolved findings; and
- automated tests proving that the delivered content and public claim agree.

Overall expectations are satisfied through the reviewed set of specific
expectations and course-wide evidence; their presence in the inventory does
not independently prove coverage.

## Remaining course gates

The official-inventory gate and complete-coverage blueprint are verified.
Authored delivery is 3 of 43 primary lessons across 1 of 9 units. These gates
remain blocked:

- educator source and instructional review;
- licensing and redistribution disposition;
- complete lesson and practice coverage;
- assessments and cumulative review;
- accessible alternatives; and
- governed progress and educator workflow.

Only after every gate passes may MTH1W be represented as complete. Work then
moves to the remaining Grade 9 courses and later grades in the documented
sequence.
