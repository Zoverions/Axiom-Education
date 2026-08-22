# Education Social Collaboration Privacy

Status: executable foundation; not a promoted production capability.

## Boundary

Axiom Education should reuse AXIOM-MESH social/circle primitives for collaboration rather than create a second education-only social network.

The current Mesh social publication model already supports `public`, `followers`, and `circle` audiences plus multiple attribution modes. Education uses the circle concept as the natural projection for a class, project group, study group, tutoring session, office-hours space, or other bounded learning collaboration.

Education adds stricter semantics above that substrate. Circle membership is useful context; it is not blanket authority to inspect every member's educational or social history.

## Supported education purposes

The first collaboration model recognizes:

- assignment discussion;
- peer help;
- group projects;
- teacher announcements;
- tutoring;
- office hours;
- study groups;
- learner support.

The model separates shared instructional material, assignment context, peer conversation, support conversation, and safeguarding-restricted material.

## Need-to-know access

A role is not a transcript permission.

`guardian`, `teacher`, `principal`, `guidance counselor`, institutional membership, or any similar descriptive relationship cannot by itself authorize a privileged read.

A privileged access grant must bind:

- the exact actor;
- the exact collaboration space;
- an allowed educational purpose;
- the requested permission;
- evidence supporting that authority;
- an issue time;
- an expiry time;
- revocation state.

A grant for an assignment discussion cannot be reused to browse unrelated peer-help conversations. A grant for one class does not authorize another class. An expired, revoked, or unevidenced grant fails closed.

## Guardians

Guardians can receive appropriate assignment, progress, policy, and safety views when authorized. That does not imply automatic access to:

- peer chat transcripts;
- counseling/support transcripts;
- private teacher-learner messages;
- safeguarding-restricted records.

Applicable learner rights, capacity, safeguarding rules, institution policy, and jurisdiction rules remain separate governed inputs.

## Educators and school administration

An authorized educator may moderate an assigned learning space or read a thread needed for the assigned instructional purpose. The educator role does not authorize browsing unrelated learner social history.

The same applies to principals, counselors, administrators, and support staff. Organizational hierarchy is not a universal data-access hierarchy.

## Safeguarding

Safeguarding-restricted access is a separate path.

Break-glass access is not enabled merely because somebody holds a senior role. It requires explicit safeguarding authority, an applicable reason, evidence, a bounded grant, and an access receipt. A break-glass action does not become permanent browse authority after the immediate purpose ends.

## Log and learner-record boundary

A raw education conversation is not automatically:

- an official learner record;
- mastery evidence;
- a grade;
- a disciplinary finding;
- a governance score.

When a collaboration produces a pedagogically material consequence, that consequence should be projected separately through the governed Education evidence path rather than making the entire social transcript part of the learner record.

Access logs themselves are sensitive and should not become a general activity feed.

## Minimization

The collaboration layer does not require typing telemetry, presence surveillance, read-receipt telemetry, attention scoring, or exposure of the learner's wider social graph.

Assignments should prefer content-addressed artifact references instead of duplicating the learner's full submission body into social threads.

Class-local pseudonyms are supported conceptually. An institution may require verified identity binding for authority while still allowing the learner's public/display identity to remain limited to the relevant educational context.

## Current implementation

This slice adds:

- `contracts/axiom-education-collaboration-privacy.v1.json`;
- `EducationCollaborationSpace`;
- evidenced, time-bounded `EducationCollaborationAccessGrant`;
- exact-purpose `EducationCollaborationAccessRequest`;
- fail-closed `EducationCollaborationAccessEvaluator`;
- explicit safeguarding break-glass receipt requirements;
- privacy invariants proving role/relationship labels alone do not authorize transcript reads;
- tests for purpose mismatch, expiry, missing evidence, safeguarding, and raw-log non-promotion.

## Non-claim

This work establishes the Education-side semantics and admission boundary. It does not claim that every private-message, delegated-read, moderation, retention, or school-policy capability is already implemented in AXIOM-MESH production runtime.
