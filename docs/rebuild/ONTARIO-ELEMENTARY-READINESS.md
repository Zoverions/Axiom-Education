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
  + canonical C2 records
  + later human/licensing/pack evidence
  -> derived readiness
```

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

## What remains incomplete

Base source capture completion does not advance the later gates automatically. The current readiness verifier still requires:

- **human source/instructional review:** incomplete;
- **licensing and redistribution review:** incomplete;
- **canonical reviewed C2 curriculum extraction:** not established as a complete corpus;
- **crosswalk review:** incomplete beyond bounded construction/evidence work;
- **deterministic full curriculum pack verification:** incomplete;
- **accessible and printable alternatives:** incomplete at whole-program level;
- **educator/cultural/context review:** incomplete;
- **governed learner/educator workflow promotion:** incomplete;
- **signed staging and governed activation:** unavailable;
- **Ministry approval or endorsement:** not claimed.

The HPE Grade 1 artifact remains a deterministic C1-bound **construction fixture**, not proof that the full official source has been canonically extracted and human-reviewed.

## Fail-closed properties

The source pipeline rejects attempts to:

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
- infer human review, licensing, full-pack verification, governed activation, or Ministry approval from C1 evidence.

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
- human review: **incomplete**;
- licensing review: **incomplete**;
- deterministic full-pack verification: **incomplete**;
- governed activation: **unavailable**.

That boundary is intentional: **all required sources are now captured, but the curriculum built from those sources is not yet promoted.**
