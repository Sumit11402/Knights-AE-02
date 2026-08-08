# CodeRush 2.0 | Team Project Repository

## Project Information

- Team Name: Knights
- Project Title: FindWell – Secure Self-Evolving Autonomous Research Agent
- Track/Theme: AE-02 – Advanced Agentic Systems Challenge

## Project Description

FindWell is a secure, self-evolving autonomous research agent that converts complex questions into evidence-backed and reproducible research packages. It plans investigations, searches webpages, PDFs and datasets, executes code inside an isolated sandbox, connects claims with citations, and records an auditable action trace.

Unlike ordinary research chatbots, FindWell can improve its retrieval prompts and tool-selection strategies. Every proposed improvement is tested on held-out tasks, versioned, approved and made reversible through rollback. Untrusted instructions found inside websites or documents are detected and blocked to prevent prompt-injection attacks.

## Technical Stack

- Frontend: Chrome Extension using HTML, CSS and JavaScript; Flutter/Dart mobile application
- Backend: Python 3.11+, AutoResearchClaw-based 23-stage research pipeline
- Database: Supabase/PostgreSQL and JSON/JSONL project-memory artifacts
- AI APIs: OpenAI, Google Gemini and Anthropic Claude
- Research Tools: Crawl4AI, Tavily, DuckDuckGo, OpenAlex, Semantic Scholar and arXiv
- Document Processing: PyMuPDF
- Sandbox and Testing: Docker, Pytest and isolated execution environments
- Other Tools: Git, GitHub and NumPy

## Setup and Installation


### 1. Clone the repository

```bash
git clone https://github.com/marotipatre/x402-Project.git
```

```bash
cd Knights-AE-02
```
---
### 2. install dependencies

```bash
npm install
```
---
### 3. Start the web app 
```bash
npm run dev
```
---
you will usually see something like 
```bash
local https://localhost:5173/
```
---
## App


### 1. Clone the repository

```bash
git clone https://github.com/marotipatre/x402-Project.git
```








