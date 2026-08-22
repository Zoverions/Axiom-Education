# Education Model Integration and Usage

Status: executable routing foundation; no production model provider is activated.

## Principle

Axiom Education does not own one permanent AI model and does not make a model part of the trusted education authority layer.

Education submits a bounded pedagogical task to the AXIOM personal compute fabric. The fabric selects an eligible runtime, model, and compute location under privacy, consent, jurisdiction, retention, safety, capability, deadline, and budget constraints. Only after those hard constraints pass may quality, reliability, latency, cost, and energy influence ranking.

Model output is data. It is not authority.

## Education task classes

The initial task vocabulary includes:

- explain a concept;
- Socratic tutoring;
- generate practice;
- evaluate a practice draft;
- generate a storyboard;
- plan a game or simulation;
- summarize an admitted resource;
- translate;
- perform an accessibility transformation;
- assist within an authorized collaboration context.

These are task classes, not provider bindings. A local model, managed provider, school-hosted model, personal node, or future model can compete for the same task when it satisfies the same governed boundary.

## Context minimization

A model request is assembled from explicit context scopes rather than handing the model the learner's entire profile.

Examples of scopes are:

- target competency;
- current learner input;
- assignment context;
- resource context;
- recent pedagogical feedback;
- a minimized misconception summary;
- accessibility requirements;
- language preference;
- a story/avatar profile when the learner has chosen to use it.

The context grant is task-bound and time-bound. A model cannot ask for more scope and then approve its own request.

The default is **not** to send:

- the full longitudinal learner record;
- raw social history;
- guardian identity;
- school identity;
- diagnosis;
- unrelated prior conversations.

If a task needs one of those data classes in the future, that must be represented as an explicit governed context scope with its own policy.

## Local and remote inference

The Education layer inherits the Mesh compute-placement choices.

A family, learner, institution, or applicable policy may require local-only execution for a task. When local-only is selected, a higher-quality remote model is simply ineligible.

When remote inference is allowed, the exact remote egress and retention class still have to be permitted. Availability of a cloud model is not permission to send learner data to it.

No eligible model means one of two things:

1. fail closed for a model-required task; or
2. use a non-model educational path such as an existing reviewed resource, deterministic exercise, teacher workflow, or local content.

The system must not silently relax privacy or substitute a remote provider merely to keep the experience flowing.

## Usage budgets

Every model task can be bounded by:

- maximum calls;
- maximum input units;
- maximum output units;
- maximum monetary cost;
- maximum wall time.

These budgets can later be composed from learner/family preferences, school/institution funding policy, subscription/service limits, local-device capacity, or a specific assignment's allocation. The source of a budget is governance context; the model cannot raise its own budget.

A fallback candidate is subject to the same remaining budget. Fallback is not a way to escape a cap.

## Usage receipts

After execution, Education should retain a minimized operational receipt containing fields such as:

- pedagogical task class;
- actual provider;
- actual model;
- runtime capsule;
- compute node;
- context-scope identifiers used;
- whether remote egress occurred;
- retention class;
- input/output units;
- actual cost when known;
- latency;
- fallback reason when applicable.

The operational receipt does not need the raw learner prompt or response.

Families, learners, and institutions can therefore see meaningful information such as:

> 14 tutoring calls this week · mostly local · 2 remote calls · $0.18 external cost

without receiving a surveillance transcript of everything the learner said.

Access to raw educational conversations, where they exist, remains governed by the separate collaboration/learner-record privacy rules.

## Funding and payer separation

Who pays for a model call is separate from who may see the learner content.

A school may fund a model budget without gaining blanket access to prompts. A guardian may pay for additional inference without receiving every tutoring transcript. A learner may use owner-local compute with no external monetary charge while still producing a usage receipt for capacity and routing decisions.

Later payment/subscription integration should therefore bind payer, budget source, and settlement separately from learner-data authority.

## Model evaluation

A model should be evaluated by education task class, not by a single global leaderboard.

Useful evidence includes:

- correctness on bounded tasks;
- source-groundedness;
- structured-output validity;
- later learner outcome evidence where appropriate;
- user corrections;
- recovery after misunderstanding;
- latency;
- reliability;
- cost;
- privacy/egress class.

Engagement and commercial margin may not silently expand learner-data disclosure.

## Consequential assessment boundary

A model can create practice, suggest feedback, or propose an evaluation. It cannot by itself create:

- a final grade;
- Ontario credit;
- mastery status with governance consequences;
- a transcript entry;
- accreditation;
- an identity or authority claim;
- a credential.

Consequential assessment requires the applicable deterministic, educator, institution, jurisdiction, or other evidence/verification path.

This protects the system from turning a probabilistic tutor into an unreviewed school authority.

## Claw Academy

Claw Academy uses this same service.

A storyboard panel can request, for example:

```text
task: storyboard
competency: fraction equivalence
context: current story location + learner-selected character profile
required output: structured scene plan
privacy: local preferred, remote allowed for non-sensitive context
budget: one call, bounded input/output/cost
```

A later renderer may turn the resulting scene plan into text, animation, audio, video, a simulation, or a game challenge through separate admitted providers.

Claw therefore does not need to know whether the underlying explanation came from a local small model, a frontier API, a school-hosted model, or a deterministic content template.

## Implemented foundation

This slice adds:

- `contracts/axiom-education-model-routing.v1.json`;
- education model task, capability, and context-scope vocabulary;
- time-bounded `EducationModelContextGrant`;
- per-task `EducationModelBudget`;
- admitted/healthy candidate profiles;
- deterministic hard filtering before quality ranking;
- local-only and remote-egress enforcement;
- minimized `EducationModelUsageReceipt`;
- explicit model-output authority prohibitions;
- tests covering privacy filters, budget filters, context overreach, usage minimization, and authority boundaries.

## Non-claim

This is an Education-side contract and routing model. It does not activate a production model, approve any provider for children's data, prove pedagogical quality, create a production payment path, or promote a new Mesh capability.
