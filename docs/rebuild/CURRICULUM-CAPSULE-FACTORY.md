# Curriculum Capsule Factory

Status: architecture framework; no new curriculum pack is claimed complete by this document.

## Purpose

Axiom Education needs a repeatable way to build verified jurisdiction curriculum capsules without hardcoding one province, state, or country into the platform.

Ontario Secondary remains the first active jurisdictional corpus. The next intended capsule family is Ontario Elementary, followed by additional high-value jurisdictions selected by coverage, population served, source quality, licensing/redistribution constraints, language support, and practical demand.

Candidate future jurisdictions include, without fixing priority yet:

- Ontario elementary;
- California;
- New York;
- Texas;
- United Kingdom constituent education systems as separately required rather than assuming one UK-wide curriculum;
- Germany, respecting federal/state education authority rather than assuming one national school curriculum where that is not accurate;
- Australian national/state/territory curriculum contexts as applicable;
- China;
- United Arab Emirates;
- other jurisdictions selected through the same evidence process.

Actual jurisdiction structure and source authority must be verified from current official primary sources before a pack is built. This framework deliberately does not encode assumptions about which government level controls curriculum in a country.

## Architecture

```text
official source corpus
  -> source ledger
  -> normalized standards records
  -> stable competency crosswalk
  -> deterministic pack build
  -> manifest + provenance
  -> signature
  -> independent verification
  -> staging
  -> governed activation
  -> jurisdiction resolver
  -> experience products such as CLAW
```

The curriculum capsule is a domain artifact, not an application fork.

## Pack classes

A jurisdiction may require more than one pack.

Examples:

- elementary / primary;
- secondary;
- subject-specific;
- grade-band specific;
- language stream;
- vocational/technical;
- special-program;
- local-authority extension;
- institution/program overlay.

A pack declares its authority scope and does not silently claim a broader mandate.

## Source acquisition rules

Every authoritative curriculum claim must originate from a traceable source ledger.

Preferred source order:

1. official ministry/department/board/authority source;
2. official publication/archive mirror maintained by that authority;
3. official legislation/regulation where it directly defines standards;
4. officially designated implementation/support material;
5. secondary sources only as discovery aids, never as final authority when a primary source exists.

For each source capture:

- authority;
- canonical URL or document identifier;
- retrieval date;
- publication/effective date when available;
- language;
- file/media type;
- local archival digest;
- copyright/licensing/redistribution status;
- extraction method;
- human review state;
- replacement/supersession relationship.

A URL alone is not provenance.

## Anti-drift requirements

The build must distinguish:

- source retrieved;
- source parsed;
- record normalized;
- record reviewed;
- pack built;
- pack signed;
- pack verified;
- pack staged;
- pack activated.

No later state may be inferred from an earlier state.

If a source changes, the system captures a new digest/version. It does not overwrite historical evidence.

## Canonical standards record

A normalized record should minimally support:

```json
{
  "record_id": "authority-defined-or-axiom-namespaced-id",
  "authority_id": "...",
  "jurisdiction_id": "...",
  "pack_id": "...",
  "grade_band": "...",
  "subject": "...",
  "strand": "...",
  "expectation_code": "...",
  "expectation_text": "...",
  "effective_from": "...",
  "source_digest": "...",
  "source_locator": "...",
  "official_recognition": true,
  "competency_ids": []
}
```

Official text and Axiom-authored metadata must be visibly distinct.

## Stable competency layer

Curriculum codes vary by jurisdiction and change over time. Experience content therefore targets stable Axiom competency identifiers and is crosswalked into jurisdiction standards.

A crosswalk assertion contains:

- competency ID;
- jurisdiction expectation ID;
- relationship type (`equivalent`, `supports`, `partial`, `prerequisite`, etc.);
- evidence/explanation;
- author/reviewer;
- confidence state;
- source and pack digests.

A crosswalk is a derived assertion, not official curriculum text unless the authority itself publishes that mapping.

## Verification stages

### C0 — discovered

Source identified but not yet captured.

### C1 — captured

Source bytes archived and digested.

### C2 — parsed

Machine-readable records extracted with provenance pointers.

### C3 — reviewed

Extraction/normalization reviewed against source.

### C4 — reproducible

Repeated build produces byte-identical canonical pack artifacts.

### C5 — signed

Manifest signed by an approved external key.

### C6 — independently verified

Independent verifier checks signature, source ledger, schema, record counts/digests and negative paths.

### C7 — staged

Valid pack is available for governed activation but grants no authority.

### C8 — activated

Policy-approved activation binds the pack into an effective jurisdiction context.

The UI and documentation must never render a pack above the highest stage actually achieved.

## Ontario Elementary next

Ontario Elementary should be created as a new jurisdictional capsule family using this factory, not appended informally to the secondary corpus.

The build should:

1. identify current official Ontario elementary curriculum sources by subject/grade;
2. archive exact primary-source bytes and digests;
3. record licensing/redistribution constraints;
4. normalize identifiers without rewriting official wording;
5. create grade/subject/strand/expectation records;
6. construct competency crosswalks separately from official records;
7. build deterministic capsule artifacts;
8. verify record coverage against the official source inventory;
9. sign and independently verify the pack;
10. stage it for the jurisdiction resolver;
11. use it as the first elementary standards source for CLAW vertical slices.

Ontario Secondary work continues independently and should not be destabilized to enable Elementary.

## Multi-jurisdiction expansion

Each new jurisdiction begins with a **governance/source-structure discovery pass** before data extraction.

That pass answers:

- which authority actually publishes mandatory standards;
- whether authority is national, regional, local, or layered;
- whether multiple language/program streams exist;
- whether public/private systems differ materially;
- whether source material is legally redistributable;
- whether standards are current or superseded;
- how grade/year bands map to Axiom's neutral education context;
- whether there are official machine-readable datasets;
- whether the pack should be one artifact or several composable layers.

Do not copy the Ontario topology onto another jurisdiction by assumption.

## Dedicated curriculum build instance

A dedicated curriculum-ingestion/build service or repository may eventually be justified. Its role would be source acquisition, normalization, deterministic build, provenance, signing and verification—not learner runtime or curriculum activation.

Until that split is operationally justified, the framework remains in Axiom Education so the schemas and verification rules have one canonical owner.

## Promotion gate

No jurisdiction capsule is production-ready merely because records have been scraped or parsed.

Production promotion requires at minimum:

- complete source ledger for claimed scope;
- deterministic build;
- schema validation;
- source-to-record traceability;
- licensing/status review;
- negative-path verification;
- signature verification;
- independent verification;
- explicit capability/evidence registration;
- governed activation path.
