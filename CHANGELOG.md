# Changelog

All notable changes to Gym Log. Releases are newest first. Every versioned
entry carries `Build:` (the Android version code, which must increase for
every release) and `Schema:` (`none`, or the schema version/reason when the
persisted document changed). The release workflow marks schema-changing builds
as pre-release; see `docs/RELEASE.md`.

## [Unreleased]

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
