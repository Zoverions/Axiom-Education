# Archived: Curriculum Sources & Augmentation Strategy

> **Historical document — not provenance evidence.**
>
> This strategy predates Curriculum Pack v1 and includes unverified claims about official coverage, redistribution rights, neutral source quality, model grounding, and guaranteed engagement. It is preserved for traceability only. Current curriculum authority is the signed canonical pack, `curriculum/source-ledger.v1.json`, its schemas, verification tools, and human review state.

---

# Curriculum Sources & Augmentation Strategy

This document tracks the origins of the educational data powering the OntarioEdAI platform and outlines our strategy for incorporating open-source educational resources.

## 1. Core Curriculum (The Ground Truth)

Our primary data substrate is built upon the official Ministry of Education documents for Ontario, Canada. These have been parsed and structured into machine-readable JSON and SQLite schemas.

**Included Disciplines (Grades 9-12):**
* **Mathematics:** De-streamed (MTH1W) and legacy academic/applied pathways.
* **Science:** SNC1W (de-streamed), Biology, Chemistry, Physics.
* **English:** ENL1W, ENG3U, ENG4U (focus on literacy, digital media, and critical analysis).
* **Technology & Skilled Trades:** TAS1O, TAS2O, ICD2O, and legacy computer studies.
* **Business:** BEM1O, BEP2O, BOH4M (Entrepreneurial mindset and leadership).
* **Guidance & Career Education:** GLC2O and overarching Grade 9-12 frameworks.
* **Health & Physical Education:** PPL1O, PPL2O (Active living, consent, mental health).
* **The Arts:** Universal frameworks for visual arts, music, drama, and dance.
* **Language Acquisition:** Core French (FSL), Native Languages, English as a Second Language (ESL), American Sign Language (ASL).
* **Cross-Curricular:** First Nations, Métis, and Inuit (FNMI) Studies framework, and Co-operative Education frameworks.

## 2. Custom Augmented Modules: "Ethics & Moral Foundations"

While the Ontario curriculum implicitly covers ethics within specific subjects, the Master Plan requires a dedicated, explicit focus on the evolution of human thought.

We have custom-built an open-source module: **Ethics, Moral Foundations, and the Evolution of Thought (EMF1O/EMF3U)**.

## 3. Open Educational Resources (OER) Ingestion Strategy

To ensure the platform is universally applicable and not strictly bound to Ontario, we are building ingestion pipelines for global Open Educational Resources.

* **Grokipedia / Wikipedia:** Extracting factual, unbiased summaries of historical events and scientific concepts to feed the Deterministic Engine.
* **Khan Academy (Perseus/Content):** Leveraging their open-source math generators and problem sets to supplement dynamically generated questions.
* **International Frameworks:** The database schema is designed to ingest US Common Core, UK A-Levels, and Australian curriculum standards.

## 4. The "On-The-Fly" Content Generation Principle

The curriculum database tells the AI what to teach. Open-source libraries provide facts. The NPU-driven SLM dynamically generates the question presented to the student.
