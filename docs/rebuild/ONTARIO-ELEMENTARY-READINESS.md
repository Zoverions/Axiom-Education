# Ontario Elementary Readiness

Ontario Elementary readiness is a **derived evidence view**, not mutable state written back into source discovery.

The historical C0 discovery ledger remains immutable in meaning. Existing historical source identities can receive digest-bound append-only resolution amendments. Source identities that were absent from the historical ledger enter through an append-only additions layer, and later route resolution for those added identities uses a second digest-bound amendment layer rather than rewriting the original addition.

The composed evidence model is:

```text
historical C0 discovery
  + append-only historical-source amendments
  + append-only new source identities
  + digest-bound amendments to added source identities
  + C1 exact-byte historical snapshots
  + source-surface monitoring
  + content-addressed human source identity/scope review
  + content-addressed human licensing/redistribution review
  + exact-byte-gated C2 candidate intake
  + content-addressed human normalization review
  + fail-closed canonical C2 promotion
  + later pack/staging/activation evidence
  -> derived readiness
```

No later stage is inferred merely because an earlier stage is complete.

## Current milestone: base source capture complete

The current derived state has bounded C1 evidence for every discovered Ontario Elementary/Kindergarten source identity:

- **16/16 discovered source identities have C1 locks**;
- **16/16 have bounded recapture targets**;
- English-language-school Grades 1-8 required program-family C1 coverage: **8/8**;
- French-language-school required program-family C1 coverage: **8/8**;
- Kindergarten 2026 has C1 evidence outside the Grades 1-8 family denominator;
- French-school English preserves both regular **Anglais** and the policy-required conditional **Anglais pour débutants** pathway, with atomic C1 evidence for the pair;
- no discovered source remains at C0-only status;
- no registered capture target remains pending C1.

This justifies the narrow statement **Ontario Elementary base source capture is complete**.

It does **not** justify saying Ontario Elementary is complete, curriculum-correct, school-ready, credit-bearing, Ministry-approved, production-ready, or governed-activation-ready. Source capture is only one evidence stage.

## C1 snapshot evidence is not recapture stability

A C1 lock proves that exact bytes were captured at a recorded time and digested. It does not promise that the serving transport surface is immutable forever.

Current monitoring separates two classes.

### Strict exact-byte document sources — 5

The following document-like PDF sources have demonstrated exact-byte recapture stability and remain strict CI drift gates:

- English Health and Physical Education, Grades 1-8, 2019;
- English Mathematics, Grades 1-8, 2020;
- French as a Second Language, Grades 1-8, Revised 2013;
- French-language-school Anglais, Grades 4-8, Revised 2006;
- French-language-school Anglais pour débutants, Grades 4-8, Revised 2013.

A changed digest, byte length, media type, locator, or source binding on these sources is a fail-closed drift event requiring review.

### Observational DCP HTML response surfaces — 11

The remaining C1 sources are current DCP HTML curriculum routes and therefore remain observational even where one hosted run was byte-stable:

- Kindergarten 2026;
- English Arts;
- English Language;
- English Science and Technology;
- English Social Studies / History and Geography;
- French Sciences et technologie;
- French Études sociales / Histoire et Géographie;
- French Français;
- French Mathématiques;
- French Éducation physique et santé;
- French Éducation artistique.

Several of these routes have demonstrated cross-job exact-byte or availability volatility. Français and Mathématiques were byte-identical across their bounded C1 capture and three separate probes in workflow run `32421398988`, but they remain HTML response surfaces and therefore are not promoted to strict document monitoring from one run alone. In the same run, French Éducation physique et santé and French Éducation artistique produced valid historical C1 captures while their three-probe observations converged on different byte signatures and lengths. That is transport/template evidence, not proof of curriculum-content change.

The repository therefore preserves this distinction:

```text
historical exact-byte capture = C1 evidence
repeatable immutable document = possible strict drift gate
HTML response repeatability = observational evidence only
HTML response drift = not semantic curriculum change by itself
```

## French-language-school source model

The French source family is no longer unresolved.

Current source identities include:

- **Français, Grades 1-8, 2023** — Publications Ontario `CL33252`, current DCP `elementaire-francais` route;
- **Mathématiques, Grades 1-8, 2020** — Publications Ontario `CL32239`, current DCP `elementaire-mathematiques` route; separate official online-resource record `300333` remains distinct;
- **Éducation physique et santé, Grades 1-8, 2019** — Publications Ontario `022579`, current DCP `elementaire-education-physique-sante` route;
- **Éducation artistique, Grades 1-8, Revised 2009** — online-resource publication `231943_U`, separate book publication `231943`, current DCP `elementaire-education-artistique` route;
- **Sciences et technologie, Grades 1-8, 2022** — current French DCP `sciences-technologie` route;
- **Études sociales, Histoire et Géographie** — current French DCP `etudes-sociales-histoire-geo` route, supplying both the Grades 1-6 Social Studies and Grades 7-8 History/Geography family rows while detailed revision reconciliation remains a later evidence task;
- **Anglais, Grades 4-8, Revised 2006** — exact Ministry curriculum PDF, primary French-school English source;
- **Anglais pour débutants, Grades 4-8, Revised 2013** — exact Ministry curriculum PDF plus Publications Ontario `232897_U`, retained as a conditional alternative rather than substituted for regular Anglais.

The additions validator and digest-bound addition-amendment validator preserve the original Publications Ontario identity, subject, grade scope, policy version and source provenance. A later route resolution cannot silently rewrite those fields or manufacture a C1 digest.

## Human source identity and scope review — 0/16

Base capture does not decide whether Axiom's composed metadata correctly represents the official source identity, authority, policy version, grade scope, and locator. Those claims now have a separate deterministic human-review layer.

`tools/ontario_elementary_source_review.py` generates **16 content-addressed review targets**. Each target binds the exact composed source-entry digest and exact C1 lock digest. A valid review must be an explicit human attestation with reviewer identity and qualification, and it must address:

- official authority;
- source identity;
- policy version;
- grade scope;
- official locator.

An approval cannot contain open findings. A changed source object or C1 lock makes the review stale. Version 1 allows only one current attestation per source; duplicate current attestations fail closed rather than relying on filename ordering.

Current committed state: **0 submitted / 0 approved / 16 unreviewed**. No machine-generated approval exists.

## Licensing and redistribution review — 0/16

Licensing is a separate content-addressed human gate. Public availability is explicitly **not** treated as redistribution permission.

`tools/ontario_elementary_licensing_review.py` creates 16 targets bound to the current source-review target and C1 lock. Supported human decisions are:

- `verbatim-redistribution-permitted`;
- `reference-only-use-permitted`;
- `external-reference-only`;
- `prohibited`;
- `unresolved`.

A resolved decision requires the rights/authority and terms basis to be recorded, the redistribution scope and conditions to be decided, all required confirmations to be true, and no open findings. Verbatim permission additionally requires at least one evidence locator. The verifier records the human decision but does not claim that software has independently decided copyright law or proved the legal conclusion correct.

Current committed state: **0 submitted / 0 resolved / 16 unresolved / 0 verbatim permissions**.

Historical C1 locks remain `review-required`; later licensing evidence is additive and does not rewrite what was known at capture time.

## Deterministic reviewer dossier

`tools/ontario_elementary_reviewer_dossier.py` packages a deterministic human-review handoff containing:

- the 16 source-review targets;
- the 16 licensing-review targets;
- current readiness and monitoring context;
- all 16 metadata-only C1 locks;
- 16 blank source-review templates;
- 16 blank licensing-review templates;
- summaries of any submitted evidence;
- a reviewer guide and content-digested manifest.

The dossier packages **no captured Ontario curriculum source bytes**. Blank templates contain the exact target digest but no reviewer identity, no decision, and no preselected confirmations; they are intentionally invalid until a qualified human completes them.

## C2 candidate intake — 0/16 eligible

C2 normalization has an explicit pre-canonical gate rather than an implied transition from C1.

`tools/ontario_elementary_c2_intake.py` currently supports **reference-only candidate intake only**. A source becomes eligible only when:

1. its current source identity/scope review is `approved`;
2. its current licensing decision is either `reference-only-use-permitted` or `verbatim-redistribution-permitted`; and
3. the operator supplies official source bytes whose SHA-256 and byte length exactly match the historical C1 snapshot.

An exact-byte match proves only that the operator input matches the historical C1 capture. It does not prove semantic extraction, normalization correctness, human normalization review, canonical C2 promotion, pack readiness, or activation.

`external-reference-only`, `prohibited`, `unresolved`, missing licensing evidence, or missing source approval all block candidate intake. Even a future verbatim-redistribution permission exposes only `reference-only` candidate mode in C2 intake v1. Paraphrase and verbatim candidate modes remain intentionally unsupported until a separately reviewed licensing-aware canonicalization boundary exists.

Current committed state: **0/16 eligible sources, 0 committed C2 candidates, and 0 canonical C2 records**.

The existing HPE Grade 1 artifact remains a deterministic C1-bound **construction fixture**, not proof that the official source was source-byte-derived, normalized correctly, and human-reviewed.

## Human normalization review and canonical C2 promotion — 0 candidates / 0 reviews / 0 canonical records

The transition from a verified C2 candidate to the canonical `records-v2` directory is now an executable gate rather than a documentation-only follow-up.

`tools/ontario_elementary_c2_promotion.py` builds content-addressed review targets for exact current candidates in `curriculum/ontario-elementary/c2-candidates/`. A target binds:

- the candidate `record_id` and canonical `content_digest`;
- the exact current source ID;
- the current C1 source-lock digest;
- the historical C1 source-byte SHA-256 and byte length; and
- `reference-only` content mode.

A qualified-human normalization review must bind that exact target and exact source evidence. An approval requires explicit confirmation that the reviewer checked:

- the exact C1 source bytes;
- official structure and identifiers;
- education context and grade/level scope;
- hierarchy and relationships;
- absence of embedded source wording in reference-only mode;
- C1 provenance binding;
- separation of Axiom-authored metadata from official fields; and
- the absence of any implied completeness or activation claim.

Negative findings and `changes-required`/`rejected` decisions remain provenance. The latest valid review controls the disposition of that exact candidate revision.

Canonical promotion re-runs the earlier gates. `promote` requires the exact C1 source bytes again, re-verifies the reference-only candidate through the C2 intake gate, verifies the exact approved human normalization review, and copies the **unchanged candidate bytes** into `records-v2`. It refuses a different existing canonical file or an output outside the canonical directory.

`verify-canonical` is part of `tools/verify.py` and CI. Every future canonical record must exactly match a retained current candidate whose source/licensing evidence is still eligible and whose exact current normalization target has an approved review. A canonical record without that evidence fails closed.

Current committed state remains deliberately empty:

- committed reference-only C2 candidates: **0**;
- submitted human normalization reviews: **0**;
- approved normalization targets: **0**;
- canonical C2 records: **0**.

This gate closes the architectural transition but creates no curriculum content or human approval.

## What remains incomplete

Base source capture completion does not advance the later gates automatically. The current readiness state still reports:

- **human source identity/scope review:** 0/16 approved;
- **licensing and redistribution review:** 0/16 resolved;
- **reference-only C2 candidate eligibility:** 0/16;
- **committed C2 candidates:** 0;
- **human normalization reviews:** 0;
- **canonical reviewed C2 curriculum records:** 0;
- **crosswalk review:** incomplete beyond bounded construction/evidence work;
- **deterministic full curriculum pack verification:** incomplete;
- **accessible and printable alternatives:** incomplete at whole-program level;
- **educator/cultural/context review:** incomplete;
- **governed learner/educator workflow promotion:** incomplete;
- **signed staging and governed activation:** unavailable;
- **Ministry approval or endorsement:** not claimed.

## Fail-closed properties

The source and review pipeline rejects attempts to:

- rewrite the historical discovery artifact in place;
- introduce an already-existing source ID through the additions path;
- amend an added source without matching the digest of its prior exact source object;
- alter source identity, subject family, grade scope, policy version, or established publication lineage through a route-resolution amendment;
- claim an upstream digest at C0;
- capture an unregistered source ID or non-allowlisted host;
- use a source locator not already present in the composed discovery evidence;
- pre-approve redistribution through remote capture;
- leave a committed C1 lock without a bounded recapture target;
- leave a C1 lock outside monitoring classification;
- classify an HTML response surface as a strict document source under the current policy;
- partially promote the regular/conditional French-school English family;
- claim source-capture completeness when its component evidence disagrees;
- accept a stale, machine-authored, incomplete, or duplicate-current source-review attestation;
- infer source approval from C1 capture;
- accept a stale, machine-authored, incomplete, or duplicate-current licensing attestation;
- infer redistribution permission from public availability or C1 capture;
- claim licensing completion unless all 16 current targets have resolved decisions;
- admit C2 candidate normalization without current source approval and compatible licensing evidence;
- accept operator source bytes whose digest or byte length differs from the C1 lock;
- expose paraphrase or verbatim C2 candidate modes through the v1 intake gate;
- accept a stale human normalization review whose candidate digest, C1 lock, or C1 byte evidence no longer matches;
- approve normalization while required confirmations are false or open findings remain;
- promote a candidate whose current source/licensing eligibility has become blocked;
- promote bytes that differ from the reviewed candidate;
- leave a canonical C2 record without a retained matching candidate and current exact approved normalization review;
- infer full-pack verification, governed activation, curriculum completeness, or Ministry approval from canonical C2 presence or any earlier evidence stage.

## Current derived state

The machine-verifiable source/readiness state is therefore:

- discovered source identities: **16**;
- registered bounded capture targets: **16**;
- committed C1 snapshots: **16**;
- strict exact-byte document sources: **5**;
- observational DCP HTML sources: **11**;
- English Grades 1-8 required program families with C1 evidence: **8/8**;
- French Grades 1-8 required program families with C1 evidence: **8/8**;
- Kindergarten C1 snapshot: **yes**;
- uncaptured discovered sources: **0**;
- pending bounded capture targets: **0**;
- overall base source capture: **complete**;
- source-review targets: **16**;
- approved source reviews: **0/16**;
- licensing-review targets: **16**;
- resolved licensing reviews: **0/16**;
- verbatim redistribution permissions: **0**;
- reference-only C2 intake eligibility: **0/16**;
- committed C2 candidates: **0**;
- submitted human normalization reviews: **0**;
- approved normalization targets: **0**;
- canonical C2 records: **0**;
- deterministic full-pack verification: **incomplete**;
- governed activation: **unavailable**.

That boundary is intentional: **all required sources are captured, while human source review, licensing, source-derived C2 candidate creation, human normalization review, and canonical promotion remain evidence-gated and unpromoted.**
