# AXIOM Education Contract v1

**Status:** experimental contract and client; no live provider  
**Contract ID:** `education.ontarioedai`  
**Version:** `1.0.0`  
**Canonical SHA-256:** `19f3fdb09352bb87694913d760562065a9a84fcd89780d541ee186be4b193254`  
**Minimum AXIOM kernel:** `0.12.0-dev.0`

## Purpose

The contract is the first executable boundary between OntarioEdAI and AXIOM-MESH. It defines what OntarioEdAI may ask for, what purpose and consent must accompany learner-related requests, which actions are high-risk, and what AXIOM must report while no approved education provider exists.

The identical canonical JSON file is committed in both repositories:

```text
OntarioEdAI/contracts/axiom-education.v1.json
AXIOM-MESH/mesh/config/domain-contracts/education.v1.json
```

Both sides pin the exact file digest. A syntactically valid replacement contract is rejected unless its bytes match the pinned SHA-256.

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
    "contract_id": "education.ontarioedai",
    "contract_version": "1.0.0",
    "contract_sha256": "19f3...3254",
    "active_pack_manifest_sha256": "...",
    "course_code": "MTH1W"
  }
}
```

The Dart client inserts the contract ID, version, and digest itself. Callers cannot override those fields.

## Initial actions

| Action | Risk | Consent | Current AXIOM state |
|---|---:|---|---|
| `education.curriculum.pack.inspect` | low | none | unavailable |
| `education.curriculum.pack.stage` | medium | none | unavailable |
| `education.curriculum.pack.activate` | high | confirmation and independent approval | unavailable |
| `education.curriculum.query` | low | none | unavailable |
| `education.tutor.respond` | medium | personalized local tutoring | unavailable |
| `education.learner.event.append` | medium | learning progress recording | unavailable |
| `education.learner.progress.read` | medium | learning progress review | unavailable |
| `education.portfolio.export` | high | learner-controlled export plus confirmation and independent approval | unavailable |

AXIOM policy declares every action but denies it with HTTP `503` and code `capability_unavailable`. The contract therefore cannot become accidentally executable merely because the JSON or client is installed.

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
