# Institutional and Resource Intelligence

Status: executable foundation; not a promoted production capability.

## Purpose

Axiom Education needs one education substrate that can serve existing schools, families, Claw Academy, homeschool environments, post-secondary institutions, professional learning, and future experience shells.

Claw Academy is therefore an experience layer, not the owner of classrooms, learners, guardians, teachers, principals, guidance counselors, assignments, assessment, reporting, or educational authority semantics.

## Shared institutional layer

The shared institutional model represents:

- institutions and learning groups;
- learner enrollment and other evidenced relationships;
- descriptive roles including learner, guardian, teacher, principal, guidance counselor, support worker, administrator, assessor, and mentor;
- scoped authority projections backed by Mesh evidence;
- guardian learning preferences as governed inputs rather than unconditional powers.

A role is not a permission. `teacher`, `principal`, `guardian`, or any other label does not authorize an action by itself. Consequential actions require applicable identity, relationship/delegation evidence, capability scope, policy, consent where required, and a non-expired/non-revoked authority path.

Guardian pacing and content-timing preferences can express requests such as:

- slow down when allowed;
- maintain current pacing;
- accelerate when the learner is ready;
- prioritize an area;
- defer content when allowed;
- prioritize content when it becomes relevant.

These preferences are inputs to a later readiness/content-policy resolver. They do not independently suppress required curriculum, override learner rights, override safeguarding obligations, or invent jurisdiction policy.

## Resource intelligence

A competency can have many pedagogical presentations. The resource layer treats video, text, audio, animation, worked examples, simulations, games, stories, projects, human instruction, and external experiences as resources that may teach overlapping competencies.

YouTube is one possible external provider. It is not a platform dependency and receives no special learner authority.

Each resource can describe:

- provider and source;
- competency alignment;
- presentation format;
- trust/review state;
- language;
- accessibility features;
- content tags consumed by resolved policy;
- pace;
- difficulty;
- approximate duration.

## Direct learner feedback

The first feedback vocabulary is:

- helpful;
- not helpful;
- still confused;
- too fast;
- too slow;
- too easy;
- too hard;
- liked this example;
- show another way;
- more like this;
- already knew this.

The learner can therefore tell the system whether a particular explanation helped without that signal becoming a permanent claim that the learner has one fixed "learning style".

## Outcome-aware recommendation

The deterministic recommendation engine ranks eligible resources using:

1. target-competency fit;
2. trust/review state;
3. required accessibility features;
4. resolved content eligibility;
5. language;
6. current duration preference;
7. recent learner feedback for this competency;
8. later demonstrated outcome evidence;
9. contextual pace, format, and difficulty fit.

A self-report such as `helpful` is useful evidence, but later assessment evidence can reinforce or contradict it. `show another way` deliberately favors a different presentation rather than repeatedly serving the same format.

The engine intentionally accepts no watch-time, click-through, advertising-yield, streak, or generic engagement input. Its job is to improve learning and learner agency, not maximize attention capture.

## Trust states

Resources progress through explicit states:

```text
discovered
  -> machine-analyzed
  -> community-reviewed
  -> educator-reviewed
  -> institution-approved
  -> jurisdiction-approved
```

These states describe review provenance. They do not prove learner mastery or accreditation.

## Policy boundary

The recommender does not decide what a child is legally or developmentally permitted to access. A separate content/readiness policy layer resolves applicable learner state, guardian input, educator/institution policy, safeguarding requirements, learner rights, and jurisdiction rules and passes an eligibility decision into resource selection.

Denied resources, resources below the required trust floor, or resources missing required accessibility features fail eligibility before ranking.

## Privacy boundary

The preferred record is pedagogically meaningful consequence rather than surveillance exhaust:

```text
learner encountered competency C
explanation A did not land
learner requested another approach
resource B was reported helpful
later independent evidence improved
```

Raw watch history is not required to make that useful.

Cross-learner aggregation, population-level effectiveness claims, or public ratings require separate privacy and governance work and are intentionally outside this slice.

## Next implementation slices

1. governed persistence for feedback and outcome observations through learner memory/events;
2. content/readiness policy resolver with explicit guardian, learner, educator, institution, safeguarding, and jurisdiction inputs;
3. school/institution adapters for enrollment, assignments, reporting, and existing interoperability standards;
4. learner and parent feedback UI;
5. external resource discovery/admission adapters, beginning with reviewed video/OER resources rather than unrestricted search;
6. Claw Academy storyboard integration so panels can request an eligible resource, alternate explanation, game, simulation, or generated experience through the same interfaces.
