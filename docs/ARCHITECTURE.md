# Architecture Decisions

Durable constraints and decisions only. M0 was the scaffold and shell; the M2–M9 data, domain, and feature layers plus the interim JSON document store are implemented. Drift persistence, schema-migration snapshots, and Safe Mode remain target architecture. The current repository also contains the DSH Workflow and the seeded specification.

## Current system

- Runtime/platform: Flutter 3.47.7 stable, Android phones only, minSdk 24, compileSdk/targetSdk 36.
- Main modules: M0 implements `lib/app/` (bootstrap, router, theme, locale state), `lib/core/` (l10n accessor, shared widgets, date formatting), and `lib/features/` (shell, workout, programs, history, progress, settings). M2 adds exercise and program features plus `lib/data/` (interim document store and controller). M3 adds the Workout tab: set rows, session start/add/finish, settings unit control, and session persistence through the same controller; it also adds history (lazy session list, trained-day calendar, session detail), set/session editing and deletion, session and per-exercise notes, and the optional in-app rest timer. M5 adds the `INT-002` double-progression rules in `lift_core` and a labeled, revertible suggestion on set rows (ADR-0009). M6 adds `lib/data/backup_*`, full JSON export/import through the Android document UI, isolated JSON encoding/parsing, Merge/Replace transactions with pre-Replace snapshots, historical fixtures, and the export reminder. M8 adds private photos: up to three session photos with a viewer/removal, an optional exercise photo in the editor and picker row, EXIF-stripped downscaling, startup lost-pick recovery, and orphan pruning. M9 adds the About screen, the enforced-off Android backup policy row, CI micro-benchmarks and guard self-checks, the changelog/build/schema gate, and the tag-triggered release workflow. `packages/lift_core` holds the pure domain models, Persian search normalization, lookup URL builder, rep-range validation, reorder helpers, canonical-gram conversion and numeric parsing, prefill, session entities, note-limit validation, backup format validation/merge, and settings, with a CI-enforced purity guard. Post-M9 architecture pass: the document edit algebra now lives in `lift_core` (`session_log.dart`, `plan_edits.dart`, `exercise_edits.dart`, `settings_edits.dart`, `set_entry.dart`, `session_plan.dart`, `body_weight_edits.dart`); `lib/data/app_data_controller.dart` is the commit policy only (serialize, snapshot, durable save, publish, rollback, photo reconciliation); `lib/data/backup_flow.dart` owns the import/export protocol and `lib/features/backup/` its UI; `lib/app/document_gate.dart` and `lib/core/widgets/action_runner.dart` own the load/failure surfaces so screens only write their success builder; set rows are planned by `session_plan.dart` and logged sets return their derived PRs in the same commit. The 2026-10-26 owner pass adds pure derived-stat modules (`body_weight.dart`, `workout_stats.dart`, `weekly_goals.dart`, `plate_math.dart`), the session-record helper in `personal_records.dart`, the memoized `lib/data/training_overview.dart` provider, a painted brand emblem, the dashboard/body-weight/weekly-summary surfaces, the post-workout summary route, the plate/warm-up sheet, weekly goals in Settings, and the `features/body_weight/`, `features/goals/` folders. The visual layer moved to the night-session token/component system (rounded `AppCard`, `AppBackdrop`, weekly ring, tabular display type, and the painted finish cat). Set rows keep a narrow rebuild scope: the screen watches load/unit only, a per-card `_ExerciseStats` consumer watches its own session exercise, and the active hero watches the session aggregate.
- Data stores: the exercise/program/logging slices persist an atomic, versioned JSON document (schema v4: exercises, programs, sessions, bodyWeights, settings with optional weekly goals) in app-private storage; the target store remains on-device SQLite through Drift. Version 1 documents are read as empty history/default settings, version 2 as history with an empty check-in list, and version 3 as check-ins plus settings without goals; all are rewritten as version 4 without discarding anything. Body-weight check-ins remain a separate collection; one reading per week is updated in place, and exports include `bodyWeights` only when it is non-empty so historical fixtures still round-trip. Weekly goals are two optional integers in `settings`, so no new top-level collection or stored aggregate exists. When the M1 Drift layer lands it must import this document rather than discard it. The private `backups/` folder holds the last three data-file snapshots for pre-Replace imports; Settings lists and restores them. They contain only the JSON document, and Replace/restore delete photos that are not in the selected data set. Photos live as deterministic app-private files under `photos/` (`exercise_<id>.jpg`, `session_<id>_<slot>.jpg`) with no photo metadata in the data document, so JSON export cannot carry photo references; a small pending marker supports lost-activity recovery. Export/import uses the Android document UI and keeps reminder metadata in a separate local file.
- External services: none. The only network hand-off is a user-initiated external browser for exercise image lookup or the donation link. Import/export and photos use system UI.
- Deployment topology: signed APK distributed through GitHub Releases. A tag-triggered workflow builds with owner secrets, verifies the certificate fingerprint, and uploads `<name>-v<version>.apk` plus its SHA-256; schema-changing releases are marked pre-release first. No backend, no server, no account.

## Layer structure

```text
app/                 bootstrap, router, theme, document gate, dependency wiring
core/                database setup, localization adapters, CalendarService,
                     Flutter-facing unit adapters, action runner
data/                Drift tables, DAOs, repositories, export/import flow, photo storage
features/            workout, programs, exercises, history, progress, settings, backup, photos
packages/lift_core/  PURE DART: entities, document edits, progression, e1RM, PR detection,
                     row planning, unit conversion, digit/decimal normalization
test/                unit, migration, fixture-import, golden tests
integration_test/    TARGET (not present): key user flows
drift_schemas/       TARGET (not present): committed schema snapshots, one per version
docs/spec/           product source of truth
docs/adr/            owner decisions
```

Dependency direction:

```text
widgets → feature controllers (Riverpod) → repository interfaces → Drift data layer
                                      ↘ packages/lift_core (pure, no outward imports)
```

- `packages/lift_core` imports no Flutter, database, platform, or UI package. Pure normalization and conversion live there; `lib/core` only adapts them for the app.
- Data and features may depend on `lift_core`; `lift_core` depends on nothing outward.
- Adding a feature means a folder under `features/`, an additive migration only if data changes, and a pure function in `lift_core` where domain logic is involved (Section 25.1).
- `CalendarService` wraps Jalali display so the date library stays replaceable and never leaks into the database or export. Features call `context.formatDate` and `context.calendarMonth`; only `lib/core/calendar/calendar_service.dart` imports `shamsi_date`.

## Data model and invariants

The schema follows [Section 21](spec/11-data-model.md). Section 21 is a **Recommendation**: these are target design principles. Owner decisions (ADR-0002) and Confirmed requirements override where noted. Core entities: `Exercise`, `Program`, `ProgramDay`, `PlanItem`, `Session`, `SessionExercise`, `SetLog`, `BodyWeightEntry`, `SessionPhoto`, `AppMeta`. Derived (never stored) values include PRs, weekly stats, body-weight weeks, and exercise time.

- **Stable string IDs (UUIDs).** Merge import and historical fixtures rely on stable identity; array position is never identity.
- **UTC timestamps only.** Jalali is a display concern; no Jalali strings in the database or export.
- **Canonical weight in integer grams** (ADR-0002). Display kg/lb is a boundary conversion; stored data never changes when the display unit changes.
- **Notes are plain text capped at 2,000 characters** (`LOG-007`). Session and per-exercise notes serialize with their session; empty notes are stored as null.
- **The rest timer is in-app only** (`LOG-008`). It stores an end timestamp in memory and recomputes the remaining time from the clock, including after the app resumes; it never gates set logging and adds no permission.
- **History references exercises, not plan items.** Deleting or editing a program never changes logged history.
- **Personal records are derived, not stored, in v1.0.** PR state is recomputed by query so there is no second source of truth. Cache only if measurement shows a need.
- **Body-weight check-ins are canonical grams + UTC**, validated to 20–500 kg, and are separate from a set's external load. The weekly series uses the latest reading in each week; the app updates the current week's reading in place.
- **Weekly and session stats are derived in one pass**: `workout_stats.dart` buckets only sessions inside the requested window, and the overview is memoized by document identity and calendar day (`lib/data/training_overview.dart`). Nothing derived is persisted.
- **Additive evolution by default:** new nullable columns and new tables. A released schema version is immutable; only new migration steps are allowed.
- **Write-through:** each set write commits immediately (Confirmed `LOG-001`); there is no "save later" buffer. Active-session survival across restart and process death is target design from the Recommendation `LOG-009`/`NFR-REL-001`.
- **Indexes:** at least `SetLog(sessionExerciseId)`, `SessionExercise(exerciseId)`, and `Session(startedAt)` for prefill and charts.
- **No destructive recovery:** never delete and recreate the database to recover (`DAT-002`, Confirmed). Failure enters Safe Mode, which is target design from the Recommendation `DAT-004`.

## Trust boundaries and critical data flows

1. **JSON import (untrusted input).** File → parse and validate `schemaVersion`, `appVersion`, shape, IDs, references, and value ranges → dry-run summary → single atomic transaction. Invalid, truncated, duplicate-ID, orphan-reference, or absurd-value files are rejected with no data change. A newer `schemaVersion` is rejected with an "update the app" message. Unknown fields are ignored. Merge never silently overwrites; Replace snapshots first (ADR-0003).
2. **Photos.** System picker/camera → temporary cache → decode, apply orientation, downscale to 1600 px, clear all EXIF/metadata, re-encode JPEG → atomic rename into app-private `photos/`. No broad storage or camera permission. The data document never contains photo paths, so the export has no photo payload (ADR-0006). A pending target marker plus `retrieveLostData()` attaches a pick that survives Android killing the activity; a directory prune removes files for deleted sessions/exercises and interrupted temporary writes. Android Auto Backup stays disabled per `PHO-003`/`DAT-007`; deleting a session or photo removes its files per `PHO-005`.
3. **External browser hand-off.** Exercise lookup and donation open an external browser with a URL-encoded query. The app has no `INTERNET` permission in release builds; a failed launch shows a non-blocking message.
4. **Export.** User-initiated system share/save UI. The JSON contains exercises, programs, sessions, sets, body-weight check-ins when present, and data-relevant settings, plus top-level `schemaVersion`, `appVersion`, `exportedAt` (UTC), and `generator`. Stable IDs and explicit nulls; no photo payload. The `bodyWeights` field is additive in backup schema 1 and omitted while empty, so every historical fixture still round-trips byte-for-byte.
5. **Database open and migration.** Copy the database file including WAL/SHM to a private `backups/` folder with old and new versions in the name, keep the last three (Assumption), then migrate. If the snapshot cannot be written, do not start. A failure leaves the original byte-identical and shows Safe Mode, which never writes to the database and can export the raw file plus diagnostics (target design, `DAT-004` Recommendation).
6. **Release and signing.** The applicationId is permanent after the first release; updates require the same signing certificate. Signing keys and passwords are owner-only, never in the repository, prompts, logs, or artifacts. Release builds take signing values only from `GYM_LOG_*` environment values (CI secrets or an owner's shell), refuse to run without them, and have no debug-key fallback. A certificate-fingerprint check, SHA-256 checksum generation, and the CHANGELOG `Schema:` gate run before upload; schema changes publish as pre-release first (`docs/RELEASE.md`).

## Non-negotiable invariants

- No `INTERNET` permission in release builds; no analytics, ads, crash-reporting SDKs, or Firebase (`NFR-ARCH-001`, `NFR-SEC-001`).
- No backend, cloud sync, account, or LLM (`NFR-ARCH-001`, Section 15).
- Never edit an existing migration; only add a new step with tests (`DAT-001`).
- Never delete and recreate the database to recover (`DAT-002`).
- Snapshot before migration (`DAT-003`, Confirmed); Safe Mode never writes is target design from the Recommendation `DAT-004`.
- UUIDs for stable identity; UTC for time; integer grams for weight (target design, Section 21; grams owner-decided).
- History references exercises, never plan items; PRs are derived (target design, Section 21).
- Domain logic only in `packages/lift_core`; no Flutter or database imports there (`NFR-MNT-001`).
- Every user-facing string exists in `fa` and `en` (`L10N-002`).
- Exact-pinned dependencies with license, maintenance status, and size recorded before adoption.
- Photos stay private: deterministic app-private files, atomic writes, and metadata-free re-encoding implement the `PHO-002` Recommendation; JSON export exclusion is owner-decided (ADR-0006) and photo references are absent from the document by construction; Auto Backup exclusion is the `PHO-003` Recommendation; image paths and content are never logged.
- No secrets or signing keys in the repository, logs, prompts, screenshots, fixtures, or artifacts.

## Chosen patterns

Status note: Flutter/Android is Confirmed. Riverpod/go_router, integer grams, import modes, e1RM thresholds, chart axis, photos, and backup are owner decisions recorded in ADRs. Drift and the calendar library remain the spec's Recommendations or candidates; photo storage is implemented from the spec's Recommendations with the pinned `image_picker`/`image` packages. The M4 chart spike selected a custom painter (ADR-0008).

| Area | Decision | Why | Revisit when |
|---|---|---|---|
| UI framework | Flutter, Android phones only, API 24+ | Flutter/Android confirmed; API 24 is the current Flutter floor (Assumption); one codebase and fast iteration | Never without an owner decision |
| Database | Drift over SQLite | Typed queries, streams, generated migration tests (Section 25.2) | If migration tooling or Android support regresses |
| State management | `flutter_riverpod` | Testable feature controllers; owner decision, pinning conditional (ADR-0001) | License/maintenance verification fails |
| Navigation | `go_router` | Declarative routing; owner decision, pinning conditional (ADR-0001) | License/maintenance verification fails |
| Domain core | `packages/lift_core` pure Dart | Fast tests; UI changes cannot break progression/PR logic | If the core needs platform APIs, which would violate the dependency rule |
| Calendar display | `shamsi_date` `1.1.1` behind `CalendarService` | Replaceable; keeps Jalali out of storage and features (Section 26); `tool/guards/check_calendar_boundary.dart` enforces the import boundary | Maintenance or correctness problem; replace the adapter |
| Charts | Custom painter, no chart package (ADR-0008) | Measured 1,000-point/RTL spike; explicit gaps and LTR time axis; no new dependency | A required chart feature (tooltips, zoom, volume overlays) makes custom work uneconomical |
| Photo storage | Deterministic app-private files, system picker/camera, re-encode | Privacy, no broad permission, no export references, recoverable atomic writes | Platform picker behavior or file naming changes |
| Export/import | JSON + system share/picker | User-controlled, no storage permission, last line of defense | Format versioning proves insufficient |
| Migrations | Committed schema snapshots + generated tests | Directly serves update safety (`DAT-001`) | Drift tooling changes |

## Explicitly rejected complexity

- Backend, cloud sync, accounts, social features.
- LLM or any AI model; free-text set parsing.
- Bundled exercise library with images or videos.
- Analytics, crash-reporting SDKs, Firebase, ads.
- In-app auto-updater.
- Stored PR rows as a second source of truth.
- ZIP photo archive and CSV export in v1.0 (Future/Could).
- Supersets, a bodyweight-load model for exercises (body-weight check-ins are scale readings, not exercise loads), iOS, web, tablet layouts.
- A second state-management, routing, chart, or database framework.

## Operational baseline

- **Configuration/secrets:** no secrets in the repository. Signing material is owner-only with two independent backups (the `DAT-005` Recommendation); CI secrets, when they exist, are never printed. Agents never generate, read, store, or request keys.
- **Migrations (target design, not implemented):** when the Drift layer lands, `drift_schemas/` will hold one snapshot per version and migration tests will run in CI. The current store is the JSON document; the last three pre-Replace data snapshots are restorable from Settings and are the only current snapshot control. Opening an up-to-date database will run no migration code.
- **Backup and tested restore:** Replace snapshots first (owner decision, ADR-0003); JSON round-trip and per-release historical fixtures are target quality gates from the `IO-004`/`IO-005` Recommendations. Android Auto Backup is a manifest/build-time decision and stays disabled (`DAT-007`, A18). Settings shows the enforced-off policy row; it is not an operational toggle because Android provides no runtime opt-in, and `verifyReleaseManifest` fails if backup is enabled. Export reminder after 30 days (`SET-004`, Confirmed); moving phones requires JSON export/import, stated on About.
- **Logging/monitoring:** no analytics or crash SDKs. Safe Mode diagnostics (target design, `DAT-004` Recommendation) contain app/schema versions and error type only, never training data; image paths and content are never logged.
- **Rollback:** the database never downgrades. A newer database than the app shows the "update the app" Safe Mode variant (target design, `DAT-004` Recommendation). APK updates require the same applicationId and signing certificate; the upgrade drill is a release gate.

## Open architecture decisions

- File save/share package remains pending license/maintenance/size verification at pin time. `image_picker` and `image` are pinned and recorded in `docs/DEPENDENCIES.md`.
- **Backup toggle (resolved):** ADR-0007's runtime toggle is implemented as an enforced-off policy row because Android Auto Backup is build-time and `DAT-007`/A18 require the release manifest to keep `allowBackup="false"`. A future runtime opt-in requires a verified platform mechanism and an explicit ADR/guard revision; do not weaken the manifest guard.
- Flutter SDK is pinned at `3.47.7` (Dart `3.13.5`); upgrades require a new pin review.
- Project name, `applicationId` (placeholder `com.example.gym_log`; release refused), license, and reference device remain owner decisions.

See [Section 28](spec/21-open-decisions.md) and [the specification index](spec/README.md#open-decisions).
