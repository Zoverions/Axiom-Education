# C.L.A.W. legacy archive — reading guide and status

> **ARCHIVE ONLY — SUPERSEDED — NOT BUILD-AUTHORITATIVE.**
>
> Everything under this legacy lane documents *deprecated* C.L.A.W. Academy /
> Curious Critter Academy material recovered on 2026-08-22. It is preserved for
> design archaeology only. Nothing here is current product canon, current
> runtime authority, or a production claim, and nothing here activates a
> capability by itself.

## What is archived (and what is not)

- **Archived here:** migration archaeology — the full audit, asset hashes,
  visual provenance, authoring crosswalk, feature migration matrix, concept
  salvage ledger, and character/visual comparison scaffolds derived from the
  recovered legacy source archive.
- **Not archived here:** the legacy application itself. The recovered legacy
  React/TypeScript application, its database schema/migrations, and its media
  assets are **not vendored into this repository**. The source of record for
  the archive is the external bundle supplied 2026-08-22:
  `CLAW_Academy_Materials_Archive..zip`
  (SHA-256: `53708663c7459592d97f5cb339d5b0ffd3a3ac3157047e3463c0c6cc8e23978e`,
  529 ZIP entries / 471 files, 220 `.tsx` + 130 `.ts` files, 64 database
  tables, 52 page routes, 15 embedded minigame components, 58 visual image
  assets). The zip is not committed; it is recorded by provenance reference
  only, and that is deliberate — the old application does not build as part of
  Axiom Education and must not be reanimated by accident.

## Index of legacy artifacts

All legacy archaeology files live alongside this guide in `docs/rebuild/`.

| Document | Role | Status |
| --- | --- | --- |
| `CLAW-LEGACY-ARCHIVE-AUDIT.md` | Full archive inventory: systems found, source drift, privacy/evidence hazards, migration rules | **Historical-source audit; not production authority** |
| `CLAW-LEGACY-ARCHIVE-README.md` | This reading guide | **Status record** |
| `CLAW-LEGACY-ASSET-HASHES.md` | Byte-level provenance registry for selected legacy visual assets | **Historical evidence** |
| `CLAW-LEGACY-AUTHORING-CROSSWALK.md` | Legacy Story Builder / branching narrative / comic authoring ideas mapped onto the current Claw experience graph | **Design migration note; does not port the old runtime or database model** |
| `CLAW-LEGACY-FEATURE-MATRIX.md` | Retain / reinterpret / retire / research classification of legacy concepts | **Implementation-planning companion; activates nothing** |
| `CLAW-LEGACY-SALVAGE.md` | Retain / reinterpret / retire / research ledger of durable legacy concepts | **Design archaeology; does not supersede `CLAW-ACADEMY-V2.md` or executable Claw contracts** |
| `CLAW-LEGACY-VISUAL-MANIFEST.md` | Visual provenance registry for legacy character/environment art | **Historical evidence; not product canon** |
| `CLAW-PSYCHOLOGICAL-INSIGHT-GOVERNANCE.md` | Clarifies that psychology-informed personalization is governed, not prohibited | **Superseding clarification for the legacy lane only** |
| `CLAW-VISUAL-CHARACTER-BIBLE-DRAFT.md` | Provisional visual/character comparison scaffold combining early blueprint and recovered archive | **Draft; current Claw v2 character canon not yet locked** |

## What is authoritative instead

- **Flagship experience architecture:** `docs/rebuild/CLAW-ACADEMY-V2.md`
- **Executable contracts:** `contracts/` (canonical Axiom Education contract digest is CI-verified; see the "Axiom Education CI" workflow)
- **Current implementation:** `lib/features/claw/`, `lib/core/models/claw_*`, `test/features/claw/`, `test/core/models/claw_*`

Where a legacy document conflicts with any of the above, the above wins.

## Boundary rules

1. This lane is **read-only by design**: the recovered legacy application must
   not be restored, rebuilt, or vendored into the repo.
2. Legacy concepts move forward only through the retain / reinterpret / retire /
   research classifications in `CLAW-LEGACY-SALVAGE.md` and
   `CLAW-LEGACY-FEATURE-MATRIX.md`, and only as documented, reviewed work —
   never by silent inheritance.
3. This PR is **draft** and exists for review of the archaeology artifacts. It
   does not activate capabilities, change production status, or alter deployed
   behavior. Do not mark ready for review without an explicit review decision.
