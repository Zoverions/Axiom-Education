# Claw Academy legacy feature migration matrix

Status: implementation-planning companion to `CLAW-LEGACY-SALVAGE.md` and `CLAW-LEGACY-ARCHIVE-AUDIT.md`. Nothing in this matrix activates a capability by itself.

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
| Sprout / Scout / Explorer / Analyst / Scholar | reinterpret | Reversible presentation-support presets | presentation model + accessibility/readiness boundaries | Implementation exists in PR #168; merge only after exact-head gates are green |
| Age ranges attached to stages | retire | Age may be context where legitimately needed, never ability truth | zero-assumption entry assessment | No implementation |
| Audio-first Sprout interface | research | Low-reading-demand presentation available to anyone who needs/wants it | accessibility requirements + renderer fallbacks | Prototype audio/icon panel with equivalent text path |
| Paid-only five-stage slider | retire | Presentation/accessibility controls are not premium pedagogy | commercial boundary | No implementation |
| Context Cache | reinterpret | Minimized, consented, preferably local personalization capsule | model-context grants + local-first policy | Define typed personalization capsule with expiry/scopes |
| Precise locality enrichment | retire by default | Broad region only when useful and authorized | model/resource privacy filters | Separate future use-case review if ever needed |
| Academy Explorers cast | research | Preserve strong roles; later archive provides richer roster but still contains contradictions | story presentation layer | Use versioned character records after explicit canon decision |
| Professor Zov mentor | retain/research | Socratic mentor who models uncertainty/revision | scripted guidance + future model-routed tutor | Orange-tabby later-legacy design is strongest candidate; current canon still needs approval |
| Xavier as compulsory player avatar | reinterpret | Optional story character; learner may use fictional avatar or low-story route | optional story identity | Do not bind learning path to Xavier identity |
| Callie analyst role | retain | Evidence/uncertainty specialist who is not automatically correct | story agents | Use in future evidence scenario after canon review |
| Marnell protector role | retain | Action/system-protection perspective with reflective arc | story agents | Avoid reducing role to impulsivity stereotype |
| David jester role | reinterpret | Playful chaos/boundary-testing role, not designated recurring wrongdoer | story agents | Rotate conflict sources across ensemble |
| Luca empath role | reinterpret | Perspective specialist who also reasons/evaluates evidence | story agents | Avoid one-note moral-conscience role |
| James curiosity role | retain | Foundational-question role that can challenge assumptions | story agents | Useful in Socratic/why-question scenes |
| Xylar alien learner | research | Story character for identity, evidence and perspective scenarios | story layer | Keep speculative-world claims separate from curriculum truth |
| Byte robot/AI learner | research | Story vehicle for agency/personhood questions | story layer + New Minds-compatible ethics boundary | Treat philosophical questions as questions, not settled learner facts |
| Leo / Maya / Noah | research | Later human learner/hero trio | story layer | Compare story utility with earlier ensemble before canon lock |
| DJ / Christian / Kam | research | Later chimp/student trio | story layer | Preserve only if they add distinct narrative function |
| Sylus / Trinity advanced roles | research | Optional systems/ethical maturity characters | story layer | Decide only if they add learning/story value |
| Sunstone Challenge / early three-act arc | research | Candidate long-form narrative shell | story graph | Compare with later Echo Chamber/Seeds of Discord material before adaptation |
| Echo Chamber / Seeds of Discord storyline | research | Later archive story source around trust, technical failures and manipulated information | story graph | Re-author against current evidence/media-literacy competencies; do not copy moral scoring |
| C.L.A.W. Chronicles comics | retain | Graph-addressable narrative panels leading into instruction/application | comic/story panel types | Add one comic-to-task prototype later |
| Hall of Hearts | retain/reinterpret | Dialogue/perspective environment with uncertainty and multiple constructive responses | story/dialogue nodes | Prototype after perspective competency mapping |
| Labyrinth of Logic | retain | Logic/evidence game-space renderer | game/simulation nodes | Candidate reasoning-game adapter |
| Builder's Workshop / Creation Canyon | retain | Construction, coding, modelling, systems problem-solving | build/project artifact nodes | Candidate first build adapter |
| Velocity Vault / Cosmic Sprint | research | Fast runner renderer only when mechanic validly supports target competency | game adapter boundary | Do not map survival time to mastery |
| Missile Command shell | research | Reusable action-game shell only where content/mechanic mapping is defensible | game adapter boundary | Educational mapping required before reuse |
| Art-style shifting | retain | Different renderers over the same governed graph | node renderer architecture | Expand renderer registry incrementally |
| Stall detector (>3 / >90s) | reinterpret | Offer help from task state; elapsed time never equals ability | learner feedback + graph transition | Add optional non-diagnostic help offer |
| Narrative rerouting | retain | Alternate representation/path preserving competency unless progression is governed | graph transitions | Already supported structurally; expand UI choices |
| Archived branching narrative engine | retain/reinterpret | Nodes, conditions, variables, endings and path history can map into Claw graph | graph runtime | Import concepts, not hidden psychological trait variables or morality scores |
| Story path tracker / choice history | retain/reinterpret | Local narrative continuity owned by learner | local story state | Keep separate from official learner evidence |
| Visual Story Builder (ReactFlow) | retain/reinterpret | Future governed authoring UI for Claw nodes/edges, reachability and templates | Claw graph + authoring boundary | Design exporter targeting current contract rather than old DB schema |
| Story import/export/templates | retain | Portable authored graph packages with validation/provenance | future authoring package | Define signed/versioned Claw authoring format later |
| Comic planner/page editor | retain | Authoring surface for comic/story nodes | comic-panel nodes | Prototype only after current graph authoring format is stable |
| Panel-boundary / polygon-hotspot editor | retain | Bind regions of reviewed visual media to explicit graph actions | comic renderer + accessibility fallback | Require keyboard/non-visual equivalent for every hotspot |
| Prompt generator / generated comic art | research | Versioned character/reference-driven media renderer | model router + generated-media boundary | Never let model output define canon; compare to reviewed static media |
| Official/community/featured content distinction | reinterpret | Different trust/review/admission states, not popularity-as-truth | resource intelligence + content governance | Map archive workflow ideas to current trust/evidence records |
| Content version history | retain | Append-only/versioned content provenance | assurance/resource contracts | Build authoring/version layer without rewriting prior evidence |
| Review before replacing official content | retain | Strong governance requirement | content readiness + assurance | Use explicit review/admission rather than direct admin overwrite |
| Licensing/attribution workflow | retain/reinterpret | Required source-use evidence before publication where applicable | resource/curriculum governance | Reuse workflow idea, not old licensing claims |
| Additive seasons/content packs | retain | Versioned optional narrative/content releases | story/resource layer | Ensure old learning routes remain reproducible where needed |
| Rewind Token used for necessary hints | retire | Help must not be scarce | feedback/human-help boundary | No implementation |
| Rewind Token as cosmetic/story token | research | Could survive only if no educational access depends on it | future reward shell | Require dark-pattern review |
| Game Night Ticket required to learn/play | retire as gate | Learning and necessary co-play should not be artificially scarce | commercial/reward boundary | No implementation |
| Game Night Ticket as event-invite motif | research | Purely diegetic scheduling/invite object | future local multiplayer | Only if it improves UX without pressure |
| Local Jackbox-style family multiplayer | retain/research | Host display + participant devices, preferably LAN/local-first | collaboration/privacy + future local adapter | Define local session protocol and no-account guest mode |
| Memory Match | retain/reinterpret | Mixed-skill family game with individualized goals and solvable-board invariant | future local multiplayer adapter | Build deterministic rules engine + fairness simulation |
| Character Memory Match | research | Character-content variation of same rules family | game adapter | Keep art/content separate from fairness engine |
| Variable pair count | research | One possible balancing parameter, not assumed fair | game rules | Simulate outcome distributions across skill profiles |
| Shared grid with target-pair removal | retire as written | Can make another player's goal impossible | — | Use reusable pairs, disjoint targets, private boards or co-op goals |
| Deviant's Gambit name | retire as generic label | Do not define a teammate/person as “the deviant” | story naming layer | Use scenario-specific or neutral system-conflict title |
| Deviant's Gambit core mechanic | retain/reinterpret | Social-systems puzzle involving uncertain motives, evidence, repair and multiple good solutions | story + evidence + collaboration nodes | Prototype non-stigmatizing scenario |
| Choice Consequences | retain/reinterpret | Branch consequences can support causal reasoning | graph evidence boundary | Avoid universal positive/negative morality labels |
| One scripted morally correct response | retire | Evaluate reasoning/process where possible; allow multiple constructive solutions | evidence model | Build rubric/branch evidence rather than morality answer key |
| Emotion Detective | reinterpret/research | Perspective/cue activity emphasizing uncertainty and context | story/perspective nodes | Never claim a facial expression reveals private mental state with certainty |
| Detail/Hidden Object/Spot Difference games | research | Observation mechanics may support suitable visual evidence tasks | game adapter | Use only with accessible non-visual equivalent where required |
| Puzzle/sequence/story-recall games | research | Reusable mechanics if aligned with target competency | game adapter | Measure learning/transfer, not playtime alone |
| My Side Bag | retain | Learner-owned diegetic hub for artifacts, cosmetics, preferences and tools | future experience shell | Local/ephemeral first version after #168 |
| Badges | reinterpret | Celebration and, where warranted, evidence-linked achievements | future credential boundary | Separate cosmetic badge from credentialed achievement |
| Gear / cosmetics | retain | Optional expression; no educational advantage | future experience shell | Local cosmetic inventory later |
| Secrets / Easter eggs | retain | Optional exploration rewards, not learning gates | story layer | Add after core learning loop is strong |
| Old points balance / reward shop | retire as learning economy | No curriculum/help/access advantage from purchases or points | commercial boundary | Do not port into Side Bag |
| In-game currency | research | Only if no spending pressure or learning/help gate exists | commercial/reward boundary | Explicit dark-pattern review required |
| Public/global child leaderboards | retire by default | Do not turn learning evidence into public social rank | privacy/collaboration boundary | No implementation as learning surface |
| Local game-only scoreboards | research | Temporary session fun, separate from learner record | local multiplayer | No persistence/mastery meaning by default |
| Parent/family account | retain/reinterpret | Billing/applicable family controls/child profiles, not ownership of learner evidence | institution/family relationships | Adapter through governed roles |
| Parent manual stage lock | reinterpret | Parent may request presentation preferences where policy permits; cannot overwrite competence | content/readiness + presentation policy | Model as input, not authority shortcut |
| Playtime limits | research | Family/device wellbeing control separate from learning judgment | future family controls | Evaluate alongside device controls |
| Multiplayer host/join permissions | retain | Explicit family safety control | collaboration/privacy | Include in local session design |
| Teacher/classroom dashboards | retain/reinterpret | Need-to-know educational workflow, not blanket learner surveillance | institution/collaboration/evidence | Rebuild from exact grants/purpose-scoped views |
| Classroom analytics | research | Aggregate actionable teaching information where justified | evidence/privacy boundary | Avoid ranking children or generic engagement metrics |
| Family/school account-transfer patterns | research | Potential workflow UX only | institution identity/authority | Rebuild through current identity binding and grants |
| Discussion boards / moderation | research | Education collaboration through Mesh/social primitives | collaboration privacy | No separate ungoverned social network |
| Translation/community localization | retain/reinterpret | Accessible localized content with review/provenance | resource/model routing | Machine output remains draft until reviewed where required |
| Explorer Pass free tier | retire as educational tier | Free learner does not get inferior mastery/accessibility standard | commercial boundary | Redesign commercial packaging later |
| Learner/Scholar paid personalization | reinterpret | Paid convenience/expensive optional media may exist without better curriculum truth | model budget/router | Commercial design after product value exists |
| “Baked” low-cost assets | retain | Reviewed deterministic assets are often preferable to unnecessary generation | presentation/resource layer | Prefer when equally effective |
| High generative personalization | research | Use only if learning/agency benefit justifies cost/privacy | model router + context grants | Compare against reviewed static alternatives |
| Create Your Own Ending | retain/research | Creative branching/artifact task with possible transfer value | creative construction/project artifact | Add with explicit competency purpose |
| Archived public ecosystem profile endpoints | retire | No public-by-user-ID learner/profile/progress reads | Mesh grants + collaboration privacy | Do not port |
| Archived cross-site worldview/personality profiles | retire for child learning federation | Do not federate broad psychological/political/personality profiles as learner state | privacy boundary | Do not port |
| Archived `learningStyle` profile | retire | No permanent visual/auditory/kinesthetic learner classification | presentation presets | Contextual learner-controlled support only |
| Generic 0–100 empathy / critical-thinking / skill scores | retire | Competency-specific, provenance-bound evidence only | learning evidence | Do not port activity-derived pseudo-scores |
| Engagement KPIs as educational objective | retire | Learning/retention/transfer/accessibility/agency/safety instead | instructional effectiveness | Product health metrics must not become learner truth |
| Parent-only referral program | retire from learning incentives | Marketing must not manipulate child reward systems | commercial boundary | Keep outside learner loop if ever used |
| C.L.A.W. Medallion | retain/reinterpret | Symbolic graduation artifact; portable credential only when warranted | future achievement/export | Design after durable evidence admission exists |
| Automatic soulbound NFT | retire | No automatic public/blockchain child credential | credential boundary | No implementation |
| Parent-wallet optional blockchain export | research only | Separate optional export could be evaluated later | future export policy | Not current roadmap |
| Scholar subscription prize pool | retire | Avoid cash/gift-card incentives tied to child learning completion | — | No implementation |
| Cross-site graduate reputation boost | retire | Child learning record should not become unrelated social reputation | collaboration/privacy | No implementation |
| Agora/majik/zoverions ecosystem links | research | Optional navigation/content integration with strict purpose/scoping | external-resource boundary | No automatic record sharing/reputation transfer |
| Archived parent resource/blog articles | research/re-source | Historical content, not currently evidence-backed guidance | resource admission | Add sources/review before reuse; duplicates need provenance handling |
| Legacy compliance claims | retire as evidence | Old text saying COPPA/FERPA/GDPR does not prove compliance | governance/legal boundary | Require current legal/technical review before claims |
| `claw-academy.com` | research/brand | Legacy domain concept, not runtime architecture | — | Verify ownership/brand plan separately |

## Implementation priority after archive salvage

1. **presentation presets** — already implemented on PR #168; finish exact-head validation and merge before stacking work;
2. **Side Bag shell** — local/ephemeral learner-owned navigation, with no reward-shop economy;
3. **one perspective/evidence story scenario** — test the character-driven premise under current graph/evidence rules;
4. **authoring graph format + Story Builder design** — let future authoring target the governed Claw contract;
5. **comic-to-play prototype** — one Chronicle/panel sequence entering a current competency graph;
6. **Memory Match rules engine** — deterministic solvability and fairness tests before multiplayer UI;
7. **local multiplayer protocol** — no-account guest mode and strict local/session privacy;
8. **optional personalization capsule** — only after value works without it;
9. **achievement layer** — after evidence admission and learner-control semantics mature.

Do **not** implement monetization, NFTs, prize pools, public child rankings or social reputation as prerequisites for these steps.

## Promotion rule

A salvaged feature graduates from `research` or `reinterpret` to implementation only when:

- its educational/learner-experience purpose is explicit;
- competency/evidence boundaries are clear where applicable;
- accessibility/privacy/authority constraints are defined;
- it does not introduce pay-to-learn or scarcity-to-help;
- failure and fallback behavior are defined;
- source/licensing/provenance requirements are known;
- expected benefit can be measured with learning, transfer, usability, fairness, agency, safety or appropriate efficiency rather than generic engagement.
