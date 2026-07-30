# OntarioEdAI

OntarioEdAI is a local-first adaptive education application being rebuilt as the first governed education capability pack for AXIOM-MESH.

**Current rebuild:** `0.5.0-dev.0`  
**Branch:** `rebuild/axiom-education-v0.5`  
**Status:** active development; not production-ready

The Flutter application remains independently releasable. AXIOM-MESH supplies the policy, consent, bounded execution, evidence, portability, and synchronization substrate for governed effects.

## First five minutes

Requirements:

- Flutter `>=3.19.0`
- Dart `>=3.3.0 <4.0.0`
- Python tooling only when rebuilding curriculum artifacts

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

The current application opens a curriculum diagnostic browser. The learner workspace, AXIOM bridge, signed curriculum packs, configured tutor provider, encrypted learner records, and governed classroom synchronization are rebuild work.

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

- curriculum browsing from bundled SQLite is implemented;
- curriculum JSON and SQLite are useful experimental assets;
- local tutor inference is disabled because the existing Phi-3 path is incomplete and simulated;
- canvas observation is experimental;
- the legacy UDP/TCP classroom mesh is disabled by default and development-only;
- governed learner records, signed curriculum packs, selective portfolio export, accessibility gates, and AXIOM classroom synchronization are specified or adapter-required;
- mock IRT fields are heuristics, not calibrated psychometrics.

A missing model, provider, verifier, identity, policy, consent, source, or artifact must produce an explicit unavailable or denied result. It must never produce mock success in a governed or release build.

## Rebuild documents

- [Canonical product definition](docs/rebuild/PRODUCT-DEFINITION.md)
- [Evidence-gated requirements](docs/rebuild/REQUIREMENTS.md)
- [Legacy architecture research input](ARCHITECTURE.md)
- [Curriculum sources and augmentation notes](CURRICULUM_SOURCES.md)

When documents conflict, executable behavior and [`config/capabilities.json`](config/capabilities.json) control. Legacy documents are research and traceability inputs unless promoted with code, tests, evidence, and current status.

## Curriculum pipeline

The existing development pipeline is:

```bash
python parse_markdown.py
python migrate_to_sqlite.py
python rag_ingestion.py
```

It is not yet the supported release pipeline. The rebuild will replace it with a pinned, reproducible curriculum-pack builder that records jurisdiction, authority, official-or-extension status, source digest, parser version, licence, human-review state, content digest, and supersession.

Retrieval indexes are disposable derived artifacts. They are never the authority for curriculum content.

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

- a signed curriculum pack;
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
