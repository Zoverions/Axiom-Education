# Archived: OntarioEdAI Master Architecture

> **Historical document — not current architecture.**
>
> This material predates the governed Axiom Education rebuild. It contains aspirational claims about model availability, continuous monitoring, encryption, identity, mesh authorization, privacy, and compliance that were not established by production code and evidence. It is preserved only for design traceability. Current authority is `docs/rebuild/PRODUCT-DEFINITION.md`, `docs/rebuild/REQUIREMENTS.md`, `config/capabilities.json`, executable tests, and the shared Axiom Education contract.

---

# OntarioEdAI Master Architecture

This document outlines the decentralized, privacy-first, on-device cognitive symbiote platform for education.

## Phase 1: The Data Substrate & Knowledge Base

The curriculum acts as the central nervous system.

* **Master Curriculum Schema**: Local JSON schemas and SQLite mappings defining expectations (e.g. MTH1W, ENG3U).
* **Local RAG Index**: **ChromaDB** is deployed locally. It ingests the Ontario schema and future Open Educational Resources to ensure the Small Language Model (SLM) stays strictly on-topic via verified grounding constraints.

## Phase 2: The Dual-Engine Logic System (Backend)

We strictly separate raw computation from language generation to eliminate hallucinations.

* **Deterministic Engine (Truth)**: Uses **SymPy** for mathematics/physics and rule-based parsers (like **spaCy**) for language arts to calculate ground truth.
* **Generative Engine (Translation)**: Utilizes heavily quantized SLMs (**Phi-3-Mini**, **Qwen2-Math**, or **Gemma 2 2B**) running via **Llama.cpp**.
* **Function**: The deterministic engine feeds the verified truth to the SLM. The SLM translates that truth into a personalized narrative, generating the tailored choices (Visual, Abstract, Real-world) for the student's specific mentality.

## Phase 3: The Symbiotic Workspace (Frontend)

* **Dynamic Problem Rendering**: Adapted via **Perseus** (Khan Academy's open-source engine) combined with **MathJax** to render generated questions flawlessly.
* **The Infinite Canvas**: Integrated with **Excalidraw** or **Fabric.js** as an interactive scratchpad for geometric and analytical problems.
* **Real-Time Friction Audit**: Continuous tracking of student steps. The SLM intervenes with strategic hints based on deterministic alignment checks when an error occurs.

## Phase 4: Hardware Targeting & Economic Scaling

Designed to function on aggressively priced hardware.

| Hardware Tier               | Specifications                                                                                                                                           | Target Capability                                                                                              |
|-----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| **Minimum (Economical)**    | 8GB RAM, Intel N100 / ARM equivalent, 128GB Storage                                                                                                      | Runs 2B-3B parameter models (4-bit quantized) smoothly. Basic 2D canvas. CSS-optimized UI.                     |
| **Symbiote (OEM Premium)**   | MediaTek Dimensity 8300/9300 (30-40+ TOPS NPU), 16GB–24GB LPDDR5X RAM, 12.7-inch 120Hz Paper-Matte Display, USI 2.0 Stylus ($350-$450 BOM Budget) | Runs **True Parallel Asymmetric Multi-Agent System**. Zero-latency canvas interaction with dedicated visual parsing. |

**The True Parallel Asymmetric Multi-Agent System:**
With the "Symbiote" hardware tier (utilizing the massive RAM bandwidth and dedicated NPU), the software architecture transitions to continuous parallel execution:
* **The Watcher (0.5B Vision Model):** Runs continuously in the background (~500MB RAM), parsing handwritten math and diagrams from the infinite canvas into digital variables in real-time.
* **The Orchestrator (SymPy + Python):** Instantly verifies the mathematical operations parsed by the Watcher.
* **The Tutor (3B-7B Language Model):** Resides entirely in NPU memory, chiming in with tailored hints instantly (zero loading bars) the moment a student makes an error.

*Strategic Impact:* By leveraging a flagship-tier white-label device, we bypass cloud dependencies, ensuring 100% on-device privacy (crucial for school board compliance) while driving the recurring cost of cloud-AI tutoring to zero.

## Phase 5: The Elementary Adaptation (Tactile & Scaffolded GUIs)

To accommodate K-8 developmental stages, the dynamic UI generation is adapted for younger minds relying on System 1 intuition.

* **Dynamic Workbooks**: The NPU-driven SLM generates interactive HTML5/Canvas elements on the fly (e.g., a draggable pizza for fractions) instead of text-heavy multiple-choice queries.
* **Cognitive Scaffolding**: SLM outputs are dynamically adjusted for lower reading levels (Flesch-Kincaid adjustments) and use highly visual analogies tailored to the child's interests.

## Phase 6: The Decentralized Mesh Network

To bypass traditional centralized infrastructure, the tablets act as their own network in the classroom.

* **Protocol**: Uses **Wi-Fi Aware (NAN)** and **Bluetooth Mesh** for offline device discovery and direct data streaming.
* **The Classroom Swarm**: Tablets automatically form a local mesh. Curriculum updates or interactive workbooks pushed by a teacher propagate peer-to-peer (P2P) via local IPFS, drastically reducing bandwidth.
* **Offline Collaboration**: **WebRTC** routes over the LAN/Mesh, enabling real-time collaboration on a shared Excalidraw canvas completely offline.

## Phase 7: Self-Sovereign Identity & Achievement Ledger

With zero cloud dependency, the device serves as a secure, decentralized vault for the student's data.

* **Zero-Trust Authentication**: Generates Decentralized Identifiers (DIDs) locally. Student data is encrypted at rest (AES-256) using the tablet's Trusted Execution Environment (TEE), unlocked only via local biometric or PIN access.
* **Verifiable Credentials (VCs)**: Achievements and mastery of curriculum modules are stored as cryptographic badges on the device.
* **The Node Sync**: When connecting to a teacher's master node, credentials are gossiped and validated locally. If a student switches schools, their entire educational history is securely transferred P2P without relying on proprietary, centralized school board databases.

## Phase 8: Deployment & Open-Source Evolution

* **Containerization**: Packaged via **Docker** or as a standalone **Electron/Tauri** (Flutter target for current iteration) executable.
* **The Curation Loop (FACE Protocol)**: Local anonymized logs track comprehension rates. Voluntary opt-in systems allow metadata aggregation to fine-tune future versions of open-source models.
