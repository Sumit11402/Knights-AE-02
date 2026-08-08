# FindWell — AI Chrome Extension (Manifest V3)

The official browser extension for **FindWell — AI Research Assistant & Guide**.

## Features

- **Instant Webpage Analysis**: Summarize articles, technical documentation, academic papers, and dynamic web pages in seconds.
- **Resilient Multi-LLM Engine**: Multi-provider failover chain supporting:
  - **Google Gemini API**: `gemini-2.0-flash`, `gemini-1.5-flash`
  - **Groq Cloud API**: `llama-3.1-8b-instant`
  - **OpenRouter AI**: `openrouter/auto`
- **Robust JSON Extraction**: Employs balanced-brace parsing (`parseJsonFromLLM`) to guarantee error-free structured responses.
- **Account Sync**: Cross-device shared AI memory with the FindWell mobile app (`findwell_app`) via Supabase authentication.

## Installation

1. Open Chrome and navigate to `chrome://extensions`.
2. Enable **Developer mode** in the top-right corner.
3. Click **Load unpacked**.
4. Select the `findwell_extension` directory.
