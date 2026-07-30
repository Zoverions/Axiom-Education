# Axiom Education Curriculum Source Policy

This document defines the current provenance boundary for jurisdictional curriculum packs and Axiom Education extensions.

The former augmentation strategy is archived at [`docs/archive/CURRICULUM-SOURCES-LEGACY.md`](docs/archive/CURRICULUM-SOURCES-LEGACY.md). It is not evidence of source accuracy, licensing permission, Ministry approval, pedagogical quality, or production readiness.

## Authority hierarchy

1. Canonical signed curriculum-pack records and manifest.
2. `curriculum/source-ledger.v1.json`.
3. Versioned curriculum schemas and deterministic pack tooling.
4. Course-by-course human review evidence.
5. Disposable retrieval indexes derived from the canonical records.

JSON, SQLite, Chroma, embeddings, and generated indexes are not independently authoritative merely because they are local.

## Required record provenance

Every curriculum record must identify, when available:

- jurisdiction;
- issuing authority;
- official or extension status;
- source locator and source-document digest;
- publication and effective dates;
- ingestion date and parser version;
- licence or redistribution status;
- review state and reviewer evidence;
- content digest and supersession relationship.

Unknown values must remain explicitly unknown. They must not be inferred from filenames, repository history, or model output.

## Namespace policy

- Ontario-derived records use the Ontario jurisdictional namespace.
- Axiom Education-created content uses an extension namespace and must not imply Ontario Ministry recognition.
- Third-party OER uses a separate provider namespace with explicit licence and attribution metadata.
- Custom course codes such as historical `EMF1O` or `EMF3U` are extensions unless an issuing authority independently recognizes them.

## Current Ontario pack status

The current corpus deterministically builds into 293 canonical records across 21 courses. That reproducibility establishes pack integrity, not source completeness or official approval.

Outstanding work includes:

- capture of upstream official-document digests;
- licensing and redistribution review;
- course-by-course verification against current Ministry documents;
- effective-date and supersession review;
- removal or correction of unsupported records;
- educator and accessibility review.

## Open educational resources

No source is accepted as factual, neutral, pedagogically appropriate, or redistributable based only on brand or popularity. Each OER source requires:

- licence verification;
- attribution requirements;
- version and retrieval date;
- subject-matter review;
- suitability and accessibility review;
- separation from official jurisdictional expectations.

## Generated content

Generated questions, explanations, hints, and examples are not curriculum records. They must bind the exact curriculum expectation IDs, pack digest, generator and provider versions, verifier state, and uncertainty. Deterministically solvable claims require an approved verifier before being represented as verified.
