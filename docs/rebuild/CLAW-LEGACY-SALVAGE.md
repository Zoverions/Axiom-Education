# Claw Academy legacy concept salvage

Status: design archaeology and migration guidance. This document records useful ideas from deprecated C.L.A.W. Academy / Curious Critter Academy material recovered on 2026-08-22. It is **not** a restoration of that application and does not supersede `CLAW-ACADEMY-V2.md` or the executable Claw contracts.

## Archive update

The full `CLAW_Academy_Materials_Archive..zip` has now been inspected. For reconstructing legacy history it supersedes the earlier pasted blueprint as the strongest source because it contains later application source, schema, seed data, design documents, authoring tools, games, and 58 visual assets.

See `CLAW-LEGACY-ARCHIVE-AUDIT.md` for the detailed inventory and migration hazards. The archive remains historical evidence, not current runtime authority.

## Migration rule

Legacy concepts are classified as **retain**, **reinterpret**, **retire**, or **research**.

The modern boundary is simple:

> curriculum truth, competency targets, evidence requirements, learner rights, accessibility, privacy, and authority come from the shared Axiom Education substrate. Story, characters, games, personalization, rewards, and commercial packaging may change the experience, but must not silently change those truths or rights.

## Retain

### Creative Logic and Adventure Workshop identity

`C.L.A.W.` = **Creative Logic and Adventure Workshop** remains a strong expansion for the flagship experience. It expresses creativity, reasoning, narrative, construction, and play without limiting Claw to one subject or jurisdiction.

### Gameplay is education

The strongest legacy loop should survive in generalized form:

```text
story/comic -> explicit instruction -> guided application -> game/simulation/build -> reflection -> transfer -> later retention
```

A comic or character scene can introduce a problem; instruction can teach the relevant skill; a game can require application; later evidence checks whether learning transferred. A game is not educational merely because it carries C.L.A.W. branding.

### Perspective-taking plus evidence/reasoning

Empathy/perspective-taking and critical-thinking/evidence skills are useful cross-cutting competency families. They can be recurring narrative themes across subjects while remaining mapped to reviewed competencies rather than becoming the exclusive curriculum.

### Character-driven instructional roles

The recovered cast contains useful **roles**: mentor, analyst, empath, protector, jester, curious questioner, learner/leader, synthetic/outsider perspectives, and mature role models. Those roles can become reusable instructional agents in story graphs.

Names, ages, species, likenesses, family relationships, and canonical visual designs remain separate creative decisions and do not create educational authority.

### Family co-play

Local family multiplayer is worth retaining. Claw can support a host screen plus participant devices and give different players different challenge parameters while preserving a shared activity. Fairness must be measured rather than assumed.

### Side Bag

`My Side Bag` remains a useful diegetic learner hub for optional cosmetics, badges, collected artifacts, secrets, accessibility/presentation shortcuts, favourites, and session tools.

The archive clarifies that the Side Bag itself was still largely a **planned Phase 5 shell** (`Design Side Bag UI`, badge system, cosmetics, Tickets/Tokens display, Secrets collection), while the separate points/reward-shop system was more implemented. This is useful: current Claw can preserve the Side Bag identity **without inheriting the old reward economy**.

It should remain learner-controlled and must not become a scarcity store, streak dashboard, advertising surface, behavioural profile, or educational-advantage marketplace.

### Multiple game/art modes

Visual novel, comic, puzzle, platformer, runner, sandbox/build, simulation, and local party-game modes fit as different renderers/adapters over the same governed graph when the mechanic actually supports the learning purpose.

### Authoring tools

The archive adds a major retained idea not visible in the short blueprint: visual story/comic authoring. Its ReactFlow Story Builder, graph validation, templates, import/export, comic planner, panel editor, polygon/hotspot tooling, and content-versioning ideas are strong candidates for future governed Claw authoring tools.

They should target the current Claw contracts rather than revive the archived database/schema.

## Reinterpret

### Five-stage Progressive Learning Slider

Keep the memorable names:

- Sprout
- Scout
- Explorer
- Analyst
- Scholar

But reinterpret them as **reversible presentation-support presets**, not age-derived ability levels.

They may adjust:

- amount and complexity of text;
- default audio support;
- simultaneous variables/clues;
- scaffolding density;
- vocabulary and explicit metacognitive terminology;
- interaction/visual complexity where an equivalent route exists.

They must **not**:

- infer competence from age;
- become permanent learner labels;
- block accessibility features;
- override competency evidence;
- determine grades, mastery, placement, or credentials;
- be available only to paying learners.

A learner, guardian, or educator may request a presentation preset where policy permits. A system suggestion remains contextual and revisable.

### Context Cache

Retain the cost-efficiency insight, but rebuild it as a **minimized personalization context**, preferably local-first and explicitly consented.

Reasonable examples include broad region, preferred fictional themes, selected interests, and learner-chosen story details. Avoid precise location, inferred home/school locations, persistent behavioral profiling, or unnecessary third-party enrichment.

The cache must be scoped per task/provider and must never become a hidden master profile.

### Frustration mitigation

Retain rerouting and alternate representations, but do not infer hidden cognitive state from gaze, facial expression, stylus hesitation, or raw screen time.

Preferred signals are explicit and bounded:

- `still confused`;
- `show me another way`;
- `too hard` / `too easy`;
- task errors where the task itself provides valid evidence;
- explicit hint/human-help requests.

A timeout may offer help, but elapsed time alone is not ability evidence.

### Memory Match

Retain the family-fairness goal and per-player challenge settings. The old shared-pair-removal design can make another player's assigned goal impossible.

A modern version should use one of these patterns:

- player-specific win quotas over a shared set where claimed pairs remain available as landmarks;
- disjoint guaranteed target sets;
- independent private boards synchronized to a common round;
- cooperative team goals with individualized contributions.

Challenge settings should be self-selected or contextually suggested rather than age-locked. Fairness must be evaluated with actual outcome distributions, usability, accessibility and, where relevant, learning outcomes.

### Social-puzzle / “Deviant's Gambit” mechanic

Retain the core mechanic: a teammate creates a problem for an understandable or uncertain reason, and the learner combines evidence gathering with perspective-taking and constructive systems design.

Retire the generic label that defines a person as “the deviant,” and avoid one morally correct dialogue option. Better designs expose multiple plausible motives, incomplete evidence, trade-offs, repair and several constructive solutions.

Possible neutral framing includes **Hidden Motive**, **Team Tangle**, **The Misaligned Plan**, or story-specific titles.

### ARENA as an optional scaffold

The legacy Apprehend / Refine / Extract-Navigate / Advance loop can survive as one reasoning scaffold where appropriate. It must not become a universal correctness engine or override subject-specific evidence and pedagogy.

### Comics and Chronicles

Retain recurring web-comic/story material, but implement it as graph-addressable narrative content so a dilemma can lead into instruction, simulation, discussion, construction, or transfer tasks rather than a separate content silo.

### Archived branching variables

The old engine's node/choice/condition/path mechanics are reusable. Hidden story variables such as `trust`, `courage`, `wisdom`, or positive/negative outcome labels should remain **story state at most**, not learner psychological truth, ability evidence, or moral score.

### School/family/admin workflows

The archived dashboards and account flows are useful UX references, but authorization must be rebuilt through current institution, identity, collaboration, consent and learner-evidence boundaries. Legacy role labels do not grant current access.

## Retire

The following legacy mechanics should not return as designed:

- hard age -> stage -> ability mapping;
- permanent `visual` / `auditory` / `kinesthetic` learner-style profiles;
- generic activity-derived 0–100 empathy, critical-thinking, or skill scores;
- public-by-numeric-user-ID learner/ecosystem profile reads;
- cross-site child worldview/personality/psychological profile federation;
- a free tier locked to only one presentation stage;
- paywalling presentation controls or core accessibility;
- scarce Rewind Tokens required for necessary hints/help;
- learning access conditioned on Game Night Tickets;
- public child learning leaderboards/rank rewards as educational infrastructure;
- reward-shop/points systems that create educational advantage or pressure;
- optimizing education for session length, repeat visits, streaks, notifications or spending;
- child-facing referral incentives;
- hidden behavioral or affective profiling;
- precise-location personalization without a separate necessary consented use case;
- one-answer positive/negative morality scoring;
- automatic child NFT/soulbound credentialing;
- cross-domain reputation boosts derived from a child's learning record;
- subscription-funded cash/gift-card prize pools for child completion;
- historical compliance claims treated as proof of current compliance.

These introduce privacy, fairness, developmental, evidence, consumer-protection, or incentive problems that are unnecessary to achieve the educational goal.

## Credential/reward replacement

The **C.L.A.W. Medallion** is worth retaining as a symbolic graduation artifact, but not as an automatic blockchain asset.

Preferred direction:

- local visual medallion/collectible;
- evidence-linked achievement only when evidence warrants it;
- optional learner-controlled portable export later through an admitted credential format such as Open Badges/CLR;
- no public wallet requirement;
- no unrelated reputation boost;
- no disclosure of learning history without explicit scoped authorization.

Cosmetics/story variations may reflect fictional choices without exposing sensitive learning evidence publicly.

## Commercial boundary

Subscription tiers may fund convenience, richer optional art/media, family features, optional generative variations, or higher-cost model use. They must not make a paid learner entitled to better curriculum truth, necessary accessibility, safety, or a more valid mastery standard.

Provider choices such as Stripe, a particular auth provider, blockchain, or AI vendor are implementation options, not architecture requirements.

Parent/family accounts can manage billing and applicable family controls while learner rights and educational evidence remain independently governed.

## Visual archive conclusion

The full archive changes the earlier visual conclusion.

The separately supplied classroom image showed an orange cat instructor, while one old prose summary described Zov as black. The archive now adds a multi-view Zov character sheet, classroom/portrait/running/sprite art, faculty imagery, application references, and later seed source that repeatedly converge on an **orange tabby Professor Zov in orange/grey futuristic/explorer equipment**.

Therefore orange Zov is the strongest **later legacy-canon candidate**. The black-cat description remains provenance for an earlier iteration, not an equally supported current legacy fork.

Other cast questions remain genuinely unresolved. Examples include early-human versus later-chimp Xavier and a human Callie in art versus one later seed taxonomy calling her chimp. Several archive filenames also point to the wrong visible characters. See the visual manifest and provisional character bible.

## Research queue

Before productionizing salvaged mechanics, test:

1. whether presentation presets improve comprehension/access without becoming ability labels;
2. mixed-skill Memory Match fairness using actual outcome/usability distributions;
3. whether social-puzzle scenarios improve perspective-taking, evidence evaluation, repair and transfer rather than answer-key guessing;
4. local multiplayer privacy, host controls, moderation and offline/LAN behavior;
5. audio-first/icon-first usability with accessibility review;
6. learner agency around hints, alternate representations and human help;
7. whether story/cosmetic rewards motivate without crowding out intrinsic learning goals;
8. whether recovered authoring concepts can produce valid current Claw graphs without importing old schema/authority assumptions;
9. which recovered visual/cast generation should become explicit versioned Claw v2 canon.

## Current implementation mapping

The merged Claw graph/renderer can absorb these ideas without redesigning the education backend:

- comic/story -> `story-panel` / `comic-panel`;
- Hall of Hearts -> story/dialogue + perspective-taking competency nodes;
- Labyrinth of Logic -> game/simulation nodes bound to reasoning/evidence competencies;
- Builder's Workshop / Creation Canyon -> code/build/project-artifact nodes;
- presentation preset -> presentation policy, not competency truth;
- alternate route -> governed graph transition preserving target competency;
- local checkpoint -> evidence candidate only;
- family party game -> future local multiplayer adapter;
- Side Bag -> future learner-owned experience shell;
- Zov guidance -> reviewed scripted guidance or bounded Socratic-tutor task through model routing;
- old Story Builder -> future authoring frontend targeting current Claw graph contracts;
- comic hotspot editor -> future accessible visual-interaction authoring adapter;
- medallion -> future evidence-backed achievement/export adapter.

This preserves the imagination and useful engineering ideas of the older project while keeping the modern architecture evidence-led, privacy-minimizing, learner-controlled, interoperable, and non-extractive.
