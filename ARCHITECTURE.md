# Axiom Education Architecture

The historical OntarioEdAI master-architecture document is deprecated and preserved at [`docs/archive/ONTARIOEDAI-MASTER-ARCHITECTURE.md`](docs/archive/ONTARIOEDAI-MASTER-ARCHITECTURE.md) for traceability only.

It is **not** current claim authority. In particular, it must not be used to claim that local language models, deterministic verifiers, continuous canvas monitoring, encrypted learner storage, decentralized identity, peer-to-peer authorization, compliance, or classroom federation are production capabilities.

Current architecture is defined by:

1. [`docs/rebuild/PRODUCT-DEFINITION.md`](docs/rebuild/PRODUCT-DEFINITION.md)
2. [`docs/rebuild/REQUIREMENTS.md`](docs/rebuild/REQUIREMENTS.md)
3. [`contracts/axiom-education.v1.json`](contracts/axiom-education.v1.json)
4. [`config/capabilities.json`](config/capabilities.json)
5. executable code, protected tests, and merge evidence

## Product scope

Axiom Education is the general education-domain platform. It is not architecturally limited to Ontario, high school, MTH1W, or the current Flutter presentation shell.

Jurisdictions, grade bands, courses, institutions, age-specific experiences, and external learning providers are replaceable or composable domain surfaces over a portable governed learner/evidence substrate. Ontario is the first jurisdiction family; Ontario elementary and secondary are parallel curriculum tracks. MTH1W is the first deep secondary vertical slice, not the product boundary.

## Current boundary

```text
Axiom Education UI / experience layer
  -> AXIOM Gateway
  -> policy, consent, risk, and planning
  -> short-lived capability grant
  -> approved provider, curriculum, or education capsule
  -> bounded execution
  -> encrypted learner state and evidence in Grid
```

The application is independently releasable and remains outside the AXIOM trusted kernel. Installation never grants authority. Missing providers, consent, policy, verification, or artifacts fail closed.
