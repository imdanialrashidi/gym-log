# Plan 004: Bound and measure the work done by one set confirmation

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- lib packages/lift_core tool test docs` and
> `git diff --stat 852445e..HEAD -- lib packages/lift_core tool test docs`.
> The working tree contains unrelated uncommitted changes; preserve them.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: 001 (they both edit `set_row.dart` / `workout_screen.dart`)
- **Category**: perf
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

`NFR-PERF-002` requires tap-to-confirmation ≤ 100 ms, and the design contract
says the check action gives immediate visible confirmation. Today one tap on a
prefilled set performs, in order: a whole-`AppData` revalidation via
`copyWith`, a `jsonEncode` of the whole document on the UI isolate, a file
write, and a full `personalRecordsForExercise` scan/sort across every session
— all before the row leaves its saving state. The existing 10 000-set
benchmarks cover prefill, chart aggregation, and export, but none covers this
path; the export codec alone measured 25.6 ms on the pinned workstation. The
full-document save is a known interim-store cost and is not changed here; this
plan removes avoidable per-tap work and makes the path measurable.

## Current state

- `lib/data/app_data_controller.dart:45-66` — `_mutate` calls `update`, then
  `store.save`, then publishes; `:516-573` — `logSet`.
- `lib/data/app_data_store.dart:70-89` — `save` serializes writes and
  `_write` executes `jsonEncode(data.toJson())` synchronously on the caller
  isolate.
- `lib/features/workout/presentation/set_row.dart:290-314` — `_check` keeps
  `_saving` true while awaiting `widget.onLog`.
- `lib/features/workout/presentation/workout_screen.dart:128-184` — `_logSet`
  awaits the write, then calls `personalRecordsForExercise` over all sessions
  and returns the new set's PR set; `:654-657` — every session-exercise card
  build calls `personalRecordsForExercise` again; `:664-669` — every empty row
  calls `prefillForExercise`, which re-scans all sessions through
  `latestSessionForExercise` (`packages/lift_core/lib/src/session_history.dart:14-26`).
- `packages/lift_core/lib/src/personal_records.dart:38-102` — the full scan and
  sort.
- `tool/benchmarks/run_benchmarks.dart:33-55` — existing metrics.
- `docs/perf/README.md` and `docs/perf/RESULTS.md` — the 10 000-set fixture and
  the `UNPROVEN` device rows.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Domain tests | `(cd packages/lift_core && dart test)` | all pass |
| Workout tests | `flutter test test/features/workout_test.dart` | all pass |
| Perf tests | `flutter test test/perf/benchmark_fixture_test.dart` | all pass |
| Benchmarks | `dart run tool/benchmarks/run_benchmarks.dart` | all budgets pass |
| Analyze | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed packages/lift_core/lib packages/lift_core/test lib test tool` | exit 0 |
| Full gate | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope**:
- `packages/lift_core/lib/src/personal_records.dart`
- `packages/lift_core/lib/src/prefill.dart`
- `packages/lift_core/lib/src/session_history.dart` (only if a helper is
  needed; prefer not)
- `packages/lift_core/test/personal_records_test.dart`
- `packages/lift_core/test/prefill_test.dart`
- `lib/features/workout/presentation/workout_screen.dart`
- `test/features/workout_test.dart`
- `tool/benchmarks/run_benchmarks.dart`, `tool/benchmarks/thresholds.json`
- `docs/perf/README.md`, `docs/perf/RESULTS.md`, `docs/perf/benchmark-baseline.json`

**Out of scope**:
- Replacing the JSON document store with Drift or changing its schema.
- Changing `NFR-PERF-002` or declaring a device result from workstation
  numbers.
- Changing PR/progression/prefill semantics.
- Optimizing progress or session-detail screens (plan 005).

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Add a single-set PR function in `lift_core`

Keep `personalRecordsForExercise` unchanged. Add:

```dart
Set<PersonalRecordType> personalRecordTypesForSet({
  required List<Session> sessions,
  required String exerciseId,
  required String setId,
});
```

It must return the same set of types the full map gives for `setId`, without
sorting or allocating the full map. One linear pass in chronological order is
acceptable; preserve every rule:
- warm-ups excluded;
- no external session (or first working set) is a baseline and earns nothing;
- ties are not PRs;
- `mostRepsAtWeight` needs a prior working set at the same exact weight;
- e1RM uses the existing estimate and only counts supports reps 1–12;
- ordering ties use the same `_compareEntries` order as the full function.
If the set ID is not found for that exercise, return an empty set (the caller
already validated the set exists; keep the function total).

Add table tests in `personal_records_test.dart` that call both functions for
every set in a fixture containing: first set, warm-ups, a tie, a weight PR, a
reps-at-weight PR, an e1RM PR, bodyweight, out-of-order `loggedAt`, and two
sessions with equal timestamps. The two functions must agree for every set.

**Verify**: `(cd packages/lift_core && dart test test/personal_records_test.dart)` → all pass.

### Step 2: Use it in `_logSet`

In `workout_screen.dart`, replace the full-map call at `:173-178` with
`personalRecordTypesForSet(...)` for `logged.id`. Keep the return shape
`SetLogOutcome(set: logged, personalRecords: ...)`. Do not change the save
order: the write still completes before the outcome is returned.

**Verify**: `flutter test test/features/workout_test.dart` → all pass.

### Step 3: Stop recomputing the card PR map on every build

In `_SessionExerciseCardState`:
- Add `late PersonalRecordsBySet _personalRecords;` and compute it in
  `initState` for `widget.sessionExercise.exerciseId`.
- Recompute in `didUpdateWidget` only when `!identical(oldWidget.data, widget.data)`
  or the exercise ID changed. Do not compute it in `build`.
- Use `_personalRecords` for the row badges.
- Keep the suggestion snapshot behavior unchanged.

Also cache the last working sets for prefill: in `initState`, compute
`late final List<SetLog> _lastWorkingSets = lastWorkingSetsForExercise(...)`
for the same exercise/session exclusion used by `_suggestion`; add a pure
`SetPrefill prefillFromWorkingSets({required List<SetLog> workingSets, required int setIndex})`
in `prefill.dart` (same rules as `prefillForExercise`, no session scan) and use
it for each empty row. Existing `prefillForExercise` remains for callers that
do not already have the working sets.

**Verify**: `flutter test test/features/workout_test.dart test/features/progression_suggestion_test.dart` → all pass.

### Step 4: Add benchmarks for the new path

Extend `tool/benchmarks/run_benchmarks.dart` and `thresholds.json` with:
- `single_set_pr` — `personalRecordTypesForSet` on the 10 000-set fixture for
  the last set;
- `full_pr_map` — the existing full `personalRecordsForExercise` (baseline for
  comparison);
- `document_validation` — `fixture.copyWith()` (the whole-AppData validation
  performed on every mutation).

Use the existing 3 warm-up / 15 measured / median harness. Start with a
generous budget (e.g. 100 ms) so the new entries cannot fail spuriously; the
point is to record a baseline. Run and append the results to
`docs/perf/RESULTS.md` with the exact command. Do not claim a device result.

**Verify**: `dart run tool/benchmarks/run_benchmarks.dart` → all pass and prints the three new rows.

### Step 5: Decide whether the encode needs to move off the UI isolate

Using the recorded `export_json` and `document_validation` medians:
- If `export_json` median is **≤ 50 ms** on the pinned workstation, do not
  move encoding in this plan. Record in `RESULTS.md` that the codec is not the
  dominant cost and that device measurement is still required.
- If it is **> 50 ms**, stop and report before optimizing. Moving `jsonEncode`
  to an isolate requires sending/copying the document and may be slower; it
  needs its own measured plan.

Do not change `JsonAppDataStore` in this plan.

### Step 6: Update docs and run the gate

Add the new benchmark rows to `docs/perf/README.md` and `RESULTS.md`, including
the explicit statement that none of these is `NFR-PERF-002` and that the tap
budget remains `UNPROVEN`. Run the full table.

## Test plan

- `personalRecordTypesForSet` equals the full map for every set in the complex
  fixture, including ties, warm-ups, bodyweight, and equal timestamps.
- `prefillFromWorkingSets` equals `prefillForExercise` for the same latest
  session and set index, including the “set index beyond length” fallback and
  empty handling.
- Workout widget tests: logging still returns the right PR badge, and a
  prefilled row still logs.
- Benchmark test: fixture remains 10 000 sets / 1 000 chart points.

## Done criteria

- [ ] `personalRecordTypesForSet` exists and agrees with the full map in tests.
- [ ] `_logSet` no longer calls the full map.
- [ ] The card computes its PR map in lifecycle, not `build`; tests still show the correct badges.
- [ ] Empty rows use the cached working sets for prefill; results match the old function.
- [ ] `dart run tool/benchmarks/run_benchmarks.dart` prints `single_set_pr`, `full_pr_map`, and `document_validation`; all budgets pass.
- [ ] `docs/perf/RESULTS.md` records the new medians and keeps `NFR-PERF-002` `UNPROVEN`.
- [ ] All focused tests, analyzer, format, and the full gate pass (or the prerequisite is `BLOCKED`).
- [ ] No out-of-scope files; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- `personalRecordTypesForSet` cannot match the full map without sorting; do not
  trade correctness for speed.
- The card’s PR badges depend on a rebuild that `didUpdateWidget` does not see;
  test the actual widget path and report before changing the data flow.
- The new benchmark cannot be added without changing the fixture shape.
- A benchmark median is above its budget on a quiet run; report the actual
  numbers rather than loosening semantics.
- The live code does not match the excerpts (drift).

## Maintenance notes

- The single-set function is a second implementation of the PR rules; the
  agreement test is the guard. Any PR rule change must update both functions
  and that test.
- The full-document save remains the structural risk; the Drift direction in
  `plans/README.md` is the long-term answer. Do not claim `NFR-PERF-002` from
  this plan.
- A reviewer should check that the card cache invalidates on every `AppData`
  identity change, including a Replace/restore.
