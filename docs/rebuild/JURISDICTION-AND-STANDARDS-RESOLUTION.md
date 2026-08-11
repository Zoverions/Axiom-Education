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

## Mobility and history

Changing jurisdictions never rewrites historical evidence.

If a learner moves from Ontario to another jurisdiction:

1. old events retain their Ontario pack manifest and expectation mappings;
2. the new context becomes effective from its stated date;
3. new activity resolves against the new standards stack;
4. crosswalks may translate prior evidence into the new competency/standards view;
5. the translation is a new derived assertion, not a rewrite of the old record.

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

## Promotion boundary

This document and `contracts/axiom-education-jurisdiction.v1.json` are architecture artifacts only. Do not add an implemented capability until there is:

1. a deterministic resolver;
2. signed-pack validation;
3. context-claim validation;
4. crosswalk validation;
5. negative-path tests;
6. integration with at least one non-Ontario pack or synthetic conformance fixture;
7. exact evidence binding into learner events.
