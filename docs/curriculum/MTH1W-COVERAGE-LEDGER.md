# MTH1W Coverage Ledger

**Status:** official expectation inventory verified; instructional coverage incomplete
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

The official-inventory gate is verified. These gates remain blocked:

- educator source and instructional review;
- licensing and redistribution disposition;
- complete lesson and practice coverage;
- assessments and cumulative review;
- accessible alternatives; and
- governed progress and educator workflow.

Only after every gate passes may MTH1W be represented as complete. Work then
moves to the remaining Grade 9 courses and later grades in the documented
sequence.
