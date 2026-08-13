# Ontario Elementary normalized standards v2

This directory is reserved for `axiom-curriculum-standard-record.v2` records.

The v2 model is intentionally not shaped around a high-school course code. It supports Kindergarten, elementary, secondary, post-secondary, apprenticeship, professional, lifelong, and other learning contexts while keeping jurisdiction and authority explicit.

## Promotion boundary

A record may enter this directory only at **C2-normalized** and only when its official source already has exactly one valid C1 source lock.

C2 means the source has been transformed into a canonical standards record. It does **not** mean:

- the normalization has been human source-reviewed;
- the official wording is legally redistributable;
- the record is complete or correct;
- a competency crosswalk has been verified;
- a deterministic pack has been built;
- the record has been signed, staged, or activated.

## Text modes

Each standard explicitly declares one of three content modes:

- `verbatim` — exact source wording. The verifier refuses this unless the bound C1 lock has `redistribution_status: redistributable-reviewed`.
- `paraphrase` — Axiom-authored normalized wording, kept separate from official text claims.
- `reference-only` — no source wording is embedded; the record carries identifiers, hierarchy, provenance, and source binding only.

This allows us to preserve official structure and provenance without assuming public source text can be republished.

## Axiom metadata separation

Tags and other Axiom-authored metadata live under the `org.axiom.education` namespace. They are not Ontario Ministry curriculum fields and must never be presented as such.

## Verification

```bash
python tools/curriculum_standard_record.py verify-directory \
  --directory curriculum/ontario-elementary/records-v2 \
  --lock-dir curriculum/ontario-elementary/source-locks \
  --allow-empty
```

Valid C1 metadata locks now exist, but the canonical directory remains empty
until record normalization and the required human source/licensing review are
performed against appropriately retained source evidence. The separate HPE
construction fixture proves deterministic reference-record generation only; it
does not promote Ontario Elementary beyond its actually evidenced stage.
