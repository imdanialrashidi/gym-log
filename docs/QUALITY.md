# Quality Contract

Evaluator-facing quality bar for meaningful changes. Keep project-specific after the first real feature; do not turn it into a generic checklist dump.

## Release rule

A change is not complete because the code compiles or the happy-path check passes. Every accepted behavior must be implemented rather than stubbed, exercised at the appropriate layer (real run, not opinion), and supported by evidence.

A required criterion that is unproven is **not passed**.

## Project status

M0 is implemented: pinned Flutter 3.47.7/Dart 3.13.5, Android minSdk 24,
dark fa/en RTL shell, four tabs with text-only empty states, theme token source,
Vazirmatn, contrast/golden tests, release-manifest guards, and a CI lane.
M2 adds the exercise library and program/day/plan-item planners backed by an
interim app-private JSON document. M3 adds the Workout tab logging slice:
canonical-gram kg/lb conversion, Persian/Arabic-Indic numeric input, prefill,
session start from a program day or empty, add-exercise/add-set, RIR and
warm-up flags, finish, and write-through active-session persistence in the
same document (schema v2). M3 also adds the history list with a trained-day
calendar, session detail, set and session editing/deletion, session and
per-exercise notes, and the optional in-app rest timer. M4 adds derived PR
detection, Epley e1RM with the ADR-0004 display thresholds, the Progress tab
and exercise progress detail with a custom-painter chart, range filter, RIR
gaps, and the subtle PR badge (ADR-0008). M5 adds the `INT-002`
double-progression rules in `lift_core` and a labeled, revertible set-row
suggestion with structured, localized reasons (ADR-0009). M6 adds full JSON
export through the system save UI, validated import with a dry-run summary,
Merge/Replace transactions with pre-Replace snapshots, round-trip and
historical-fixture tests, and the in-app 30-day export reminder. The Drift
database, system notifications, and background timer notifications do not
exist yet; the live workout bar is in-app only.
Deloads, periodization, set-count changes, and the optional RIR gate remain
out of scope.

M7 adds localization and accessibility polish: Settings digit and
default-increment controls, Persian/Latin digits across every screen and chart,
Jalali display behind `CalendarService` with Saturday week starts for Persian,
LTR/RTL goldens for every route, a directionality guard, 200% text/48 dp set-row
and chart tests, and a native-speaker review sheet with a CI coverage check.

M8 adds private photos: the system camera/gallery picker, a pending-target
marker and `retrieveLostData()` startup recovery, re-encode downscaling to
1600 px with every EXIF directory cleared, deterministic app-private files,
three-per-session limit with viewer/removal, an optional exercise photo in the
editor/detail/picker, orphan pruning, and JSON/backup exclusion checks. The
session-detail and photo-viewer surfaces have fa/en goldens; picker and
injected-failure behavior is covered by widget and real-file tests.

M9 adds the About screen (version, license, source, donation, privacy, and
medical-advice notice), the enforced-off Android backup policy row, CI
micro-benchmarks with hard budgets on a deterministic 10,000-set fixture, the
reference-device runbook, secrets-only release signing with a certificate
fingerprint check, checksum generation, the CHANGELOG/build/schema gate, and
the tag-triggered release workflow. About links are covered by widget tests with
a mocked launcher; `NFR-PERF-003` passes in CI, while device budgets and real
signing/upgrade drill remain owner steps. The project is at M9; Drift
persistence, schema-migration snapshots, and Safe Mode are not implemented.

Post-M9 owner pass (2026-10-26) adds the pre-session dashboard, body-weight
check-ins, the weekly summary, RIR explainer, a painted brand emblem, the
refreshed palette, the post-workout summary and its cat mascot, optional weekly
goals in document schema v4, the plate/warm-up calculator, and the night-session
visual system.
The new domain logic (weekly series, session/exercise stats, body-weight edits,
goal progress/streak, plate math, session records) has lift_core tests; the
document store has a v2→v3 test and a v3→v4 read/write test; body weight, weekly
summary, session summary, dashboard goals, plate sheet, and the redesigned
screens have widget and fa/en golden tests plus a 200% text sweep; and
`CI-STATS-001` guards the one-pass weekly aggregation (1.529 ms median vs
8.388 ms on the first measurement, floor 6 ms). The owner pass is a local
working-tree implementation, not a released build.

Device performance, process-death criteria, and the real Android system
share/picker remain `UNPROVEN` on this workstation; the reload-from-file test
is the available persistence proof, and the export codec is measured off the
UI thread. The body-weight chart's device paint time, dashboard cold start, and
history scroll on a physical device also remain `UNPROVEN`. Real camera/gallery flows, Android killing the activity mid-pick,
real signing/install-over-update, and real-device backup behavior are not
simulated.

- Product contract: `docs/PRODUCT.md`; requirements and statuses: `docs/spec/`.
- Stack and invariants: `docs/ARCHITECTURE.md`; visual contract: `docs/DESIGN.md`.
- Reference device, permanent `applicationId`, project name, and license are
  **Needs Decision**. Release builds are refused while the applicationId is the
  placeholder or signing secrets are absent. About states "All rights reserved"
  until the owner chooses and publishes a license. Device performance criteria
  remain `UNPROVEN`; `NFR-PERF-003` is proven by the CI fixture benchmark.
  Owner release steps live in `docs/RELEASE.md`.
- `scripts/project-verify.sh` is the canonical local lane; CI runs
  `scripts/verify.sh`, which executes it. Do not claim a lane ran unless the
  command output was observed.

## Functional completeness

For accepted scope:

- controls that imply behavior must actually perform that behavior;
- persistence must survive the lifecycle promised by the product;
- displayed state must come from the authoritative source rather than a convenient fake;
- required error, empty, loading, disabled, success, permission, retry, and recovery states must behave coherently;
- no accepted feature may be satisfied by a placeholder, TODO handler, mock response, display-only control, or hard-coded success path unless the contract explicitly says it is a prototype.

## Correctness

- Preserve domain invariants across success and failure paths.
- Validate external/untrusted data at boundaries.
- Handle retries, duplicate requests, time, rounding, ordering, partial failure, and concurrency where they are material to the changed behavior.
- A production bug should gain regression evidence when practical.
- Checks should assert behavior and contracts rather than implementation trivia.
- A new regression test should demonstrably fail on pre-fix behavior (or a safe focused mutation) when practical, then pass after the fix.
- Generated checks must build, pass reliably, add a distinct behavioral signal, and isolate relevant state; line coverage alone is not acceptance evidence.

`test-design` owns test-value decisions — apply it before adding or materially changing tests. `No new test` is acceptable for behavior-neutral changes or behavior the suite already proves.

## Mandatory test scope (project)

The project mandates automated tests in the areas below; the migration tests are spec-mandated, and all are acceptance evidence even where the workflow default would not require a new test:

- **Migrations and update safety (when the Drift layer lands; target design)** (`DAT-001`–`DAT-003`, plus a project-level Safe Mode test for the `DAT-004` Recommendation): committed schema snapshots, generated migration tests, a failing-migration test that proves the snapshot exists and the original database is byte-identical, and no destructive-reset path. Until then the active mandatory evidence is JSON import/export and the pre-Replace data-snapshot tests.
- **JSON import/export** (`IO-001`–`IO-006`, `DAT-006`): schema validation, round-trip equivalence, every historical fixture, truncated/corrupt/newer-version rejection, duplicate/orphan/absurd-value rejection, atomicity, and Merge/Replace behavior.
- **`packages/lift_core` domain logic** (`INT-001`–`INT-003`, unit conversion, digit/decimal normalization, PR detection): table-driven unit tests for rules, boundaries, mixed units, warm-ups, ties, and deletion recalculation.
- **Photo privacy and lifecycle** (`EXR-005`, `PHO-001`–`PHO-003`, `PHO-005`): a geotagged source verifies EXIF/GPS removal and downscaling, private-directory writes, the three-photo limit, no orphans after photo/exercise/session deletion and import prune, JSON/backup exclusion, no broad/storage/camera permission, cached-image eviction after replacement, and injected cancellation, unreadable, low-storage, write-failure, and lost-activity recovery paths.

Outside those areas, apply `test-design` and its test-value checks. `No new test` remains valid for behavior-neutral changes, and no test is added merely to satisfy a process rule. Never weaken, skip, or delete a valid test or control to obtain green status.

## Security and data integrity

For trust-boundary changes, apply the focused risk review below.

At minimum:

- authorization and ownership are enforced server-side;
- client-provided roles, prices, payment/subscription states, ownership, and permissions are never authoritative;
- secrets and sensitive data do not enter source, logs, screenshots, fixtures, prompts, or public artifacts;
- money/callback/state-transition operations are verified, idempotent, replay-aware, and auditable where applicable;
- schema/data changes have compatibility, rollback/recovery, and failure-path reasoning.

For this product there is no server: the equivalent trust boundary is the app sandbox, import validation, and the absence of network permission. Data ownership is local, and no client-supplied role or payment state exists.

### Focused risk review

Review only the accepted scope and actual diff. Trace changed trust boundaries, input-to-sink data flows, state transitions, public contracts, dependencies, and operational behavior; check the actual controls and checks before reporting a finding.

Check only relevant failure paths: authorization/tenant isolation, injection and unsafe files/URLs, credential/session handling, payment/replay/idempotency, races and partial writes, timeout/cancellation/recovery, unbounded work, inaccessible/error states, dependency/CI mismatch, migration rollback. For High-risk scopes prefer a `/review` pass and, when the runtime exposes a fresh-context `subagent`, independent review; otherwise perform a direct evidence-focused pass and report independent review as unexecuted.

For each evidence-backed finding give severity, exact `file:line` or symbol, a concrete failure/attack scenario, the impact if triggered, why the current control is insufficient, whether it is a regression introduced by this diff or `Pre-existing`, the smallest safe fix, and a proof check. Suppress speculative findings (no concrete scenario), duplicates, and purely stylistic findings. Prefer a few actionable findings over speculative checklist output.

- **BLOCKER:** exploitable security, data loss/corruption, money/access violation, migration/deployment breakage, or a broken critical flow.
- **MAJOR:** likely user-visible correctness/reliability failure or substantial security/performance regression.
- **MINOR:** bounded defect or maintenance risk.
- **NIT:** optional clarity/style improvement; never a release blocker.

Return the acceptance evidence and one verdict: `PASS`, `PASS WITH FIXES`, or `BLOCK`. `PASS` requires proven required criteria and no unresolved BLOCKER/MAJOR. Use `/review` for the complete review procedure.

## User-facing quality

For rendered interfaces:

- exercise the critical journey in the real application, or with a browser tool when the runtime exposes one and browser behavior matters; otherwise use widget/golden evidence and mark browser-dependent criteria `UNPROVEN`;
- preserve keyboard access, visible focus, semantic controls, labels, contrast, touch targets, and reduced-motion behavior;
- check realistic data, long text, localization/RTL when relevant, and at least one narrow viewport for mobile-facing surfaces;
- follow the accepted `docs/DESIGN.md`; reuse existing design tokens/components when sound, change deliberately when the direction requires it;
- do not add explanatory copy that merely restates obvious UI;
- visual polish cannot compensate for missing interaction depth or broken behavior.

Default accessibility baseline when the product has not chosen a stricter target: WCAG 2.2 AA, text contrast ≥ 4.5:1 (3:1 large text), non-text UI/state contrast ≥ 3:1, reflow at 320 CSS px, usable at 200% text zoom with visible focus and meaning not carried by color alone.

## Reliability and performance

Apply only where relevant to the changed path:

- avoid unbounded reads/work, N+1 access, duplicate calls, uncontrolled concurrency, blocking hot paths;
- use explicit timeouts/cancellation/retries where the boundary requires them;
- preserve meaningful non-sensitive logs or diagnostics for critical transitions;
- performance claims require a reproducible baseline and after-measurement;
- a flaky check or intermittent runtime path is a reliability defect, not permission to weaken the gate.

For production web surfaces without accepted product-specific field budgets, target Core Web Vitals `good` at p75 segmented by mobile/desktop: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1. Before field data exists, require an accepted repeatable lab budget plus rollout checks; lab results are pre-production signals, not field proof.

## Maintainability and architecture

- Prefer existing project patterns and stable framework/platform primitives.
- Keep public interfaces small and backward-compatible unless a breaking change is accepted.
- Keep business rules separable from presentation/transport when the existing architecture supports it.
- New abstractions should solve more than one real current use case or remove a demonstrated risk/duplication.
- New dependencies require a concrete benefit over existing/platform capabilities — the runtime already provides filesystem, shell, search, web, and optional subagents; adding a package that duplicates them needs justification.
- Architecture invariants that matter repeatedly should be enforced mechanically with types, lint rules, structural tests, schemas, or CI rather than prose alone.

## Evidence hierarchy

Prefer stronger evidence when practical:

1. deterministic automated check of the accepted behavior;
2. real `bash` run or browser-tool exercise of the relevant journey when available;
3. analyzer/type/lint/structural analysis for invariant classes;
4. reproducible measurement for performance/reliability claims;
5. focused independent-evaluator inspection (`/review`) for aspects that cannot be automated economically.

A reviewer or subagent opinion alone is not proof. Never report a test or check as passed unless its command was executed and its result was observed.

## Evaluator rubric

Judge the accepted contract, not adjacent scope. For each criterion return one of:

- **PASS** — implementation and evidence satisfy the criterion;
- **FAIL** — evidence demonstrates incorrect/incomplete behavior;
- **UNPROVEN** — implementation may exist but adequate evidence is missing;
- **BLOCKED** — a genuine prerequisite prevents verification.

The overall task cannot be called complete while a required criterion is `FAIL` or `UNPROVEN`, or while a required independent review has an unresolved BLOCKER/MAJOR finding.

## Project verification lanes

| Lane | Applies to | Required checks |
|---|---|---|
| **Documentation** | Docs, workflow, and repo-instruction changes | Requirement-ID set and definition-row losslessness, section coverage, internal links, `git diff --check`, scoped diff review. No app gate is required for docs-only work. |
| **Affected** | Ordinary change | `dart format --output=none --set-exit-if-changed …`, `flutter analyze --fatal-infos --fatal-warnings`, the exact targeted test or content assertion, then the nearest existing tests covering changed symbols. |
| **Feature** | Cross-module or user-facing slice | Affected lane plus the accepted journey at the appropriate layer: widget/golden, migration, fixture-import, manifest guard, or a real run. |
| **Full** | High-risk or release-bound work | `bash scripts/verify.sh` (template checks + `scripts/project-verify.sh` + debug APK) and the existing CI workflow. Never a parallel verification system. |
| **Device** | Performance, accessibility, backup, signing, camera/gallery | Profile-mode run on the owner-selected reference device; upgrade drill on a real device. `UNPROVEN` until selected and measured. |

### Canonical project commands

`scripts/project-verify.sh` runs, in order:

```sh
scripts/check_toolchain.sh
flutter pub get
(cd packages/lift_core && dart pub get)
flutter gen-l10n
dart format --output=none --set-exit-if-changed \
  lib/app lib/core/calendar lib/core/links lib/core/l10n/digit_style_scope.dart lib/core/l10n/l10n.dart lib/core/widgets lib/data lib/features \
  lib/main.dart test tool packages/lift_core
flutter analyze --fatal-infos --fatal-warnings
(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)
dart run tool/guards/check_l10n.dart
dart run tool/guards/check_fa_review_sheet.dart
dart run tool/guards/check_directionality.dart
dart run tool/guards/check_calendar_boundary.dart
dart run tool/guards/check_no_destructive_reset.dart
dart run tool/guards/check_changelog.dart
dart run tool/guards/check_no_signing_material.dart
dart run tool/guards/check_workflow_pins.dart
tool/guards/selfcheck.sh
(cd packages/lift_core && dart test)
flutter test
dart run tool/benchmarks/run_benchmarks.dart
flutter build apk --debug
tool/release/selfcheck.sh
(cd android && ./gradlew --console=plain :app:verifyReleaseManifest)
```

CI runs `bash scripts/verify.sh`, which executes that same lane after the
template self-checks. The Flutter archive and version are pinned in
`tool/toolchain.env`; CI verifies the archive SHA-256 before use.

### Mechanical guardrails

| Guard | Command | Fails when |
|---|---|---|
| Release manifest posture (`NFR-ARCH-001`, `DAT-007`, `PHO-001`) | `(cd android && ./gradlew --console=plain :app:verifyReleaseManifest)` | merged release manifest has `INTERNET`, broad storage/media location, `CAMERA`, `allowBackup` is not `false`, `fullBackupContent` is not `false`, or `dataExtractionRules` is missing |
| Placeholder release identity | `flutter build apk --release` or `(cd android && ./gradlew :app:verifyReleaseApplicationId)` (expected failure until owner decision) | `applicationId` starts with `com.example.` |
| fa/en resource parity (`L10N-002`) | `dart run tool/guards/check_l10n.dart` | a key or placeholder exists in only one locale, or a value is empty |
| fa review coverage (`L10N-010`) | `dart run tool/guards/check_fa_review_sheet.dart` | a fa key or its Persian text is missing from `docs/l10n/fa-review-sheet.md`, or the sheet has stale content |
| Direction-aware layout (`L10N-001`, `L10N-004`) | `dart run tool/guards/check_directionality.dart` | app code hard-codes physical left/right spacing, alignment, corners, or LTR text direction (chart excepted) |
| Calendar boundary (`L10N-005`) | `dart run tool/guards/check_calendar_boundary.dart` | any file except `lib/core/calendar/calendar_service.dart` imports `shamsi_date` |
| Pure domain package (`NFR-MNT-001`) | `(cd packages/lift_core && dart test)` | `lift_core` imports Flutter, database, platform, UI, or another package |
| No destructive reset (`DAT-002`) | `dart run tool/guards/check_no_destructive_reset.dart` | `deleteDatabase`, `DROP TABLE`/`DROP DATABASE`, or `PRAGMA writable_schema` appears in app/domain source |
| Performance budgets and floors (`NFR-PERF-003`, proxies for `005`/`006`) | `dart run tool/benchmarks/run_benchmarks.dart` | an expected benchmark ID is missing or duplicated, or a median on the 10,000-set fixture exceeds either its spec budget or its regression floor in `tool/benchmarks/thresholds.json` |
| Workflow pinning and toolchain (`NFR-MNT-002`) | `dart run tool/guards/check_workflow_pins.dart` | a workflow action uses a movable tag instead of a 40-hex commit SHA, or a workflow's Flutter version/archive/SHA-256 drifts from `tool/toolchain.env` |
| Changelog and version discipline (`DAT-008`) | `dart run tool/guards/check_changelog.dart` | a release entry lacks `Build:`/`Schema:`, build numbers do not increase, or the newest entry does not match `pubspec.yaml` |
| No signing material in the tree (`DAT-005`) | `dart run tool/guards/check_no_signing_material.dart` | a keystore/base64 keystore/`.pem`/`.key`/`.p8` file, `key.properties`, `signing.properties`, or `keystore.properties` exists; a private-key block appears; or a properties/env/shell file contains a literal signing password (placeholders starting with `$` or `<` are allowed) |
| Signing secrets only (`DAT-005`) | `(cd android && ./gradlew :app:verifyReleaseSigning)` | `GYM_LOG_*` signing values are missing, the keystore file is absent, or the keystore sits inside the repository |
| Release packaging tools | `tool/release/selfcheck.sh` | certificate-mismatch or checksum-mismatch detection stops working, or naming/checksum generation fails |

`tool/guards/selfcheck.sh` proves detection, not only a clean run: it copies the
guard-relevant tree to a temporary directory, runs every guard on the clean
copy, then introduces one known violation per guard and requires a non-zero
exit. It mutates nothing in the repository and runs in the project lane. The
release identity guard and release signing gate are intentionally red until the
owner supplies the permanent identity and secrets; the other guards are green
in `scripts/project-verify.sh`.

### Criteria that require a physical device

These remain `UNPROVEN` on this workstation and must not be claimed from
widget tests, goldens, an emulator, or a debug build:

| Criterion | Device proof required |
|---|---|
| `UI-001` | First launch on a physical device set to light system theme is dark (the widget test proves theme selection, not the device/splash path). |
| `NFR-COMP-001` | Install and launch on an API 24 physical device (or the owner-selected reference device). |
| `NFR-A11Y-001` | Text contrast, 48 dp targets, and 200% text scale on a real Android renderer. |
| `NFR-PERF-001..006` | Profile-mode cold start, tap-to-confirmation, prefill, chart, history scroll, and export measurements on the reference device. `NFR-PERF-003` is additionally proven by the CI fixture benchmark; proxies for `005`/`006` do not replace the device trace. See `docs/perf/`. |
| `DAT-007` / backup posture | Real-device backup behavior and data-extraction rules, not only the merged-manifest guard. |
| `DAT-005` / `DAT-008` | Owner signing, install-over-update, and upgrade drill on a real device. |
| Photos, camera/gallery, share/import (`PHO-*`, `IO-*`) | Real system picker/share behavior; real Android activity death and lost-data recovery; real Auto Backup behavior. Injected-failure and directory tests are the workstation proof. |

Risk tiers: data layer, migrations, import/export, photos, signing, and release workflow are **High** and require a reviewer pass (fresh-context `subagent` when available), the full gate, and a named human owner. Ordinary feature slices are **Medium**; docs/copy-only work is **Low** with the documentation lane.

## Project-specific quality invariants

These are project operating rules. Where the spec labels the underlying behavior **Recommendation** or **Assumption**, the rule is the target design/quality bar, not a product commitment; the spec status still governs acceptance.

- **Requirements:** every behavior change cites the requirement IDs it satisfies. Only **Confirmed** spec rows and explicit owner decisions are commitments; do not upgrade an Assumption/Recommendation by implementation or test wording.
- **Architecture direction:** `packages/lift_core` is pure Dart with no Flutter, database, platform, or UI imports (`NFR-MNT-001`, Confirmed). UI → controllers → repositories → Drift; features may depend on core, never the reverse.
- **Data (Section 21 target design; ADR-0002):** UUID stable IDs, UTC timestamps only, integer grams, history references exercises not plan items, PRs derived. Set writes commit immediately (Confirmed `LOG-001`); active-session survival across restart and process death is target design from the Recommendation `LOG-009`/`NFR-REL-001`.
- **Update safety:** never edit an existing migration (`DAT-001`, Confirmed); only add a step with a schema snapshot and tests. Never delete and recreate the database (`DAT-002`, Confirmed). Snapshot before migrating (`DAT-003`, Confirmed). Safe Mode never writes is target design from the Recommendation `DAT-004`.
- **Privacy and security:** release builds have no `INTERNET` permission; no analytics, ads, crash SDKs, or Firebase. No backend. Photos are private and EXIF-stripped, deleted with their session, excluded from JSON export (owner decision, ADR-0006), and excluded from Auto Backup by default (`PHO-002`/`PHO-003`/`PHO-005`, Recommendations). Photo files use deterministic entity names outside the data document; image paths and content are never logged. Secrets and signing keys never enter the repository, logs, prompts, screenshots, fixtures, or artifacts.
- **Dependencies:** exact pins with license, maintenance status, and size recorded before adoption. No package without a concrete benefit over platform capabilities.
- **Localization:** every user-facing string exists in `fa` and `en`; RTL is exercised on every screen; the chart time axis stays left to right; Persian copy is native-reviewed.
- **Accessibility:** text contrast ≥ 4.5:1, non-text controls ≥ 3:1, 48 dp targets, 200% text support, meaning never carried by color alone.
- **Performance:** budgets are measured in profile mode on the reference device; an unmeasured budget is `UNPROVEN`, not passed. Never claim a device result from an emulator or debug build.
- **Release:** owner-only signing; the two independent key backups are the `DAT-005` Recommendation; checksums, changelog including schema changes, pre-release for friends, and the Section 37.4 checklist. Agents never tag, release, deploy, or handle keys.
- **Evidence:** use `PASS`, `FAIL`, `UNPROVEN`, `BLOCKED`, `NOT EXECUTED` distinctly. A reviewer opinion, an exit-zero command, or an unseen screenshot is not acceptance proof.

## Release acceptance map

- Product scenarios A1–A18: [docs/spec/20-acceptance-and-checklists.md](spec/20-acceptance-and-checklists.md).
- Owner gates: G1 logging-speed friend test, G2 double-progression de-scope, G3 corrupt/large-file import, G4 budgets and drills.
- Delivery checklist: [Section 37.4](spec/20-acceptance-and-checklists.md#374-delivery-checklist-each-release).
- Owner runbook: [docs/RELEASE.md](RELEASE.md); performance evidence:
  [docs/perf/](perf/README.md).
- Product outcome: [docs/PRODUCT.md](PRODUCT.md).
