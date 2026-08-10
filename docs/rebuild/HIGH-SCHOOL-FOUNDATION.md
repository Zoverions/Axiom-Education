# High-School Foundation Strategy

**Status:** Canonical product sequencing decision
**Initial course:** Ontario Grade 9 Mathematics (`MTH1W`)
**Updated:** 2026-08-10

## Decision

Axiom Education must be a useful high-school learning platform when every AI,
adaptive, network, and learner-record capability is unavailable.

The product will establish the conventional school experience first:

```text
course → unit → lesson → worked example → guided practice
       → independent practice → quiz/unit assessment → review
```

Adaptive sequencing and an AI tutor may enhance that path later. They may not
become prerequisites for opening a lesson, understanding the taught method,
attempting standard exercises, receiving deterministic feedback, or reviewing
course material.

## What “traditional first” means

The baseline student experience must include:

1. curriculum-aligned courses organized into understandable units and lessons;
2. visible learning goals, prerequisite knowledge, and estimated lesson scope;
3. teacher-authored direct instruction with vocabulary, notation, and examples;
4. fully worked examples that make reasoning and intermediate steps visible;
5. guided practice with graduated hints;
6. independent exercises with task-specific feedback and another attempt;
7. conventional quizzes, unit tests, review sets, and transparent scoring;
8. a student-owned view of assigned work, completion, evidence, and next steps;
9. educator assignment, review, accommodation, and correction workflows; and
10. dependable offline operation for downloaded courses.

Items 1–6 now have executable authored slices for the four Grade 9 math
foundation topics and all nine source-mapped MTH1W unit drafts. Each authored
unit lesson exposes multiple valid reasoning routes and representations while
keeping one outcome and one quality standard. The older foundation topics retain
preliminary local identifiers; the nine authored units bind to B1.1 through
F1.4 in the verified official inventory. The
[source audit](../curriculum/MTH1W-SOURCE-AUDIT.md) records the distinction and
known legacy conflicts. Item 7 has a unit-quiz and performance-task slice for
all nine authored units, but cumulative assessment review remains open. Items 8
and 9 remain product requirements. Durable progress remains disabled until the
governed learner-record path is available.

## Source-mapped MTH1W build

The complete conventional course blueprint defines 9 units, 43 primary
lessons, and 110 estimated hours. All nine planned unit slots are now authored
as machine-verified drafts:

- Unit 1 maps B1.1 through B1.3 and contains 3 lessons, 6 worked examples, 33
  practice items, a delayed-feedback 10-item quiz, and an educator-reviewed
  performance-task contract.
- Unit 2 maps B2.1 through B2.2 and adds exponent-pattern, place-value,
  factor-expansion, and operation-pattern routes through 2 lessons, 4 worked
  examples, 22 practice items, a 10-item quiz, and a scale-comparison task.
- Unit 3 maps B3.1 through B3.5 through five rational-number lessons. Number-line,
  measurement, exact-computation, unit-rate, percentage, and equivalent-ratio
  routes connect signed quantities, fractions, rates, and proportions.
- Unit 4 maps C1.1 through C1.5 through five algebra lessons using bounded
  historical-source evidence, pattern tables, visual decomposition, area
  models, counterexamples, algebra tiles, labelled properties, balance models,
  and inverse operations.
- Unit 5 maps C2.1 through C2.3 through three device-optional mathematical-coding
  lessons using hand tracing, pseudocode, flowcharts, invariant checks,
  prediction, debugging, and controlled revision.
- Unit 6 maps C3.1 through C4.4 through seven relations and analytic-geometry
  lessons using difference tables, connected representations, graphical and
  algebraic model comparison, test points, coordinate mappings, and slope
  construction. Every visual route includes a nonvisual equivalent.
- Unit 7 maps D1.1 through D2.5 through eight data-analysis and modelling lessons.
  Lifecycle maps, stakeholder scenarios, ordered plots, residuals, source
  audits, candidate-model comparison, and prediction stress tests support a
  safe iterative modelling process. Direct collection is adult-approved,
  minimized, non-sensitive, and optional because a public-data route exists.
- Unit 8 maps E1.1 through E1.6 through six geometry and measurement lessons.
  Source-aware cultural geometry, constrained construction, measurement units,
  similarity and scale, Pythagorean reasoning, and composite/three-dimensional
  measurement use individually reviewable split lesson assets. Python and
  Flutter materialize the split package through the same canonical unit-content
  model used by the earlier units.
- Unit 9 maps F1.1 through F1.4 through four financial-literacy lessons grounded
  in Ontario curriculum context plus Bank of Canada and Financial Consumer
  Agency of Canada sources. Learners analyse sourced financial context,
  appreciation/depreciation, disclosed borrowing scenarios, and budget changes.
  The activities compare fictional classroom scenarios and explicitly do not
  recommend financial products or personal financial action.

Across the nine authored draft units there are 43 lessons, 86 worked examples,
473 guided/independent/retrieval practice items, 90 unit-quiz items, and nine
performance tasks. These are machine-verified draft artifacts, not reviewed
course-completion evidence.

Human educator review, cultural review where applicable, licensing and
redistribution disposition, reviewed course-wide expectation coverage,
cumulative assessment review, printable/accessibility alternatives, governed
progress, and educator workflows are still open gates.

## Current Grade 9 math foundations preview

The course screen separately presents four sequenced foundation lessons:

| Lesson | Derived local topic reference | Conventional instruction |
|---|---|---|
| Order of operations with rational numbers | `MTH1W-A1` | rule-and-line and expression-tree routes; symbolic, tree, and verbal representations |
| Percentages and proportional reasoning | `MTH1W-A2` | decimal-multiplier and proportion routes; grid, double-number-line, and equation representations |
| Solving linear equations | `MTH1W-B2` | balance-model and inverse-operation routes; balance, algebraic-line, and substitution representations |
| Equation of a line from two points | `MTH1W-B4` | change-table and slope-formula routes; graph, table, and equation representations |

The instructional notes are version-controlled, human-authored application
content. Each lesson is joined at runtime to a topic record loaded from the
integrity-checked local curriculum database. This proves consistent local
binding, not official curriculum accuracy. A missing required record fails
closed; the app does not substitute an ungrounded lesson.

The practice flow remains deterministic and local. It counts different checked
items and offers three as a practical stopping cue. Session results are
ephemeral and are not grades, mastery claims, or learner records. The preview
also includes an in-app home-learning routine for two learners sharing a
device.

The [Global Instructional Methods Baseline](../research/GLOBAL-INSTRUCTIONAL-METHODS.md)
defines the production lesson contract. Multiple methods are task strategies,
not fixed learner types; a student may compare them and choose the route that
makes the current relationship clearest.

## Product patterns used as inspiration

These sources inform the pattern, not the wording or visual design:

- [Khan Academy Algebra 1](https://www.khanacademy.org/math/algebra-1-eureka-squared-aligned)
  demonstrates a student-visible course and unit hierarchy with skills,
  quizzes, unit tests, and a course challenge.
- The US Institute of Education Sciences practice guide
  [Organizing Instruction and Study to Improve Student Learning](https://ies.ed.gov/ncee/wwc/PracticeGuide/1)
  recommends spacing, alternating worked examples with problem solving,
  retrieval through quizzes, linking representations, and explanatory
  questions.
- The Education Endowment Foundation guidance on
  [teacher feedback](https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports/feedback)
  places high-quality initial instruction and formative assessment before
  feedback.
- The EEF guidance on
  [metacognition and self-regulated learning](https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports/metacognition%20)
  supports explicitly teaching, modelling, and scaffolding how students plan,
  monitor, and evaluate their learning inside subject lessons.
- [CAST Universal Design for Learning Guidelines 3.0](https://udlguidelines.cast.org/action-expression/)
  inform clear goals, links to prior knowledge, graduated support,
  action-oriented feedback, learner choice, and accessible ways to respond.

## Adolescent psychology and school-environment principles

High-school students should be treated as developing, capable learners rather
than engagement metrics. The interface and future classroom features must:

- combine meaningful choice with clear structure and boundaries;
- explain why a topic matters without manipulative urgency or reward loops;
- frame mistakes as information about the task, not a judgment of ability;
- build competence through attainable steps, visible reasoning, and specific
  feedback;
- use age-respectful language and avoid childish gamification;
- create space for planning, monitoring, explanation, and reflection inside
  the academic task;
- support belonging and future teacher/peer connection without pretending an
  automated system is a human relationship;
- never infer emotion, disability, diagnosis, motivation, or protected traits
  from ordinary mistakes, timing, hint use, or navigation; and
- avoid high-stakes labels or recommendations from sparse, unvalidated data.

The APA resource on
[academic caring for adolescents](https://www.apa.org/education-career/k12/academic-caring-adolescents)
highlights value, autonomy support, structure, and family communication. CDC
research describes school connectedness as feeling cared for, supported, and
that one belongs, and reports associations with adolescent academic and health
outcomes in its
[2021 high-school survey analysis](https://www.cdc.gov/mmwr/volumes/72/ss/ss7201a2.htm).
These principles inform future educator and classroom work; the current local
app does not claim to create school connectedness by itself.

## Delivery order

The canonical content sequence is fixed:

1. complete and verify the official MTH1W course;
2. complete the remaining Grade 9 course catalogue one course at a time; and
3. move through later grades in order.

The full ledger and definition of course completion are in
`docs/rebuild/COURSE-COMPLETION-ROADMAP.md`.

### Foundation A — teach and practise

- Preserve and verify the complete official MTH1W inventory recorded in the
  [coverage ledger](../curriculum/MTH1W-COVERAGE-LEDGER.md).
- Complete educator, cultural where applicable, and licensing review before
  representing authored lessons as reviewed official coverage or redistributing
  official wording.
- Review all `MTH1W` authored lessons against the official bindings,
  instructional scope, and source evidence.
- Complete mixed review and cumulative assessment evidence across the course,
  not only unit-level quizzes and tasks.
- Complete printable/offline and accessible alternatives for every required
  learning and assessment action.

### Foundation B — school workflow

- Add governed student progress, assignments, due dates, resubmission, and
  transparent grade/evidence views.
- Add educator course planning, review, feedback, accommodation, and appeal.
- Add classroom and guardian communication only through approved identity,
  consent, and synchronization paths.

### Enhancement C — adaptation

- Introduce transparent, reversible recommendations based on sufficient
  evidence, beginning with deterministic review scheduling.
- Allow students and educators to inspect and override the recommendation.
- Keep uncalibrated heuristics visibly separate from mastery or grades.

### Enhancement D — optional tutor

- Add a governed tutor only after provider, grounding, verification, safety,
  and evaluation gates pass.
- The tutor may explain, question, or suggest; it may not silently grade,
  diagnose, mutate learner records, or replace the conventional course path.

## Foundation completion gate

The high-school foundation is not complete until a student can finish a full
course without AI: navigate every unit, receive reviewed instruction, study
examples, complete practice and assessments, understand feedback, review prior
material, and use accessible alternatives; and an educator can assign, inspect,
correct, and review that work through governed records. Passing authored-content
and software verification is necessary but not sufficient.