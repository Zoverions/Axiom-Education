# MTH1W human review evidence

This directory is reserved for human review records that conform to `schemas/content-review-evidence.v1.schema.json` and pass `tools/mth1w_review_evidence.py`.

No approval is implied by the existence of this directory or by a machine-generated review plan.

## Generate the current review plan

```bash
python tools/mth1w_review_evidence.py plan --output /tmp/mth1w-review-plan.json
```

The plan derives all 43 current lesson targets from the authored course content. Each target contains a canonical SHA-256 of the exact lesson object. A later lesson edit changes that digest, making old review evidence stale automatically.

## Review evidence

A submitted record identifies:

- reviewer name and qualification;
- review type;
- exact unit and lesson;
- exact content digest;
- review date;
- decision: `approved`, `changes-required`, or `rejected`;
- required instructional confirmations;
- findings and their dispositions;
- scope limitations.

Negative findings remain evidence. A `changes-required` or `rejected` review is valid provenance but does not satisfy a promotion gate.

An approved educator review cannot contain open findings, and major/critical findings must be resolved. Educator approval also requires confirmation of expectation binding, content correctness, pedagogical suitability, and age appropriateness.

## Verify submitted records

```bash
python tools/mth1w_review_evidence.py verify-directory \
  --directory curriculum/reviews/mth1w
```

At present there are no submitted human review JSON records. The course therefore remains blocked on educator review even though the review mechanism itself is machine verified.

## Boundary

This mechanism does not decide whether a reviewer is legally authorized to grant Ontario secondary credit, does not make Axiom Education a school, and does not turn a reviewed lesson into a Ministry-approved resource. It only makes the project's own human-review evidence explicit, revision-bound, inspectable, and fail-closed.
