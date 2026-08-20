# Ontario Elementary Readiness

Ontario Elementary readiness is a **derived evidence view**, not mutable state written back into source discovery.

The historical C0 discovery ledger remains immutable in meaning. Existing source identities can receive append-only resolution amendments; newly discovered source identities that were absent from the historical ledger enter through a separate append-only additions layer. Neither mechanism rewrites the original 2026-08-11 artifact. Readiness composes those discovery layers with later evidence:

```text
historical C0 discovery
  + append-only source-resolution amendments
  + append-only new C0 source identities
  + C1 exact-byte historical snapshots
  + source-surface monitoring
  + canonical C2 records
  + later human/licensing/pack evidence
  -> derived readiness
```

## Snapshot evidence is not recapture stability

A C1 lock proves that exact bytes were captured at a recorded time and digested. It does not promise that the serving transport surface is immutable forever.

Current hosted evidence distinguishes two monitoring classes.

### Strict exact-byte document sources

The following sources currently behave as stable document-like assets and remain strict CI drift gates:

- Health and Physical Education, Grades 1-8, 2019;
- Mathematics, Grades 1-8, 2020;
- French as a Second Language, Grades 1-8, Revised 2013.

A changed digest, length, media type, locator, or source binding on these sources is a fail-closed drift event requiring review.

### Observational DCP response surfaces

Language 2023, Science & Technology 2022, Kindergarten 2026, and Social Studies/History/Geography have valid historical C1 snapshots, but their current DCP HTML routes are treated as observational response surfaces rather than immutable source documents.

Language produced two distinct exact-byte signatures across three successful requests in one hosted run. Science produced two byte-identical successful responses and one HTTP 404 in one hosted run. For Kindergarten 2026, the bounded C1 capture and a separate three-request stability job in workflow run `32407467373` returned different SHA-256 signatures at the same byte length; the three stability requests were mutually identical. Social Studies/History/Geography showed the same cross-job pattern in workflow run `32411047398`: its C1 capture SHA differed from the SHA shared by all three stability requests, while all four responses had the same 6,297,332-byte length.

Those observations do **not** prove curriculum content changed. They block treating these HTML response surfaces as immutable document sources until a stable authoritative asset or separately reviewed canonicalization/availability strategy exists.

## French-language-school source expansion

The original discovery ledger identified all eight required French-language-school program families as unresolved but did not contain source identities for them. Rewriting that historical ledger would weaken provenance, so `source-discovery-additions.v1.json` now introduces new C0 identities only after official-source evidence is resolved.

Four French-language-school families currently have official Publications Ontario identity evidence at C0:

- **Français, Grades 1-8, 2023** — publication `CL33252`;
- **Mathématiques, Grades 1-8, 2020** — publication `CL32239` is the primary identity record used here; separate official online-resource record `300333` is preserved as a distinct format record rather than collapsed;
- **Éducation physique et santé, Grades 1-8, 2019** — publication `022579`;
- **Éducation artistique, Grades 1-8, Revised 2009** — online-resource publication `231943_U`, with separate official book record `231943` preserved as a distinct format record.

These are **C0 source identities only**. They have no committed C1 snapshots, no capture targets yet, no redistribution approval, and no canonical C2 records. Exact current curriculum routes/bytes must be resolved independently before promotion. The remaining French-language-school families—English, Science and Technology, Social Studies Grades 1-6, and History/Geography Grades 7-8—remain unresolved rather than being inferred from English-language-school artifacts or obsolete French publications.

## Current derived state

The verifier currently requires the truthful state:

- 12 confirmed discovered source identities after composing the historical ledger, amendments, and append-only additions;
- 8 registered bounded capture targets;
- 7 C1 snapshot sources;
- 3 strict exact-byte monitored sources;
- 4 observational DCP response surfaces;
- 0 canonical reviewed C2 records;
- Kindergarten 2026 has a metadata-only C1 historical snapshot; source bytes are not retained and redistribution remains review-required;
- Social Studies, Grades 1-6, and History and Geography, Grades 7-8 has a metadata-only historical C1 snapshot bound to the current official DCP `elementary-sshg` route; Publications Ontario `233531` preserves the 2018 revised base lineage and Ontario's 2026-27 direction confirms new Grade 7-8 History learning;
- English-language required program families with C1 source evidence: 7/8;
- French-language required program families with C1 source evidence: 0/8;
- French-language required program families with C0 source identity evidence: 4/8;
- French-language families still unresolved at source identity: English, Science and Technology, Social Studies Grades 1-6, and History/Geography Grades 7-8;
- The Arts is the sole uncaptured discovered English-language required-program source and retains a bounded capture target;
- human source review incomplete;
- licensing review incomplete;
- deterministic full-pack verification incomplete;
- governed activation unavailable.

Seven C1 snapshots must not be described as seven-twelfths product completion. Likewise, three strict recapture sources must not be described as a fraction of curriculum truth, and four French C0 identities must not be described as four completed curricula. These are different evidence dimensions. Kindergarten is outside the Grades 1-8 required-program-family denominator used for the 7/8 English-language count. One SSHG source supplies evidence for two English required program-family rows.

## Fail-closed properties

`tools/curriculum_source_additions.py` rejects attempts to:

- introduce a source ID that already exists and should use the amendment chain;
- overwrite an existing program-family source binding;
- bind an addition to a non-required program family;
- duplicate an addition or coverage binding;
- claim an upstream digest at C0;
- silently inherit the Ontario additions when validating a custom discovery artifact.

`tools/ontario_elementary_readiness.py` rejects attempts to:

- count more C1 sources than discovered/registered sources;
- leave a C1 snapshot outside the monitoring classification;
- relabel the current observational DCP surfaces as if all C1 sources were strictly recapturable;
- claim English/French C1 program coverage beyond required families;
- claim whole-base source completion while known gaps remain;
- claim human review, licensing completion, deterministic pack verification, or governed activation from machine evidence alone.

The readiness view names the historical discovery ledger and the source-additions registry as separate inputs. It does not alter source locks, curriculum records, monitoring observations, or official-source artifacts it summarizes.
