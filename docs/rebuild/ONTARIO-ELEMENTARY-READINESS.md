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

The original discovery ledger identified all eight required French-language-school program families as unresolved but did not contain source identities for them. Rewriting that historical ledger would weaken provenance, so `source-discovery-additions.v1.json` introduces new C0 identities only after official-source evidence is resolved.

Six French-language-school source identities now cover seven of the eight required program families at C0:

- **Français, Grades 1-8, 2023** — Publications Ontario `CL33252`;
- **Mathématiques, Grades 1-8, 2020** — Publications Ontario `CL32239` is the primary identity record used here; separate official online-resource record `300333` remains a distinct format record rather than being collapsed;
- **Éducation physique et santé, Grades 1-8, 2019** — Publications Ontario `022579`;
- **Éducation artistique, Grades 1-8, Revised 2009** — online-resource publication `231943_U`, with separate official book record `231943` preserved as a distinct format record;
- **Sciences et technologie, Grades 1-8, 2022** — exact current Ontario French Curriculum and Resources route `https://www.dcp.edu.gov.on.ca/fr/curriculum/sciences-technologie`;
- **Études sociales, Histoire et Géographie, Grades 1-8 current route** — exact Ontario French Curriculum and Resources root `https://www.dcp.edu.gov.on.ca/fr/curriculum/etudes-sociales-histoire-geo`; this one source identity supplies the Social Studies Grades 1-6 and History/Geography Grades 7-8 program-family rows, while detailed 2018/2026 expectation reconciliation remains a later evidence task.

All six remain **C0 source identities**. French Science and French SSHG now also have bounded, exact-route capture targets so hosted workflows can attempt metadata-only C1 candidates and separately probe response-surface stability. Listing those targets is not C1 evidence. The other four French C0 identities still have no capture target. No French source currently has a committed C1 snapshot, redistribution approval, or canonical C2 record.

The additions validator accepts only two provenance modes: a Publications Ontario record or an exact `www.dcp.edu.gov.on.ca/fr/curriculum/...` route carrying the dedicated `official-current-dcp-curriculum-route` classification. The remote-capture validator preserves that distinction: a DCP-only C0 identity must bind its source locator and download URL exactly to the admitted route and cannot acquire invented Publications Ontario metadata through the capture registry. A generic DCP resource page or unrelated website cannot satisfy these gates.

The only French-language-school required family still unresolved at source identity is **English**. Ontario's French-language-school policy surface distinguishes English instruction from the other French-medium curricula and includes Anglais / Anglais pour débutants boundaries. The repository therefore does not substitute an English-language-school Language artifact or treat one legacy French publication as a complete Grades 1-8 source.

## Current derived state

The verifier currently requires the truthful state:

- 14 confirmed discovered source identities after composing the historical ledger, amendments, and append-only additions;
- 10 registered bounded capture targets;
- 7 C1 snapshot sources;
- 3 strict exact-byte monitored sources;
- 4 observational DCP response surfaces;
- 3 pending C1 capture targets: English Arts, French Science and Technology, and French Social Studies/History/Geography;
- 0 canonical reviewed C2 records;
- Kindergarten 2026 has a metadata-only C1 historical snapshot; source bytes are not retained and redistribution remains review-required;
- Social Studies, Grades 1-6, and History and Geography, Grades 7-8 has a metadata-only historical C1 snapshot bound to the current official English DCP `elementary-sshg` route; Publications Ontario `233531` preserves the 2018 revised base lineage and Ontario's 2026-27 direction confirms new Grade 7-8 History learning;
- English-language required program families with C1 source evidence: 7/8;
- French-language required program families with C0 source identity evidence: 7/8;
- French-language required program families with C1 source evidence: 0/8;
- French-language family still unresolved at source identity: English;
- The Arts is the sole uncaptured discovered English-language required-program source and retains a bounded capture target;
- six French C0 source identities plus English Arts are discovered but not yet C1-captured; two of those French identities now have bounded pending capture targets;
- human source review incomplete;
- licensing review incomplete;
- deterministic full-pack verification incomplete;
- governed activation unavailable.

Seven C1 snapshots must not be described as seven-fourteenths product completion. Likewise, three strict recapture sources must not be described as a fraction of curriculum truth, and seven French C0 program-family bindings must not be described as seven completed curricula. These are different evidence dimensions. Kindergarten is outside the Grades 1-8 required-program-family denominator used for the 7/8 English-language count. The English SSHG source and the French SSHG source each supply two required program-family rows in their respective streams.

## Fail-closed properties

`tools/curriculum_source_additions.py` rejects attempts to:

- introduce a source ID that already exists and should use the amendment chain;
- overwrite an existing program-family source binding;
- bind an addition to a non-required program family;
- duplicate an addition or coverage binding;
- claim an upstream digest at C0;
- use a non-Publications Ontario host for publication-backed provenance;
- treat a generic DCP resource page as a DCP-only curriculum identity;
- omit the exact DCP curriculum route from DCP-only evidence;
- silently inherit the Ontario additions when validating a custom discovery artifact.

`tools/remote_curriculum_source_capture.py` rejects attempts to:

- capture an unregistered source ID or non-allowlisted host;
- use an arbitrary URL in place of an admitted C0 source locator;
- loosen size, media-type, redistribution, redirect, or host-policy boundaries;
- make a DCP-only source use a different download route than its admitted French curriculum route;
- add synthetic publication metadata to a DCP-only source merely at capture time.

`tools/ontario_elementary_readiness.py` rejects attempts to:

- count more C1 sources than discovered/registered sources;
- leave a C1 snapshot outside the monitoring classification;
- relabel the current observational DCP surfaces as if all C1 sources were strictly recapturable;
- claim English/French C1 program coverage beyond required families;
- claim whole-base source completion while known gaps remain;
- claim human review, licensing completion, deterministic pack verification, or governed activation from machine evidence alone.

The readiness view names the historical discovery ledger and the source-additions registry as separate inputs. It does not alter source locks, curriculum records, monitoring observations, or official-source artifacts it summarizes.
