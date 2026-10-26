# Plan 005: Derive progress and personal records in one pass per data revision

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- packages/lift_core lib/features test` and
> `git diff --stat 852445e..HEAD -- packages/lift_core lib/features test`.
> Preserve unrelated uncommitted changes.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: 004 (both edit `lift_core`; run 004 first)
- **Category**: perf
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

The Progress overview and session detail call the per-exercise derived-data
functions inside build loops. `prepareExerciseProgress` scans every session for
one exercise; `personalRecordsForExercise` scans every session and sorts the
exercise's entries. With E trained exercises and S sessions, the overview does
E full scans and allocates four series per exercise on every `AppData` publish,
and session detail does one full scan+sort per exercise. The app shell's
`IndexedStack` keeps the Progress branch mounted after first use, so this work
can run while the user is logging on another tab. The aggregation is
deterministic and can be grouped by exercise in a single session pass; this
plan makes that change without altering any series or badge semantics.

## Current state

- `lib/features/progress/presentation/progress_screen.dart:23` watches the
  whole `AppData` provider; `:49-53` calls `_summaries` in build; `:95-112`
  collects exercise IDs and calls `prepareExerciseProgress` per ID.
- `lib/features/history/presentation/session_detail_screen.dart:30` watches the
  whole provider; `:122-130` calls `personalRecordsForExercise` inside the
  exercise loop.
- `packages/lift_core/lib/src/progress.dart:89-127` — per-exercise scan and
  series construction.
- `packages/lift_core/lib/src/personal_records.dart:38-102` — per-exercise scan
  and sort.
- `lib/app/router.dart:32` — `StatefulShellRoute.indexedStack` keeps branches
  mounted.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Domain tests | `(cd packages/lift_core && dart test)` | all pass |
| Progress tests | `(cd packages/lift_core && dart test test/progress_test.dart test/personal_records_test.dart)` | all pass |
| Widget tests | `flutter test test/features/progress_test.dart test/features/history_test.dart test/features/personal_records_ui_test.dart` | all pass |
| Analyze | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| Domain analyze | `(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed packages/lift_core/lib packages/lift_core/test lib test` | exit 0 |
| Full gate | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope**:
- `packages/lift_core/lib/src/progress.dart`
- `packages/lift_core/lib/src/personal_records.dart`
- `packages/lift_core/test/progress_test.dart`
- `packages/lift_core/test/personal_records_test.dart`
- `lib/features/progress/presentation/progress_screen.dart`
- `lib/features/history/presentation/session_detail_screen.dart`
- Focused widget tests listed above.

**Out of scope**:
- Caching results in a provider keyed by data identity; this plan only removes
  the E× factor. A cache is a follow-up if measurement still shows jank.
- Changing chart, range, tie, warm-up, or PR semantics.
- Changing the session-detail layout or copy.
- The logging path (plan 004).

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Add a grouped progress aggregation

In `progress.dart`, add:

```dart
Map<String, ExerciseProgress> prepareExerciseProgressMap({
  required List<Session> sessions,
  required Iterable<String> exerciseIds,
  required DateTime now,
  ProgressRange range = ProgressRange.all,
});
```

Implementation rules:
- Compute the cutoff once.
- Build `Set<String> wanted` from `exerciseIds`.
- One pass over `sessions`; skip active sessions; for each
  `SessionExercise` whose ID is wanted, collect its `workingSets`.
- For each exercise with working sets, set `hasHistory = true`. If the session
  is before the cutoff, skip adding its best set (but keep `hasHistory`).
- Choose the best set with the existing `_compareBestSets` ordering.
- After the pass, sort each exercise's best sets exactly as the current
  function does and build the four series + best values with the existing loop.
- Return an empty `ExerciseProgress` for a wanted ID with no data. Add a
  private/const empty constructor or a helper; do not return `null`.
- Refactor the existing `prepareExerciseProgress` to call the map with a
  single ID and return its entry. This keeps one implementation.

**Verify**: `(cd packages/lift_core && dart test test/progress_test.dart)` → all existing tests pass.

### Step 2: Add a grouped personal-records computation

In `personal_records.dart`, add:

```dart
Map<String, PersonalRecordsBySet> personalRecordsForExercises({
  required List<Session> sessions,
  required Iterable<String> exerciseIds,
});
```

One pass over sessions/exercises/sets collects `_LoggedEntry` values per
wanted exercise; then sort each exercise's entries with `_compareEntries` and
run the existing baseline/PR loop per exercise. `personalRecordsForExercise`
becomes a one-ID call to this function. Preserve the existing empty-set entries
for non-PR sets and warm-up exclusion. Do not change tie/baseline rules.

**Verify**: `(cd packages/lift_core && dart test test/personal_records_test.dart)` → all pass.

### Step 3: Add equivalence tests

In `progress_test.dart`:
- Build a fixture with several exercises, warm-ups, active and finished
  sessions, mixed dates, and all four ranges.
- For each range, compare `prepareExerciseProgressMap(...)[id]` with
  `prepareExerciseProgress(...)` for every ID; assert equality of
  `hasHistory`, `sessionCount`, all four series (including null gaps), and the
  best values/confidence.
- Include an ID with no data and assert the empty result.

In `personal_records_test.dart`:
- Compare `personalRecordsForExercises(ids)` with per-ID
  `personalRecordsForExercise` for every ID and every set; assert identical
  maps, including empty sets and warm-ups.

These are the regression guard for the refactor; they must fail if a
grouping boundary changes results.

**Verify**: `(cd packages/lift_core && dart test test/progress_test.dart test/personal_records_test.dart)` → all pass.

### Step 4: Use the grouped functions in the screens

`progress_screen.dart`:
- In `_summaries`, first collect exercise IDs (existing loop), then call
  `prepareExerciseProgressMap(sessions: data.sessions, exerciseIds: ids,
  now: now)` once. Build `_ExerciseSummary` from the map; skip `!hasData`.
- Keep the existing sort by last date/name.

`session_detail_screen.dart`:
- Before the `ListView` children loop, collect the session's exercise IDs and
  call `personalRecordsForExercises` once. Pass the per-exercise map into
  `_ExerciseSection`; it already takes a `PersonalRecordsBySet`.
- Do not compute PRs inside the widget list.

**Verify**: `flutter test test/features/progress_test.dart test/features/history_test.dart test/features/personal_records_ui_test.dart` → all pass.

### Step 5: Run the gate and record the result

Run the table. Do not claim device frame budgets; `NFR-PERF-004` remains
`UNPROVEN`. If a benchmark exists for chart aggregation, rerun it and note
whether the grouped function changed the median; do not change its budget in
this plan (plan 008 owns the gate).

## Test plan

- Grouped progress equals individual progress for every exercise and range,
  including null gaps and empty data.
- Grouped PRs equal individual PRs for every set and exercise.
- Existing progress/history widget tests stay green; no golden changes.

## Done criteria

- [ ] `prepareExerciseProgressMap` and `personalRecordsForExercises` exist and are used once per screen build.
- [ ] Per-ID functions delegate to the grouped versions.
- [ ] Equivalence tests cover multiple exercises, ranges, warm-ups, active sessions, and empty IDs.
- [ ] `(cd packages/lift_core && dart test)` and the three focused widget tests pass.
- [ ] Analyzer and format checks pass; `bash scripts/verify.sh` passes or the prerequisite is `BLOCKED`.
- [ ] No out-of-scope files; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- The grouped result cannot match the individual result for a range or tie;
  preserve the existing semantics instead of “fixing” them.
- A screen needs data from a different provider or a cache to use the grouped
  function; do not add caching in this plan.
- The live code does not match the excerpts (drift).

## Maintenance notes

- Any new derived metric must be added to the grouped pass and the equivalence
  tests, or the two code paths will drift.
- The overview still recomputes when `AppData` changes, even offstage. If device
  measurement still shows jank, the next step is a memoized provider keyed by
  the `AppData` identity, not more per-screen caching.
- A reviewer should check that active sessions remain excluded and that null
  gaps are preserved exactly.
