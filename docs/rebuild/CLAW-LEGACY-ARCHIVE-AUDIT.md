# C.L.A.W. Academy legacy source archive audit

Status: historical-source audit and migration guidance. This document records what was actually present in the recovered legacy archive. It does **not** make the archived application build-authoritative, production-ready, compliant, or canonical for Claw v2.

## Source provenance

- supplied: 2026-08-22
- uploaded filename: `CLAW_Academy_Materials_Archive..zip`
- archive SHA-256: `53708663c7459592d97f5cb339d5b0ffd3a3ac3157047e3463c0c6cc8e23978e`
- ZIP entries: 529
- non-directory files: 471
- primary root: `CLAW_Academy_Materials_Archive/C.L.A.W_Academy_Project/`

The archive README describes the bundle as source materials, application source, database schema/migrations, documentation, educational resources, and local media assets, while excluding generated/dependency/runtime material such as `node_modules`, `.git`, build output, `.env`, and logs.

For legacy archaeology, this archive now has higher evidentiary weight than the earlier pasted blueprint because it contains the later implemented source tree, seed data, artwork, and design documents. It still does not automatically define current Claw v2 canon or architecture.

## Inventory snapshot

The archive contains a substantial React/TypeScript product, not merely a concept document.

| Surface | Observed archive count / evidence |
| --- | ---: |
| TypeScript React (`.tsx`) files | 220 |
| TypeScript (`.ts`) files | 130 |
| Markdown documents | 22 |
| JSON files | 22 |
| PNG images | 30 |
| WebP images | 20 |
| JPG images | 7 |
| visual image assets | 58 |
| database tables in `drizzle/schema.ts` | 64 |
| application page routes | 52 |
| embedded minigame components | 15 |

Major archived technologies include React 19, Vite, TypeScript, tRPC, Drizzle ORM/MySQL, Radix UI, Tailwind, Stripe, S3-style storage, Resend, Twilio, ReactFlow, Recharts, and model/image-generation integration hooks.

The archive was inspected as historical source. It was **not** treated as a verified reproducible build, and this audit does not claim its archived tests pass.

## High-value source documents

Useful historical design sources include:

- `FRAMEWORK_SPEC.md`
- `CLAW_Academy_Master_Storyline.md`
- `BRANCHING_NARRATIVE_DESIGN.md`
- `MINIGAME_DESIGN.md`
- `NEW_MINIGAMES_GUIDE.md`
- `STORY_BUILDER_DESIGN.md`
- `TESTING_GUIDE.md`
- `docs/CLAW_ECOSYSTEM_INTEGRATION.md`
- `docs/CLAW_QUICK_START.md`
- `docs/REQUIREMENTS_FOR_OTHER_SITES.md`
- `todo.md`

`todo.md` is especially broad, but its checked/unchecked items are historical planning assertions rather than verification evidence. It should be mined for ideas and provenance, not interpreted as current readiness.

## Product surfaces found in the archive

The archived application includes learner, parent, teacher, administrator, content-authoring, comic, story, game, leaderboard, subscription, account, and ecosystem-integration surfaces.

Representative routes include:

- learner home/explore/resources/onboarding/account;
- student dashboard/settings/storylines/comics/gallery/showcase;
- parent dashboard/settings/portal;
- teacher dashboard/classrooms/templates/submissions/analytics;
- admin content builder, comic builder, storyline manager, badge manager, story builder/library, comic planner, users/activity/settings;
- Cosmic Sprint and Missile Command game routes;
- leaderboards and reward-related surfaces.

These are useful UX and workflow references. Their old authorization, storage, telemetry, scoring, and commercial semantics are **not** inherited by current Axiom Education.

## Embedded minigames found

The archive includes at least these embedded minigame components:

- Branching Narrative
- Character Memory Match
- Choice Consequences
- Coloring Game
- Detail Detective
- Emotion Detective
- Hidden Objects
- Jigsaw Puzzle
- Memory Match
- Sequence Puzzle
- Sliding Puzzle
- Spot the Difference
- Story Recall Quiz
- Story Sequencer
- Word Detective

It also contains larger game shells such as Cosmic Sprint and an enhanced Missile Command implementation.

The presence of a game does not prove educational validity. A game should enter current Claw only when its mechanic has an explicit competency purpose, accessibility/fallback path, and evidence boundary.

## Strong legacy engineering ideas worth salvaging

### 1. Branching narrative engine

The archived narrative system represents nodes, choices, conditions, variables, endings, path history, and branching state. This maps naturally onto the current Claw experience graph.

What to preserve:

- graph-addressable narrative content;
- explicit transitions and conditions;
- learner-visible consequences;
- path history for local story continuity;
- multiple endings where pedagogically useful.

What not to inherit:

- hidden `trust`, `courage`, `wisdom`, or similar story variables as psychological/ability truth;
- `positive`/`negative` choice labels as a universal morality score;
- branching state becoming mastery without separate evidence.

### 2. Visual Story Builder

The archived ReactFlow authoring tooling includes node/edge editing, reachability validation, variables, templates, import/export, and story-library concepts.

This is a strong candidate for a future **governed Claw authoring surface**. Current implementation should target the Claw graph/contract rather than reviving the old database model.

### 3. Comic authoring and interaction tooling

The archive contains comic planning, page editing, panel-boundary editing, polygon/hotspot editing, prompt-generation concepts, and interactive comic viewers.

This supports the current `comic-panel` / story-node architecture and suggests a future pipeline:

```text
reviewed competency + story intent
  -> authoring graph
  -> comic page/panel plan
  -> accessible visual/text alternatives
  -> hotspot/action bindings
  -> governed Claw transitions
```

### 4. Content community/versioning ideas

Historical planning contains useful distinctions between official, community, and featured material; version history; review before official replacement; licensing/attribution; and additive seasons/content packs.

These should be rebuilt through current resource admission, curriculum assurance, evidence, and collaboration contracts rather than inherited from the old application.

### 5. Family, classroom, and administrator workflow patterns

The old UI contains potentially useful workflow and information-architecture ideas for families, schools, teachers, and administrators. Reuse should be visual/workflow-level only unless current authority grants, privacy boundaries, and learner evidence semantics explicitly support the behavior.

## Visual and character evidence

The archive materially strengthens the historical evidence for Professor Zov and the later cast, while also exposing more contradictions.

### Professor Zov

Multiple later archive sources agree on an **orange tabby cat** with orange/grey futuristic or explorer-style equipment:

- `zov-character-sheet.webp`
- `zov-classroom.webp`
- `zov-classroom-optimized.webp`
- `zov-portrait.png` / `zov-portrait.webp`
- `zov-running.png`
- `zov-side-sprite.png`
- `faculty-group.webp`
- later storyline seed data explicitly describing Professor Zov as an orange tabby.

This makes the orange-tabby design the strongest **later legacy-canon candidate**. The earlier text describing a black cat remains part of provenance but has weaker support in the recovered implementation.

This still does not automatically lock orange Zov as current Claw v2 canon; current canon requires an explicit creative decision.

### Cast evolution

The archive documents a later roster that differs from the early blueprint. It includes or references:

- students: Xavier, Marnell, David, Luca, James, Callie, Xylar, Byte, Leo, Maya, Noah, DJ, Christian, Kam and supporting students;
- faculty/staff: Professor Zov, Principal Minerva, Professor Nimbus, Professor Terra, Coach Rumble, Chef Anya, Janitor Bob, Counselor Kiko;
- antagonistic/story roles: Vector/Jack, Gloom, Zed, Blaze;
- additional/advanced characters including Sylus and Trinity.

Contradictions remain. Examples:

- early Xavier is human; later ensemble art/source presents Xavier as a chimp/monkey learner;
- Callie is human in early text and archive artwork, while one later seed script categorizes her as a chimp;
- several image filenames do not match the character names visible in the image itself;
- generated concept sheets contain duplicated or malformed labels.

Therefore filenames and one-off generated labels must not become semantic character IDs.

## Security, privacy, and evidence boundaries that must **not** be ported

### Public ecosystem profile access

The old ecosystem router exposes profile/progress/achievement-style reads through public procedures keyed by numeric user ID. Historical responses can include identity/profile material and derived learning-like metrics.

**Migration rule:** retire this access model. Current learner information must remain subject-, purpose-, grant-, and policy-bound through Axiom/Mesh boundaries.

### Permanent “learning style” storage

The old schema stores categories such as `visual`, `auditory`, `kinesthetic`, and `mixed` on student profiles.

**Migration rule:** do not carry this forward as a permanent learner label. Current Claw presentation preferences are reversible contextual support choices, not a theory of learner identity.

### Synthetic psychological/learning scores

The archive contains fields or calculations resembling:

- generic 0–100 skill levels;
- empathy scores;
- critical-thinking levels;
- game/quest empathy scores.

Some ecosystem logic derives such values from activity counts such as posts, comics, story progress, or badges rather than validated learning evidence.

**Migration rule:** these are not acceptable mastery, empathy, character, or cognitive measures. Current learner evidence stays competency-specific, contextual, provenance-bound, revisable, and non-authoritative until admitted through the appropriate governed path.

### Cross-site psychological profiling

Historical shared ecosystem types include broad worldview, political, moral-foundations, attachment, personality, and emotional-intelligence style profiles.

**Migration rule:** do not inherit these as child/learner records or federation payloads.

### Leaderboards and reward economies

The archive contains public/classroom/school/inter-school leaderboard concepts, rank rewards, points balances, purchases, and reward-shop items.

**Migration rule:** ranking and reward mechanics cannot be learning authority and should not become public child-comparison infrastructure by default. Necessary help, accessibility, curriculum, or instructional quality must never depend on points or purchases.

### Engagement optimization

Legacy framework material includes engagement-oriented targets such as daily activity, session duration, completion and return rates.

**Migration rule:** these cannot become Claw's educational optimization objective. Current effectiveness metrics prioritize learning gain, retention, transfer, misconception recovery, accessibility, agency, safety, human support, reliability, and appropriate efficiency.

### Time/attempt counts

Several games record time, errors, attempts, or survival duration.

**Migration rule:** these may be local game-state or optional usability signals, but they are not learner ability or mastery by default.

### Emotion recognition

`EmotionDetective` presents facial-expression/emotion matching mechanics.

**Migration rule:** any modern perspective/emotion activity must teach uncertainty, context, cultural variation, and the difference between observable cues and another person's private mental state. It must not pretend to read emotions with certainty from a face.

## Source/schema drift discovered

The archive is not internally consistent enough to serve as a direct production source of truth.

Examples identified during inspection include:

- family-linking source referring to a `studentProfiles.parentId` relationship that does not match the inspected archived student-profile schema;
- student source attempting to update `studentProfiles.avatarUrl` even though the inspected schema places avatar data elsewhere;
- `FRAMEWORK_SPEC.md` describing fields that no longer match the later archived schema;
- a classroom leaderboard-settings path containing a TODO that handles only the first classroom;
- comic-progress logic that appears to query page completion through an incomplete/first-page path.

These do not mean every old feature is unusable as inspiration. They do mean **no archived runtime should be copied into Claw v2 merely because it already exists.**

## Research/content quality notes

Five archived blog/resource articles appear in both source and public-copy locations and contain broad research claims without embedded source URLs/citations.

**Migration rule:** do not import them as evidence-backed educational guidance until their claims are independently sourced and reviewed.

Similarly, historical compliance language mentioning COPPA, FERPA, GDPR, or similar regimes is a claim in old project material, not sufficient compliance evidence. Current documentation must not repeat those claims without a real legal/technical compliance review.

## Migration classification

### Salvage as concepts / patterns

- story graph authoring;
- comic planning/panel/hotspot tooling;
- game mechanics with valid competency mapping;
- local family co-play;
- diegetic academy navigation;
- character/environment artwork as provenance-controlled creative reference;
- content versioning/community review concepts;
- family/school/admin workflow patterns after authority redesign.

### Rebuild through current contracts

- learner evidence;
- personalization;
- accounts/relationships;
- school/teacher access;
- collaboration/social features;
- resource admission;
- curriculum mapping;
- model routing;
- achievements/credentials;
- multiplayer identity/session permissions;
- generated media.

### Explicitly do not port

- public-by-ID learner/ecosystem profiles;
- permanent learning-style labels;
- activity-derived empathy/critical-thinking scores;
- cross-site child psychological profiles;
- public child learning leaderboards;
- pay/scarcity gates on help or curriculum;
- engagement as the educational objective;
- one-answer morality scores;
- automatic NFT/social-reputation propagation from child learning records.

## Current migration rule

The archive is a **design and provenance mine**, not an import target.

A legacy feature moves into Claw v2 only when:

1. its educational or learner-experience purpose is explicit;
2. it maps to current competency/evidence semantics where applicable;
3. privacy, authority, accessibility and fallback behavior are defined;
4. its implementation can be separated from obsolete archived assumptions;
5. it is validated on the current repository and cross-platform gates;
6. historical art/content is versioned and reviewed rather than silently treated as canon.

This preserves the years of useful C.L.A.W. thinking in the archive without inheriting the parts that the newer Axiom Education architecture was specifically designed to improve.
