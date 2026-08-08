# Coding Standards & System Rules — FindWell

## 1. Coding Conventions & Code Style

* **Python Standard**: Adhere strictly to PEP 8 with mandatory type hints (`typing` / modern `|` syntax). Use `ruff` for linting and formatting.
* **Flutter/Dart Standard**: Adhere to official Dart style guidelines. Use `flutter_lints` with strict typing (`final` fields, explicit return types).
* **Async Safety**: Never perform blocking I/O on the main event loop. All external network calls, database reads, and file ops must be async (`async/await`).
* **Immutability**: Data transfer objects (DTOs), evidence units, and strategy configurations must be immutable (`@dataclass(frozen=True)` in Python, `freezed` or `final` fields in Dart).

---

## 2. Package & Library Preferences

### Recommended
* **Python**: `fastapi`, `pydantic v2`, `httpx`, `playwright`, `sqlite3` / `aiosqlite`, `chromadb`, `pytest`.
* **Flutter**: `flutter_riverpod`, `go_router`, `dio`, `hive_flutter`, `flutter_markdown_plus`, `google_fonts`.

### Prohibited / Avoided
* **Do NOT use raw `eval()` or `exec()` in host process**: Code execution MUST happen exclusively within the disposable Docker sandbox container.
* **Do NOT use synchronous HTTP libraries** (e.g., `requests` in main async pipelines). Use `httpx` or `dio`.
* **Do NOT hardcode credentials or API keys**: Store keys in OS secure storage (`flutter_secure_storage`) or environment variables (`.env`).

---

## 3. Security Boundary & Injection Defenses

* **Untrusted Input Rule**: All external data—web page text, HTML, PDFs, user uploads, API responses—MUST be treated as untrusted data.
* **Prompt Injection Isolation**: Never directly concatenate untrusted web content into system prompts without passing through the `UntrustedSanitizer` parser.
* **Control Layer Protection**: The self-evolution module may only update versioned strategy files or skill prompt overlays. **It is strictly forbidden from overwriting core Python engine source files.**

---

## 4. AI Assistant Hard Constraints (What AI Must NEVER Do)

1. **NEVER touch trusted core code during self-evolution runs**: Core orchestration logic (`findwell_core/security/`, `findwell_core/sandbox/`) is immutable at runtime.
2. **NEVER bypass approval gates for external actions**: File deletion, external API posting, credential access, or money/payment endpoints require explicit human confirmation.
3. **NEVER fabricate citations or statistics**: If evidence is missing or ambiguous, output explicit uncertainty ratings rather than generating unverified assertions.
4. **NEVER skip unit tests**: All new modules must have matching test coverage in `tests/`.
