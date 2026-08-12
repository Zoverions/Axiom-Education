# MTH1W reviewer dossier

The remaining MTH1W promotion work is increasingly human-evidence work rather than missing course structure. To make that work reviewable without weakening the gates, Axiom Education can generate one deterministic reviewer dossier from the current repository state.

## Build

```bash
python tools/mth1w_reviewer_dossier.py build \
  --output build/mth1w-reviewer-dossier
```

Canonical verification builds the dossier twice and requires byte-identical output:

```bash
python tools/mth1w_reviewer_dossier.py verify
```

## Package contents

The dossier contains:

- `lesson-review-plan.json` — all 43 content-addressed lesson targets and required review types;
- `source-use-inventory.json` — every declared external source use bound to exact unit-content digests;
- `assessment-plan.json` — the current cumulative assessment blueprint;
- `current-readiness.json` — the exact current gate/claim declaration;
- `submitted-review-summary.json` — counts derived from actual review-evidence directories;
- `accessible-offline/` — deterministic learner-facing and separate answer/review text alternatives for all 43 lessons;
- `submitted-evidence/` — copies of any currently committed human-review JSON records;
- `REVIEW-GUIDE.md` — a generated review order and evidence-submission guide;
- `manifest.json` — SHA-256 and byte length for every packaged file.

## Evidence boundary

The dossier status is:

`machine-generated-review-inputs-no-approval`

Generating or signing the dossier does not mean any human reviewer approved its contents. It cannot satisfy educator, cultural/context, licensing, accessibility/usability, assessment-validity, mastery, grade, credit, school-equivalence, or Ministry-recognition claims.

Submitted human reviews remain separate evidence objects. A lesson review must bind to the current lesson digest; a source-licensing review must bind to the current source-use digest. If content changes, the older review becomes stale rather than carrying approval to the changed material.

## Why this matters

Previously, a qualified reviewer would have needed to assemble the lesson targets, source list, assessment design, accessibility alternatives, and current gate status from several repository locations. The dossier makes the same evidence surface reproducible and portable while preserving the fail-closed distinction between **review material** and **review evidence**.

The generated dossier is a build artifact and is not committed by default.
