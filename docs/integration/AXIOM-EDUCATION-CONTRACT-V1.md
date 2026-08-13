# Axiom Education Contract v1

**Status:** experimental contract, bounded host-injected transport, and governed learner runtime; no default host or production provider
**Brand:** Axiom Education  
**Contract ID:** `axiom.education`  
**Controller:** `capsule:axiom.education`  
**Curriculum-pack profile:** `jurisdictional`  
**Version:** `1.0.0`  
**Canonical SHA-256:** `a20e191a05308ef85bdc1cc74bfa0d54b98a176818f8030a172b4c3709a28fa2`  
**Minimum AXIOM kernel:** `0.12.0-dev.0`
**Current reviewed compatibility profile:** exact `0.12.0-dev.3` pin in `config/axiom-mesh-compatibility.v1.json`

## Purpose

Axiom Education is the generic education-domain boundary and independently releasable lifelong-learning application for AXIOM-MESH. Ontario is its first curriculum profile, not the product identity or permanent scope of the shared contract.

The contract defines what an education application may request, what purpose and consent must accompany learner-related requests, which actions are high-risk, and what AXIOM must report while no approved education provider exists.

The identical canonical JSON file is committed in both repositories:

```text
Axiom-Education/contracts/axiom-education.v1.json
AXIOM-MESH/mesh/config/domain-contracts/education.v1.json
```

Both sides pin the exact file digest. A syntactically valid replacement contract is rejected unless its bytes match the pinned SHA-256.

## Jurisdictional curriculum profile

`curriculum_pack_profile: jurisdictional` means the domain contract remains reusable while curriculum packs retain their own jurisdiction, authority, provenance, licensing, review, and signature metadata.

Ontario is the first profile. Future jurisdictions must use separate reviewed curriculum packs and policy without changing the generic Axiom Education authority boundary or inheriting Ontario-specific claims.

## Gateway envelope

OntarioEdAI submits through the existing AXIOM operator surface:

```text
POST /v1/intents
Authorization: Bearer <externally managed token>
idempotency-key: <unique bounded key>
Content-Type: application/json

{
  "action": "education.curriculum.query",
  "input": {
    "contract_id": "axiom.education",
    "contract_version": "1.0.0",
    "contract_sha256": "a20e191a...8fa2",
    "active_pack_manifest_sha256": "...",
    "course_code": "MTH1W"
  }
}
```

The Dart client inserts the contract ID, version, and digest itself. Callers cannot override those fields.

## Initial actions

| Action | Risk | Consent | Current AXIOM state |
|---|---:|---|---|
| `education.curriculum.pack.inspect` | low | none | host-bound request; provider availability governs |
| `education.curriculum.pack.stage` | medium | none | host-bound request; provider availability governs |
| `education.curriculum.pack.activate` | high | confirmation and independent approval | host-bound request; no production activation provider evidenced |
| `education.curriculum.query` | low | none | host-bound request; provider availability governs |
| `education.tutor.respond` | medium | personalized local tutoring | host-bound request; no production tutor provider evidenced |
| `education.learner.event.append` | medium | learning progress recording | executable host-bound client; production provider not evidenced |
| `education.learner.progress.read` | medium | learning progress review | executable host-bound client; production provider not evidenced |
| `education.portfolio.export` | high | learner-controlled export plus confirmation and independent approval | host-bound request; no production export provider evidenced |

The application has no default host binding and no local learner-record fallback. A reviewed host must supply the exact compatibility profile, relative Gateway requester, and memory-only token provider; AXIOM policy and provider availability still govern every operation. The contract therefore cannot become accidentally authoritative merely because its JSON, client, or host seam is installed.

## Minor-data defaults

The shared contract requires:

- data minimization;
- local processing preference;
- no advertising;
- no behavioural targeting;
- no covert attention or emotion monitoring;
- no diagnosis inference;
- human review and appeal;
- no raw prompts in evidence;
- no raw student work in logs.

A future provider may tighten these constraints. It may not loosen them.

## Client behavior

`AxiomEducationClient` is transport-independent. It does not own:

- a Gateway URL;
- API tokens or service identity;
- TLS or certificate trust;
- network permissions;
- a model provider;
- learner-record storage;
- curriculum activation authority.

A deployment-specific transport must be injected later and separately reviewed.

Before any transport call, the client rejects:

- unknown actions;
- missing required fields;
- fields outside the action contract;
- caller-supplied contract identity fields;
- malformed SHA-256 values;
- wrong consent purpose;
- missing subject or consent identifiers;
- excessive query result limits;
- excessive tutor output or deadline budgets;
- empty or oversized prompts;
- invalid idempotency keys.

Gateway responses preserve AXIOM semantics:

- `503 capability_unavailable` → explicit unavailable exception;
- `403 policy_denied` → explicit policy exception;
- `409 confirmation_required` or `independent_approval_required` → explicit approval exception;
- transport failure → explicit transport exception;
- a `2xx` response containing an `error` object → protocol failure, never success.

## Activation requirements

The bridge remains experimental until all are complete:

1. deployment-specific mutually authenticated transport;
2. external token and credential custody;
3. approved curriculum, tutor, learner-record, and export provider capsules;
4. AXIOM provider conformance evidence;
5. exact consent lookup and scope enforcement at runtime;
6. curriculum-pack signature verification and staged rollback;
7. encrypted learner-record implementation;
8. redacted evidence and log inspection;
9. accessibility and human appeal workflows;
10. pilot-specific privacy, security, and operational review.
