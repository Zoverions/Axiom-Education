# Changelog

All notable changes to Axiom Education are recorded here. The project is still
in active pre-release development and does not yet make production-readiness
claims.

## Unreleased

### Added

- A conventional MTH1W course path that teaches four curriculum-bound lessons
  through explicit goals, prerequisites, direct instruction, worked examples,
  misconception checks, reflection prompts, and focused deterministic
  practice. The entire path works offline without an AI tutor.
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

- CI now runs the complete Python suite and the canonical verification command.
- Dart formatting is enforced across the full `lib` and `test` trees.
- Existing Dart sources and tests were normalized with Dart 3.11 formatting.
