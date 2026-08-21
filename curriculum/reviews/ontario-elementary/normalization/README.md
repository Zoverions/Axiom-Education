# Ontario Elementary C2 normalization review evidence

This directory stores **qualified-human normalization review evidence** for exact current reference-only C2 candidates.

Generate the current plan with:

```bash
python tools/ontario_elementary_c2_promotion.py plan --output /tmp/ontario-elementary-c2-promotion-plan.json
```

A review must bind to the exact candidate `content_digest`, generated `review_target_sha256`, current C1 source-lock digest, and historical C1 source-byte SHA-256/length. A changed candidate or source binding requires a new review; do not edit digests to transfer an older judgement.

An `approved` review requires the human reviewer to confirm the exact source bytes were reviewed against the candidate, official structure/identifiers and education context were checked, hierarchy/relationships were checked, the candidate remains reference-only without embedded source wording, C1 provenance is correct, Axiom-authored metadata remains separate, and no completeness or activation claim is implied.

Negative findings and `changes-required`/`rejected` decisions remain provenance. Review evidence does not itself place a candidate in the canonical `records-v2` directory.

Canonical promotion additionally re-runs current source/licensing eligibility, exact C1-byte verification, candidate verification, and the exact human review before copying the unchanged candidate bytes into `records-v2`.

Promotion to `records-v2` means only that the reviewed record is accepted as a canonical **C2-normalized reference record**. It does not establish curriculum completeness, pack reproducibility, signing, staging, activation, learner mastery, grades, credits, school equivalency, or Ministry approval.
