# Review scheduler candidate

Status: **bounded algorithm candidate; not integrated into learner-record persistence or lesson UI**.

This work is tracked under issue #183. It evaluates whether Axiom Education can replace the current placeholder `AdaptiveEngine.nextReviewInterval(...)` heuristic with a learner-history-aware review scheduler without changing correctness authority or introducing a new storage/network path.

## Current slice

`lib/core/services/fsrs_day_scheduler.dart` is a pure, deterministic, day-granularity scheduling candidate. It accepts only explicit in-memory state, elapsed whole days, and a learner review rating, then returns an interval plus a proposed next in-memory state.

It does **not**:

- read or write learner records;
- create a persistence schema or migration job;
- call a provider or network service;
- use credentials, device APIs, deployment APIs, or external authority;
- decide whether an answer is correct;
- modify or bypass `MathAnswerVerifier`;
- replace `AdaptiveEngine.nextReviewInterval(...)` in the current lesson UI yet.

Invalid elapsed time, malformed state, or an unsupported state schema version fails closed to a one-day review interval and returns no next state. Creating the first scheduler state requires `elapsedDays == 0`; a nonzero elapsed value without prior state also fails closed rather than being silently ignored. The public forgetting-curve helper explicitly rejects negative elapsed time and non-finite or non-positive stability inputs. The caller therefore cannot silently persist a fabricated migration result or receive a misleading first-state schedule.

## Reference and claim boundary

The formulas and default parameter vector are adapted from `open-spaced-repetition/ts-fsrs` release `v5.4.2`, exact commit `bb71e35a2f5af5a5ac6cce9ef7c41ad24855721d`, which identifies its current algorithm as FSRS-6. The upstream project is MIT-licensed; attribution and the licence text are preserved in `THIRD_PARTY_NOTICES.md`.

The local regression suite pins published upstream reference vectors for:

- the forgetting curve;
- difficulty updates;
- recall stability;
- forgetting stability; and
- short-term stability.

This does not claim full ts-fsrs compatibility. The candidate intentionally omits learning/relearning step queues, fuzzing, timestamp scheduling, parameter optimization, package bindings, and persistence behavior. Those omissions keep this slice pure and reversible while Axiom Education evaluates the scheduling contract.

## Authority boundary

Review scheduling is advisory personalization. A longer or shorter review interval never constitutes evidence that an answer is correct, never grants a learner or agent capability, and never changes consent or authorization state. Correctness remains owned by the repository's existing correctness authority.

## Next gate

Before any lesson-UI or learner-record integration:

1. exact-head unit/analyzer/platform checks must be green;
2. state/version migration semantics must be reviewed against the existing learner-record boundary rather than creating a parallel store;
3. parameter migration/clipping must remain bounded and testable if configurable parameters are introduced;
4. any UI integration must retain a conservative one-day fallback when scheduler state cannot be safely interpreted; and
5. documentation and compatibility tests must move with the integration.
