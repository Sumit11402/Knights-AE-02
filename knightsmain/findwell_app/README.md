# FindWell Mobile — Flutter Application

Cross-device mobile application for **FindWell — AI Research Assistant & Guide**.

## Features

- **Project Dashboard**: Track research projects, stages, paper collections, and draft sections.
- **4-LLM Multi-Model Engine**: Connects with Google Gemini, Groq (`llama-3.1-8b-instant`), and OpenRouter (`openrouter/auto`) with seamless failover.
- **Cross-Device Shared Memory**: Syncs with Supabase backend (`docs/supabase_schema.sql`) for unified chat history and paper libraries across mobile and browser extensions.
- **Interactive Chat**: Real-time research guidance, custom instructions, and paper summaries.
- **Literature Explorer**: Search arXiv papers, save references, and view abstracts.

## Getting Started

### Configuration & Credentials Requirement

`findwell_app` uses `const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '')` in `lib/models/settings.dart`. The application will **not** connect to Supabase cloud sync unless provided with the `SUPABASE_ANON_KEY` at build or run time.

#### Running & Building with `--dart-define`

You can pass the key directly on the command line:

```bash
# Run on connected device / emulator:
flutter run --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

# Build production Android APK:
flutter build apk --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

#### Best Practice: Using `--dart-define-from-file`

To avoid typing sensitive keys on the command line or leaving them in terminal history, use `--dart-define-from-file` with a gitignored configuration file (e.g. `env.json` or `.env`):

```bash
# 1. Create a gitignored env.json (or copy .env.example to .env):
# env.json content: { "SUPABASE_ANON_KEY": "YOUR_SUPABASE_ANON_KEY" }

# 2. Run using env.json:
flutter run --dart-define-from-file=env.json

# Or run using .env:
flutter run --dart-define-from-file=.env
```

## Architecture

- **State Management**: Flutter Riverpod
- **Routing**: `go_router`
- **Backend / Database**: Supabase Flutter SDK & REST API
- **HTTP Engine**: `dio` with custom retry & failover interceptors
