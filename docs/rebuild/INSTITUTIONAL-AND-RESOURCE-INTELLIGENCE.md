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

These preferences are governed inputs. They do not independently suppress required curriculum, override learner rights, override safeguarding obligations, or invent jurisdiction policy.

A reusable `GuardianLearningPreferencePanel` now exposes these choices without presenting a direct curriculum-removal control.

## Existing-school admission boundary

The first roster admission service provides a generic boundary for existing SIS/LMS integrations. An external school system may supply an enrollment or role candidate, but the candidate remains untrusted until it is bound to a local actor with:

- source-system evidence;
- identity-binding evidence;
- explicit local admission evidence;
- a role compatible with the admitted subject kind.

The resulting school role/enrollment projection is descriptive Education context only. It does not grant Mesh authority. A later interoperability adapter can map OneRoster, LTI, or another school-system format into this generic boundary without making the external platform the authority kernel or owner of the learner record.

## Content/readiness governance

The first content/readiness resolver now accepts evidenced directives from:

- learner preference;
- guardian preference;
- educator recommendation;
- institution policy;
- jurisdiction policy;
- safeguarding policy.

Each directive has an explicit effect (`allow`, `defer`, `prioritize`, or `deny`), strength (`advisory`, `required`, or `non-waivable`), governed priority, evidence references, scope, and validity/revocation window.

The resolver does not assign authority based on whether the source is called a parent, teacher, principal, government, or learner. Strength and priority have to arrive from the applicable evidenced policy. Unevidenced, expired, or revoked directives do not become binding.

Within the controlling binding tier, denial fails closed. Equally strong contradictory binding directions produce `review-required` rather than an invented answer. Advisory preferences can change sequencing when allowed but cannot override a stronger binding policy.

Chronological age is deliberately not treated as a complete maturity or legal-capacity model.

## Resource intelligence

A competency can have many pedagogical presentations. The resource layer treats video, text, audio, animation, worked examples, simulations, games, stories, projects, human instruction, and external experiences as resources that may teach overlapping competencies.

YouTube is one possible external provider. It is not a platform dependency and receives no special learner authority.

Each admitted resource can describe:

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

## Privacy-minimized discovery and explicit admission

External discovery now uses a provider-neutral query containing only pedagogically necessary fields such as target competency, requested format, language, accessibility needs, duration limit, and optional search tags.

The discovery request deliberately has no learner id, guardian id, institution id, learner history, diagnosis, or raw policy context.

A provider returns an untrusted `LearningResourceCandidate`. Candidates do not have a trust state. Therefore an external provider cannot self-assert `educator-reviewed`, `institution-approved`, or `jurisdiction-approved`.

A separate Axiom-side admission step assigns review state only when review evidence is supplied. Provider identity mismatch fails closed.

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

A reusable Flutter `LearningResourceMoment` and `LearningResourceFeedbackPanel` now provide this feedback surface for any future renderer: video, story/comic panel, simulation, game, generated experience, text, or conventional lesson content.

The UI emits explicit pedagogical signals only. It does not infer mastery or collect passive engagement telemetry.

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

## Curriculum assurance and the Ontario demonstration

Curriculum/course assurance is now represented separately from resource trust. The assurance ladder is:

```text
unverified
  -> source-aligned-demonstration
  -> machine-audited
  -> human-reviewed
  -> institution-approved
  -> jurisdiction-approved
  -> accredited
```

The levels are deliberately non-transitive. Machine auditing does not imply qualified human review. Human review does not imply institutional approval. Jurisdiction approval does not silently imply accreditation or credit-bearing status.

The current Ontario implementation defaults to `source-aligned-demonstration` unless an evidence-backed assurance record explicitly promotes a declared scope. Its default claim is therefore that it is designed to align as closely as practicable with identified published Ontario curriculum sources at the time of creation, while **not** claiming Ministry approval, school-board approval, qualified human review, accreditation, or Ontario credit-bearing status.

A frozen demonstration retains its source and assurance metadata. A later verified capsule supersedes it rather than rewriting historical provenance.

## Policy boundary

The recommender does not decide what a child is legally or developmentally permitted to access. The content/readiness policy layer resolves applicable evidenced inputs and passes the resulting eligibility/sequence decision into resource selection.

Denied resources, review-required content, resources below the required trust floor, or resources missing required accessibility features fail eligibility before ranking/presentation.

## Persistence boundary

Resource feedback and recommendation telemetry are **not** automatically written into the existing official learner-event stream.

The current governed learner-memory profile has a pinned event vocabulary, event-to-memory-kind mapping, and ownership mapping. This slice deliberately does not widen those verified contracts implicitly or write a parallel local shadow record.

Before feedback becomes durable learner-record evidence, a later Mesh-aligned change must explicitly define:

- the admitted event type;
- memory kind;
- learner/actor ownership rule;
- consent requirements;
- correction/retraction semantics;
- minimum retained content;
- portability/export behavior.

This keeps a useful UI signal from silently becoming surveillance or an unofficial second student record.

## Privacy boundary

The preferred durable record is pedagogically meaningful consequence rather than surveillance exhaust:

```text
learner encountered competency C
explanation A did not land
learner requested another approach
resource B was reported helpful
later independent evidence improved
```

Raw watch history is not required to make that useful.

Cross-learner aggregation, population-level effectiveness claims, or public ratings require separate privacy and governance work and are intentionally outside this slice.

## Implemented in this slice

- shared institution, learning-group, relationship, role, and scoped-authority models;
- guardian pacing/content-timing preferences with explicit non-authority invariants;
- reusable guardian preference UI;
- generic existing-school roster admission boundary;
- content/readiness directive model and fail-closed conflict resolver;
- generic resource metadata and trust states;
- direct learner feedback and later outcome-observation models;
- outcome-aware deterministic resource recommendation;
- privacy-minimized external resource discovery;
- explicit Axiom-side resource review/admission;
- reusable learner resource-feedback UI;
- curriculum assurance model and explicit Ontario demonstration status;
- contract tests and focused unit/widget tests for the above boundaries.

## Next implementation slices

1. define and admit governed persistence for learner resource feedback/outcome evidence without weakening the pinned learner-memory profile;
2. implement concrete school-system interoperability mappings on top of the generic roster admission boundary;
3. implement reviewed video/OER discovery adapters using the generic catalog interface;
4. connect guardian preference UI to evidenced relationship and policy-issuance workflows;
5. connect Claw Academy storyboard panels so they can request an eligible resource, alternate explanation, game, simulation, or generated experience through the same interfaces;
6. build zero-assumption entry-assessment primitives and a broader competency graph beneath grade/course labels.
