# Axiom Education

Axiom Education is a local-first adaptive learning platform built as the education domain layer for AXIOM-MESH.

**Current rebuild:** `0.5.0-dev.0`  
**Status:** active development; not production-ready  
**Canonical repository:** `Zoverions/Axiom-Education`  
**Canonical branch:** `main`  
**First curriculum capsule:** Ontario Secondary Curriculum Pack

The historical product and repository name `OntarioEdAI` is deprecated. Ontario remains the first supported jurisdictional curriculum pack because its source corpus is present; it is not the identity or architectural boundary of the platform. The former repository URL is retained only through GitHub's compatibility redirect.

See the [Repository Rename Record](docs/REPOSITORY-MIGRATION.md) and [Deprecations](docs/DEPRECATIONS.md).

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

## First five minutes

Supported rebuild toolchain:

- Flutter `3.41.1`
- Dart `3.11.x`
- Python `3.12` for curriculum and claim verification
- OpenSSL 3.x for external-key Ed25519 curriculum-pack signing

```bash
flutter pub get --enforce-lockfile
python tools/check_capabilities.py
python -m unittest discover -s tests -p 'test_curriculum_pack.py' -v
flutter analyze
flutter test
flutter run -d windows
```

The current application opens the Axiom Education diagnostic browser over the bundled Ontario curriculum database. The learner workspace, live AXIOM transport, configured tutor provider, encrypted learner records, governed pack activation, and governed classroom synchronization remain rebuild work.

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

Verify content integrity:

```bash
python tools/curriculum_pack.py verify \
  --pack-dir /tmp/axiom-education-ontario
```

The protected workflow builds the complete Ontario pack twice and compares `manifest.json` and `records.jsonl` byte-for-byte. It then signs one build with an ephemeral Ed25519 key and requires successful signature verification.

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
- [Curriculum Pack v1](docs/curriculum/CURRICULUM-PACK-V1.md)
- [Repository rename record](docs/REPOSITORY-MIGRATION.md)
- [Deprecations](docs/DEPRECATIONS.md)
- [Current curriculum source policy](CURRICULUM_SOURCES.md)

Historical research is preserved under `docs/archive/`. When documents conflict, executable behavior and [`config/capabilities.json`](config/capabilities.json) control. Archived or deprecated documents are never current claim authority.

## Security and privacy boundary

The project targets local processing and data minimization, but local-first architecture alone is not a compliance or security claim. Minor-related data defaults prohibit advertising, behavioural targeting, covert attention or emotion monitoring, diagnosis inference, raw prompts in evidence, and raw student work in logs. Human review and appeal remain mandatory design requirements.
