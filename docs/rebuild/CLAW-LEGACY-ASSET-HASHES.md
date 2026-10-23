# C.L.A.W. legacy asset hash registry

Status: exact byte-level provenance for selected visual assets inside recovered archive `CLAW_Academy_Materials_Archive..zip`.

Archive SHA-256: `53708663c7459592d97f5cb339d5b0ffd3a3ac3157047e3463c0c6cc8e23978e`

Archive character path prefix:

`CLAW_Academy_Materials_Archive/C.L.A.W_Academy_Project/client/public/characters/`

These hashes identify recovered bytes. They do **not** make the corresponding design or filename current Claw v2 canon.

| Archived filename | SHA-256 | Provenance note |
| --- | --- | --- |
| `zov-character-sheet.webp` | `5402550059db1e54cfe23fdd242224c5b8ab7b2d9cc296810a29e28c37bec204` | Orange-tabby multi-view Zov sheet |
| `zov-classroom.webp` | `d75fb8348a06b68093cdba33e9b188327ccc35d28422f39e9fd745ff612424c7` | Orange Zov classroom scene |
| `zov-classroom-optimized.webp` | `d75fb8348a06b68093cdba33e9b188327ccc35d28422f39e9fd745ff612424c7` | Exact byte duplicate of `zov-classroom.webp` |
| `zov-portrait.webp` | `1a3b761e1168f3a458343682632b941ffa8b08dba5250ab4ce36b465e6d037f3` | Orange-tabby portrait |
| `faculty-group.webp` | `b597893671a916852383fc1f914b7820e2f1159dd53e5d8804d9542431bdd4d9` | Faculty group centered on orange Zov |
| `character-sylus.webp` | `29150b5944342cceb9bce83079f670447f25a662483d7685217a5b5e24f4e5ee` | Misleading filename; main student/faculty ensemble sheet |
| `character-extra1.webp` | `f7c999746e684a2a5e34dae260bd20f069f1ef3927fb4a29fae2ac00935bbca1` | Supporting student/staff concept sheet; generated-label errors present |
| `character-extra2.webp` | `a78cf7edfc136601e8b492055f0709b9d86030c0f2b9463691f553da2bc8a600` | DJ / Christian / Kam concept sheet |
| `character-callie.webp` | `c7a191aff34025d96800882175528691ebc2a55c1a8ce96a1018de520309edbb` | Misleading filename; visible labels identify Leo / Maya / Noah |
| `character-david.webp` | `91a16427819d9fca42428da9561a4a12d5502be6337ebb669132bf6ca5042a3e` | Misleading filename; visible labels identify Zed / Blaze |
| `character-jax.webp` | `2d5cb362dcd79bfd591cf95cc0a148c2bf724d18e7fd731318f3d5a8ce773dd6` | Misleading filename; visible label identifies Xylar |
| `character-marnell.webp` | `67d1aa28157f8c037c17b4e2a24fd3fe7f28eaf654fff29ddf0db46a8a567555` | Misleading filename; visible label identifies Byte |
| `character-luca.webp` | `90e2dd9966fc156dfaa490fa2f440f09d961164fb0e649a30fe706549ff68a85` | Misleading filename; visible labels identify Sylus / Trinity; generated-label noise present |
| `character-trinity.webp` | `b7e767aca6b12e3163a0ae7cafa124eb53153c0063f0a4f839a6517ac9794eb2` | Misleading filename; visible labels identify Vector (Jack) / Gloom |
| `the-force-squad.webp` | `61cb68532aabb61f13bafce2cf960c5f204d9594edc0e0ad548e3a190afe779c` | DJ / Christian / Kam-like trio with generated interface text |

## Rules

- Never infer character identity from the archived filename alone.
- When a derivative is cropped, converted, upscaled, recoloured, edited, or regenerated, give the derivative a new hash/reference rather than replacing this record.
- Exact duplicate bytes may share one content identity even when multiple historical filenames exist.
- Visible generated labels are evidence of what a concept sheet depicts, but malformed/duplicated labels are not automatically canonical names.
- Current canon should cite approved asset IDs plus explicit approval provenance, not only historical hashes.
