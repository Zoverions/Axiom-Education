# Axiom Education

Axiom Education is a local-first, lifelong education platform and education-domain layer for AXIOM-MESH. It is designed to support learning across age groups, jurisdictions, institutions, and life stages without making any one curriculum, grade band, school system, or delivery experience the product boundary.

**Current rebuild:** `0.5.0-dev.0`  
**Status:** active development; not production-ready  
**Canonical repository:** `Zoverions/Axiom-Education`  
**Canonical branch:** `main`  
**First supported jurisdiction:** Ontario, Canada  
**Active Ontario tracks:** Kindergarten / Grades 1-8 curriculum-capsule foundation and Secondary curriculum, with MTH1W as the first deep course vertical slice

The historical product and repository name `OntarioEdAI` is deprecated. Ontario remains the first supported jurisdiction because its source corpus and active rebuild work are present; it is not the identity or architectural boundary of the platform. Elementary, secondary, post-secondary, apprenticeship, professional, reskilling, civic, hobby, and later-life learning can share the same governed learner and evidence substrate while using different curriculum packs and experience layers.

See the [High-School Foundation Strategy](docs/rebuild/HIGH-SCHOOL-FOUNDATION.md), [Ontario Elementary Readiness](docs/rebuild/ONTARIO-ELEMENTARY-READINESS.md), [Repository Rename Record](docs/REPOSITORY-MIGRATION.md), [Branch Hygiene Policy](docs/BRANCH-HYGIENE.md), and [Deprecations](docs/DEPRECATIONS.md).

## Product boundary

```text
Axiom Education application / experience layer
  -> AXIOM Gateway
  -> policy, consent, risk, and plan evaluation
  -> short-lived capability grant
  -> approved education, curriculum, or provider capsule
  -> bounded execution
  -> encrypted learner state and evidence in Grid
```

The Flutter application remains independently releasable. AXIOM-MESH supplies the policy, consent, bounded execution, evidence, portability, and synchronization substrate for governed effects.

A curriculum pack, grade band, school program, or learning experience is a configured domain surface inside Axiom Education. None of those surfaces defines Axiom Education as a whole. Installing a curriculum or education capsule does not grant access to learner records, activate a provider, or authorize execution.

## Current usable surface

The runnable application currently provides a local Ontario secondary curriculum browser and the first bounded MTH1W practice slice. In parallel, the Ontario Elementary track now has a complete base source-acquisition layer for its current composed source set: 16/16 bounded metadata-only C1 snapshots, 8/8 English-language Grades 1-8 required-program-family source coverage, 8/8 French-language-school required-program-family source coverage, and separate Kindergarten 2026 C1 evidence. Five source surfaces are strict exact-byte PDFs and eleven DCP HTML surfaces remain observational. Captured Ontario source bytes are not committed and every historical C1 lock remains `review-required` for redistribution.

Elementary source capture is **not** curriculum readiness. Current human source identity/scope review is 0/16 approved, licensing review is 0/16 resolved, and the canonical Elementary `records-v2` directory contains 0 C2 records. Deterministic source-review and licensing-review plans, a reviewer dossier, and a fail-closed C2 intake gate are executable; C2 candidate eligibility remains 0/16 until current human source approval and compatible licensing evidence exist. The C2 intake v1 supports reference-only candidates only and additionally requires operator-supplied source bytes to match the historical C1 SHA-256 exactly.

The currently runnable secondary surface includes:

- recoverable first-run initialization;
- a searchable list of courses and expectation counts;
- course, strand, expectation, and tag browsing;
- pull-to-refresh and explicit retry states;
- automatic restoration of a missing or invalid bundled curriculum database;
- a read-only curriculum database and a separate local settings store;
- a four-lesson Grade 9 math foundations path with explicit goals, prerequisites, direct instruction, worked examples, multiple reasoning routes and representations, misconception checks, and reflection prompts;
- source-mapped offline MTH1W draft content for all 9 planned units and all 43 primary lesson slots, with 86 worked examples, 473 guided/independent/retrieval practice items, nine delayed-feedback 10-item quizzes with correction attempts, and nine transparent performance tasks;
- repo-bounded split-unit loading for Units 8 and 9 so geometry/measurement and financial-literacy lessons remain individually reviewable while still passing through the same canonical content contract as Units 1 through 7;
- lesson-selected focused practice plus a mixed-practice route, both available without AI;
- deterministic offline practice for `MTH1W-A1`, `MTH1W-A2`, `MTH1W-B2`, and `MTH1W-B4`;
- actual answer entry with exact rational and slope-intercept verification;
- an ephemeral on-screen count of checks, exact successes, and distinct items that is never saved to a learner record;
- a three-different-item stopping cue that is explicitly not a grade or mastery result;
- an in-app and written home-learning routine for two learners sharing a device;
- item-linked scaffolded hints, derived local topic references, uncalibrated difficulty disclosure, and digest evidence;
- fail-closed behavior when the practice configuration, item integrity, or verifier is unavailable.

The foundations preview and source-mapped unit drafts do **not** use tutor inference or automatically write a learner record. They remain usable without AI. The repository now contains an experimental, host-injected AXIOM Gateway client and governed learner write/self-read runtime, but it has no default host binding, local learner-record fallback, production provider, or authority-expanding path. The authored nine-unit milestone is **not** a complete MTH1W course, credit, grade, transcript, Ministry-approved resource, school enrolment, or replacement for an authorized education provider. Each authored unit has a draft quiz and performance task, while reviewed complete-course assessment, production learner progress, delegated authority, pack activation, portfolio export, and classroom synchronization remain experimental, disabled, specified, or adapter-required in [`config/capabilities.json`](config/capabilities.json).

The source conflict and blocked completion claim are documented in the
[MTH1W Source Audit](docs/curriculum/MTH1W-SOURCE-AUDIT.md) and enforced by
[`config/curriculum-readiness.json`](config/curriculum-readiness.json). The
[source-pinned official inventory](curriculum/official/ontario-mth1w-2021.inventory.json)
contains all 57 expectation references without redistributing their verbatim
descriptions; the [MTH1W Coverage Ledger](docs/curriculum/MTH1W-COVERAGE-LEDGER.md)
records the difference between authored coverage and reviewed coverage. The
[Home Learning Guide](docs/home-learning/START-HERE.md) describes safe current
use. Product sequencing is MTH1W first, then every remaining Grade 9 course,
then later grades, as defined in the
[Course Completion Roadmap](docs/rebuild/COURSE-COMPLETION-ROADMAP.md).
The [Global Instructional Methods Baseline](docs/research/GLOBAL-INSTRUCTIONAL-METHODS.md)
requires multiple valid routes without assigning fixed learning-style labels.
The scope and negative-path gates for the current MTH1W implementation are frozen in [MTH1W Phase 0 and Phase 1](docs/vertical-slices/MTH1W-PHASE-1.md).

## First five minutes

Supported rebuild toolchain:

- Flutter `3.41.1`
- Dart `3.11.x`
- Python `3.12` for curriculum and claim verification
- OpenSSL 3.x for external-key Ed25519 curriculum-pack signing

```bash
python tools/verify.py
flutter devices
flutter run -d <device-id>
```

The verification command validates the supported toolchain, installs the exact
Python test dependencies and locked Dart dependencies, checks capability and
curriculum-readiness claims, verifies Ontario Elementary source-review and
licensing-review evidence plus the deterministic reviewer dossier and fail-closed
C2 intake gate, checks both monolithic and split authored-unit content, checks
formatting, runs static analysis, and runs the complete Python and Flutter test
suites. Use an activated virtual environment if you do not want the Python
development dependencies installed into your user environment.

For an Android installation smoke build:

```bash
flutter build apk --debug
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. The protected GitHub workflow also builds this APK and publishes it as a short-lived workflow artifact after formatting, analysis, and tests pass.

Desktop runs require the corresponding Flutter desktop toolchain to be enabled. For example:

```bash
flutter config --enable-windows-desktop
flutter run -d windows
```

## Axiom Education contract

The generic cross-repository contract is [`contracts/axiom-education.v1.json`](contracts/axiom-education.v1.json).

- Brand: `Axiom Education`
- Contract ID: `axiom.education`
- Version: `1.0.0`
- Curriculum-pack profile: `jurisdictional`
- Gateway: `POST /v1/intents`
- Installation grants authority: `false`

The contract defines bounded curriculum inspection, staging, activation, querying, tutoring, learner-event, progress, and portfolio actions. Learner-data actions require exact purpose-bound consent. High-risk activation and export require explicit confirmation and independent approval.

### Mesh compatibility and forward roadmap

The governed runtime requires the machine-verified
[`config/axiom-mesh-compatibility.v1.json`](config/axiom-mesh-compatibility.v1.json)
profile in addition to a host-injected relative Gateway requester. The profile
records the current reviewed AXIOM-MESH `main` checkpoint and full Gateway
contract digest as **provenance**, not as repository-head runtime authority.
Runtime binding is scoped to the exact Education contract, learner-memory
profile, the semantic Gateway `intents.submit` seam, and the full `Gateway ->
Hypervisor -> Sandbox -> Grid` authority path. A missing or incompatible
runtime seam leaves the runtime unbound before any token or request is used.

This boundary deliberately tolerates unrelated additive Mesh work. New social,
agent, observability, or read-only Gateway routes do not silently broaden
Education authority and do not, by themselves, invalidate the Education host
binding. A change to the Education `/v1/intents` seam or an authority-bearing
Education contract still requires explicit review and a new compatibility
profile.

Runtime Capsule, Personal Agent Pack, Compute Node Profile, Local Trust
Envelope, and Agent Runtime Adapter surfaces are tracked only as
personal-compute/interoperability readiness. Assurance Graph,
provider-observation, and checkout-freshness foundations have merged into
AXIOM-MESH but remain readiness-only for Education with runtime adoption
explicitly disabled. Delegated human authority and the AXIOM Host profile
remain draft/non-production inputs. Merging or installing a contract does not
promote it: a reviewed Education adoption decision, compatibility evidence,
and executable tests are required.

A missing provider, verifier, identity, policy, consent, source, or artifact must produce an explicit unavailable or denied result. It must never produce mock success in a governed or release build.

## Current capability status

The authoritative status registry is [`config/capabilities.json`](config/capabilities.json).

Presently:

- curriculum browsing from a schema-verified bundled SQLite database is implemented;
- the current Ontario secondary corpus deterministically builds into 293 canonical records across 21 courses;
- the frozen MTH1W subset is checked against the full corpus and independently rebuilt twice byte-for-byte;
- MTH1W-labelled A1, A2, B2, and B4 practice generation and bounded deterministic local checking are experimental and explicitly limited to four derived topic references whose official mapping is under review;
- the official MTH1W hierarchy is source-pinned at 14 overall and 43 specific expectations, while educator/cultural review, licensing, reviewed course-wide coverage, cumulative assessment review, accessibility, progress, and teacher workflows remain incomplete;
- a machine-verified 9-unit, 43-lesson MTH1W blueprint maps every official expectation exactly once within a 110-hour planning envelope, but authored primary lessons total only 63.75 hours and leave 46.25 hours unallocated; all nine unit slots are authored machine-verified drafts, not a complete course;
- Units 8 and 9 use repo-bounded split manifests that are materialized through the same canonical unit validator in Python and the same `Mth1wUnitContent` runtime model in Flutter;
- the four-lesson Grade 9 Math Foundations Preview is experimental; it compares multiple valid reasoning routes but is not a complete MTH1W course;
- curriculum-pack generation, digest verification, and external-key Ed25519 signing are experimental and do not authorize activation;
- Ontario-derived records and Axiom Education extensions use visibly separate namespaces and official-recognition flags;
- legacy `irt_*` values are exported only as visibly uncalibrated adaptation heuristics;
- local tutor inference is disabled, fails closed, and no longer returns simulated logits output;
- canvas observation is an explicitly experimental bounded classifier and no longer returns mock equations;
- handwriting scoring no longer returns fixed synthetic scores when its model is missing;
- the legacy UDP/TCP classroom mesh is disabled by default, AES-GCM protected when explicitly enabled for development, and is not a trusted authority path;
- governed learner records, selective portfolio export, accessibility gates, pack activation, and AXIOM classroom synchronization remain specified or adapter-required;
- Ontario Elementary base source capture is complete for the current composed source set: 16/16 metadata-only C1 snapshots, 5 strict PDF and 11 observational HTML monitoring surfaces, with 8/8 English and 8/8 French required-program-family source coverage plus Kindergarten 2026 evidence;
- Ontario Elementary human source review is 0/16 approved, licensing review is 0/16 resolved, canonical C2 records remain 0, and the reference-only C2 intake gate therefore has 0/16 eligible sources. None of those incomplete gates may be inferred from base source capture.

## Ontario curriculum packs

Ontario is the first jurisdiction family, not the product boundary. Elementary and secondary content are separate curriculum tracks that share generic pack, provenance, jurisdiction, learner, and governance infrastructure.

Build the current deterministic unsigned Ontario secondary pack into an empty directory:

```bash
python tools/curriculum_pack.py build \
  --input assets/curriculum/ontario_curriculum_full.json \
  --ledger curriculum/source-ledger.v1.json \
  --output /tmp/axiom-education-ontario \
  --pack-id ontario-secondary \
  --pack-version 1.0.0
```

Build the frozen MTH1W phase-one subset:

```bash
python tools/curriculum_pack.py build \
  --input curriculum/slices/mth1w.v1.json \
  --ledger curriculum/source-ledger.v1.json \
  --output /tmp/axiom-education-mth1w \
  --pack-id ontario-mth1w-phase-1 \
  --pack-version 1.0.0
```

Verify content integrity:

```bash
python tools/curriculum_pack.py verify \
  --pack-dir /tmp/axiom-education-ontario
```

The protected workflow builds the complete current Ontario secondary pack twice and compares `manifest.json` and `records.jsonl` byte-for-byte. It also verifies that the frozen MTH1W subset contains exactly 11 source-identical records and produces byte-identical repeated builds. The complete pack is then signed with an ephemeral Ed25519 key and must pass signature verification.

Retrieval indexes are disposable derived artifacts. They are never the authority for curriculum content.

## Curriculum trust boundary

A valid pack signature proves that the exact canonical manifest was signed by the corresponding private key. It does not prove:

- Ontario Ministry approval;
- curriculum correctness or completeness;
- licensing or redistribution permission;
- pedagogical quality;
- safe application activation.

The MTH1W source audit pins the reviewed official PDF digest and documents known
identifier conflicts. The broader secondary source ledger still records that
upstream official-document digests have not been captured for the entire corpus
and that course-by-course source and licensing review remains required.

The Elementary track has a separate evidence chain. Its current composed source
set has 16/16 bounded C1 snapshots, but the exact source bytes are not retained
in the repository. Five PDF sources have strict exact-byte monitoring and eleven
DCP HTML sources remain observational response surfaces. Human source review,
licensing review, canonical C2 normalization, deterministic full-pack evidence,
staging, and governed activation are independent later gates. The deterministic
reviewer dossier packages metadata, plans, and blank human-review templates but
explicitly excludes captured Ontario source bytes. The C2 intake gate additionally
requires operator-supplied bytes to match the historical C1 digest and cannot
currently admit any source because review evidence is still incomplete.

## Platform evidence

The protected repository gates exercise Linux-hosted verification and Android
packaging plus a dedicated Windows quality lane. The active integration branch
also contains a bounded Apple lane using the exact Flutter 3.41.1 lock to run
formatting, analysis, Flutter tests, a macOS debug build, and an iOS debug build
with code signing disabled.

Apple CI is build-compatibility evidence only. It does not establish signing,
notarization, App Store readiness, physical-device deployment, production Apple
support, or accessibility approval. Native/plugin-sensitive dependency upgrades
remain separately reviewed because Android-only evidence is not sufficient to
certify platform behavior.

## Canonical documents

- [Product definition](docs/rebuild/PRODUCT-DEFINITION.md)
- [Ontario Elementary readiness](docs/rebuild/ONTARIO-ELEMENTARY-READINESS.md)
- [Changelog](CHANGELOG.md)
- [Evidence-gated requirements](docs/rebuild/REQUIREMENTS.md)
- [MTH1W Phase 0 and Phase 1](docs/vertical-slices/MTH1W-PHASE-1.md)
- [MTH1W source audit](docs/curriculum/MTH1W-SOURCE-AUDIT.md)
- [MTH1W coverage ledger](docs/curriculum/MTH1W-COVERAGE-LEDGER.md)
- [Home learning guide](docs/home-learning/START-HERE.md)
- [Course completion roadmap](docs/rebuild/COURSE-COMPLETION-ROADMAP.md)
- [Curriculum Pack v1](docs/curriculum/CURRICULUM-PACK-V1.md)
- [Repository rename record](docs/REPOSITORY-MIGRATION.md)
- [Branch hygiene policy](docs/BRANCH-HYGIENE.md)
- [Deprecations](docs/DEPRECATIONS.md)
- [Current curriculum source policy](CURRICULUM_SOURCES.md)

Historical research is preserved under `docs/archive/`. When documents conflict, executable behavior and [`config/capabilities.json`](config/capabilities.json) control. Archived or deprecated documents are never current claim authority.

## Security and privacy boundary

The project targets local processing and data minimization, but local-first architecture alone is not a compliance or security claim. Minor-related data defaults prohibit advertising, behavioural targeting, covert attention or emotion monitoring, diagnosis inference, raw prompts in evidence, and raw student work in logs. Human review and appeal remain mandatory design requirements.
