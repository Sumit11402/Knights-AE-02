# Project Roadmap & Implementation Phases — FindWell

## Milestone Overview

Each phase is designed as a fully functional, testable milestone delivering incremental value while preserving security containment.

---

## Phase 1: Core Foundation & Secure Execution Sandbox
**Goal**: Build the core backend engine, Docker execution sandbox, basic live RAG, and initial Flutter desktop/web client.

* **In Scope**:
  * Python Async Core Engine & FastAPI Server.
  * Docker Execution Sandbox with memory/CPU quotas and network allowlisting.
  * Hybrid Live RAG pipeline (OpenAlex / arXiv / live web fetch + SQLite vector index).
  * Prompt injection sanitizer for untrusted web inputs.
  * Flutter UI: Project dashboard, research planner view, live trace log viewer.
* **Out of Scope**: Self-evolution strategy benchmarking (Phase 3), human approval gate webhooks (Phase 2).

---

## Phase 2: Evidence Graph & Governed Human Approval
**Goal**: Implement immutable claim-to-source evidence linking, human-in-the-loop approval workflow, and full paper draft generation.

* **In Scope**:
  * Evidence Graph parser linking claims to specific passage text, DOIs, and hashes.
  * Human Approval Gate for sensitive tool execution & export actions.
  * Section-by-section draft generation with verified BibTeX citations.
  * Flutter UI: Interactive Evidence Graph viewer, Approval Checkpoint modal, Draft Editor.
* **Out of Scope**: Automated strategy mutation (Phase 3).

---

## Phase 3: Governed Self-Evolution Loop & Benchmarking
**Goal**: Enable the agent to critique its own research failures, propose versioned strategy upgrades, run benchmark evaluation suites, and support instant rollback.

* **In Scope**:
  * Execution log critic & strategy proposal generator.
  * Evaluation runner (GAIA / held-out task test suite).
  * 1-click strategy rollback mechanism.
  * Security lock enforcing control-layer immutability during self-improvement.
  * Flutter UI: Strategy Evolution Dashboard, Benchmark Comparison charts, Strategy Diff Viewer.
* **Out of Scope**: External cluster distribution.

---

## Phase 4: Hardening, Longitudinal Testing & Release
**Goal**: Comprehensive red-teaming (prompt injection attacks), longitudinal benchmark validation, and final platform packaging.

* **In Scope**:
  * Automated security red-teaming test suite (adversarial prompt injections).
  * Longitudinal multi-session testing to prove strategy improvement stability.
  * Full platform build: Android APK, Standalone Desktop executable, Web build.
  * Final documentation and deployment guides.
