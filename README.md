# Axiom Education

Axiom Education is a local-first adaptive learning platform built as the education domain layer for AXIOM-MESH.

**Current rebuild:** `0.5.0-dev.0`  
**Status:** active development; not production-ready  
**Canonical repository:** `Zoverions/Axiom-Education`  
**Canonical branch:** `main`  
**First curriculum capsule:** Ontario Secondary Curriculum Pack

The historical product and repository name `OntarioEdAI` is deprecated. Ontario remains the first supported jurisdictional curriculum pack because its source corpus is present; it is not the identity or architectural boundary of the platform. The former repository URL is retained only through GitHub's compatibility redirect.

See the [Repository Rename Record](docs/REPOSITORY-MIGRATION.md), [Branch Hygiene Policy](docs/BRANCH-HYGIENE.md), and [Deprecations](docs/DEPRECATIONS.md).

## Product boundary

```text
Axiom Education application
  -> AXIOM Gateway
  -> policy, consent, risk, and plan evaluation
  -> short-lived capability grant
  -> approved education or provider capsule
  -> bounded execution
  -> encrypted learner state and evidence in Grid
```

The Flutter application remains independently releasable. AXIOM-MESH supplies the policy, consent, bounded execution, evidence, portability, and synchronization substrate for governed effects.

Installing a curriculum or education capsule does not grant access to learner records, activate a provider, or authorize execution.

## Current usable surface

The runnable application provides a local Ontario curriculum browser and the first bounded MTH1W practice slice:

- recoverable first-run initialization;
- a searchable list of courses and expectation counts;
- course, strand, expectation, and tag browsing;
- pull-to-refresh and explicit retry states;
- automatic restoration of a missing or invalid bundled curriculum database;
- a read-only curriculum database and a separate local settings store;
- deterministic offline practice for `MTH1W-A1`, `MTH1W-A2`, `MTH1W-B2`, and `MTH1W-B4`;
- actual answer entry with exact rational and slope-intercept verification;
- item-linked scaffolded hints, exact expectation IDs, uncalibrated difficulty disclosure, and digest evidence;
- fail-closed behavior when the practice configuration, item integrity, or verifier is unavailable.

The MTH1W practice phase does **not** use tutor inference or write a learner record. The application does **not** currently provide governed learner records, pack activation, educator review and appeal, portfolio export, or classroom synchronization. Those paths remain disabled, specified, or adapter-required in [`config/capabilities.json`](config/capabilities.json).

The scope and negative-path gates are frozen in [MTH1W Phase 0 and Phase 1](docs/vertical-slices/MTH1W-PHASE-1.md).

## First five minutes

Supported rebuild toolchain:

- Flutter `3.41.1`
- Dart `3.11.x`
- Python `3.12` for curriculum and claim verification
- OpenSSL 3.x for external-key Ed25519 curriculum-pack signing

```bash
flutter pub get --enforce-lockfile
python tools/check_capabilities.py
python -m unittest discover -s tests -p 'test_*.py' -v
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

For an Android installation smoke build:

```bash
flutter build apk --debug
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. The protected GitHub workflow also builds this APK and publishes it as a short-lived workflow artifact after formatting, analysis, and tests pass.

Desktop runs require the corresponding Flutter desktop toolchain to be enabled. For example:

```bash
flutter config --enable-windows-desktop
flutter run -d windows
```

## Axiom Education contract

The generic cross-repository contract is [`contracts/axiom-education.v1.json`](contracts/axiom-education.v1.json).

- Brand: `Axiom Education`
- Contract ID: `axiom.education`
- Version: `1.0.0`
- Curriculum-pack profile: `jurisdictional`
- Gateway: `POST /v1/intents`
- Installation grants authority: `false`

The contract defines bounded curriculum inspection, staging, activation, querying, tutoring, learner-event, progress, and portfolio actions. Learner-data actions require exact purpose-bound consent. High-risk activation and export require explicit confirmation and independent approval.

A missing provider, verifier, identity, policy, consent, source, or artifact must produce an explicit unavailable or denied result. It must never produce mock success in a governed or release build.

## Current capability status

The authoritative status registry is [`config/capabilities.json`](config/capabilities.json).

Presently:

- curriculum browsing from a schema-verified bundled SQLite database is implemented;
- the Ontario curriculum corpus deterministically builds into 293 canonical records across 21 courses;
- the frozen MTH1W subset is checked against the full corpus and independently rebuilt twice byte-for-byte;
- MTH1W A1, A2, B2, and B4 practice generation and exact local checking are experimental and explicitly bounded to those four expectations;
- curriculum-pack generation, digest verification, and external-key Ed25519 signing are experimental and do not authorize activation;
- Ontario-derived records and Axiom Education extensions use visibly separate namespaces and official-recognition flags;
- legacy `irt_*` values are exported only as visibly uncalibrated adaptation heuristics;
- local tutor inference is disabled, fails closed, and no longer returns simulated logits output;
- canvas observation is an explicitly experimental bounded classifier and no longer returns mock equations;
- handwriting scoring no longer returns fixed synthetic scores when its model is missing;
- the legacy UDP/TCP classroom mesh is disabled by default, AES-GCM protected when explicitly enabled for development, and is not a trusted authority path;
- governed learner records, selective portfolio export, accessibility gates, pack activation, and AXIOM classroom synchronization remain specified or adapter-required.

## Ontario Curriculum Pack

Build a deterministic unsigned pack into an empty directory:

```bash
python tools/curriculum_pack.py build \
  --input assets/curriculum/ontario_curriculum_full.json \
  --ledger curriculum/source-ledger.v1.json \
  --output /tmp/axiom-education-ontario \
  --pack-id ontario-secondary \
  --pack-version 1.0.0
```

Build the frozen MTH1W phase-one subset:

```bash
python tools/curriculum_pack.py build \
  --input curriculum/slices/mth1w.v1.json \
  --ledger curriculum/source-ledger.v1.json \
  --output /tmp/axiom-education-mth1w \
  --pack-id ontario-mth1w-phase-1 \
  --pack-version 1.0.0
```

Verify content integrity:

```bash
python tools/curriculum_pack.py verify \
  --pack-dir /tmp/axiom-education-ontario
```

The protected workflow builds the complete Ontario pack twice and compares `manifest.json` and `records.jsonl` byte-for-byte. It also verifies that the frozen MTH1W subset contains exactly 11 source-identical records and produces byte-identical repeated builds. The complete pack is then signed with an ephemeral Ed25519 key and must pass signature verification.

Retrieval indexes are disposable derived artifacts. They are never the authority for curriculum content.

## Curriculum trust boundary

A valid pack signature proves that the exact canonical manifest was signed by the corresponding private key. It does not prove:

- Ontario Ministry approval;
- curriculum correctness or completeness;
- licensing or redistribution permission;
- pedagogical quality;
- safe application activation.

The source ledger records that upstream official-document digests have not yet been captured and that course-by-course source and licensing review remains required.

## Canonical documents

- [Product definition](docs/rebuild/PRODUCT-DEFINITION.md)
- [Evidence-gated requirements](docs/rebuild/REQUIREMENTS.md)
- [MTH1W Phase 0 and Phase 1](docs/vertical-slices/MTH1W-PHASE-1.md)
- [Curriculum Pack v1](docs/curriculum/CURRICULUM-PACK-V1.md)
- [Repository rename record](docs/REPOSITORY-MIGRATION.md)
- [Branch hygiene policy](docs/BRANCH-HYGIENE.md)
- [Deprecations](docs/DEPRECATIONS.md)
- [Current curriculum source policy](CURRICULUM_SOURCES.md)

Historical research is preserved under `docs/archive/`. When documents conflict, executable behavior and [`config/capabilities.json`](config/capabilities.json) control. Archived or deprecated documents are never current claim authority.

## Security and privacy boundary

The project targets local processing and data minimization, but local-first architecture alone is not a compliance or security claim. Minor-related data defaults prohibit advertising, behavioural targeting, covert attention or emotion monitoring, diagnosis inference, raw prompts in evidence, and raw student work in logs. Human review and appeal remain mandatory design requirements.
