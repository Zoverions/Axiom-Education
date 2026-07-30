# OntarioEdAI Curriculum Pack v1

**Status:** experimental build and verification surface  
**Pack schema:** `ontarioedai-curriculum-pack.v1`  
**Record schema:** `ontarioedai-curriculum-record.v1`  
**Builder:** `tools/curriculum_pack.py` `1.0.0`

## Purpose

Curriculum Pack v1 converts the legacy monolithic curriculum JSON into a deterministic artifact suitable for review, distribution, rollback, and later AXIOM capsule registration.

The format separates four questions that the prior database blurred together:

1. What does the record say?
2. Where did the record come from?
3. Has the record changed?
4. Who signed this exact manifest?

A signature does not answer whether the material is correct, officially approved, legally redistributable, pedagogically sound, or safe to activate. Those remain separate review and policy decisions.

## Pack contents

A built unsigned pack contains exactly:

```text
manifest.json
records.jsonl
```

A signed pack additionally contains:

```text
manifest.sig
signature.json
```

Private and public signing keys must remain outside the pack directory. The builder never generates, stores, or copies a private key.

## Determinism

The builder uses:

```text
UTF-8
Unicode NFC normalization
JSON keys sorted lexicographically
compact JSON separators
one trailing newline per canonical object
records sorted by record_id
no build timestamp
```

For identical curriculum input, source ledger, builder version, pack ID, and pack version, `manifest.json` and `records.jsonl` must be byte-for-byte identical.

The protected workflow builds the repository curriculum twice and compares both files using `cmp` before any signature is applied.

## Source boundary

`curriculum/source-ledger.v1.json` routes every course into an explicit namespace and source classification.

The current rules distinguish:

- `official-derived` Ontario curriculum transcriptions;
- `ontarioedai-extension` material such as the EMF ethics modules.

Every record includes:

- jurisdiction;
- course, strand, and expectation identity;
- source namespace and authority;
- official-recognition flag;
- upstream URL where available;
- upstream document digest or an explicit digest-status reason;
- exact ingestion-artifact digest;
- review status;
- rights holder, usage basis, redistribution status, and notice;
- uncalibrated adaptation heuristics;
- content digest.

OntarioEdAI extensions must remain in their own namespace and carry `official_recognition: false`.

## Legacy IRT migration

Legacy fields named `irt_a`, `irt_b`, and `irt_c` are not exported as validated psychometric parameters.

They are mapped to:

```json
{
  "adaptation_heuristics": {
    "status": "uncalibrated",
    "difficulty": null,
    "discrimination": null,
    "guessing_assumption": null
  }
}
```

Their numeric values may be preserved for compatibility, but the status remains `uncalibrated` until a separately reviewed calibration process exists.

## Build

The output directory must exist or be creatable and must be empty.

```bash
python tools/curriculum_pack.py build \
  --input assets/curriculum/ontario_curriculum_full.json \
  --ledger curriculum/source-ledger.v1.json \
  --output /tmp/ontarioedai-pack \
  --pack-id ontario-secondary \
  --pack-version 1.0.0
```

Verify content and manifest integrity:

```bash
python tools/curriculum_pack.py verify \
  --pack-dir /tmp/ontarioedai-pack
```

## Sign

Generate or obtain an Ed25519 key through an approved external custody process. The following is suitable only for disposable development verification:

```bash
umask 077
openssl genpkey -algorithm ED25519 -out /tmp/private.pem
openssl pkey -in /tmp/private.pem -pubout -out /tmp/public.pem
```

Sign the exact canonical manifest:

```bash
python tools/curriculum_pack.py sign \
  --pack-dir /tmp/ontarioedai-pack \
  --private-key /tmp/private.pem \
  --public-key /tmp/public.pem
```

Verify and require the signature:

```bash
python tools/curriculum_pack.py verify \
  --pack-dir /tmp/ontarioedai-pack \
  --public-key /tmp/public.pem \
  --require-signature
```

## Verification failures

Verification fails closed for, among other cases:

- unexpected files or symlinks;
- non-canonical JSON;
- oversized inputs or records;
- malformed JSONL framing;
- duplicate or unsorted record IDs;
- altered record content;
- altered pack or course digests;
- count or classification mismatches;
- missing signatures when required;
- changed signature envelopes;
- wrong public keys;
- changed manifest bytes;
- unsupported schemas or algorithms.

## Current evidence and open work

At the current branch revision, CI builds **293 records across 21 courses** twice with identical bytes, verifies all digests, signs the first build with an ephemeral Ed25519 key, and verifies the signed pack.

This is not activation evidence. Before a pack can become an implemented application or AXIOM capability, the project still requires:

- capture and pinning of authoritative upstream document digests;
- course-by-course human source review;
- licensing and redistribution review;
- approved curriculum signing authority and key custody;
- signer revocation and rotation;
- downgrade prevention;
- application-side signature verification;
- AXIOM capsule registration and policy;
- staged activation, rollback, and learner-visible provenance.
