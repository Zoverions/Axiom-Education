# Claw Academy legacy concept salvage

Status: design archaeology and migration guidance. This document records useful ideas from deprecated C.L.A.W. Academy / Curious Critter Academy blueprints supplied on 2026-08-22. It is **not** a restoration of those blueprints and does not supersede `CLAW-ACADEMY-V2.md` or the executable Claw contracts.

## Migration rule

Legacy concepts are classified as **retain**, **reinterpret**, **retire**, or **research**.

The modern boundary is simple:

> curriculum truth, competency targets, evidence requirements, learner rights, accessibility, privacy, and authority come from the shared Axiom Education substrate. Story, characters, games, personalization, rewards, and commercial packaging may change the experience, but must not silently change those truths or rights.

## Retain

### Creative Logic and Adventure Workshop identity

`C.L.A.W.` = **Creative Logic and Adventure Workshop** remains a strong expansion for the flagship experience. It expresses the intended combination of creativity, reasoning, narrative, construction, and play without limiting Claw to one subject or jurisdiction.

### Gameplay is education

The strongest legacy loop should survive in generalized form:

```text
story/comic -> explicit instruction -> guided application -> game/simulation/build -> reflection -> transfer -> later retention
```

A comic or character scene can introduce a problem; instruction can teach the relevant skill; a game can require application; later evidence checks whether learning transferred. The game is not educational merely because it is branded as such.

### Perspective-taking plus evidence/reasoning

Empathy/perspective-taking and critical-thinking/evidence skills are useful cross-cutting competency families for Claw. They can be recurring narrative themes across subjects while remaining mapped to reviewed competencies rather than becoming the exclusive curriculum.

### Character-driven instructional roles

The old cast contains useful **roles**: mentor, analyst, empath, protector, jester, curious questioner, learner/leader, and mature role model. Those roles can become reusable instructional agents in story graphs.

Names, ages, species, likenesses, family relationships, and canonical visual designs remain separate creative decisions and should not be treated as educational authority.

### Family co-play

Local family multiplayer is worth retaining. Claw can support a host screen plus participant devices and give different players different challenge parameters while preserving a shared activity. Fairness should be measured rather than assumed.

### Side Bag

`My Side Bag` remains a useful diegetic learner hub for optional cosmetics, badges, collected artifacts, secrets, and session tools. It should remain learner-controlled and should not become a dark-pattern dashboard for streaks, spending, or engagement pressure.

### Multiple game/art modes

Visual novel, comic, puzzle, platformer, runner, sandbox/build, simulation, and local party-game modes fit naturally as different renderers/adapters over the same governed graph.

## Reinterpret

### Five-stage Progressive Learning Slider

Keep the memorable names if useful:

- Sprout
- Scout
- Explorer
- Analyst
- Scholar

But reinterpret them as **reversible presentation-complexity presets**, not age-derived ability levels.

They may adjust factors such as:

- amount and complexity of text;
- default audio support;
- number of simultaneous variables;
- scaffolding density;
- vocabulary and explicit metacognitive terminology;
- interaction complexity.

They must **not**:

- infer competence from age;
- become permanent learner labels;
- block accessibility features;
- override demonstrated competency evidence;
- determine grades, mastery, placement, or credentials;
- be available only to paying learners.

A learner, guardian, or educator may request a presentation preset where policy permits. The system may suggest a contextual change, but the choice remains revisable.

### Context Cache

Retain the cost-efficiency insight, but rebuild it as a **minimized personalization context**, preferably local-first and explicitly consented.

Safe examples include broad region, preferred fictional themes, selected interests, and learner-chosen story details. Avoid precise location, inferred home/school locations, persistent behavioral profiling, or unnecessary third-party enrichment.

The cache must be scoped per task/provider and should never become a hidden master profile.

### Frustration mitigation

Retain rerouting and alternate representations, but do not infer hidden cognitive state from gaze, facial expression, stylus hesitation, or raw screen time.

Preferred signals are explicit and bounded:

- "still confused";
- "show me another way";
- "too hard" / "too easy";
- repeated task errors where the task itself provides valid evidence;
- explicit request for a hint or human help.

A timeout may offer help, but elapsed time alone is not ability evidence.

### Memory Match

Retain the family-fairness goal and per-player challenge settings. The old design needs an algorithmic correction: removing a shared pair that another player requires can make another player's goal impossible.

A modern version should use one of these patterns:

- player-specific win quotas over a shared set, where claimed pairs remain available as public landmarks;
- disjoint guaranteed target sets;
- independent private boards synchronized to a common round;
- cooperative team goals with individualized contributions.

Challenge settings should be self-selected or contextually suggested rather than age-locked. The system should evaluate actual win balance, enjoyment, accessibility, and learning outcomes across mixed-ability families.

### Social-puzzle / "Deviant's Gambit" mechanic

Retain the core mechanic: a teammate creates a problem for an understandable reason, and the learner must combine evidence gathering with perspective-taking and constructive systems design.

Rework the framing so a person is not labeled a "deviant" and there is not always one morally correct dialogue option. Better designs can expose multiple plausible motives, uncertain evidence, trade-offs, repair, and more than one constructive solution.

Possible modern labels include **Hidden Motive**, **Team Tangle**, **The Misaligned Plan**, or a story-specific title.

### ARENA as an optional scaffold

The legacy Apprehend / Refine / Extract-Navigate / Advance loop can survive as one story or reasoning scaffold when it is educationally appropriate. It must not become the universal correctness engine or override subject-specific evidence and pedagogy.

### Comics and Chronicles

Retain recurring web-comic/story material, but implement it as graph-addressable narrative content so the same dilemma can lead into instruction, simulation, discussion, construction, or transfer tasks rather than a separate content silo.

## Retire

The following legacy mechanics should not return as designed:

- hard age -> stage -> ability mapping;
- a free tier locked to only one cognitive/presentation stage;
- paywalling the five-stage presentation controls or core accessibility;
- scarce Rewind Tokens required to obtain necessary hints or escape frustration;
- learning access conditioned on earning consumable Game Night Tickets;
- optimizing for session length, repeat visits, streaks, notification opens, or spending;
- child-facing referral incentives;
- hidden behavioral or affective profiling;
- precise-location personalization without a separate, necessary, consented use case;
- a child achievement automatically minting an NFT or soulbound token;
- cross-domain reputation boosts derived from a child's learning record;
- a subscription-funded cash/gift-card prize pool for child graduation;
- any game winner receiving educational authority, mastery status, or financially meaningful advantage merely for winning.

These concepts introduce privacy, fairness, developmental, consumer-protection, or incentive problems that are unnecessary to achieve the educational goal.

## Credential/reward replacement

The **C.L.A.W. Medallion** is worth retaining as a symbolic graduation artifact, but not as an automatic blockchain asset.

Preferred direction:

- local visual medallion / collectible;
- evidence-linked achievement only when the underlying evidence warrants it;
- optional learner-controlled portable export later through Open Badges / CLR or another admitted credential format;
- no public wallet requirement;
- no unrelated reputation score boost;
- no disclosure of a child's learning history to another service without explicit scoped authorization.

Cosmetics and story variations may reflect choices, but should not expose sensitive learner evidence publicly.

## Commercial boundary

Subscription tiers may fund convenience, richer art/media, family features, optional generative story variations, or higher-cost model use. They must not make the paid learner educationally entitled to better curriculum truth, necessary accessibility, safety, or a more valid mastery standard.

Provider choices such as Clerk/Auth.js, Stripe, a particular blockchain, or a particular AI vendor are implementation options, not architecture requirements.

Parent accounts can manage billing and applicable family controls, while learner rights and educational evidence remain governed independently.

## Visual reference supplied with this salvage

The 2026-08-22 reference image depicts:

- a bright futuristic classroom;
- an anthropomorphic orange cat instructor in explorer/technical gear;
- a large dark-teal world/space learning display labeled `C.L.A.W. ACADEMY`;
- two seated animal-like learners using consoles;
- a clean optimistic science-adventure tone.

Treat this as **legacy visual direction, not canonical character specification yet**. The pasted legacy text itself conflicts on Professor Zov's appearance (for example, orange-cat imagery versus a black-cat description). Additional recovered images should be compared before locking the character bible.

## Research queue

Before productionizing the salvaged mechanics, test:

1. whether presentation presets improve comprehension/access without becoming ability labels;
2. mixed-age/mixed-skill Memory Match fairness using actual win-rate and enjoyment distributions;
3. whether social-puzzle scenarios improve perspective-taking, evidence evaluation, repair, and transfer rather than reward answer-key guessing;
4. local multiplayer privacy, host controls, moderation, and offline/LAN behavior;
5. audio-first and icon-first usability with accessibility review;
6. learner agency around hints, alternate representations, and human help;
7. whether story/cosmetic rewards motivate without crowding out intrinsic learning goals;
8. character and visual-system consistency once the remaining legacy art is recovered.

## Current implementation mapping

The already-merged Claw v2 graph/renderer can absorb these ideas without redesigning the education backend:

- comic/story -> `story-panel` / `comic-panel`;
- Hall of Hearts -> story/dialogue + perspective-taking competency nodes;
- Labyrinth of Logic -> game/simulation nodes bound to reasoning/evidence competencies;
- Builder's Workshop / Creation Canyon -> code/build/project-artifact nodes;
- presentation preset -> presentation-layer policy, not competency truth;
- alternate route -> governed graph transition preserving the target competency;
- local checkpoint -> evidence candidate only;
- family party game -> future local multiplayer adapter;
- Side Bag -> future learner-owned experience shell;
- Zov guidance -> reviewed scripted guidance or bounded Socratic-tutor task through model routing;
- medallion -> future evidence-backed achievement/export adapter.

This preserves the imagination of the older project while keeping the modern architecture evidence-led, privacy-minimizing, learner-controlled, interoperable, and non-extractive.
