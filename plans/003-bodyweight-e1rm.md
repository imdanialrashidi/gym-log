# Plan 003: Treat zero-load (bodyweight) sets as “no e1RM” instead of 0 kg

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- packages/lift_core lib/features/progress test` and
> `git diff --stat 852445e..HEAD -- packages/lift_core lib/features/progress test`.
> The working tree contains unrelated uncommitted changes; preserve them.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: correctness
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

Bodyweight sets are stored with `weightGrams == 0` and are explicitly supported
by the double-progression rules. `estimateOneRepMax` currently has no zero-load
case, so it returns an estimate of 0 g with normal confidence. Progress then
shows “best estimated 1RM: 0 kg” and draws a flat zero e1RM series, rather than
the gaps used for unsupported rep counts. That is a meaningless number presented
as a measurement. A zero-load set cannot have an Epley estimate; it has no
external load. Returning no estimate makes the existing null/gap rendering do
the right thing without changing weight handling.

## Current state

- `packages/lift_core/lib/src/e1rm.dart:20-50` — `estimateOneRepMax`; it rejects
  negative weight and reps outside 1–12, but has no `weightGrams == 0` case.
- `packages/lift_core/lib/src/progress.dart:140` — a 0 estimate becomes a point;
  `:150-154` and `:166-168` keep `bestOneRepMaxGrams = 0.0` and normal
  confidence.
- `lib/features/progress/presentation/exercise_progress_screen.dart:185` —
  feeds the value to the chart; `:295-298` — only `null` renders as
  `progressValueMissing`.
- `packages/lift_core/lib/src/progression.dart:73,180-193` — bodyweight is an
  explicit supported case; do not change it.
- `packages/lift_core/test/e1rm_test.dart` — existing table tests; add the zero
  case here.
- `packages/lift_core/test/progress_test.dart` and `test/features/progress_test.dart`
  — existing progress series and widget patterns.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| e1RM tests | `(cd packages/lift_core && dart test test/e1rm_test.dart)` | all pass |
| Progress tests | `(cd packages/lift_core && dart test test/progress_test.dart)` | all pass |
| Widget tests | `flutter test test/features/progress_test.dart` | all pass |
| Domain analyze | `(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)` | exit 0 |
| App analyze | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed packages/lift_core/lib packages/lift_core/test lib test` | exit 0 |
| Full gate | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope**:
- `packages/lift_core/lib/src/e1rm.dart`
- `packages/lift_core/test/e1rm_test.dart`
- `packages/lift_core/test/progress_test.dart`
- `test/features/progress_test.dart`
- `test/features/personal_records_ui_test.dart` only if an existing bodyweight
  expectation needs adjustment (prove it first).

**Out of scope**:
- Changing progression rule behavior for bodyweight.
- Changing how weight 0 is stored or entered.
- Adding a bodyweight flag or a new entity field.
- Changing e1RM thresholds for reps (ADR-0004).

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Return no estimate for zero load

In `e1rm.dart`, add the zero case before the formula:

```dart
if (weightGrams == 0) {
  // No external load, so Epley's load-based estimate is undefined. The UI
  // renders this as a gap, the same as reps outside the supported range.
  return null;
}
```

Update the doc comment to state that zero load returns `null`. Do not change
the negative-weight `ArgumentError` or the rep threshold behavior.

**Verify**: `(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)` → exit 0.

### Step 2: Add unit tests

In `packages/lift_core/test/e1rm_test.dart`:
- `estimateOneRepMax(weightGrams: 0, reps: 5)` is `null`.
- `estimateOneRepMax(weightGrams: 1, reps: 5)` is not null (a real, tiny load
  still estimates; do not generalize zero to “small”).
- The existing negative-weight throw and 1–12 threshold table stay unchanged.

In `packages/lift_core/test/progress_test.dart`, add a bodyweight session
(`weightGrams: 0`) and assert:
- `estimatedOneRepMaxSeries` has a point with `value == null` for that session.
- `bestOneRepMaxGrams` is `null` and `bestOneRepMaxConfidence` is `null`.
- `bestWeightGrams` still reports `0.0` (the set exists; only the estimate is
  absent).
- The reps and RIR series are unaffected.

**Verify**: `(cd packages/lift_core && dart test test/e1rm_test.dart test/progress_test.dart)` → all pass.

### Step 3: Add the widget expectation

In `test/features/progress_test.dart`, add or extend a bodyweight case:
- Open the exercise progress screen for an exercise with a 0 g working set.
- Assert the e1RM summary shows `progressValueMissing`, not `0 kg`.
- Assert the e1RM chart's empty/values state uses the existing gap path; do not
  add new copy.
- Keep the best-weight summary showing the 0 value for the set; only the e1RM
  card changes.

Use the existing `pumpGymLogApp` / `MemoryAppDataStore` pattern; do not mock the
progress aggregation.

**Verify**: `flutter test test/features/progress_test.dart` → all pass.

### Step 4: Run the affected lane and full gate

Run the table commands. If Flutter/Dart are unavailable, report `BLOCKED` with
the missing prerequisite; do not claim success.

## Test plan

- Zero-load e1RM returns null; tiny positive load still estimates.
- Bodyweight progress: null e1RM point, null best e1RM/confidence, unchanged
  best weight/reps/RIR.
- Widget: missing-value copy instead of “0 kg · Estimated”.
- Existing e1RM/progress/personal-record tests stay green.

## Done criteria

- [ ] `estimateOneRepMax(weightGrams: 0, …)` returns `null`.
- [ ] Bodyweight progress produces null e1RM points and a null best e1RM.
- [ ] The progress widget shows the missing-value copy for a bodyweight e1RM.
- [ ] `(cd packages/lift_core && dart test)` and `flutter test test/features/progress_test.dart` pass.
- [ ] Analyzer and format checks pass.
- [ ] `bash scripts/verify.sh` passes, or the missing prerequisite is `BLOCKED`.
- [ ] No out-of-scope files modified; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- An existing accepted requirement says a bodyweight e1RM must be displayed as
  0; cite the requirement instead of changing it.
- The progress UI uses `0.0` as a sentinel for “missing” anywhere; inspect and
  report before changing the representation.
- The code does not match the excerpts (drift).

## Maintenance notes

- If bodyweight load ever becomes a first-class field, the e1RM rule must be
  revisited; a real bodyweight load would make an estimate meaningful again.
- Keep the zero-load rule at the domain boundary, not in the chart widget.
- A reviewer should check that the PR badge and progression rules are
  unaffected; only the estimate is suppressed.
