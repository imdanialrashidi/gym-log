# Changelog

All notable changes to Gym Log. Releases are newest first. Every versioned
entry carries `Build:` (the Android version code, which must increase for
every release) and `Schema:` (`none`, or the schema version/reason when the
persisted document changed). The release workflow marks schema-changing builds
as pre-release; see `docs/RELEASE.md`.

## [Unreleased]

No unreleased changes.

## [0.2.1] - 2026-10-28

Build: 3
Schema: none

### Added

- The active workout now keeps a finish action pinned above the tab bar, so a
  session can end from any scroll position without logging every prefilled set.
  Saved sets stay in history, empty rows are skipped, and the confirmation says
  so.
- The About screen names Danial Rashidi and links to danialrashidi.ir.
- `docs/sample-import/` ships a valid program-only backup and a one-page format
  guide so an AI can generate a program that imports cleanly.

## [0.2.0] - 2026-10-28

Build: 2
Schema: v4 (weekly goals and body-weight check-ins)

The document schema moves to v4: optional weekly goals (`weeklySessionGoal` /
`weeklySetGoal`) inside settings, on top of v3 body-weight check-ins. Older
v1–v3 documents are read with empty/default newer fields and rewritten as v4;
nothing is discarded. The backup format stays `schemaVersion: 1`; additive
fields are omitted while absent so historical fixtures keep round-tripping.

### Added

- Weekly body-weight check-in with a 12-week trend chart, latest change, and
  delete/Undo. One reading per week is updated in place.
- Weekly summary screen: sessions, volume, working sets, time, weight change,
  sets per muscle group, and previous weeks.
- Statistical Workout dashboard: this-week hero, seven-day activity strip,
  quick-start day cards, weight card, muscle split, and the last workout.
- Per-exercise set/volume/time meta in active logging, session detail, and the
  progress overview; session and exercise totals.
- Plain-language RIR explainer in the set row and on the RIR progress chart.
- Aperture brand mark, regenerated launcher/web/social kit, and a one-page
  brand sheet; refreshed achromatic palette; redesigned cards, charts,
  calendar, shell, and About lockup.
- Post-workout summary: volume hero, grouped records, muscle split, exercise
  breakdown, comparison with the previous session, and a way home.
- Monochrome engraved finish cat that says `تمرین تموم شد!` / “Workout done!”
  and a meow hint, with a reduced-motion-safe entrance.
- Optional weekly session and working-set goals with current-week progress,
  a calm streak, a dashboard block, and one editor sheet shared with Settings.
- Plate calculator and bar-first warm-up ramp for standard 20 kg/45 lb bars,
  launched per exercise with exact/remainder feedback.
- `CI-STATS-001` weekly-overview micro-benchmark.
- In-app live workout notification: a sticky bar across the four tabs names the
  current exercise, follows set progress, becomes the rest countdown, announces
  completion, and shows the next set.
- A running rest countdown now survives process death through a small local
  marker; it is cleared on dismiss, completion, finish, or a new session.
- Compact saved-set rows with weight × reps, RIR, warm-up, and PR badges, plus
  a per-exercise set-progress bar.
- A standalone palette handoff in `docs/PALETTE.md`.

### Changed

- The visual system is now **Obsidian Telemetry**: black and zinc achromatic
  surfaces, 0 dp corners, 1 px hairlines, pure white as the only action/PR/error
  signal, no gradients, glows, or shadows. The weekly ring is a square session
  gauge; charts are white hairline traces with dashed grids; Material pill
  switches are replaced by square toggles; the finish cat is a monochrome
  engraving. The cut-corner ledger and navy/electric-blue night-session
  languages are both superseded.
- The brand identity is the square **Aperture** mark (frame + calibration index
  + barbell). The launcher, favicon, web, social, and brand-sheet assets are
  regenerated from one Pillow script; the in-app mark is painted, not decoded.
- Typography keeps Vazirmatn for Persian-first coverage, but adopts the
  reference system's behavior: tabular display figures, tight display tracking,
  and wide-tracked Latin micro-labels. The old per-series chart colors are gone.
- Persian copy now separates `حرکت` (exercise) from `تمرین`/`جلسه`
  (workout/session), uses `ثبت` for set logging, and explains RIR in plain
  language; the native-speaker review sheet is regenerated.
- The live workout bar is sticky above every tab; the session clock now ticks
  once per second in a scoped label, so the hero, stats, and set rows are not
  rebuilt per second.
- A committed set rebuilds only its row and that exercise's stat strip; the PR
  map is computed once per session instead of once per exercise card.
- The active-workout list is lazy, unsaved drafts are kept alive across
  scrolling, and saved rows collapse to a compact summary.
- Startup resolves the support directory once, preloads the document alongside
  engine startup, caches the theme, and defers photo recovery to after the
  first frame.
- The first document load uses a static skeleton instead of a continuously
  repainting spinner.
- History calendar day cells are 48 dp at 360 dp width and session rows show
  duration/volume; the month summary shows sessions, volume, working sets, and
  time.

### Removed

- The navy/electric-blue night-session palette, gradient tokens, backdrop glow,
  rounded-panel geometry, the circular weekly gauge, the gold PR marker, and
  the per-series chart color argument. `logo-horizontal-navy.png` is replaced
  by `logo-horizontal-panel.png`.

### Fixed

- The active-session elapsed clock no longer freezes until the next document
  change; it advances on its own while the set rows stay still.
- Reopening the app mid-workout restores the active session, logged sets, and a
  still-running rest countdown.
- Older JSON fixtures still round-trip exactly after the schema extension.

### Notes

- The permanent `applicationId` is now `com.imdanialrashidi.gymlog`. Anyone
  running the earlier debug build must export, uninstall, and reinstall; a
  different identity cannot update in place.
- The project is MIT licensed and the About screen states `MIT`.
- The document schema changes to v4, so this build is published as a
  pre-release until the fresh-install round-trip and friend checks pass.

## [0.1.0] - 2026-10-25

Build: 1
Schema: v2 (initial document schema)

### Added

- Offline exercise library, programs, session logging with prefilled sets, RIR,
  warm-ups, history, and editing.
- Double-progression suggestions, derived personal records, and per-exercise
  progress charts with Jalali or Gregorian display.
- JSON export with validated Merge/Replace import, historical fixtures, and the
  30-day export reminder.
- Private session and exercise photos with EXIF metadata removed.
- Persian-first RTL and English LTR interfaces, Persian/Latin digits, and
  native-speaker review coverage.
- About screen with version, licenses, source, donation, and privacy notice.
- CI performance micro-benchmarks, release signing through repository
  secrets, checksums, and the owner release runbook.

### Notes

- Android Auto Backup is disabled in every build. Moving to a new phone
  requires a JSON export and import.
- The `applicationId` is still a placeholder, so release builds are refused.
- Device performance budgets remain unmeasured until the owner selects the
  reference device and runs `docs/perf/REFERENCE_DEVICE.md`.
