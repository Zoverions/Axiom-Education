# Claw Academy v2

Status: flagship experience architecture; not a promoted production capability.

## Product role

Claw Academy is the most ambitious learning experience built on Axiom Education, not a parallel education backend.

Schools, homeschool environments, tutors, families, adult learners, and future experiences should all be able to use the same:

- competency graph;
- curriculum capsules and assurance records;
- learner-owned evidence;
- institutional relationships and authority;
- guardian/educator policy inputs;
- resource intelligence;
- social collaboration privacy;
- model routing;
- instructional-effectiveness evidence;
- credential and interoperability boundaries.

Claw adds a highly adaptive, narrative, visual, interactive, game-capable experience shell over those services.

## North star

Claw Academy should aim to become the most useful and effective educational experience available to a learner, but it must earn that status through evidence rather than claim it by design.

The optimization target is:

> durable and transferable learning, achieved with learner agency, accessibility, privacy, safety, and efficient use of learner time, human support, money, and compute.

Novelty is valuable only when it improves one or more of those outcomes without violating the hard constraints.

## The experience is a graph, not a course slideshow

A conventional LMS assumes a sequence such as:

```text
unit -> lesson -> page -> quiz
```

Claw v2 should instead render an experience graph:

```text
competency target
   |
   +-> story/comic panel
   |      |
   |      +-> visual explanation
   |      +-> generated or reviewed video
   |      +-> character interaction
   |
   +-> worked example
   |      |
   |      +-> retrieve next step
   |      +-> ask why
   |      +-> alternate representation
   |
   +-> simulation / game / build challenge
   |
   +-> peer / tutor / teacher help
   |
   +-> transfer challenge
   |
   +-> later retention check
```

The learner may take different routes through the graph while the governed competency target and evidence requirements remain explicit.

## Storyboard panels

A panel is a reusable unit of experience rather than a static rectangle of content.

A panel can display or launch:

- story or comic content;
- explanation text;
- diagram, image, animation, or manipulable representation;
- worked example;
- learner choice;
- response field;
- adaptive hint;
- admitted video or OER resource;
- simulation;
- game;
- code/build challenge;
- real-world observation;
- peer or group task;
- teacher/tutor help request;
- AI Socratic dialogue;
- metacognitive reflection;
- retrieval checkpoint;
- transfer problem;
- project artifact;
- evidence candidate.

A panel declares:

- its target competencies;
- its instructional strategy or strategies;
- required device capabilities;
- required accessibility capabilities;
- content/readiness tags;
- expected evidence;
- fallback panels.

This makes the visual experience separable from curriculum truth and learner authority.

## Personal story layer

A learner may opt into a persistent fictional character/avatar or other story identity.

That identity can be used to personalize scenes, challenges, generated media, and narrative continuity without requiring the learner's real public identity.

The character layer is optional. A learner who wants a conventional textbook-like experience can use the same competency path without a story wrapper.

If a remote model or external generator needs character information, the exact story-character scope must be part of the model context grant. The system must not send the learner's full profile merely because a scene is personalized.

## Instructional mixture

Claw should choose among evidence-backed strategies rather than lock a learner into a permanent style.

For example, one concept might begin with:

```text
brief explanation
-> worked example
-> learner retrieves the next step
-> corrective feedback
-> simulation
-> novel transfer problem
```

Another learner may benefit from:

```text
story problem
-> concrete visual representation
-> peer explanation
-> guided practice
-> project artifact
-> delayed check
```

The route can change again later.

The system should learn contextual statements such as:

> Visual representations followed by stepwise practice have recently worked well for this learner on proportional reasoning.

It should not learn permanent identity statements such as:

> This learner is a visual learner.

## Best methods from around the world

Claw consumes the shared instructional-effectiveness registry, whose current baseline draws from international evidence and standards including:

- EEF evidence synthesis for metacognition/self-regulation, feedback, mastery-oriented learning, and tutoring;
- CAST Universal Design for Learning 3.0;
- OECD Learning Compass, Teaching Compass, and PISA digital-learning frameworks;
- learning-science evidence on worked examples, spacing, retrieval, feedback, explanatory questioning, and transfer;
- emerging randomized evidence for research-designed AI tutoring and human-AI tutor support.

These sources inform strategy eligibility and design patterns. They do not become universal rules.

## External tools

Claw should be able to launch the best available tool for a task while keeping the learner record and authority inside Axiom/Mesh.

Examples include:

- interactive simulations;
- graphing/math tools;
- coding environments;
- creative authoring tools;
- robotics and physical-computing systems;
- educational games;
- Roblox-style or Minecraft-style constructed environments;
- AR/VR experiences;
- language/reading tools;
- accessibility tools;
- external assessments;
- human tutoring services.

The architecture should prefer standards where available:

- OneRoster 1.2 for school roster/gradebook exchange;
- LTI 1.3 / LTI Advantage for tool launch and bounded learning-tool integration;
- CASE 1.1 for competencies/standards;
- QTI 3 for accessible assessment exchange;
- Common Cartridge 1.4 for learning-content packaging;
- Open Badges 3.0 / CLR 2.0 for future portable achievements and learner-controlled records.

A provider-specific adapter is allowed when no suitable standard exists, but it receives only the minimum governed context it needs.

## Model integration

Claw does not call a single permanent model directly.

A panel requests a pedagogical task such as:

```text
task: socratic-tutor
competency: fraction equivalence
context:
  - current learner answer
  - current panel
  - minimized misconception summary
output:
  - one probing question
  - optional hint structure
budget:
  - one model call
  - bounded input/output/cost
```

The Education model router decides which admitted local or remote model is eligible.

The same panel should continue to work when the best model changes.

## Generated video and media

Generated media should be treated as a renderer over a structured learning scene, not as an unconstrained model improvisation.

Preferred pipeline:

```text
competency + panel + strategy
-> structured scene plan
-> verify educational constraints
-> select media renderer
-> generate/render
-> present with accessible alternatives
-> gather explicit feedback and later outcome evidence
```

Where appropriate, the learner's selected fictional character may appear in the scene. Real-person likeness or sensitive identity data requires its own explicit scope and applicable consent.

## Games and construction

Games should not exist to increase session length.

A game challenge should bind to one or more competencies and define what evidence can actually be produced by the interaction.

Good game use cases include:

- manipulating variables in a simulation;
- constructing a system that satisfies constraints;
- debugging code;
- navigating a spatial problem;
- collaborating on a project;
- applying knowledge under novel conditions;
- creating a game or level that demonstrates understanding.

A completion badge or high score is not mastery unless the game mechanic validly measures the competency.

## Social learning

Claw can use shared Education/Mesh social spaces for:

- assignment discussion;
- peer explanation;
- study groups;
- project teams;
- teacher announcements;
- office hours;
- tutoring;
- learner-support spaces.

These spaces retain the need-to-know privacy boundary. A guardian, teacher, principal, or counselor role does not create universal transcript access.

## Human support

The platform should know when not to continue automating.

Possible escalation targets include:

- peer;
- mentor;
- tutor;
- teacher;
- guardian where appropriate;
- guidance counselor/support worker where applicable;
- subject expert;
- external service admitted by policy.

The system should track whether escalation resolved the learning need, while minimizing the retained conversation content.

## Learner feedback

At any meaningful learning moment, the learner should be able to say things such as:

- that helped;
- still confused;
- show another way;
- too fast;
- too slow;
- too easy;
- too hard;
- I liked this example;
- more like this;
- I already knew this;
- I want human help.

Those signals change routing. They do not change curriculum truth or directly establish mastery.

## Evidence loop

The strongest adaptive signal is not whether the learner stayed in the app. It is what happened to learning.

Claw should progressively support:

- immediate task evidence;
- correction after feedback;
- misconception recovery;
- delayed retention;
- transfer/generalization;
- robustness across representations;
- self-assessment calibration;
- help-seeking effectiveness;
- strategy flexibility;
- accessibility success.

This is how the system learns whether a resource, tool, model, or instructional strategy actually helped.

## Starting from zero assumptions

The first interaction does not need to assume age, grade, literacy, speech, camera, microphone, diagnosis, or previous school record.

The entry system can begin with very low-assumption interactions supported by the device, then progressively establish contextual competency evidence.

A school enrollment may provide useful curriculum context, but it does not overwrite demonstrated evidence or turn grade placement into a complete ability model.

## Relationship to Ontario

Ontario is the first major curriculum source family because it is the local development context and has active curriculum-capsule work.

Claw Academy is not an Ontario-only product.

As other curriculum/competency frameworks are admitted to the Mesh, their relationships can be mapped through reviewed crosswalks into the shared competency graph. Claw can then construct a learner path that satisfies applicable local requirements while also drawing from strong global resources and learning strategies.

## Success dashboard

A future Claw dashboard should emphasize outcomes such as:

```text
Target competency: proportional reasoning
Current evidence: emerging
Recent learning gain: positive
Delayed retention: demonstrated at 7 days
Transfer: not yet checked
Misconception: unit-rate inversion resolved twice
Helpful routes lately:
  - worked example + next-step retrieval
  - simulation
Human help: not needed this cycle
Accessibility barriers: none recorded
Model use: 3 local calls, 1 remote call
External cost: $0.04
```

It should not lead with:

```text
streak: 37 days
minutes watched: 412
engagement score: 91
```

## Legacy replacement

The existing `AdaptiveLessonScreen`, `StudentProfile(irtTheta, irtBand)`, and placeholder `AdaptiveEngine` are not the Claw v2 foundation.

They may remain temporarily as legacy/reference surfaces while the rebuild lands, but the new authoritative adaptation path should be:

```text
competency graph
+ contextual learner evidence
+ readiness/accessibility policy
+ instructional-effectiveness registry
+ resource/tool/model/human options
-> bounded next experience
```

A synthetic theta or hard-coded Ontario level must not become an official assessment, mastery, grade, or placement decision.

## Build order

1. stabilize and validate the shared institution/resource/evidence/model/entry foundation;
2. add shared instructional-strategy/effectiveness models and evidence records;
3. add Claw experience-graph models and a generic panel renderer;
4. build one small end-to-end story arc against a few foundational competencies;
5. connect alternate explanation/resource feedback;
6. connect model-routed Socratic tutoring;
7. connect one simulation and one game/build adapter;
8. add delayed retention and transfer checkpoints;
9. add human/peer help launch through the collaboration boundary;
10. compare the new path against the legacy adaptive session using meaningful learning outcomes, not time-on-app.

## Non-claim

Claw Academy v2 is a design and executable-contract direction. It is not yet an accredited school, a proven globally superior educational intervention, or a production system for minors. Its purpose is to create an architecture capable of earning those kinds of effectiveness claims through transparent evidence over time.
