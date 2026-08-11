# Ontario Elementary readiness

Ontario Elementary readiness is a **derived evidence view**, not a mutable stage field on the original discovery ledger.

The C0 discovery file is intentionally preserved as the source-discovery artifact that later evidence was captured against. C1 source locks bind to exact discovery entries. Rewriting old discovery entries to say “captured” would invalidate that provenance relationship.

The current readiness view is generated with:

```bash
python tools/ontario_elementary_readiness.py report \
  --output build/ontario-elementary-readiness.json
```

Canonical verification uses:

```bash
python tools/ontario_elementary_readiness.py verify
```

## Evidence composition

The readiness view composes four layers:

1. `source-discovery.v0.json` — C0 official-source discovery and program-family accounting;
2. `source-locks/*.json` — C1 exact-byte capture/digest evidence;
3. `records-v2/*.json` — canonical C2 normalized records, when separately promoted;
4. `source-capture-targets.v1.json` — bounded capture routes available for known official sources.

A later evidence layer does not rewrite the earlier one.

## Current source-capture state

The current branch has eight confirmed discovered source families and five committed C1 locks:

- Health and Physical Education 2019;
- Mathematics 2020;
- Language 2023;
- Science and Technology 2022;
- French as a Second Language 2013.

The following confirmed discovered sources remain uncaptured:

- Kindergarten 2026;
- The Arts 2009/current-version reconciliation;
- Social Studies Grades 1-6 / History and Geography Grades 7-8, including the current 2026 History boundary.

## Program-family state

English-language schools currently have C1 source evidence for five of eight required program families:

- French as a Second Language;
- Language;
- Health and Physical Education;
- Mathematics;
- Science and Technology.

The Arts, Social Studies Grades 1-6, and History and Geography Grades 7-8 remain below C1.

French-language-school program families remain explicitly unresolved in the current discovery accounting and therefore have zero C1 family coverage in this derived view. Shared-looking subject names are **not** silently substituted across language-school program families.

Kindergarten is tracked separately and remains below C1 until the exact 2026 source is captured.

## What five C1 locks do not mean

Five captured source families do not mean Ontario Elementary is five-eighths “complete” in a product or pedagogical sense. C1 establishes only exact-byte source evidence.

The readiness view must continue to report these separately:

- source capture completeness;
- program-family coverage;
- canonical C2 normalization;
- human source review;
- licensing/redistribution review;
- deterministic full-pack verification;
- governed activation.

A machine-generated readiness report can never set the human-review, licensing, or governed-activation fields to complete.

## Why this matters

This prevents two common forms of evidence drift:

1. **provenance rewriting** — modifying an old discovery record after later evidence was captured against it;
2. **scope inflation** — turning several successful source captures into a claim that the whole jurisdiction, language stream, grade range, or curriculum is verified.

The derived-readiness pattern is reusable for later jurisdictions and program families.
