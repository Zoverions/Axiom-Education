# OntarioEdAI

OntarioEdAI is a local-first adaptive education application being rebuilt as the first governed education capability pack for AXIOM-MESH.

**Current rebuild:** `0.5.0-dev.0`  
**Status:** active development; not production-ready

The Flutter application remains independently releasable. AXIOM-MESH supplies the policy, consent, bounded execution, evidence, portability, and synchronization substrate for governed effects.

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

The current application opens a curriculum diagnostic browser. The learner workspace, AXIOM bridge, configured tutor provider, encrypted learner records, governed pack activation, and governed classroom synchronization remain rebuild work.

## Product boundary

```text
OntarioEdAI UI
  -> AXIOM Gateway
  -> policy, consent, risk, and plan evaluation
  -> short-lived capability grant
  -> approved education or provider capsule
  -> bounded execution
  -> encrypted learner state and evidence in Grid
```

OntarioEdAI does not receive ambient authority over learner records, providers, credentials, curriculum activation, or classroom nodes.

## Current capability status

The authoritative status registry is [`config/capabilities.json`](config/capabilities.json).

Presently:

- curriculum browsing from a schema-verified bundled SQLite database is implemented;
- the current curriculum corpus deterministically builds into 293 canonical records across 21 courses;
- curriculum-pack generation, digest verification, and external-key Ed25519 signing are experimental and do not yet authorize activation;
- Ontario-derived records and OntarioEdAI extensions use visibly separate namespaces and official-recognition flags;
- legacy `irt_*` values are exported only as visibly uncalibrated adaptation heuristics;
- local tutor inference is disabled, fails closed, and no longer returns simulated logits output;
- canvas observation is an explicitly experimental bounded classifier and no longer returns mock equations;
- handwriting scoring no longer returns fixed synthetic scores when its model is missing;
- the legacy UDP/TCP classroom mesh is disabled by default, AES-GCM protected when explicitly enabled for development, and is not a trusted authority path;
- governed learner records, selective portfolio export, accessibility gates, pack activation, and AXIOM classroom synchronization remain specified or adapter-required.

A missing model, provider, verifier, identity, policy, consent, source, or artifact must produce an explicit unavailable or denied result. It must never produce mock success in a governed or release build.

## Rebuild documents

- [Canonical product definition](docs/rebuild/PRODUCT-DEFINITION.md)
- [Evidence-gated requirements](docs/rebuild/REQUIREMENTS.md)
- [Curriculum Pack v1](docs/curriculum/CURRICULUM-PACK-V1.md)
- [Legacy architecture research input](ARCHITECTURE.md)
- [Curriculum sources and augmentation notes](CURRICULUM_SOURCES.md)

When documents conflict, executable behavior and [`config/capabilities.json`](config/capabilities.json) control. Legacy documents are research and traceability inputs unless promoted with code, tests, evidence, and current status.

## Curriculum pack

Build a deterministic unsigned pack into an empty directory:

```bash
python tools/curriculum_pack.py build \
  --input assets/curriculum/ontario_curriculum_full.json \
  --ledger curriculum/source-ledger.v1.json \
  --output /tmp/ontarioedai-pack \
  --pack-id ontario-secondary \
  --pack-version 1.0.0
```

Verify content integrity:

```bash
python tools/curriculum_pack.py verify \
  --pack-dir /tmp/ontarioedai-pack
```

The protected workflow builds the complete pack twice and compares `manifest.json` and `records.jsonl` byte-for-byte. It then signs one build with an ephemeral Ed25519 key and requires successful signature verification.

The legacy ingestion commands remain development inputs:

```bash
python parse_markdown.py
python migrate_to_sqlite.py
python rag_ingestion.py
```

Retrieval indexes are disposable derived artifacts. They are never the authority for curriculum content.

## Curriculum trust boundary

A valid pack signature proves that the exact canonical manifest was signed by the corresponding private key. It does not prove:

- Ontario Ministry approval;
- curriculum correctness or completeness;
- licensing or redistribution permission;
- pedagogical quality;
- safe application activation.

The source ledger explicitly records that upstream official-document digests have not yet been captured and that course-by-course source and licensing review remains required.

## Security and privacy boundary

The project targets local processing and data minimization, but local-first architecture alone is not a compliance or security claim.

Until the governed learner-record path is implemented:

- the current Hive `student_data` box must not store governed learner records;
- raw canvas images and detailed strokes should be treated as ephemeral development data;
- the legacy mesh must remain disabled outside explicit development tests;
- no DID, verifiable credential, assessment-validity, or production-encryption claim should be made.

Security issues should follow [`.github/SECURITY.md`](.github/SECURITY.md).

## Initial delivery target

The first complete vertical slice is `MTH1W` and must include:

- a reviewed and approved signed curriculum pack;
- deterministic algebra and numerical verification;
- a configured local tutor provider;
- expectation-linked generated practice;
- scaffolded hints;
- consent-bound learner events;
- visible provenance and uncertainty;
- educator review and appeal;
- selective portfolio export;
- offline operation.

Additional courses follow only after that slice passes its acceptance gates.
