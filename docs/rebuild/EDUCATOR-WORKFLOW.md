# Governed educator workflow

Axiom Education needs assignment, submission, feedback, revision, review, correction, and appeal semantics without creating a second learner-record authority inside the Flutter app.

The workflow therefore remains a **payload/state contract** projected through the existing pinned `axiom.education` v1 action:

```text
education.learner.event.append
```

That parent action already requires purpose-bound consent for `learning-progress-recording`, a subject, event ID, payload digest, and governed memory-object reference.

## Event chain

The sibling contract `contracts/axiom-education-educator-workflow.v1.json` defines these bounded transitions:

```text
assignment.created
  -> assigned
submission.created
  -> submitted
review.started
  -> under-review
feedback.recorded
  -> feedback-available
revision.requested
  -> revision-requested
submission.resubmitted
  -> submitted
review.finalized
  -> finalized
```

A finalized or feedback-available review can enter an appeal path:

```text
appeal.filed
  -> appealed
appeal.review.started
  -> under-review
correction.recorded
  -> corrected
review.finalized
  -> finalized
```

Each event binds to the previous event digest. Review, feedback, appeal, correction, and finalization events also bind to the current submitted artifact digest. A resubmission changes that artifact digest, so later review events cannot silently refer to the earlier submission.

## Data minimization

Workflow events carry digests and identifiers, not raw work or feedback.

Raw learner work and detailed feedback, when a governed provider exists, belong in purpose-bound encrypted learner memory objects referenced by `memory_object_id`. They are not copied into gateway event fields, logs, or evidence records.

The event schema has `additionalProperties: false`; raw-work, grade, credit, transcript, or similar ad-hoc fields are rejected.

## Authority

An `actor_role` is workflow metadata, not proof of authority.

- `educator` does not self-authorize an educator.
- `authorized-representative` does not self-authorize a guardian or representative.
- installation grants no authority.

Identity, delegation, policy, provider admission, consent, and any institution/credit authority remain AXIOM concerns outside this workflow contract.

## No automatic grade or credit

`finalized` means the workflow reached a finalized review state. It does not mean:

- mastery was proven;
- a grade was awarded;
- a course credit was issued;
- a transcript was changed;
- an Ontario school or Ministry recognized the result.

Those are separate claims with separate authority and evidence requirements.

## Verification

```bash
python tools/check_educator_workflow_contract.py
python -m pytest -q tests/test_educator_workflow.py
```

The contract remains foundation work until an approved AXIOM learner-record provider persists these events under real identity, consent, policy, revocation, correction, and audit controls.
