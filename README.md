# Gym Log

Local-first, offline Android workout log for logging weight, reps, RIR, and
rep-range work. Flutter app, Persian-first RTL, English LTR, no account, no
backend, no analytics, and no `INTERNET` permission in release builds.

Status: **M9 hardening and release engineering**. The four-tab shell, dark
theme, fa/en localization, Vazirmatn font, pinned toolchain, CI guardrails,
exercise library, program/day/plan-item planners, the Workout tab's
active-session logging (units, numeric normalization, prefill, RIR/warm-up,
finish), history with session detail and editing, the Progress tab with derived
personal records, Epley e1RM, per-exercise charts, double-progression
suggestions, full JSON export, validated Merge/Replace import, historical
fixtures, the export reminder, Persian/Latin digits, Jalali display behind
`CalendarService`, Saturday-first Persian weeks, the digit/increment Settings
controls, private photos, and the About screen exist. The post-M9 owner pass
adds a painted aperture brand mark and refreshed palette, a statistical dashboard,
weekly body-weight check-ins with a trend chart, a weekly summary with sets per
muscle group, per-exercise set/volume/time meta, and a plain-language RIR
explainer. The 2026-10-26 build pass adds the post-workout summary, optional
weekly goals with streaks, a plate/warm-up calculator, and improved Persian copy
(`حرکت` for exercise, `تمرین` for workout). The 2026-10-28 rebrand replaces the
night-session look with **Obsidian Telemetry**: an achromatic black/zinc
instrument surface, square hardlines, a white strike-point, the aperture brand
mark, and a regenerated logo/launcher/social kit. Weekly goals live in document
schema v4; the JSON backup format stays additive schema 1.

M9 adds CI micro-benchmarks with hard budgets on a deterministic 10,000-set
fixture, the reference-device runbook, secrets-only release signing with a
certificate-fingerprint check, checksum generation, the CHANGELOG/build/schema
gate, and a tag-triggered release workflow. Device performance budgets remain
`UNPROVEN` until the owner selects a reference device and records the run; real
signing and the upgrade drill also remain owner steps (`docs/RELEASE.md`).
Sessions persist in the interim app-private JSON document with private,
EXIF-stripped photo files alongside it; the Drift database is a later
milestone. The `applicationId` is a placeholder and release builds are
intentionally refused.

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
lib/features/     shell, workout (dashboard), body_weight, programs, history, progress, photos, settings
packages/lift_core/  pure Dart domain package (guard-enforced)
test/             unit, widget, contrast, golden tests
android/          pinned Flutter Android host and release guards
tool/             guards and pinned toolchain metadata
docs/spec/        product source of truth by requirement ID
docs/adr/         owner decisions
.dsh/skills/      project workflow skills (DSH)
```

## Contracts

- Agent workflow: [AGENTS.md](AGENTS.md) and project skills in [`.dsh/skills/`](.dsh/skills/)
- Product: [docs/PRODUCT.md](docs/PRODUCT.md) and [docs/spec/README.md](docs/spec/README.md)
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Design: [docs/DESIGN.md](docs/DESIGN.md)
- Brand kit: [assets/branding/README.md](assets/branding/README.md) · palette: [docs/PALETTE.md](docs/PALETTE.md)
- Quality and verification lanes: [docs/QUALITY.md](docs/QUALITY.md)
- Release and signing runbook: [docs/RELEASE.md](docs/RELEASE.md)
- Performance budgets and evidence: [docs/perf/](docs/perf/README.md)
- Dependency ledger: [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md)

## Working policy

Local-only on `main`: changes stay uncommitted in the working tree. Do not
commit, push, branch, open a PR, release, or mutate production. Never add
secrets or signing keys to the repository, logs, prompts, screenshots, or
artifacts.
