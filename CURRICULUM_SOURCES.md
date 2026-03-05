# Curriculum Sources & Augmentation Strategy

This document tracks the origins of the educational data powering the OntarioEdAI platform and outlines our strategy for incorporating open-source educational resources.

## 1. Core Curriculum (The Ground Truth)

Our primary data substrate is built upon the official Ministry of Education documents for Ontario, Canada. These have been parsed and structured into machine-readable JSON and SQLite schemas.

**Included Disciplines (Grades 9-12):**
*   **Mathematics:** De-streamed (MTH1W) and legacy academic/applied pathways.
*   **Science:** SNC1W (de-streamed), Biology, Chemistry, Physics.
*   **English:** ENL1W, ENG3U, ENG4U (focus on literacy, digital media, and critical analysis).
*   **Technology & Skilled Trades:** TAS1O, TAS2O, ICD2O, and legacy computer studies.
*   **Business:** BEM1O, BEP2O, BOH4M (Entrepreneurial mindset and leadership).
*   **Guidance & Career Education:** GLC2O and overarching Grade 9-12 frameworks.
*   **Health & Physical Education:** PPL1O, PPL2O (Active living, consent, mental health).
*   **The Arts:** Universal frameworks for visual arts, music, drama, and dance.
*   **Language Acquisition:** Core French (FSL), Native Languages, English as a Second Language (ESL), American Sign Language (ASL).
*   **Cross-Curricular:** First Nations, Métis, and Inuit (FNMI) Studies framework, and Co-operative Education frameworks.

## 2. Custom Augmented Modules: "Ethics & Moral Foundations"

While the Ontario curriculum implicitly covers ethics within specific subjects (e.g., Business ethics, English media bias, Science climate change), the Master Plan requires a dedicated, explicit focus on the evolution of human thought.

We have custom-built an open-source module: **Ethics, Moral Foundations, and the Evolution of Thought (EMF1O/EMF3U)**.

**Topics Covered:**
*   **Early Spiritualism:** Examining cave paintings, animism, and early attempts to understand existence.
*   **Philosophical Evolution:** The transition from mythos to logos, examining Eastern and Western philosophical foundations.
*   **Modern Ethics:** Application of moral frameworks (utilitarianism, deontology, virtue ethics) to modern challenges (AI, bioethics).
*   **Personal Mentality & Choice:** Emphasizing that students have the freedom to explore and align with belief systems that resonate with their own cognitive style.

## 3. Open Educational Resources (OER) Ingestion Strategy

To ensure the platform is universally applicable and not strictly bound to Ontario, we are building ingestion pipelines for global Open Educational Resources.

*   **Grokipedia / Wikipedia:** Extracting factual, unbiased summaries of historical events and scientific concepts to feed the Deterministic Engine.
*   **Khan Academy (Perseus/Content):** Leveraging their open-source math generators and problem sets to supplement the dynamically generated SLM questions.
*   **International Frameworks:** The database schema is designed to ingest US Common Core, UK A-Levels, and Australian curriculum standards. The SLM maps the local student's requirements to the corresponding global standard to pull the best learning materials.

## 4. The "On-The-Fly" Content Generation Principle

The curriculum database tells the AI *what* to teach. The Open Source libraries (like SymPy for math) provide the *facts*.

The NPU-driven SLM takes these two inputs and **dynamically generates** the actual question presented to the student. This means:
*   No two students get the exact same math word problem.
*   A student interested in robotics gets physics problems framed around servos and motors.
*   A student interested in art gets geometry problems framed around perspective drawing.

This guarantees maximum engagement and aligns perfectly with the student's personal mentality.