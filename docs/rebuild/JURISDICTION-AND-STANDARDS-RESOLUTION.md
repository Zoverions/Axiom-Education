# Jurisdiction and Standards Resolution

Status: architecture proposal on rebuild branch; not yet a promoted capability.

## Goal

Axiom Education must support learners whose applicable education standards differ by country, province/state/region, district/board, institution, program, language stream, homeschool regime, or other legitimate education authority.

The system must also remain portable. A learner may move, change schools, enter a specialist program, hold multiple simultaneous education contexts, or use Axiom Education outside a compulsory curriculum context.

Therefore jurisdiction is **not part of the permanent subject identifier**. It is governed, effective-dated context attached to the subject through independently verifiable claims.

## Separation of concerns

```text
AXIOM-MESH
  identity + attested context claims
  policy + consent + assurance
  capability issuance
  evidence + history

Axiom Education
  jurisdiction resolver
  standards-pack registry
  competency graph
  standards crosswalks
  learner-record semantics
  curriculum/tutor/portfolio domain capabilities

Experience products (for example CLAW Academy)
  age-appropriate UX
  stories, games, lessons and projects
  activity evidence generation
  presentation of current standards alignment
```

An experience product must not become a second identity provider, consent authority, curriculum authority, or learner-record authority.

## Education-context claims

An education-context claim is a separate attestation linked to a subject. It may describe, for example:

- residence in a jurisdiction;
- enrollment in a school, board/district, or program;
- guardian-selected homeschool context;
- learner-selected optional enrichment context where policy permits it;
- language, Indigenous, international, special-program, or cross-jurisdiction enrollment.

Claims are effective-dated and evidence-bound. The education domain receives only the minimum fields needed to resolve standards. It does not require raw citizenship or full residency records when an opaque verified authority/jurisdiction claim is sufficient.

## Authority stack

The generic authority stack is:

```text
country
  -> region (province/state/territory/etc.)
    -> district / board / local education authority
      -> institution
        -> program
```

Not every jurisdiction uses every layer. National systems can resolve directly from country to institution. Federated systems can use regional packs. Sovereign Indigenous or other recognized education authorities can occupy the appropriate governed authority layer without being forced into a single state-centric topology.

Multiple active layers are allowed.

## Standards packs

A standards pack is a signed, versioned, provenance-bearing jurisdictional artifact. It must identify:

- authority ID;
- jurisdiction ID;
- grade/age band;
- effective period;
- exact source provenance;
- manifest digest;
- signer key ID;
- superseded pack, when applicable;
- standards and expectation identifiers;
- mappings to stable Axiom competency identifiers.

Installing a pack grants no authority. Activation remains governed by the existing `education.curriculum.pack.activate` action.

## Minimum-preserving composition

Standards layers compose from broad to specific.

A lower authority may:

- add requirements;
- add local examples/content;
- add language/cultural context;
- map activities to additional expectations;
- choose pedagogical presentation.

It may not silently erase mandatory parent-layer requirements. Replacing parent requirements requires an explicit delegation encoded in the authority relationship and visible in the resolved evidence.

This mirrors the wider Axiom design principle that downstream authority cannot silently expand beyond its grant.

## Stable competency graph

Experience content should not be authored directly against one jurisdiction's expectation IDs as its only semantic identity.

Instead:

```text
CLAW activity
  -> stable competency IDs
  -> jurisdiction crosswalk
  -> one or more active standards expectations
```

Example:

```text
activity: compare two characters' choices
competencies:
  - perspective-taking
  - evidence-based-reasoning
  - consequence-modeling

Ontario pack:
  -> Ontario expectation mappings

Alberta pack:
  -> Alberta expectation mappings

UK pack:
  -> relevant national-programme mappings
```

One activity can therefore satisfy several standards systems without duplicating the activity. If no verified mapping exists, the activity can still be offered as enrichment, but it cannot claim curriculum coverage.

## Resolution result

A successful resolver returns an evidence-bound context containing:

- subject ID;
- `as_of` time;
- grade/age/program context;
- active education-context claim IDs and evidence digests;
- ordered active standards-pack manifest digests;
- mandatory vs optional layers;
- explicit delegations used during composition;
- a deterministic resolution digest.

Learner events bind to the active standards-pack manifest(s) and resolution digest at the time of the event.

## Backward-compatible learner-event binding

The pinned `axiom.education` v1 contract intentionally remains unchanged. Its learner-event action currently exposes one optional `active_pack_manifest_sha256` together with `course_code` and `expectation_ids`. That single pack field is an **event projection**, not a representation of the complete jurisdiction context.

The sibling `axiom.education.standards-context-binding` contract preserves the missing context without changing the v1 digest. It defines `axiom-education-event-standards-projection.v1`, which binds:

- the learner subject;
- the full jurisdiction `resolution_digest`;
- the resolution `as_of` time;
- the complete ordered list of active pack manifest digests;
- the one pack selected for the event-level v1 projection;
- course and expectation IDs;
- a verified-crosswalk manifest digest and its verification-evidence digest;
- a deterministic projection digest.

The selected v1 pack must be present in the complete context. The ordered context-pack list must remain exactly the resolver's broad-to-specific stack. A one-pack event projection therefore cannot be mistaken for the full active curriculum context.

For compatibility, the projection can live in the governed learner-event payload/evidence object. The existing v1 `payload_digest` then binds the complete standards projection while the existing top-level v1 fields continue to carry the selected pack/course/expectations needed by current integrations.

```text
full jurisdiction resolution
  -> resolution_digest + ordered pack stack
  -> verified competency crosswalk
  -> event standards projection
  -> governed event payload
  -> existing v1 payload_digest
  -> existing v1 learner event
```

This bridge does not make the `payload_digest` self-describing. Verification still requires access to the governed payload/evidence object and the referenced resolution/crosswalk evidence. Runtime integration must fail closed when those references are absent, mismatched, stale for the event's declared time, or unverifiable.

The bridge also does not verify source authenticity or crosswalk truth by itself. It validates the integrity and exact relationship among already-verified artifacts. Source/signature validation and independent crosswalk verification remain separate gates.

## Mobility and history

Changing jurisdictions never rewrites historical evidence.

If a learner moves from Ontario to another jurisdiction:

1. old events retain their Ontario pack manifest and expectation mappings;
2. the new context becomes effective from its stated date;
3. new activity resolves against the new standards stack;
4. crosswalks may translate prior evidence into the new competency/standards view;
5. the translation is a new derived assertion, not a rewrite of the old record.

The standards-context projection additionally retains the old event's exact resolution digest and ordered pack stack. A later move, pack supersession, or revised crosswalk produces new evidence rather than mutating the old projection.

## Government and authority participation

A government or education authority may operate its own standards-pack publishing and signing infrastructure, subject to the trust configuration adopted by the deploying Axiom network.

This permits national or regional adoption while preserving sovereignty:

- the authority controls its standards content and versions;
- Axiom verifies provenance, signatures, effective dates, and delegation;
- local policy controls activation;
- historical learner evidence remains portable and inspectable;
- other jurisdictions can coexist without a single global curriculum authority.

## Assurance

The jurisdiction contract currently requires at least A2 evidence for claims used to select mandatory standards. Higher-risk authority changes or standards-pack activation can require A3 independent review under the existing Axiom assurance model.

A4 collective finality is not implied by standards selection and must not be rendered unless the underlying AXIOM-MESH deployment actually provides it.

## CLAW Academy consequence

CLAW should be rebuilt as an elementary experience product over this domain model.

CLAW owns:

- elementary interaction design;
- narrative worlds and characters;
- games and projects;
- family/co-play experiences;
- age-appropriate explanation and feedback;
- activity definitions and competency mappings.

CLAW does **not** own authoritative:

- identity;
- jurisdiction membership;
- guardian consent;
- curriculum activation;
- learner progress history;
- portfolio export authority;
- standards provenance.

Those belong to AXIOM-MESH and Axiom Education.

For an official curriculum claim, CLAW should receive or construct only the minimized verified projection needed for the event. If no verified jurisdiction context or crosswalk exists, CLAW may still present the activity as enrichment but must render official curriculum coverage as unavailable rather than inferred.

## Promotion boundary

This document, `contracts/axiom-education-jurisdiction.v1.json`, and `contracts/axiom-education-standards-context-binding.v1.json` remain foundation artifacts. The deterministic resolver and structural evidence-binding bridge exist, but no implemented capability should be promoted until there is:

1. signed-pack validation in the governed runtime path;
2. governed context-claim validation and current-state resolution;
3. independently verifiable competency-crosswalk evidence;
4. durable governed storage/reference for the full resolution and event projection;
5. final learner-event commit verification of those evidence references;
6. negative-path tests across the actual AXIOM-MESH/Axiom-Education boundary;
7. integration with at least one non-Ontario pack or synthetic cross-jurisdiction conformance fixture;
8. user-facing evidence presentation that distinguishes enrichment, projected alignment, and authoritative curriculum claims.
