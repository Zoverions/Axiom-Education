# OntarioEdAI – The Cognitive Symbiote Platform

**Version:** 0.4 (Full Curriculum Database + RAG Foundation + SQLite Integration)
**Target:** Windows tablet / OEM White-Label "Symbiote" Hardware (Offline-First)
**Goal:** To establish a decentralized, privacy-first, on-device cognitive symbiote that adapts to the individual sentience of the student. From dynamic workbooks for elementary learners to university-level academic preparation, this is a sovereign educational ecosystem.

---

## The Master Plan: R&D Roadmap & Vision

We are architecting a fundamentally new paradigm for education: a decentralized, privacy-first, on-device cognitive symbiote that adapts to the individual student. This platform completely bypasses traditional "Big Tech" cloud dependencies.

### 1. The Data Substrate & Knowledge Base
The AI needs verifiable grounding. We have compiled the full Ontario Grades 9-12 curriculum into a structured SQLite database and a ChromaDB vector index.
*   **Curriculum Database:** All 30+ Ontario courses (Math, Science, English, Arts, Business, Tech, FSL, Native Languages, etc.) are deeply mapped with specific expectations.
*   **Custom Modules:** We have expanded the baseline curriculum to emphasize **Ethics, Moral Foundations, and the Evolution of Thought** (tracing human spirituality from cave paintings to modern philosophy).
*   **Local RAG Index:** Utilizes local vector storage (ChromaDB) to constrain Small Language Models (SLMs) to specific pedagogical guardrails.

### 2. The Dual-Engine Logic System
*   **Deterministic Engine:** Python/SymPy and rule-based parsers handle raw computation and absolute ground truth.
*   **Generative Engine (Tutor):** Heavily quantized SLMs (e.g., Phi-3-Mini, Llama-3 8B) translate deterministic truth into highly personalized, Flesch-Kincaid adjusted output.

### 3. The Symbiotic Workspace & Elementary Adaptation
*   **The Infinite Canvas:** An interactive scratchpad (Excalidraw/Fabric.js) where students show their work using stylus input.
*   **Dynamic Workbooks:** For younger minds (K-8), the NPU-driven SLM generates tactile, scaffolded HTML5 canvas elements (e.g., interactive fractions) instead of text-heavy queries.

### 4. Self-Sovereign Authentication & The Node Ledger
*   **Zero-Trust Security:** Decentralized Identifiers (DIDs) and TEE-based AES-256 encryption ensure student data is impenetrable without local biometric/PIN access.
*   **Verifiable Credentials (VCs):** Course mastery is stored as cryptographic badges locally, allowing seamless peer-to-peer (P2P) transfers if a student changes schools.
*   **Offline Mesh Network:** Classrooms utilize Wi-Fi Aware (NAN) and Bluetooth Mesh to form localized peer-to-peer swarms, allowing collaboration (WebRTC) and content syncing without internet.

---

## Hardware Specifications: The "Symbiote" OEM Tier

To run this platform effectively without relying on the cloud, we target a premium White-Label BOM (Bill of Materials) budget of **$350–$450**.

| Component | Specification | Capability |
| :--- | :--- | :--- |
| **Processor (SoC)** | MediaTek Dimensity 8300/9300 | 30-40+ TOPS NPU. Runs the "Tutor" language model directly on the NPU, leaving the CPU free for rendering and OS tasks. |
| **Memory** | 16GB - 24GB LPDDR5X RAM | Massive bandwidth required for fast text generation and holding large contexts in memory. |
| **Display** | 12.7-inch "Paper-Matte" IPS (120Hz) | Nano-etched glass reduces eye fatigue and simulates paper friction. |
| **Input** | USI 2.0 Active Digitizer | Zero latency, tilt recognition, flawless palm rejection for the Infinite Canvas. |

**The True Parallel Asymmetric Multi-Agent System:**
*   **The Watcher (0.5B Vision Model):** Continuously parses the canvas for handwritten input in real-time.
*   **The Orchestrator:** Instantly verifies mathematical/logical truth.
*   **The Tutor (3B-7B SLM):** Resides in NPU memory, chiming in instantly with zero loading delays.

---

## Honest Status Report (Current Build)

**Completed & Production-Ready**
*   Flutter single-codebase (Windows native targeted, testing via FFI).
*   Complete SQLite relational database containing 30+ Ontario courses + custom Ethics modules.
*   Python `rag_ingestion.py` script successfully embedding curriculum into local ChromaDB for RAG.
*   Riverpod state management architecture with optimized O(1) in-memory DB queries.
*   Dynamic Course Overviews and detail screens reading from SQLite.

**Scaffolding / Placeholders (Needs Work)**
*   ONNX/TFLite model bindings in Flutter (Phi-3-mini and handwriting scorer) – placeholder interfaces exist.
*   The actual Excalidraw/Canvas frontend component is scaffolded but not fully integrated with a "Watcher" model.
*   P2P Mesh Network protocols (Wi-Fi Aware/WebRTC) are mapped in architecture but not coded.

## Supplemental Documentation
*   `ARCHITECTURE.md` - Finer technical details on the AI logic and hardware.
*   `CURRICULUM_SOURCES.md` - Details on the data sources, Ministry PDFs, and custom augmentations (Ethics, Grokipedia integrations, Open Educational Resources).

## How to Run the App (Dev Mode)

1. Ensure Flutter is installed.
2. Run `flutter pub get`.
3. If running on Windows/Linux, the app automatically initializes `sqflite_common_ffi` to read the local `assets/curriculum/ontario_curriculum.sqlite`.
4. Run `flutter run -d windows`.

## Data Pipeline (Python)
To rebuild the curriculum databases:
1. `python3 parse_markdown.py` (Appends new courses to the master JSON).
2. `python3 migrate_to_sqlite.py` (Builds the relational SQL DB for the Flutter app).
3. `python3 rag_ingestion.py` (Builds the ChromaDB vector index for the AI Tutor).