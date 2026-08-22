# Accessible and offline MTH1W delivery

Axiom Education must not make a visual Flutter screen, stylus, animation, network connection, or one response mode a prerequisite for completing required learning work.

The first machine-enforced alternative is a deterministic UTF-8 Markdown package derived directly from the same 43 authored MTH1W lesson objects.

## What the package contains

For every current lesson the exporter produces:

- a learner-facing printable/offline text lesson;
- a separate answer key/review copy;
- exact lesson and expectation identifiers;
- learning goals and success criteria;
- vocabulary and direct instruction;
- all method routes;
- representation descriptions plus their required text alternatives;
- worked-example steps;
- guided, independent, and retrieval practice;
- constructed-response criteria without placing sample answers in the learner copy;
- reflection prompts;
- the lesson's nonvisual route and alternate response options.

The package manifest binds each export to the canonical digest of the exact lesson object and records SHA-256 for both generated files.

## Determinism

```bash
python tools/mth1w_accessible_export.py verify
```

Verification builds the complete package twice in separate temporary directories and requires:

- all 43 lessons to be present;
- identical file sets;
- byte-identical manifests and lesson files;
- correct artifact digests;
- `printable_equivalent: true` for every lesson;
- a non-empty nonvisual route;
- at least two response options;
- a text alternative for every declared representation.

A single missing accessibility field fails the export rather than falling back to a visual-only route.

To materialize a local package:

```bash
python tools/mth1w_accessible_export.py build \
  --output build/mth1w-accessible-offline
```

The generated package is a build artifact and is not committed by default.

## Student-answer separation

The learner copy does not expose selected-response correct answers, accepted short-text answers, constructed-response sample answers, item rationales, worked-example final answers, or misconception corrections that belong in the answer/review copy.

This is a content-delivery separation, not an anti-cheating security boundary. A learner with access to the answer-key artifact can read it.

## What this does not prove

A deterministic text route does not by itself establish:

- WCAG conformance;
- AODA compliance;
- screen-reader quality across devices and software;
- appropriate reading level for every learner;
- cognitive accessibility;
- high-quality braille, tactile, large-print, audio, AAC, or sign-language adaptations;
- equivalence for every motor, visual, hearing, language, or cognitive access need;
- educator approval or pedagogical validity.

Those remain human accessibility/usability and product-validation gates.

## Platform direction

The Markdown package is the first alternate delivery target, not the final accessibility architecture. The same content-addressed lesson model can later support deterministic HTML/EPUB/PDF, structured audio scripts, braille-ready text, large-print profiles, accessible diagrams, and other reviewed transforms without making any one UI the authority for lesson content.
