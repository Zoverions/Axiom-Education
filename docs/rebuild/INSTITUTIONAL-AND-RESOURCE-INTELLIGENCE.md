# Institutional and Resource Intelligence

Status: executable foundation; not a promoted production capability.

## Purpose

Axiom Education needs one education substrate that can serve existing schools, families, Claw Academy, homeschool environments, post-secondary institutions, professional learning, and future experience shells.

Claw Academy is therefore an experience layer, not the owner of classrooms, learners, guardians, teachers, principals, guidance counselors, assignments, assessment, reporting, social collaboration, model routing, or educational authority semantics.

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

Curriculum/course assurance is represented separately from resource trust. The assurance ladder is:

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

## Governed learning evidence

The existing `axiom.education.learner-memory@1.1.0` profile is deliberately not widened to force learner resource feedback into educator-workflow event types that mean something else.

A separate draft `axiom.education.learning-evidence` contract now defines learner-owned, minimized envelopes for:

- resource feedback;
- later outcome observations;
- append-only corrections;
- append-only retractions.

The proposed memory kind is `education.learning-evidence`, but no new Mesh event admission is claimed. The Education layer must not report official persistence until the corresponding Mesh event vocabulary, ownership, consent, correction, portability, and provider behavior are explicitly admitted.

Raw watch history, clickstream, advertising identifiers, provider account identifiers, and raw conversation transcripts are not required by the envelope.

## Social collaboration and need-to-know privacy

Education reuses AXIOM-MESH social/circle primitives rather than creating a second school-only social system.

A class, assignment discussion, project team, peer-help space, tutoring session, office-hours space, study group, or learner-support space can project onto a governed social circle. Education adds stricter access semantics above that substrate.

Circle membership, guardian status, educator status, principal status, counselor status, or institution membership does not automatically grant transcript access. Privileged reads require an exact, evidenced, purpose-bound, scope-bound, time-bounded grant.

A grant for one assignment or class cannot be reused to browse unrelated learner conversations. Safeguarding-restricted reads require a separate governed break-glass path with explicit safeguarding authority, reason, evidence, expiry, and access receipt.

Raw collaboration logs are not automatically learner records, mastery evidence, grades, disciplinary findings, or governance scores. Pedagogically material consequences should be projected separately through the governed learning-evidence path rather than promoting entire social transcripts.

See `EDUCATION-SOCIAL-COLLABORATION-PRIVACY.md`.

## Model integration and usage

Education uses the AXIOM personal compute fabric for replaceable model/runtime selection. A model, runtime capsule, provider, or compute node is not part of the trusted education authority layer.

The first Education task classes include concept explanation, Socratic tutoring, practice generation, draft practice evaluation, storyboards, game/simulation planning, resource summaries, translation, accessibility transformation, and collaboration assistance.

Every request has an explicit time-bounded context grant. The model receives only the scopes needed for that task, such as a target competency, current learner input, minimized misconception summary, accessibility requirement, language preference, assignment context, resource context, or learner-selected story character profile.

The default is not to send the full longitudinal learner profile, raw social history, guardian identity, institution identity, diagnosis, or unrelated conversations.

Placement filters privacy, egress, jurisdiction, retention, content/readiness policy, model admission/health, capability, deadline, and budget before ranking by task-specific quality, reliability, latency, cost, or energy.

Usage budgets can cap calls, input units, output units, monetary cost, and wall time. A fallback cannot silently cross an egress boundary or exceed the remaining budget.

A minimized usage receipt records provider/model/runtime/node, context-scope identifiers, egress/retention class, units, cost, latency, and fallback reason without requiring raw prompts or learner responses. Funding authority remains separate from transcript authority.

A model cannot create a final grade, credit, mastery decision with governance consequence, transcript entry, credential, accreditation claim, identity/authority grant, or public/social effect by itself.

See `EDUCATION-MODEL-INTEGRATION.md`.

## Competency graph beneath grade labels

The new competency graph treats a grade/course as context rather than a complete learner model. Nodes represent competencies; reviewed crosswalks remain the separate mechanism for asserting relationships to official curriculum.

Evidence can be unknown, attempted, emerging, or demonstrated. It is contextual and revisable rather than a permanent identity label.

The entry diagnostic planner starts from the learner's requested target, walks unresolved prerequisites, skips sufficiently demonstrated prerequisites, and produces a bounded probe plan. It does not infer ability from age or enrollment and does not produce a grade-placement, credit, promotion, or mastery decision.

Prerequisite cycles and missing graph endpoints fail closed.

## Device-adaptive zero-assumption entry assessment

Entry assessment probes declare exactly which interaction/device capabilities they require. Supported primitives include visual/audio output, touch/pointer/keyboard input, optional microphone/camera input, and haptics.

The selector prefers lower-assumption probes when alternatives can address the same competency. Camera and microphone probes are skipped unless the capability is both available and authorized. Literacy, speech, camera, microphone, chronological age, grade, diagnosis, demographics, and previous school records are not assumed.

A device failure, unsupported modality, or non-response is not automatically negative ability evidence. Raw camera/microphone recordings are not retained by default; minimum derived pedagogical evidence is preferred.

## Policy boundary

The recommender, collaboration layer, entry assessment, and model router do not decide what a child is legally or developmentally permitted to access. The content/readiness and authority layers resolve applicable evidenced inputs and pass bounded decisions onward.

Denied resources, review-required content, resources below the required trust floor, or resources missing required accessibility features fail eligibility before ranking/presentation.

## Privacy boundary

The preferred durable record is pedagogically meaningful consequence rather than surveillance exhaust:

```text
learner encountered competency C
explanation A did not land
learner requested another approach
resource B was reported helpful
later independent evidence improved
```

Raw watch history is not required to make that useful. Raw social transcripts and model prompts are not required for usage accounting.

Cross-learner aggregation, population-level effectiveness claims, or public ratings require separate privacy and governance work and remain outside this slice.

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
- separate minimized learner-owned learning-evidence admission contract;
- need-to-know Education collaboration spaces and access evaluator over Mesh social circles;
- safeguarding-restricted break-glass access semantics with receipts;
- zero-assumption competency graph and bounded diagnostic planning;
- device/input-adaptive entry-assessment selection;
- model task/context/budget/candidate routing over the Mesh personal compute fabric;
- minimized model usage receipts and model-output authority prohibitions;
- focused contract/unit/widget tests for these boundaries.

## Next implementation slices

1. obtain explicit Mesh admission for learning-evidence event types without modifying the pinned educator-workflow profile;
2. implement concrete school-system interoperability mappings on top of the generic roster admission boundary;
3. implement reviewed video/OER discovery adapters using the generic catalog interface;
4. connect guardian preference UI to evidenced relationship and policy-issuance workflows;
5. connect Claw Academy storyboard panels to resource intelligence, model routing, alternate explanations, games, simulations, and generated experiences;
6. define durable competency-evidence projection after Mesh admission and portability semantics are ready;
7. add concrete Education-to-Mesh social collaboration adapters only where private circle/read authority semantics are available and evidenced.
