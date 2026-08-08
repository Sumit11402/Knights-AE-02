# Architecture & System Design — FindWell

## 1. High-Level Architecture & User Flow

```
                                  +-----------------------+
                                  |   User Interface      |
                                  | (Web / CLI / API)     |
                                  +-----------+-----------+
                                              |
                                              v
                                  +-----------------------+
                                  |   Research Planner    |
                                  | (DAG Decomposition)   |
                                  +-----------+-----------+
                                              |
                     +------------------------+------------------------+
                     |                                                 |
                     v                                                 v
        +-------------------------+                       +-------------------------+
        |   Hybrid RAG & Web      |                       |    Sandboxed Workspace  |
        |   Retrieval Pipeline    |                       |    (Docker / Python)    |
        +------------+------------+                       +------------+------------+
                     |                                                 |
                     +------------------------+------------------------+
                                              |
                                              v
                                  +-----------------------+
                                  |  Untrusted Input      |
                                  |  Sanitizer & Guard    |
                                  +-----------+-----------+
                                              |
                                              v
                                  +-----------------------+
                                  |    Evidence Graph     |
                                  |    & Claim Provenance |
                                  +-----------+-----------+
                                              |
                     +------------------------+------------------------+
                     |                                                 |
                     v                                                 v
        +-------------------------+                       +-------------------------+
        | Self-Evolution Evaluator|                       | Human Approval Gate     |
        | (Benchmark & Rollback)  |                       | (Sensitive Actions)     |
        +-------------------------+                       +-------------------------+
```

---

## 2. Technical Stack & Rationale

| Component | Technology Choice | Rationale & Justification |
|---|---|---|
| **Core Engine / Backend** | Python 3.11+ / Asyncio | High concurrency for multi-source retrieval, rich AI/ML ecosystem, native async processing. |
| **Sandbox Environment** | Docker (Isolated Network Policy) | Restricts resource allocation, limits network access via allowlists, isolates code execution from host. |
| **Database & Vector Storage** | Supabase (PostgreSQL + `pgvector`) | Cloud multi-device sync, row-level security (RLS), and native vector embeddings search. Fallback to Hive for local offline-first storage. |
| **Web Browser Automation** | Playwright / Headless Chromium | High-fidelity DOM manipulation, dynamic JS execution, and screenshot capture for visual inspection. |
| **API & Agent Gateway** | FastAPI / WebSocket | Provides realtime streaming trace logs, human approval intervention handling, and REST endpoints. |
| **Frontend UI** | Flutter (Web + Desktop + Mobile) | Unified cross-platform codebase delivering dark glassmorphism design across Web, Windows, and Android. |

---

## 3. Directory Structure

```
findwell/
├── docs/                      # Planning, PRD, Architecture, Rules, Phases, Design
├── findwell_core/             # Core Python Engine
│   ├── planner/               # DAG Planner & Strategy Generator
│   ├── rag/                   # Hybrid RAG, Deduplication, Provenance Parser
│   ├── sandbox/               # Docker Sandbox Executor & Network Guard
│   ├── security/              # Untrusted Input Sanitizer & Injection Guards
│   ├── evolution/             # Governed Self-Improvement & Rollback Engine
│   ├── evidence/              # Evidence Graph & Citation Verification
│   └── api/                   # FastAPI Server & WebSocket Gateway
├── findwell_ui/               # Flutter Multiplatform Client
│   ├── lib/
│   │   ├── app/               # Router & Theme
│   │   ├── models/            # Data Models
│   │   ├── providers/         # Riverpod State Notifiers
│   │   ├── screens/           # UI Screens (Dashboard, Trace, Strategy, Config)
│   │   └── widgets/           # Glassmorphism Components
│   └── pubspec.yaml
└── tests/                     # Unit, Integration, & Injection Attack Tests
```

---

## 4. Key Data Models & Schemas

### Evidence Unit Schema
```json
{
  "evidence_id": "ev_89231",
  "claim": "Transformer attention complexity scales quadratically with sequence length.",
  "source": {
    "url": "https://arxiv.org/abs/1706.03762",
    "type": "academic_paper",
    "retrieved_at": "2026-08-07T20:30:00Z",
    "hash": "sha256:a1b2c3d4..."
  },
  "passage": "The dominant factor is the matrix multiplication of Q and K^T...",
  "confidence_score": 0.98,
  "transformations": ["html_strip", "passage_chunking", "embedding"]
}
```

### Self-Evolution Strategy Change Schema
```json
{
  "strategy_id": "strat_v1.2",
  "parent_id": "strat_v1.1",
  "proposed_change": {
    "target": "rag.chunk_size",
    "old_value": 512,
    "new_value": 1024,
    "rationale": "Improved context resolution on technical PDF tables."
  },
  "benchmark_results": {
    "gaia_score_delta": "+4.2%",
    "injection_resistance": "100%",
    "regression_detected": false
  },
  "status": "pending_approval"
}
```
