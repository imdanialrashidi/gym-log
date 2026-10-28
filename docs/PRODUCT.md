# Product Contract

Durable source of truth for what the product must do. Distilled from `docs/spec/`; requirement IDs and statuses remain authoritative there. Only rows labeled **Confirmed** in the spec are commitments. Owner decisions recorded in `docs/adr/` resolve only the points named in those ADRs.

## Product and release identity

- Product: a local-first, offline, no-account Android app for logging bodybuilding workouts.
- Working name: **TBD** (Needs Decision). It must be cleared before the first public release.
- `applicationId`: **TBD** (Needs Decision). A placeholder is allowed until the first release; after that it is permanent.
- License: **TBD** (Needs Decision).
- Price: free. A donation link appears in About and on the project site only; no ads, subscription, or in-app purchase.
- Distribution: signed APK through GitHub Releases (Confirmed). F-Droid, Cafe Bazaar, and Myket remain Needs Decision.
- Language: Persian primary with RTL; English also supported. Dark theme by default.

## Users and problem

- **Primary users:** the owner and gym friends first, then Persian-speaking lifters who find the project on GitHub or a local store. There is no growth target.
- **Context:** intermediate lifters on mid-range Android phones, training 3–6 days per week, phone in hand between sets, often offline.
- **Problem:** remembering last session's numbers and applying progressive overload is slow with notebooks and spreadsheets; many apps are account-based, ad-supported, paywalled, or not Persian-first.
- **Current alternative:** notebook, spreadsheet, or an existing tracker such as FitNotes. The closest direct competitor is FitNotes.
- **Why now:** the owner wants a free, open-source, Persian-first tool that is fast enough to use every session and safe across updates.

## MVP outcome

The MVP candidate is the scope in [Section 13](spec/02-scope-and-ux.md#13-mvp-definition-release-10), sequenced by the roadmap in [Section 33](spec/18-roadmap-budget-and-metrics.md#33-implementation-roadmap-and-milestones). It includes planned Should items; only the confirmed commitments listed below are binding, and Assumption/Recommendation items remain non-committal. The de-scope gate is explicit: if the schedule slips, ship 1.0 with prefill and PR detection, and move double progression to 1.1.

### Scope buckets

**MVP (Release 1.0).** Exercise CRUD/archive with an empty start and optional lookup; programs, ordered days, and plan items with a rep range; session logging with weight, reps, optional RIR, prefill, warm-up flag, and notes; history; per-exercise progress charts; rule-based prefill, double progression, and PR/e1RM; JSON export and validated import; migrations, pre-migration snapshot, Safe Mode, Auto Backup posture, and release discipline; Persian RTL and English, digit setting, Jalali display, kg/lb; session photos (max 3) and an optional exercise photo; signed APK releases.

**Confirmed commitments inside the MVP** include: `EXR-001`, `EXR-002`, `EXR-004`, `LOG-001`, `LOG-002`, `LOG-004`, `LOG-005`, `PLAN-001`, `PLAN-002`, `PLAN-004`, `INT-001`, `INT-002` (de-scope candidate), `INT-003`, `HIS-001`, `PRG-001`, `PRG-002`, `PRG-003`, `IO-001`, `IO-002`, the data-safety requirements labeled Confirmed in Section 23 (with `DAT-004` and `DAT-005`'s signing rules retaining their Recommendation labels), `UI-001`, `UI-002`, `SET-001`–`SET-004`, the donate link in `SET-005`, `EXR-005`, `PHO-001` with the owner-decided limit of 3, and `L10N-001`–`L10N-005`, `L10N-007`, and `L10N-010` as labeled in the spec. Owner decisions additionally settle `IO-003`, the `INT-003` thresholds, `L10N-009`, and `DAT-007`'s toggle.

**Planned but not commitments.** Rows labeled **Assumption**, **Recommendation**, or **Could** remain non-committal even when they appear in an MVP module. Notable examples: search normalization and muscle-group/increment settings (`EXR-003`, `EXR-006`, `EXR-007`), target RIR (`PLAN-003`), warm-up flag, notes, and rest timer (`LOG-003`, `LOG-007`, `LOG-008`), edit/delete and process-death survival (`LOG-006`, `LOG-009`), input normalization (`LOG-010`), single-program export (`PLAN-005`), volume chart and range filter (`PRG-004`, `PRG-005`), photo storage and deletion (`PHO-002`, `PHO-005`), Auto Backup exclusion for photos (`PHO-003`; its JSON export exclusion is owner-decided in ADR-0006), round-trip and fixture guarantees (`IO-004`, `IO-005`), and the accessibility and release-size recommendations.

**Future Phase.** CSV history export; plateau detection; deload suggestions; side-by-side photo comparison; biometric photo lock; supersets; import from other apps; home-screen widget and wear support; iOS. (Weekly muscle volume, body-weight check-ins, weekly goals, the post-workout summary, and the plate calculator moved out of this list on 2026-10-26 into the owner-requested extensions below.)

**Out of Scope (this phase), Section 15.** LLM or any AI model; free-text set entry and parsing; accounts, cloud sync, and social features; a bundled exercise library with images or videos; ads, subscriptions, and in-app purchases; analytics, crash-reporting SDKs, and Firebase; an in-app auto-updater; nutrition, calories, cardio, and GPS; tablet-optimized layouts, iOS, and web.

### Risk and validation

- **Riskiest product assumption:** logging a set is at least as fast as a notebook. If it is slower, stop adding features and redesign the set row (gate G1 / experiment E1).
- **Smallest experiments:** E0 store survey and E1 baseline timing before commitment; E2 friend pilot for two weeks with zero data-loss incidents.
- **Hard constraints:** Android phones only, Flutter, offline, no account, no backend, no telemetry. The minimum API 24 is the current Flutter floor and remains an **Assumption** in the spec. No deadline was provided; the roadmap gives hours-per-week scenarios.
- **Product success:** the owner and at least three friends use it as their main log; no data loss in any upgrade; Section 22 budgets met; a stranger understands the public repo in under five minutes.

## Owner-requested extensions (2026-10-26)

The owner requested a design and feature pass after M9. These are product
requirements for this working tree; they do not edit or relabel a spec
requirement row. Local IDs are separate from the spec prefixes.

| ID | Requirement | Acceptance |
|---|---|---|
| `BODY-001` | Weekly body-weight check-in: 20–500 kg in canonical grams, one reading per week updated in place, older weeks preserved; included in export/import. | Widget test logs, updates the same week, rejects an implausible value, deletes with Undo, and persists through the real controller. |
| `BODY-002` | Body-weight trend: 12-week chart with gaps, latest reading and change versus the previous check-in; entry point on the dashboard and Progress. | Goldens for both locales; chart starts at the first check-in; 200% text test. |
| `WEEK-001` | Weekly summary: sessions, volume, working sets, total time, weight change, and working sets per muscle group for the current week and recent weeks. | Goldens and widget test for the current week, muscle split, weight change, and session navigation. |
| `UI-004` | Home dashboard with this-week stats, seven-day activity, quick start, weight card, muscle split, and recent workout; RIR explainer in the set row; sticky rest timer banner. | Widget, golden, 48 dp, and 200% text checks; render-budget test proves one set commits without rebuilding the other rows. |
| `SUMMARY-001` | Finishing a session opens a summary: volume, duration, working sets, exercise count, grouped PRs, muscle split, per-exercise breakdown, and comparison with the previous session. | Finish-flow test, fa/en goldens, and a summary widget test with a previous session and a PR. |
| `GOAL-001` | Optional weekly session and working-set goals in schema v4, independently enabled, with current-week progress, a calm streak, and one editor sheet shared by the dashboard and Settings. | Domain goal/streak tests, dashboard/sheet widget tests, backup round-trip, 200% text. |
| `PLATE-001` | Per-exercise plate calculator with a mirrored per-side stack, exact/remainder status, and a bar-first 40/60/80% warm-up ramp for standard kg/lb bars. | Pure domain tests for kg/lb, below-bar and remainder cases; sheet golden and widget test. |
| `UI-005` | Obsidian Telemetry visual language: achromatic black/zinc surfaces, square hardlines, 1 px hairlines, white strike-point actions, square week gauge, tabular display numerals, white hairline charts, stamped finish seal, square toggles, and engraved finish cat across the dashboard, active workout, summary, Programs, History, Progress, Exercises, Settings, and About. The earlier navy/electric-blue night-session language is removed. | fa/en goldens for every changed screen; contrast/geometry test; 200% text sweep; visual review on the reference device remains `UNPROVEN`. |
| `UI-006` | Post-workout cat on the session summary is a monochrome engraved line drawing that says `تمرین تموم شد!` / “Workout done!” with a meow hint and a reduced-motion-safe entrance; it is the single deliberate levity exception. | Summary widget test for the en and fa lines; fa/en summary goldens; 200% text sweep. |
| `L10N-011` | Persian terminology and voice: workout/session `تمرین`/`جلسه`, exercise `حرکت`, logging `ثبت`, a plain-language RIR explanation, and one calm direct voice. | Regenerated native-speaker review sheet; fa widget/golden coverage. |
| `PERF-007` | Weekly overview is derived once per document revision/calendar day, with an early cutoff for older sessions. | `CI-STATS-001` benchmark: 1.529 ms median vs 8.388 ms first measurement; 6 ms regression floor. |
| `LIVE-001` | In-app live workout notification: a sticky bar above every tab names the current exercise and set progress, becomes the rest countdown, announces completion, and shows the next set. No system notification and no notification permission. | Widget tests for the exercise name, set progress, running rest, completion, and dismiss; rest marker restored after process death; fa/en goldens and 200% text. |
| `RESUME-001` | A running rest countdown survives process death in a separate local marker and restores only while it is still in the future; the active session and every logged set keep the existing durable-write behavior (`LOG-009`). | Restore widget test with an injected marker; store-cleared assertions on dismiss; existing active-session reload tests stay green. |
| `PERF-008` | Startup resolves the support directory once, preloads the document before `runApp`, caches the theme, and defers photo recovery until after the first frame. | Preload consumed once and retry-reloads test; focused widget/golden runs; `NFR-PERF-001` remains `UNPROVEN` until the reference-device profile run. |
| `UI-007` | Active-workout interaction: compact saved-set summaries, per-exercise set progress, a lazy card list, kept-alive unsaved drafts, and scoped repaint boundaries. | Workout widget tests for save/edit/delete, unit switch, 200% text, and one-row rebuild scope; regenerated `workout_active`/`workout_pr` goldens. |

These add no network, permission, account, analytics, or new dependency.
A system notification remains an explicit owner decision: it requires
`POST_NOTIFICATIONS`, a manifest-guard change, and a revision of the release
posture, so `LIVE-001` deliberately keeps the notification in-app.
Body-weight check-ins are scale readings, not a bodyweight-load model for
exercises; a set still stores its canonical external load in grams. Weekly goals are optional settings, not stored aggregates; the on-device document is
schema v4, and the backup format remains additive `schemaVersion: 1`.

## Must-have user flows

These flows describe the target experience. Where a flow depends on a Recommendation (for example Safe Mode), the requirement's spec status still governs acceptance; only Confirmed rows and owner decisions are commitments.

1. **First run:** open the app, no sign-in, Persian default on a Persian device, create or pick an exercise, and log the first set within 60 seconds.
2. **Log a session:** start from the next planned day or empty, see target sets and rep ranges, confirm prefilled weight/reps/RIR with one tap, adjust with steppers or typing, finish, and land on the post-workout summary showing volume, records, and the way home; a PR badge appears when earned.
3. **Review progress:** open history, session detail, and per-exercise charts for best-set weight, estimated 1RM, reps, and RIR; warm-ups are excluded and missing RIR is a gap.
4. **Protect data:** export a JSON backup through the system share/save UI, import it on a new phone with a dry-run summary, and see invalid or newer-schema files rejected without a data change.
5. **Recover safely:** a failed migration leaves a snapshot and the original database untouched; Safe Mode explains the problem in Persian and English and can export the raw database.
6. **Check in weekly:** log one body weight per week, see the trend and change, and read the weekly summary of sessions, volume, time, and sets per muscle.
7. **Keep a target:** set optional weekly session and working-set goals, see this week's progress and a calm streak, and change or remove the goal from one sheet.
8. **Load the bar:** open the plate calculator from an exercise, enter the target, and read the per-side stack and warm-up ramp; the math uses the standard kg or lb set and reports any remainder.

## Non-goals

The Section 15 exclusions above are product non-goals for this phase. Architecturally, the project also rejects a backend, cloud storage, user accounts, a second source of truth for PRs, and stored display units or Jalali strings.

## Acceptance criteria

The canonical scenarios are A1–A18 in [Section 37.2](spec/20-acceptance-and-checklists.md#372-key-acceptance-scenarios). The product-level gates are:

- [ ] Fresh Persian install is Persian, RTL, dark, sign-in-free, and shows an empty exercise list with a prompt (A1).
- [ ] Three logged sets survive a kill and reopen; the active session survives process death (A2, `LOG-009`).
- [ ] The next session prefills from the last one; a completed rep range produces an explainable weight suggestion; a heavier set produces a PR badge while the first set does not (A3–A7).
- [ ] Export → wipe → import restores full equality; truncated or newer-version files are rejected with no data change (A11–A13).
- [ ] A simulated failed migration leaves a snapshot, shows Safe Mode, and does not alter the original database (A15).
- [ ] A release manifest has no `INTERNET` permission, Auto Backup is off by default, and an APK signed with the same key updates over the previous version with history intact (A14, A18).
- [ ] Every screen works in Persian RTL and English LTR; text contrast is at least 4.5:1, touch targets are at least 48 dp, and meaning is never carried by color alone (A17, `NFR-A11Y-001`).

Feature-level acceptance criteria remain in the requirement tables. Scenarios that depend on a Recommendation (notably A15 Safe Mode and the `LOG-009` process-death extension) are target design; the requirement's spec status governs acceptance. Device-dependent criteria are `UNPROVEN` until measured on the owner-selected reference device.

## Security, privacy, and compliance constraints

Status: controls below are labeled when they come from a spec Recommendation; only Confirmed rows and owner decisions are commitments.

- **Data classification:** training history, logged weights/reps/RIR, and photos are private personal data. The app has no account and no server.
- **Critical access rules:** all data stays on the device. Release builds declare no `INTERNET` permission. No analytics, ads, crash-reporting SDKs, or Firebase. The only network hand-off is a user-initiated external browser for exercise lookup or the donation link. Export/share happens only through user action.
- **Photos:** app-private storage, downscaled, GPS EXIF stripping, and deletion with the session are spec Recommendations (`PHO-002`, `PHO-005`); photos are excluded from JSON export (owner decision) and from Auto Backup by default (spec Recommendation `PHO-003`), and never logged.
- **Android backup:** visible toggle, default off. Moving phones without it requires manual export/import, which the app documents.
- **Secrets and signing:** signing keys and passwords never enter the repository, prompts, logs, screenshots, fixtures, or artifacts. The `DAT-005` Recommendation calls for two independent offline backups. Agents never generate, read, store, or ask for them.
- **Retention/deletion:** no cloud retention. Uninstalling removes local data; the user can delete sessions, sets, and photos (target design; `LOG-006` and `PHO-005` are Recommendations); import is validated at the trust boundary.
- **External/payment providers:** none in the app. The donation link contains no payment code.

## Performance and UX budgets

| Budget | Target | Status |
|---|---|---|
| Cold start to interactive Workout screen | ≤ 1.5 s | Recommendation; reference device TBD, `UNPROVEN` |
| Tap ✓ to visible confirmation | ≤ 100 ms | Recommendation; `UNPROVEN` until profiled |
| Prefill query with 10,000 logged sets | ≤ 50 ms | Automated micro-benchmark required |
| History scroll with 10,000 sets | No visible jank; most frame build/raster times within 16 ms | Recommendation; device `UNPROVEN` |
| Chart first paint with 1,000 points | ≤ 200 ms | Recommendation; device `UNPROVEN` |
| JSON export of 10,000 sets | UI stays responsive; completes in a few seconds | Manual + automated; device `UNPROVEN` |
| Weekly overview aggregation on 10,000 sets | ≤ 100 ms; regression floor 6 ms | `CI-STATS-001` automated; scope is derivation only, not device first paint |

- **Device baseline:** Android API 24+ phones; reference device **TBD** (Needs Decision). Measure in profile mode on a physical device, not debug or an emulator.
- **Accessibility target:** WCAG 2.2 AA text contrast ≥ 4.5:1, non-text controls ≥ 3:1, touch targets ≥ 48 dp, usable at 200% text, meaning never by color alone.
- **Brand character:** calm, precise, quietly confident — like a well-kept training notebook, not a hype-driven gym app.
- **Locales and directions:** `fa` primary RTL and `en` LTR. Chart time runs left to right in both directions (ADR-0005). Vazirmatn, three weights.
- **Visual contract:** [docs/DESIGN.md](DESIGN.md).

## Measurement and operations

- **No telemetry by design.** Measurement is manual: E0 store survey, E1 timing, E2 friend pilot, E3 upgrade drill, E4 suggestion review against 20 real sessions, E5 performance runs.
- **Activation:** first set logged within 60 seconds, measured in the friend test.
- **Guardrails:** zero data-loss incidents; logging at least as fast as a notebook; all release manifests clean; friends actually use it.
- **Support/recovery:** Safe Mode with raw-database export and a copyable diagnostic report; JSON export/import as the last line of defense; export reminder after 30 days without an export; GitHub issues for feedback.
- **Release:** owner-only signing, checksums, changelog including schema changes, pre-release for friends, upgrade drill before each release.

## Open product decisions

- Project name, `applicationId`, and license are **Needs Decision**.
- Reference device is **Needs Decision**; performance claims stay `UNPROVEN` until it is chosen.
- Donation platform and distribution beyond GitHub are **Needs Decision**.
  About currently opens the repository owner's GitHub Sponsors URL
  (`lib/app/app_info.dart`); the owner must enable that profile or replace the
  URL before a public release. Distribution beyond GitHub remains open.
- The optional RIR gate, ZIP photo archive, CSV export, light theme, and exact Persian search-normalization rules remain open or unconfirmed as labeled in the spec. Chart rendering is resolved by ADR-0008 (custom painter).
- Target RIR, muscle-group tag, and rest timer are **Assumption**, not commitments.

See [the specification index](spec/README.md#open-decisions) and [Section 28](spec/21-open-decisions.md) for the full list.
