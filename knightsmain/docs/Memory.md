# Memory — FindWell Project Tracking

## Current Phase
**Phase 1: Core Foundation & Sandbox Integration**

---

## What Has Been Built
1. **Planning & Product Strategy**:
   - Created `/docs/PRD.md` (Self-Evolving Autonomous Research Agent requirements).
   - Created `/docs/Architecture.md` (System design, hybrid RAG, sandbox, security rules).
   - Created `/docs/Rules.md` (Coding standards, prompt injection containment rules).
   - Created `/docs/Phases.md` (4-milestone roadmap).
   - Created `/docs/Design.md` (UI dark glassmorphism system & color tokens).

2. **Complete Rebranding to FindWell**:
   - Renamed Flutter package to `findwell_app` in `pubspec.yaml`.
   - Replaced all imports across all screen, service, model, provider, and widget files to `package:findwell_app/`.
   - Updated UI text, header titles, app bars, and branding to **FindWell — Self-Evolving Autonomous Research Agent**.
   - Verified zero compilation errors via `flutter analyze`.

3. **Supabase Cloud Database & Vector Search Integration**:
   - Added `supabase_flutter` dependency.
   - Connected project instance `https://gjxycmdicnilsuwljxzy.supabase.co` with Service Role key (verified via HTTP test script).
   - Created `docs/supabase_schema.sql` (Tables: `projects`, `papers`, `draft_sections`, `chat_messages`, `evidence_units` with `pgvector` & Row-Level Security).
   - Configured pre-set Supabase credentials in `AppSettings` model, `StorageService`, and Settings UI.
   - Created `SupabaseService` for Auth, cloud project sync, and vector similarity search RPC calls (`match_evidence`).

3. **Flutter Client (Phase 1 Baseline UI)**:
   - Modern dark glassmorphism theme (`AppTheme.dark()`, `AppColors`).
   - Project Router (`GoRouter`) & Riverpod state management (`projectsProvider`, `settingsProvider`, `chatProvider`).
   - Research Outline Generator with expandable Markdown rendering.
   - Live arXiv literature search with paper card summaries & BibTeX citations.
   - Section-by-section academic paper draft generator.
   - Context-aware research Q&A chat interface.

---

## Key Decisions Made
- **Naming**: Complete pivot to **FindWell** across app branding, package configuration, codebase, and documentation.
- **Client Architecture**: Flutter cross-platform app (Web + Desktop + Android) using Riverpod, Hive local storage, and secure key storage.
- **LLM Integration**: OpenAI-compatible endpoint abstraction supporting local & cloud providers.

---

## What's Next
- Proceed with Phase 1 backend engine development (`findwell_core`) for sandboxed execution & untrusted input parsing.
