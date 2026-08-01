# MTH1W Vertical Slice — Phase 0, Phase 1, and Phase 2

**Status:** Active foundations-preview implementation contract
**Course:** Ontario Grade 9 Mathematics, de-streamed (`MTH1W`)  
**Application version:** `0.5.0-dev.0`  
**Capability scope:** preliminary local topic grounding, conventional local lessons, and deterministic local practice

> **Source boundary:** The official-source audit found that this preliminary
> local snapshot is not a complete or correctly numbered transcription of the
> official 2021 MTH1W course. This slice is displayed only as the **Grade 9 Math
> Foundations Preview**. See `docs/curriculum/MTH1W-SOURCE-AUDIT.md` and
> `config/curriculum-readiness.json`.

## Frozen curriculum scope

The current experimental Ontario corpus contains exactly 11 locally labelled
`MTH1W` records across four strands:

- `MTH1W-A1` — integer and rational operations, including order of operations;
- `MTH1W-A2` — rates, ratios, percentages, and proportional reasoning;
- `MTH1W-A3` — scientific notation;
- `MTH1W-B1` — algebraic expressions and exponents;
- `MTH1W-B2` — linear equations and inequalities;
- `MTH1W-B3` — linear and non-linear relations;
- `MTH1W-B4` — equation of a line from slope/intercept or two points;
- `MTH1W-C1` — one-variable data analysis;
- `MTH1W-C2` — bias in data collection and conclusions;
- `MTH1W-D1` — properties of triangles and quadrilaterals;
- `MTH1W-D2` — surface area and volume of composite three-dimensional figures.

These are preliminary topic descriptions, not verified official expectation
bindings. In particular, local B2 conflicts with official B2 (Powers), and
local B4 is not an official Number-strand overall expectation. The snapshot
also omits official course areas including Coding and Financial Literacy.

The frozen subset is `curriculum/slices/mth1w.v1.json`. CI proves only that it
remains an exact projection of the experimental local corpus and that two pack
builds are byte-identical. That integrity evidence does not establish official
curriculum accuracy.

## Phase 1 golden path

The first deterministic practice engine supports exactly these expectation IDs:

1. `MTH1W-A1`
2. `MTH1W-A2`
3. `MTH1W-B2`
4. `MTH1W-B4`

Unsupported expectation IDs fail closed and must not fall back to synthetic questions.

## Phase 2 conventional course path

The same four derived topic references form a sequenced, non-AI instructional
path. Every lesson includes:

- a student-visible title, expected duration, and derived topic reference;
- learning goals and prerequisite knowledge;
- teacher-authored direct instruction and a statement of relevance;
- a fully worked example with visible intermediate reasoning;
- a common misconception and a subject-specific planning prompt; and
- an action that opens deterministic practice at the lesson's expectation.

The lessons are local, deterministic application content and do not require a
tutor provider. Runtime curriculum joining fails closed when any required
expectation is missing. The student may also open mixed practice independently
of the lesson path.

## Practice-item contract

Every generated practice item must include:

- schema version;
- immutable item identifier;
- derived local topic identifier and text;
- deterministic generator identifier, version, and seed;
- learner-visible prompt;
- answer kind and canonical answer specification;
- scaffolded hints;
- visibly uncalibrated difficulty metadata;
- SHA-256 item digest over a canonical field ordering.

The JSON contract is `schemas/practice-item.v1.schema.json`.

## Acceptance criteria

### Curriculum and provenance

- The MTH1W subset contains all and only the 11 frozen local records.
- The subset preserves the experimental corpus IDs and text byte-for-byte after JSON decoding.
- The curriculum-pack builder produces byte-identical manifest and record files on repeated builds.
- The practice UI displays a derived topic reference and the item digest prefix.

### Deterministic generation

- Equal expectation ID, source text, difficulty value, and seed produce an equal practice item and digest.
- Different seeds produce different item identities for the golden-path expectations.
- A1 generates exact integer/rational arithmetic.
- A2 generates exact percentage or proportional reasoning.
- B2 generates a solvable one-variable linear equation.
- B4 generates a line from two points with an exact slope and intercept.

### Verification

- Numeric answers are checked with exact rational arithmetic rather than floating-point tolerance.
- B4 accepts a normalized `y = mx + b` answer and compares exact rational slope and intercept.
- Empty, malformed, and unsupported answers return explicit non-success results.
- A missing verifier returns `unavailable`; the UI disables submission and does not infer success.

### User experience

- `MTH1W` course detail exposes an **Open foundation lessons** action and a secondary **Quick practice** action.
- The course screen teaches before asking the learner to practise and makes the four-lesson sequence visible.
- Every lesson presents goals, prerequisites, instruction, a worked example, a misconception check, and a planning prompt before focused practice.
- The practice screen uses actual answer entry, not learner self-report.
- Hints are local, deterministic, and item-linked.
- Feedback distinguishes correct, incorrect, malformed, and unavailable states.
- The practice screen shows ephemeral counts of checks and exact successes for
  the current screen session only.
- The practice screen counts distinct checked items and offers three as a
  non-assessment stopping cue; checking one item repeatedly does not increase
  that count.
- Session counters reset when the screen closes and are never persisted or
  represented as a learner record, assessment record, or mastery claim.
- The interface states that difficulty is an uncalibrated heuristic and that no tutor or learner record is active.
- The interface states that official curriculum mapping remains under review
  and that the preview is not a complete course or grade.

## Negative-path gates

The tranche must test:

- unsupported expectation ID;
- missing verifier;
- malformed rational answer;
- malformed line equation;
- altered MTH1W subset;
- missing or extra frozen expectation;
- non-deterministic repeated generation;
- item-digest mismatch after field mutation.

## Explicitly deferred

This tranche does **not** promote or claim:

- configured local tutor inference;
- verified official MTH1W expectation coverage;
- complete MTH1W course, credit, grade, transcript, Ministry approval, or school equivalency;
- lesson quizzes, unit tests, cumulative review, or conventional grading;
- durable or governed learner-event recording;
- consent-bound learner-record mutation;
- educator review or appeal;
- portfolio export;
- calibrated psychometrics;
- completion of the ten-outcome vertical slice.

Those remain later gated phases. Phase 1 establishes the deterministic instructional and verification core they depend on.
