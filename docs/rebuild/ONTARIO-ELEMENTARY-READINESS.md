# Ontario Elementary Readiness

Ontario Elementary readiness is a **derived evidence view**, not mutable state written back into source discovery.

The C0 discovery ledger remains the source-discovery artifact that later C1 locks bind to. Rewriting those entries after capture would invalidate provenance. Readiness therefore composes separate layers:

```text
C0 discovery
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

Language 2023 and Science & Technology 2022 remain valid historical C1 snapshots, but their current DCP HTML routes have demonstrated transport/response volatility.

Language produced two distinct exact-byte signatures across three successful requests in one hosted run. Science produced two byte-identical successful responses and one HTTP 404 in one hosted run.

Those observations do **not** prove curriculum content changed. They block treating these HTML response surfaces as immutable document sources until a stable authoritative asset or separately reviewed canonicalization/availability strategy exists.

## Current derived state

The verifier currently requires the truthful state:

- 8 confirmed discovered source families;
- 5 C1 snapshot sources;
- 3 strict exact-byte monitored sources;
- 2 observational DCP response surfaces;
- 0 canonical reviewed C2 records;
- Kindergarten 2026 not C1-locked;
- English-language required program families with C1 source evidence: 5/8;
- French-language required program families with C1 source evidence: 0/8;
- known uncaptured sources remain Kindergarten, The Arts, and Social Studies/History/Geography;
- human source review incomplete;
- licensing review incomplete;
- deterministic full-pack verification incomplete;
- governed activation unavailable.

Five C1 snapshots must not be described as five-eighths product completion. Likewise, only three strict recapture sources must not be described as three-fifths curriculum truth. These are different evidence dimensions.

## Fail-closed properties

`tools/ontario_elementary_readiness.py` rejects attempts to:

- count more C1 sources than discovered/registered sources;
- leave a C1 snapshot outside the monitoring classification;
- relabel the current observational DCP surfaces as if all C1 sources were strictly recapturable;
- claim English/French program coverage beyond required families;
- claim whole-base source completion while known gaps remain;
- claim human review, licensing completion, deterministic pack verification, or governed activation from machine evidence alone.

The readiness view does not alter the source locks, curriculum records, monitoring observations, or official-source artifacts it summarizes.
