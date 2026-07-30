# Axiom Education deprecations

**Effective:** 2026-07-30  
**Canonical product name:** Axiom Education  
**Canonical branch:** `main`

This document records interfaces, names, branches, and implementation paths that remain in the repository only for traceability or temporary compatibility. Deprecated material must not be used to establish current capability, security, privacy, architecture, or release claims.

## Repository and product naming

| Deprecated surface | Replacement | Disposition |
|---|---|---|
| GitHub repository slug `OntarioEdAI` | `Axiom-Education` | Rename the repository. The old GitHub URL should exist only as GitHub's redirect. |
| Product name `OntarioEdAI` | Axiom Education | Remove from current product and operator documentation. Historical records may retain it when clearly labelled. |
| Default branch `feature/init-ontarioedai-v0.3-11996005026797377764` | `main` | Change the GitHub default branch to `main`; do not base new work on the feature branch. |
| Rebuild branch `rebuild/axiom-education-v0.5` | `main` | Merged and closed. Preserve only as Git history. |
| Internal Dart package name `ontarioedai` | `axiom_education` | Temporary compatibility shim. Migrate imports and generated platform metadata in a dedicated, test-gated change before `0.6.0`. |

Ontario remains a supported jurisdictional curriculum pack. It is not the identity or architectural boundary of the application.

## Deprecated implementation paths

| Deprecated surface | Current status | Replacement |
|---|---|---|
| Application-owned UDP/TCP classroom mesh | Disabled | AXIOM admitted nodes and signed causal synchronization |
| Hive `student_data` learner store | Not approved for governed learner data | AXIOM encrypted, owner-separated, purpose-bound learner records |
| Mock or simulated tutor output | Removed | Explicit `capability_unavailable` until an approved provider exists |
| Mock equations from canvas observation | Removed | Bounded classifier output plus a separately approved parser and deterministic verifier |
| Fixed fallback handwriting scores | Removed | Explicit model unavailability until a validated scoring artifact exists |
| Legacy `irt_*` labels as psychometric claims | Disabled | Visibly uncalibrated adaptation heuristics until validated calibration evidence exists |
| Chroma or other retrieval indexes as curriculum authority | Prohibited | Canonical signed curriculum records; indexes remain disposable derivatives |
| Automatic peer discovery as authorization | Prohibited | Identity, policy, consent, scoped grants, and independent approval where required |

## Deprecated documents

- `docs/archive/ONTARIOEDAI-MASTER-ARCHITECTURE.md` is historical design material, not current architecture.
- `docs/archive/CURRICULUM-SOURCES-LEGACY.md` is historical augmentation strategy, not current provenance evidence.
- `ARCHITECTURE.md` is retained as a deprecation pointer to the canonical rebuild documentation.

## Enforcement

A deprecated surface must not be represented as implemented or production-ready. New code must not depend on it unless the capability registry explicitly identifies a bounded compatibility path and the protected workflow exercises its negative behavior.
