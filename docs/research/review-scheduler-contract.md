# Review scheduler contract

Tracked by issue #183.

## Boundary

The review scheduler is a pure, deterministic helper behind `AdaptiveEngine`. It may calculate review timing from explicit scheduler state, but it does not decide whether an answer is correct and it does not read or write learner records. `MathAnswerVerifier` and other correctness authorities remain unchanged.

This slice adds no network, credential, device, deployment, storage, persistence, or external-effect path. The existing `nextReviewInterval` call remains available while the new stateful seam is evaluated; no lesson UI or learner-record migration is performed here.

## State and failure semantics

Scheduler state is versioned. Version 1 carries bounded stability, difficulty, repetition, and lapse values. A synthetic version-0 shape exists only to exercise migration behavior in local tests. Migration clips numeric parameters to the current supported bounds. Malformed or unsupported state fails closed to the default state and a one-day review interval rather than silently widening the next review.

The deterministic v1 fixture set in `test/core/services/review_scheduler_test.dart` is the local regression contract for this slice. It is independently generated from the AXIOM-native formula and is not a claim of FSRS conformance.

## External reference

The design review used `open-spaced-repetition/ts-fsrs` release `v5.4.2`, exact release commit `bb71e35a2f5af5a5ac6cce9ef7c41ad24855721d`, as a WATCH / TEST-pattern reference. The useful transfer is explicit scheduler state, deterministic scheduling, migration/version discipline, parameter clipping, and cross-platform test expectations. No upstream package or code is imported.

## Deferred work

Persistence is deliberately deferred. Any future learner-history integration must reuse the existing governed learner-record boundary rather than create a second durable state path. Before replacing the current lesson-facing heuristic, the scheduler should be evaluated against a larger independently generated or published reference-vector set and reviewed for migration compatibility across supported platforms.
