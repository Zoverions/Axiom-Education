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

Five sources currently behave as stable document-like assets and remain strict CI drift gates:

- Health and Physical Education, Grades 1-8, 2019;
- Mathematics, Grades 1-8, 2020;
- French as a Second Language, Grades 1-8, Revised 2013;
- French-language-school **Anglais, Grades 4-8, Revised 2006**;
- French-language-school **Anglais pour débutants, Grades 4-8, Revised 2013**.

The two Anglais PDFs were captured through the bounded source workflow in run `32416994073`. The regular Anglais candidate and all three independent recaptures were byte-identical at 382,437 bytes with SHA-256 `3a5efd2a38ab77d600397ba72a2710b7770b2c0f62aafdc19c8fd10412449037`. Anglais pour débutants was byte-identical across the candidate and all three recaptures at 3,887,969 bytes with SHA-256 `3f16c79225fa0a3b4de504a6843598389d729f14ecce00b7adaf58f95bcfe845`.

A changed digest, length, media type, locator, or source binding on a strict source is a fail-closed drift event requiring review.

### Observational DCP response surfaces

Seven C1 sources are current DCP HTML response surfaces and therefore remain observational rather than strict exact-byte documents:

- Kindergarten 2026;
- The Arts, Grades 1-8, Revised 2009;
- Language, Grades 1-8, 2023;
- Science & Technology, Grades 1-8, 2022;
- Social Studies, Grades 1-6 / History and Geography, Grades 7-8;
- French Sciences et technologie, Grades 1-8, 2022;
- French Études sociales / Histoire et Géographie.

Several have demonstrated cross-request or cross-job HTML-byte volatility. For Arts, workflow run `32416994073` produced a valid 6,297,332-byte C1 candidate with SHA-256 `1307d903c60d047ecbb9ad49d6fd12b9c157480e7453072438227bc602064830`; the separate three-request stability job produced three mutually identical responses at the same byte length with SHA-256 `38a1da204bd84562de8d175f9499a51499cc403acbeaf593152a069fc8a5d98c`. That pattern supports a historical C1 snapshot while forbidding an immutable-live-HTML claim.

Those observations do **not** prove curriculum content changed. They block treating the HTML response surface as an immutable document until a stable authoritative asset or separately reviewed canonicalization/availability strategy exists.

## French-language-school source expansion

The original discovery ledger identified all eight required French-language-school program families as unresolved but did not contain source identities for them. Rewriting that historical ledger would weaken provenance, so `source-discovery-additions.v1.json` introduces new C0 identities only after official-source evidence is resolved.

The effective discovery view now resolves all eight French-language-school required program families at C0. The relevant identities are:

- **Français, Grades 1-8, 2023** — Publications Ontario `CL33252`;
- **Mathématiques, Grades 1-8, 2020** — Publications Ontario `CL32239`, while separate online-resource record `300333` remains distinct;
- **Éducation physique et santé, Grades 1-8, 2019** — Publications Ontario `022579`;
- **Éducation artistique, Grades 1-8, Revised 2009** — online-resource publication `231943_U`, with separate book record `231943` preserved;
- **Sciences et technologie, Grades 1-8, 2022** — exact French DCP curriculum route;
- **Études sociales / Histoire et Géographie** — exact French DCP curriculum root, supplying two required family rows;
- **Anglais, Grades 4-8, Revised 2006** — exact Ministry curriculum PDF, the primary English-program source;
- **Anglais pour débutants, Grades 4-8, Revised 2013** — Publications Ontario `232897_U` plus exact Ministry PDF, represented as a conditional alternative for learners who cannot yet follow the regular Anglais program.

The English family is intentionally modeled as `primary-with-conditional-alternatives`, not as a fictitious Grades 1-8 single-source curriculum. `tools/check_conditional_curriculum_family_evidence.py` makes its C1 promotion atomic: neither source may be treated as complete family evidence unless both primary and conditional source locks exist. That invariant is enforced by the canonical verifier and the jurisdiction/curriculum workflow.

Four French source identities remain C0-only because their exact current byte routes have not yet been admitted as bounded capture targets: Français, Mathématiques, Éducation physique et santé, and Éducation artistique. French Science, French SSHG, regular Anglais, and Anglais pour débutants have committed C1 evidence.

## Current derived state

The verifier currently requires the truthful state:

- **16** confirmed discovered source identities after composing the historical ledger, amendments, and append-only additions;
- **12** registered bounded capture targets;
- **12** committed C1 snapshot sources;
- **5** strict exact-byte monitored PDF sources;
- **7** observational DCP response surfaces;
- **0** bounded capture targets awaiting C1 evidence;
- **0** canonical reviewed C2 records;
- Kindergarten 2026 has a metadata-only C1 historical snapshot; source bytes are not retained and redistribution remains review-required;
- English-language Grades 1-8 required program-family C1 source coverage: **8/8**;
- French-language required program-family C0 source-identity coverage: **8/8**;
- French-language required program-family C1 source coverage: **4/8** — English, Science and Technology, Social Studies Grades 1-6, and History/Geography Grades 7-8;
- French C0-only program families: The Arts, French, Health and Physical Education, and Mathematics;
- all 12 C1 snapshots retain no source bytes and remain `review-required` for redistribution;
- human source review incomplete;
- licensing review incomplete;
- deterministic full-pack verification incomplete;
- governed activation unavailable.

Twelve C1 snapshots must not be described as twelve-sixteenths product completion. Five strict recapture sources are not a fraction of curriculum truth, and 8/8 source-family discovery does not mean eight completed curricula. These are different evidence dimensions. Kindergarten is outside the Grades 1-8 required-program-family denominator. SSHG supplies two program-family rows in each language stream. The French English family additionally requires two source identities because its beginner curriculum is conditional rather than universal.

## Fail-closed properties

`tools/curriculum_source_additions.py` rejects attempts to:

- introduce a source ID that already exists and should use the amendment chain;
- overwrite an existing program-family primary binding;
- bind an addition to a non-required program family;
- duplicate primary or conditional bindings;
- add a conditional source before its primary source;
- add a conditional source without an applicability condition and grade scope;
- claim an upstream digest at C0;
- use a non-Publications Ontario host for publication-backed provenance;
- treat a generic DCP resource page as a DCP-only curriculum identity;
- omit the exact official curriculum source from evidence;
- silently inherit Ontario additions when validating a custom discovery artifact.

`tools/check_conditional_curriculum_family_evidence.py` rejects partial C1 state for any `primary-with-conditional-alternatives` family. A family may have none of its required sources locked or all of them locked; a primary-only or alternative-only state fails closed.

`tools/remote_curriculum_source_capture.py` rejects attempts to:

- capture an unregistered source ID or non-allowlisted host;
- use an arbitrary URL in place of an admitted C0 source locator;
- loosen size, media-type, redistribution, redirect, or host-policy boundaries;
- make a DCP-only source use a different download route than its admitted French curriculum route;
- make a Ministry-PDF-only source use a different PDF or non-PDF media type;
- add synthetic publication metadata to a DCP-only or Ministry-PDF-only source merely at capture time.

`tools/ontario_elementary_readiness.py` rejects attempts to:

- count more C1 sources than discovered/registered sources;
- leave a C1 snapshot outside the monitoring classification;
- relabel current observational DCP surfaces as if all C1 sources were strictly recapturable;
- claim English/French C1 program coverage beyond required families;
- claim whole-base source completion while known gaps remain;
- claim human review, licensing completion, deterministic pack verification, or governed activation from machine evidence alone.

The readiness view names the historical discovery ledger and source-additions registry as separate inputs. It does not alter source locks, curriculum records, monitoring observations, or official-source artifacts it summarizes.
