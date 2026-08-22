# Lifelong Learning and Experience Providers

Status: architecture framework; not a promoted capability.

## Goal

Axiom Education should preserve one portable learning history and competency/evidence graph across childhood, secondary school, post-secondary study, employment, retraining, hobbies, civic learning and later life.

CLAW Academy is the first elementary experience product. It is **not** intended to become the only lifelong user interface or to force an elementary brand onto adults.

The durable layer is Axiom Education. Experience shells may change as the learner grows while the learner's governed identity, evidence, goals, preferences, standards history and portfolio remain portable.

## Experience progression

One possible product progression is:

```text
CLAW Academy
  elementary learning experience
        |
        v
secondary learning experience
  deeper subject work, projects, collaboration, career exploration
        |
        v
post-secondary / apprenticeship / professional experience
  formal courses, credentials, research, work-integrated learning
        |
        v
lifelong learning
  reskilling, hobbies, civic learning, health/safety training,
  professional development, personal projects
```

The exact product names are intentionally left open. Product branding must not determine the underlying learning record schema.

## Learner continuity

A learner's durable state should be expressed through portable domain objects rather than app-specific account rows.

Examples:

- goals;
- active jurisdiction/program context;
- standards-pack history;
- competency evidence;
- activity/event history;
- projects and artifacts;
- reviewed assessments;
- portfolio objects;
- accessibility/preferences supplied by the learner or authorized adult;
- resource-selection evidence;
- credentials/recognition where independently verified;
- challenge, appeal and correction records.

A new experience shell may read only the scopes it is authorized to use.

## Product-level adaptation

As the learner matures, adaptation can shift from guardian/educator-directed pathways toward learner-directed goals.

Examples:

```text
elementary:
  short activities, story/game scaffolds, adult guidance

secondary:
  larger projects, collaborative work, deeper explanation,
  elective paths and explicit study strategies

post-secondary:
  independent research, simulation, labs, domain tools,
  peer review and professional standards

adult/lifelong:
  outcome-driven learning plans, work/hobby projects,
  targeted skill acquisition and self-selected evidence
```

The platform should create useful friction when friction improves learning: retrieval before hints, explanation before answer reveal, revision after feedback, deliberate practice, peer review, or reflection after a consequential decision. It should remove friction that is unrelated to the learning objective, such as inaccessible interfaces, unnecessary repetition, account bureaucracy or forced one-format instruction.

## External experience providers

Learning can occur outside the Axiom user interface. Axiom Education therefore needs a bounded **experience provider** model.

Candidate provider classes include:

- virtual worlds and game platforms;
- coding platforms;
- robotics/maker environments;
- simulations;
- laboratories;
- museums/libraries;
- video/OER providers;
- creative tools;
- collaboration platforms;
- physical-world activity providers;
- employer/apprenticeship systems;
- future digital-agent learning environments.

Roblox is an example of a possible future provider, not a hardcoded platform dependency.

## Mission pattern

A learning mission can leave the Axiom shell while remaining governed:

```text
Axiom activity/mission definition
  -> selected external provider
  -> bounded mission token/context
  -> learner creates or performs externally
  -> provider returns a signed/verified result or artifact reference
  -> Axiom verifies the declared evidence profile
  -> learner-event append
  -> optional peer/educator review
  -> portfolio inclusion
```

Example concept:

```text
mission: Design a cooperative Roblox world around resource allocation
CLAW competencies:
  systems thinking
  perspective-taking
  collaboration
  ethical trade-off analysis
official mappings:
  derived from active jurisdiction crosswalks
external artifact:
  world/project identifier + immutable evidence snapshot/digest where possible
social phase:
  peers visit, test, discuss and review
```

The provider never receives unrestricted learner state merely because a mission uses it.

## Experience-provider contract principles

A provider integration must declare:

- provider ID/version;
- exact supported actions;
- data requested from Axiom;
- data returned to Axiom;
- identity correlation behavior;
- age eligibility;
- guardian/institution requirements;
- privacy/tracking/advertising properties;
- moderation/safety assumptions;
- content ownership/licensing;
- result verification profile;
- artifact portability;
- retention/deletion behavior;
- outage/failure behavior;
- external effect destination;
- assurance limitations.

Installing or discovering a provider grants no authority.

## Social and collaborative learning

Axiom Education should support collaboration among learners with different ages, capabilities and roles without converting social participation into unrestricted data sharing.

Possible patterns:

- peer project teams;
- older learner mentorship;
- skill-based temporary teams;
- family projects;
- cross-school challenges;
- public/open project galleries;
- private classroom collaboration;
- asynchronous critique;
- cooperative missions;
- community problem-solving.

Participation requires explicit audience and disclosure scopes.

## Cross-age collaboration

Mixed-age collaboration can be educationally valuable, but it adds safeguarding and authority requirements.

A mission profile should state:

- permitted age/role ranges;
- whether direct messaging is allowed;
- moderation/review requirements;
- whether adult supervision is required;
- what identity information is disclosed;
- whether artifacts are public, group-private or private;
- reporting/blocking/remedy paths.

No global assumption that cross-age interaction is appropriate for every activity is made.

## Learner-generated worlds and artifacts

Learners should be able to build artifacts that become resources for other learners where appropriate.

An artifact can move through explicit states such as:

```text
private draft
  -> submitted
  -> reviewed
  -> classroom/shared
  -> public/reusable
  -> superseded/withdrawn
```

Publishing another learner's work as reusable content is a separate authority event from completing the work.

## Expert teaching knowledge

Axiom Education should draw from global teaching practice and peer-reviewed learning science, but should distinguish evidence sources.

Instructional method evidence can come from:

- systematic reviews/meta-analyses;
- controlled studies;
- high-quality observational research;
- curriculum/education authority guidance;
- expert educator review;
- aggregate platform outcome evidence;
- learner-specific recent evidence;
- learner/educator preference.

These are not one interchangeable score.

Methods should be selected for the task/context rather than assigning learners permanent pseudoscientific learning-style identities.

## Useful friction

The adaptive engine should explicitly support **productive friction** as a controllable instructional variable.

Examples:

- require recall before revealing the answer;
- ask for a prediction before showing a simulation;
- require an explanation before accepting a high-confidence response;
- delay a hint briefly when the learner is likely able to retrieve the answer;
- revisit material after spacing;
- require revision after feedback;
- ask learners to compare competing explanations;
- include disagreement/peer critique where safe;
- require a plan before opening a complex creation tool.

Friction should have an educational rationale, bounded duration and escape/help route. It must never be optimized for frustration, punishment or engagement addiction.

## Governance and civic learning bridge

Axiom Education may later expose **governance simulations and real bounded participation** as learning experiences through a separate Axiom Governance domain.

Examples:

- classroom/community proposals;
- mock or real Circle decisions within declared scope;
- citizen/expert deliberation exercises;
- budget/trade-off simulations;
- evidence review;
- policy comparison;
- public challenge/correction exercises.

Education does not make a governance decision authoritative. Axiom Governance supplies the participation/decision protocol; Education supplies learning context and reflection.

## Digital participants

Digital entities may act as tutors, critics, simulators, role-players, research assistants or participants only under explicit machine-principal authority and disclosure.

A digital entity's confidence or expertise claim is not accepted merely because the model produced fluent output. Its role, source access, evaluation profile and permitted effects must be declared.

## Portable hosting and recovery

Experience applications should never become the only copy of the learner's durable state.

The target architecture supports local-first state plus configurable encrypted replicas/backups through AXIOM-MESH. Cloud/object storage, institutional storage or future peer/decentralized archives may provide availability without receiving authority to interpret or modify the state.

## Promotion boundary

Before a real external experience provider can be promoted:

1. provider contract/schema;
2. privacy/safety review;
3. exact authority/data scopes;
4. failure and revocation tests;
5. artifact/result verification;
6. age/safeguarding profile where applicable;
7. evidence-binding tests;
8. independent review for consequential providers;
9. explicit capability registry status;
10. truthful UI/non-claims.
