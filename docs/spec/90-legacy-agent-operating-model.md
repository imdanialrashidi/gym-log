<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 24.
SUPERSEDED by the OMP workflow (AGENTS.md, docs/HARNESS.md, docs/QUALITY.md).
Kept verbatim for traceability; conflict resolution is in 91-omp-reconciliation.md.
-->

## 24. Agent Operating Model (placeholder pending your Workflow Guide)

Your Workflow Guide has not been received, so this section is a **Recommendation** to be reconciled with it.

### 24.1 Repository conventions

- `AGENTS.md` at the repo root (read by most coding agents): project purpose, **non-negotiable rules**, build/test commands, folder map, definition of done.
- `docs/spec/` contains this document split by module; `docs/adr/` holds short architecture decision records.
- Work is assigned by **requirement ID** (e.g. "Implement `LOG-001` and `LOG-010` per spec; do not touch other modules").

### 24.2 Non-negotiable rules for agents (draft)

1. Never edit an existing migration; only add new steps with tests.
2. Never add the INTERNET permission, analytics, ads, or crash-reporting SDKs.
3. Never add or upgrade a dependency without listing its license, maintenance status, and size, and pinning an exact version. (Recommendation: prefer releases that have been public for a couple of weeks, as a supply-chain precaution.)
4. Domain logic stays in the pure-Dart module; no Flutter or database imports there.
5. Every new user-facing string goes into both language files.
6. Every task ends with: tests passing, lints clean, and a short note of what changed and which requirement IDs it satisfies.
7. Never touch signing keys or secrets.

### 24.3 CI (GitHub Actions; Recommendation)

On every pull request: format check, static analysis, unit tests, migration tests, fixture-import tests, and a debug build. On tagged releases: a signed release build with checksums attached. **Verify current free-tier minutes and rules for public repositories** before relying on them (not verified in this pass).

---
