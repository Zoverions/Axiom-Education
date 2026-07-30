# MTH1W Vertical Slice — Phase 0 and Phase 1

**Status:** Active implementation contract  
**Course:** Ontario Grade 9 Mathematics, de-streamed (`MTH1W`)  
**Application version:** `0.5.0-dev.0`  
**Capability scope:** signed curriculum grounding plus deterministic local practice  

## Frozen curriculum scope

The current Ontario curriculum corpus contains exactly 11 `MTH1W` records across four strands:

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

The frozen subset is `curriculum/slices/mth1w.v1.json`. CI must prove that it remains an exact course-level projection of `assets/curriculum/ontario_curriculum_full.json` and that two pack builds from the subset are byte-identical.

## Phase 1 golden path

The first deterministic practice engine supports exactly these expectation IDs:

1. `MTH1W-A1`
2. `MTH1W-A2`
3. `MTH1W-B2`
4. `MTH1W-B4`

Unsupported expectation IDs fail closed and must not fall back to synthetic questions.

## Practice-item contract

Every generated practice item must include:

- schema version;
- immutable item identifier;
- exact curriculum expectation identifier and text;
- deterministic generator identifier, version, and seed;
- learner-visible prompt;
- answer kind and canonical answer specification;
- scaffolded hints;
- visibly uncalibrated difficulty metadata;
- SHA-256 item digest over a canonical field ordering.

The JSON contract is `schemas/practice-item.v1.schema.json`.

## Acceptance criteria

### Curriculum and provenance

- The MTH1W subset contains all and only the 11 frozen records.
- The subset preserves the source expectation IDs and text byte-for-byte after JSON decoding.
- The curriculum-pack builder produces byte-identical manifest and record files on repeated builds.
- The practice UI displays the exact expectation ID and the item digest prefix.

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

- `MTH1W` course detail exposes a **Start verified practice** action.
- The practice screen uses actual answer entry, not learner self-report.
- Hints are local, deterministic, and item-linked.
- Feedback distinguishes correct, incorrect, malformed, and unavailable states.
- The interface states that difficulty is an uncalibrated heuristic and that no tutor or learner record is active.

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
- durable or governed learner-event recording;
- consent-bound learner-record mutation;
- educator review or appeal;
- portfolio export;
- calibrated psychometrics;
- completion of the ten-outcome vertical slice.

Those remain later gated phases. Phase 1 establishes the deterministic instructional and verification core they depend on.
