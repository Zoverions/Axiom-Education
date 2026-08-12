# MTH1W assessment review evidence

This directory holds qualified human review evidence for the exact current MTH1W assessment surfaces.

## Current target plan

Generate the ten current targets with:

```bash
python tools/mth1w_assessment_review_evidence.py plan \
  --output /tmp/mth1w-assessment-review-plan.json
```

The plan contains:

- nine `unit-assessment-surface` targets, each bound to the SHA-256 of the complete authored unit revision containing its quiz/performance-task surface;
- one `coursewide-assessment-plan` target bound to the exact current cumulative assessment-plan digest.

Binding unit assessment review to the complete authored unit is intentionally conservative: any lesson/content revision inside that unit invalidates the prior assessment review until the changed revision is reconsidered.

## Review requirements

An `approved` assessment review must explicitly confirm:

- official curriculum alignment was reviewed;
- content validity was reviewed;
- scoring/rubric quality was reviewed;
- constructed-response handling was reviewed;
- correction, reassessment, and appeal were reviewed;
- accessibility/alternate response routes were reviewed;
- no automatic mastery, grade, or credit inference is being approved.

Approved evidence cannot contain open findings or unresolved major/critical findings.

`changes-required` and `rejected` reviews are valid evidence and must be preserved rather than deleted.

## Revision semantics

Multiple historical reviews may exist for one current target digest. The latest valid review timestamp controls the current target disposition.

This supports a real review cycle:

```text
changes required
  -> content/rubric correction
  -> new content digest (old review becomes stale)
  -> new review
  -> approval or further changes required
```

If a later review of the same current digest finds a new issue, that later negative decision blocks an earlier approval.

## Commands

Verify one review:

```bash
python tools/mth1w_assessment_review_evidence.py verify-review path/to/review.json
```

Verify all committed assessment reviews:

```bash
python tools/mth1w_assessment_review_evidence.py verify-directory
```

Verify the current curriculum-readiness gate boundary:

```bash
python tools/mth1w_assessment_review_evidence.py verify-readiness
```

## Non-claims

A machine-generated target plan creates no assessment validity, psychometric, mastery, grade, credit, transcript, Ministry, or school-equivalence claim.

Even complete assessment-review evidence does not independently satisfy educator lesson review, licensing, accessibility/usability, learner-record, or educator-workflow gates.
