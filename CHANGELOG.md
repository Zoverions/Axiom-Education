# Changelog

All notable changes to Axiom Education are recorded here. The project is still
in active pre-release development and does not yet make production-readiness
claims.

## Unreleased

### Added

- A machine-verified MTH1W course blueprint with 9 units, 43 primary lessons,
  110 estimated hours, complete official-expectation coverage, multi-method
  lesson contracts, unit assessments, and a cumulative assessment plan.
- A bundled offline Unit 1 draft with three source-mapped lessons, six worked
  examples, 33 practice items, a delayed-feedback 10-item quiz with correction
  attempts, a transparent performance task, text alternatives, and explicit
  educator/cultural-review boundaries.
- A bundled offline Unit 2 draft covering exponent patterns, scientific
  notation, and exponent relationships through two method routes, four worked
  examples, 22 practice items, a 10-item quiz, and a scale-comparison task.
- A bundled offline Unit 3 draft covering five rational-number expectations
  through 10 worked examples, 55 practice items, a 10-item quiz, and a
  proportional-decision portfolio task.
- A bundled offline Unit 4 draft covering five algebra expectations through
  evidence-aware mathematical history, visual and table pattern routes,
  equivalence proofs, property-labelled simplification, balance and inverse
  equation methods, 10 worked examples, 55 practice items, a 10-item quiz, and
  a design-and-equation performance task.
- Fail-closed Python and Flutter content loaders plus model, claim, and widget
  tests for the course blueprint and authored unit.
- A fail-closed MTH1W curriculum-readiness declaration and checker pinning the
  official 2021 source digest, known identifier conflicts, required completion
  evidence, and MTH1W-first delivery sequence.
- An in-app and written home-learning routine for two learners sharing a device,
  including a 45-minute session plan, starter week, and adult check-in prompts.
- A distinct-item practice counter and three-item stopping cue that explicitly
  does not represent a grade or mastery result.
- Source-audit and course-completion roadmap documentation: finish verified
  MTH1W, then the remaining Grade 9 courses, then later grades in order.

- A conventional Grade 9 Math Foundations Preview that teaches four
  topic-linked lessons through explicit goals, prerequisites, direct
  instruction, worked examples, misconception checks, reflection prompts, and
  focused deterministic practice. The entire path works offline without an AI
  tutor; official MTH1W mapping remains under review.
- A canonical high-school foundation strategy defining lessons, practice,
  assessment, progress, educator workflows, adolescent-learning principles,
  and the gates that must precede adaptive or tutor enhancements.
- An ephemeral MTH1W practice-session summary showing local answer checks and
  exact successes. The counters exist only while the practice screen is open
  and are never written to a learner record.
- `python tools/verify.py` as the canonical clean verification command. It
  validates the supported toolchain, installs pinned Python and locked Dart
  dependencies, verifies capability claims, checks formatting and analysis,
  and runs the complete Python and Flutter test suites.

### Fixed

- Windows benchmark cleanup now closes the shared read-only SQLite curriculum
  database and disposes its Riverpod container before removing temporary
  directories.
- Test-only Dart packages are declared directly instead of relying on
  transitive dependencies.
- Deprecated Flutter color APIs, redundant imports, and analyzer findings were
  removed.

### Changed

- The four current lessons and practice generators are now labelled **Grade 9
  Math Foundations Preview** with derived local topic references. Full MTH1W,
  credit, grade, transcript, Ministry-approval, and school-equivalency claims
  remain blocked after the official-source audit found identifier conflicts.

- CI now runs the complete Python suite and the canonical verification command.
- Dart formatting is enforced across the full `lib` and `test` trees.
- Existing Dart sources and tests were normalized with Dart 3.11 formatting.
