# Ontario Elementary normalized standards v2

This directory is reserved for canonical `axiom-curriculum-standard-record.v2` records.

The v2 model is intentionally not shaped around a high-school course code. It supports Kindergarten, elementary, secondary, post-secondary, apprenticeship, professional, lifelong, and other learning contexts while keeping jurisdiction and authority explicit.

## Promotion boundary

A record may enter this directory only at **C2-normalized** and only through the fail-closed promotion path.

For the current Ontario Elementary v1 promotion path, all of the following are required:

1. the official source has exactly one valid current C1 source lock;
2. current qualified-human source identity/scope review is approved;
3. current licensing evidence permits reference-only use;
4. operator-supplied source bytes exactly match the historical C1 SHA-256 and byte length;
5. an exact `reference-only` candidate in `../c2-candidates/` passes `tools/ontario_elementary_c2_intake.py verify-candidate`;
6. a qualified-human normalization review binds the exact candidate digest, current source-lock digest, and exact C1 source-byte digest/length and has decision `approved`; and
7. `tools/ontario_elementary_c2_promotion.py promote` copies the unchanged candidate bytes into this directory.

The retained candidate and normalization evidence remain provenance. A later change to the current candidate or authority-bearing source/licensing evidence must not silently preserve an older promotion judgement.

C2 canonical status means a reviewed normalized reference record has been admitted to this directory. It does **not** mean:

- the full curriculum is complete or correct;
- official wording is legally redistributable beyond the reviewed mode;
- a competency crosswalk has been verified;
- a deterministic full curriculum pack has been built;
- the record or pack has been signed, staged, or activated;
- learner mastery, grade, credit, transcript, enrolment, or school equivalency has been established; or
- Ontario Ministry approval exists.

## Text modes

The generic v2 record schema supports three content modes:

- `verbatim` — exact source wording; generic verification refuses this unless the bound C1 lock has `redistribution_status: redistributable-reviewed`;
- `paraphrase` — Axiom-authored normalized wording, kept separate from official text claims; and
- `reference-only` — no source wording is embedded; the record carries identifiers, hierarchy, provenance, and source binding only.

The **current Ontario Elementary promotion gate is deliberately narrower** and admits `reference-only` candidates only, even if future licensing evidence could support broader modes.

## Axiom metadata separation

Tags and other Axiom-authored metadata live under the `org.axiom.education` namespace. They are not Ontario Ministry curriculum fields and must never be presented as such.

## Verification

Generic record verification:

```bash
python tools/curriculum_standard_record.py verify-directory \
  --directory curriculum/ontario-elementary/records-v2 \
  --lock-dir curriculum/ontario-elementary/source-locks \
  --allow-empty
```

Governed Ontario Elementary promotion verification:

```bash
python tools/ontario_elementary_c2_promotion.py verify-canonical
```

The governed verifier is also part of `tools/verify.py` and CI.

The canonical directory currently contains **0 C2 JSON records** because source review/licensing remain blocked upstream. The separate HPE construction fixture proves deterministic reference-record generation only; it does not satisfy candidate intake, human normalization review, canonical promotion, or downstream activation evidence.
