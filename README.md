# Gym Log

Local-first, offline Android workout log for logging weight, reps, RIR, and
rep-range work. Flutter app, Persian-first RTL, English LTR, no account, no
backend, no analytics, and no `INTERNET` permission in release builds.

Status: **M8 photos**. The four-tab shell, dark theme, fa/en
localization, Vazirmatn font, pinned toolchain, CI guardrails, exercise
library, program/day/plan-item planners, the Workout tab's active-session
logging (units, numeric normalization, prefill, RIR/warm-up, finish), history
with session detail and editing, the Progress tab with derived personal
records, Epley e1RM, per-exercise charts, double-progression suggestions, full
JSON export, validated Merge/Replace import, historical fixtures, the
export reminder, Persian/Latin digits, Jalali display behind `CalendarService`,
Saturday-first Persian weeks, and the digit/increment Settings controls exist.
Sessions persist in the interim app-private JSON document with private,
EXIF-stripped photo files alongside it; the Drift database and release signing
are later milestones. The `applicationId` is a
placeholder and release builds are intentionally refused.

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the pinned Flutter/Android
toolchain, first-time setup, commands, and the release guard.

```sh
flutter pub get
(cd packages/lift_core && dart pub get)
flutter gen-l10n
flutter test
flutter build apk --debug
```

Full gate (same lane as CI):

```sh
bash scripts/verify.sh
```

## Structure

```text
lib/app/          bootstrap, router, theme tokens, locale state
lib/core/         localization, CalendarService, shared widgets and guards
lib/features/     shell, workout, programs, history, progress, photos, settings
packages/lift_core/  pure Dart domain package (guard-enforced)
test/             unit, widget, contrast, golden tests
android/          pinned Flutter Android host and release guards
tool/             guards and pinned toolchain metadata
docs/spec/        product source of truth by requirement ID
docs/adr/         owner decisions
```

## Contracts

- Product: [docs/PRODUCT.md](docs/PRODUCT.md) and [docs/spec/README.md](docs/spec/README.md)
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Design: [docs/DESIGN.md](docs/DESIGN.md)
- Quality and verification lanes: [docs/QUALITY.md](docs/QUALITY.md)
- Dependency ledger: [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md)

## Working policy

Local-only on `main`: changes stay uncommitted in the working tree. Do not
commit, push, branch, open a PR, release, or mutate production. Never add
secrets or signing keys to the repository, logs, prompts, screenshots, or
artifacts.
