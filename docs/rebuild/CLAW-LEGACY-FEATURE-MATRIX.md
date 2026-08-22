# Claw Academy legacy feature migration matrix

Status: implementation-planning companion to `CLAW-LEGACY-SALVAGE.md`. Nothing in this matrix activates a capability by itself.

Legend:

- **retain** — concept can survive substantially as intended;
- **reinterpret** — preserve the useful goal but change mechanics/authority/privacy assumptions;
- **retire** — do not rebuild the legacy mechanism as designed;
- **research** — promising enough to test before committing to production.

| Legacy concept | Status | Modern Claw interpretation | Current substrate | Next executable step |
| --- | --- | --- | --- | --- |
| `C.L.A.W.` = Creative Logic and Adventure Workshop | retain | Flagship experience identity across subjects and learning modes | Claw graph + renderer | Brand/canon decision later; no runtime dependency needed |
| Empathy / perspective-taking primer | retain | Cross-cutting competency family, not entire curriculum | competency graph + instructional effectiveness | Add reviewed perspective-taking competency examples |
| Critical thinking / skepticism primer | retain | Evidence evaluation, causality, uncertainty, source reasoning | competency graph + instructional effectiveness | Add evidence/reasoning story arc after source mapping |
| ARENA protocol | reinterpret | Optional reasoning scaffold for suitable scenarios | strategy IDs + graph nodes | Represent as one scaffold strategy, never universal validator |
| Sprout / Scout / Explorer / Analyst / Scholar | reinterpret | Reversible presentation-support presets | presentation model + accessibility/readiness boundaries | Define preset model independent of age and mastery |
| Age ranges attached to stages | retire | Age may be context where legitimately needed, never ability truth | zero-assumption entry assessment | No implementation |
| Audio-first Sprout interface | research | Strong low-reading-demand presentation option available to anyone who needs/wants it | accessibility requirements + renderer fallbacks | Prototype audio/icon panel with equivalent text path |
| Paid-only five-stage slider | retire | Presentation/accessibility controls are not premium pedagogy | commercial boundary | No implementation |
| Context Cache | reinterpret | Minimized, consented, preferably local personalization capsule | model-context grants + local-first policy | Define typed personalization capsule with expiry/scopes |
| Precise locality enrichment | retire by default | Broad region only when useful and authorized | model/resource privacy filters | Separate future use-case review if ever needed |
| Academy Explorers cast | research | Preserve strong roles; exact names/ages/species remain creative candidates | story presentation layer | Compare recovered visual/text evidence before canon lock |
| Professor Zov mentor | retain/research | Socratic mentor who can model uncertainty and revision | scripted guidance + future model-routed tutor | Canonize appearance later; keep role usable now |
| Xavier as compulsory player avatar | reinterpret | Optional story character; learner may use own fictional avatar or low-story route | optional story identity | Do not bind learning path to Xavier identity |
| Callie analyst role | retain | Evidence/uncertainty specialist who is not automatically correct | story agents | Use in future evidence scenario after canon review |
| Marnell protector role | retain | Action/system-protection perspective with reflective arc | story agents | Avoid reducing role to impulsivity stereotype |
| David jester role | reinterpret | Playful chaos/boundary-testing role, not designated recurring wrongdoer | story agents | Rotate conflict sources across ensemble |
| Luca empath role | reinterpret | Perspective specialist who can also reason/evaluate evidence | story agents | Avoid one-note moral-conscience role |
| James curiosity role | retain | Foundational-question role that can challenge assumptions | story agents | Useful in Socratic/why-question scenes |
| Sylus / Trinity advanced role models | research | Optional older/advanced narrative roles | story layer | Decide only if they add learning/story value |
| Sunstone Challenge / three-act arc | research | Candidate long-form narrative shell over many competency graphs | story graph | Recover full old arc before adaptation |
| C.L.A.W. Chronicles comics | retain | Graph-addressable narrative panels that lead into instruction/application | comic/story panel types | Add one comic-to-task prototype later |
| Hall of Hearts | retain/reinterpret | Dialogue/perspective environment with uncertainty and multiple constructive responses | story/dialogue nodes | Prototype after perspective competency mapping |
| Labyrinth of Logic | retain | Logic/evidence game-space renderer | game/simulation nodes | Candidate first reasoning-game adapter |
| Builder's Workshop / Creation Canyon | retain | Construction, coding, modelling, systems problem-solving | build/project artifact nodes | Candidate first build adapter |
| Velocity Vault endless runner | research | Fast spatial/pattern renderer only where mechanic validly supports competency | game adapter boundary | Do not implement until a valid evidence mapping exists |
| Art-style shifting | retain | Different renderers over the same governed graph | node-type renderer architecture | Expand renderer registry incrementally |
| Stall detector (>3 / >90s) | reinterpret | Offer help from explicit task state; elapsed time never equals ability | learner feedback + graph transition | Add optional non-diagnostic help offer |
| Narrative rerouting | retain | Alternate representation/path that preserves competency unless progression is governed | graph transitions | Already supported structurally; expand UI choices |
| Rewind Token used for necessary hints | retire | Help must not be scarce | feedback/human-help boundary | No implementation |
| Rewind Token as cosmetic/story play token | research | Could survive only if no educational access depends on it | future reward shell | Evaluate motivational value before adding |
| Game Night Ticket required to learn/play | retire as gate | Learning and necessary co-play should not be artificially scarce | commercial/reward boundary | No implementation |
| Game Night Ticket as non-scarce event invitation motif | research | Could become purely diegetic scheduling/invite object | future local multiplayer | Only if it improves UX without pressure |
| Local Jackbox-style family multiplayer | retain/research | Host display + participant devices, preferably LAN/local-first | collaboration/privacy + future local adapter | Define local session protocol and no-account guest mode |
| Memory Match | retain/reinterpret | Mixed-skill family game with individualized goals and solvable board invariant | future local multiplayer adapter | Build deterministic rules engine + fairness simulation |
| Variable pair count | research | One possible balancing parameter, not assumed fair | game rules | Simulate win-rate distributions across skill profiles |
| Shared grid with target pair removal | retire as written | Can make other goals impossible | — | Replace with reusable pairs, disjoint targets, private boards, or co-op goals |
| Deviant's Gambit name | retire as generic label | Do not define a teammate/person as the deviant | story naming layer | Use scenario-specific title or neutral mechanic name |
| Deviant's Gambit core mechanic | retain/reinterpret | Social systems puzzle involving uncertain motives, evidence, repair, and multiple good solutions | story + evidence + collaboration nodes | Prototype a small non-stigmatizing scenario |
| One scripted morally correct response | retire | Evaluate reasoning/process where possible; allow multiple constructive solutions | evidence model | Build rubric/branch evidence rather than answer-key morality |
| My Side Bag | retain | Learner-owned diegetic hub for artifacts, cosmetics, preferences, tools | future experience shell | Define local-only first version |
| Badges | reinterpret | Celebration and, where warranted, evidence-linked achievements | future credential boundary | Distinguish cosmetic badge from credentialed achievement |
| Gear / cosmetics | retain | Optional expression; no educational advantage | future experience shell | Local cosmetic inventory later |
| Secrets / Easter eggs | retain | Optional exploration rewards, not learning access gates | story layer | Add only after core learning loop is strong |
| In-game currency | research | Only if it does not drive spending pressure or gate learning/help | commercial/reward boundary | Require explicit dark-pattern review before implementation |
| Parent/family account | retain/reinterpret | Billing, applicable family controls, child profiles; not ownership of learner evidence | institution/family relationships | Later family-account adapter through governed roles |
| Parent manual stage lock | reinterpret | Parent can request presentation preferences where policy permits; cannot overwrite competence | content/readiness + presentation policy | Model as input, not authority shortcut |
| Playtime limits | research | Family/device wellbeing control separate from learning judgment | future family controls | Evaluate alongside device-level controls |
| Multiplayer host/join permissions | retain | Explicit family safety control | collaboration/privacy | Include in local session design |
| Explorer Pass free tier | retire as educational tier | No free learner gets an inferior mastery standard or accessibility | commercial boundary | Redesign commercial packaging later |
| Learner/Scholar paid personalization | reinterpret | Paid convenience/optional expensive media may exist without better curriculum truth | model budget/router | Commercial design after product value exists |
| "Baked" low-cost assets | retain | Strong default: reviewed deterministic assets often beat unnecessary generation | presentation/resource layer | Prefer baked assets when equally effective |
| High generative personalization | research | Use only when it improves learning/agency enough to justify cost/privacy | model router + context grants | Compare against reviewed static alternatives |
| Create Your Own Ending | retain/research | Creative branching/artifact task, potentially strong transfer opportunity | creative construction/project artifact | Add only with competency/evidence purpose |
| Parent-only referral program | retire from learning incentives | Marketing should not manipulate child reward systems | commercial boundary | Keep outside learner loop if ever used |
| C.L.A.W. Medallion | retain/reinterpret | Symbolic local graduation artifact; portable credential only when warranted | future achievement/export | Design after durable evidence admission exists |
| Automatic soulbound NFT | retire | No automatic public/blockchain child credential | credential boundary | No implementation |
| Parent-wallet optional blockchain export | research only | Separate optional export could be evaluated later for adults/guardians | future export policy | Not on current roadmap |
| Scholar subscription prize pool | retire | Avoid cash/gift-card incentives tied to child learning completion | — | No implementation |
| Cross-site graduate reputation boost | retire | Child learning record should not become unrelated social reputation | collaboration/privacy | No implementation |
| Agora/majik/zoverions ecosystem links | research | Optional content navigation only, with strict purpose/scoping | external-resource boundary | No automatic record sharing or reputation transfer |
| `claw-academy.com` | research/brand | Legacy domain concept, not runtime architecture | — | Verify ownership/brand plan separately before relying on it |

## Implementation priority after salvage

The legacy material should influence the build in this order:

1. **presentation presets** — because the five-stage idea can become a useful accessibility/scaffolding feature without corrupting competency truth;
2. **Side Bag shell** — because it provides coherent learner-facing navigation without needing monetization;
3. **one perspective/evidence story scenario** — to test whether the old character-driven educational premise works in the new graph;
4. **Memory Match rules engine** — separate from UI, with deterministic solvability and fairness tests;
5. **local multiplayer protocol** — only after the game rules work offline and without learner-account leakage;
6. **comic-to-play pipeline** — one short Chronicle that enters an existing competency graph;
7. **optional personalization capsule** — after value can be demonstrated without it;
8. **reward/achievement layer** — after evidence admission and learner-control semantics are mature.

Do **not** implement monetization, NFTs, prize pools, or social reputation as prerequisites for any of those steps.

## Promotion rule

A salvaged feature graduates from `research` or `reinterpret` to active implementation only when:

- its educational purpose is explicit;
- the competency/evidence boundary is clear where applicable;
- accessibility and privacy constraints are defined;
- it does not introduce a pay-to-learn or scarcity-to-help mechanism;
- failure/fallback behavior is defined;
- the expected benefit can be measured with learning, transfer, usability, fairness, or agency outcomes rather than generic engagement.
