# Plan 007: Reject mutations whose parent record no longer exists

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- lib test` and
> `git diff --stat 852445e..HEAD -- lib test`.
> Preserve unrelated uncommitted changes.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: correctness
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

Several controller mutators locate a target by ID and, when the ID is missing,
rebuild an identical document and still perform the write. The UI receives no
exception, closes the editor, and shows success; the next load shows the old
value. This is reachable when an editor is left open across a Replace import or
a data change from another screen. The session mutators already use
`_requireSession`/`_requireSessionExercise` and throw; the exercise/program
mutators do not. This plan makes the missing-ID paths fail loudly so the
existing “save failed” snackbars surface the truth, and adds one test per
mutator.

## Current state

- `lib/data/app_data_controller.dart:161-171` — `updateExercise` drops an
  unknown ID and returns the caller's object as saved.
- `:205-217` — `renameProgram`; `:255-272` — `renameDay`; `:356-369` —
  `deletePlanItem(dayId, itemId)`; `:801-817` — `_replaceDay` returns an
  identical document when no day matches.
- `:745-762` — `_requireSession`/`_requireSessionExercise` are the existing
  pattern for throwing `StateError`.
- `:219-228` — `deleteProgram` silently keeps everything when the program ID
  is unknown; decide whether it should also throw (yes, for consistency).
- `:274-291` — `deleteDay` silently keeps the list when no day matches.
- Existing tests: `test/data/app_data_controller_test.dart` covers happy paths
  and uses `ProviderContainer.test`; `test/data/import_transaction_test.dart`
  uses `MemoryAppDataStore`/`FailingAppDataStore`.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Controller tests | `flutter test test/data/app_data_controller_test.dart` | all pass |
| Import tests | `flutter test test/data/import_transaction_test.dart` | all pass |
| Widget tests | `flutter test test/features/program_flows_test.dart test/features/exercise_library_test.dart test/features/history_test.dart` | all pass |
| Analyze | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test` | exit 0 |
| Full gate | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope**:
- `lib/data/app_data_controller.dart`
- `test/data/app_data_controller_test.dart`
- Any focused widget test that needs an updated expectation because a stale
  editor now shows the existing save-failed snackbar.

**Out of scope**:
- Changing UI copy or adding a new error dialog.
- Adding optimistic concurrency/version fields to the document.
- Changing the Replace/restore flow (plan 002).
- Changing any successful mutation path.

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Make the helpers strict

In `app_data_controller.dart`:
- Add `_requireProgram`, `_requireDay`, `_requireExercise`, `_requirePlanItem`
  helpers that throw `StateError('<Type> <id> does not exist')`, matching
  `_requireSession`.
- `updateExercise`: call `_requireExercise` before the update.
- `renameProgram`/`deleteProgram`: call `_requireProgram`.
- `renameDay`/`deleteDay`: call `_requireDay`.
- `deletePlanItem`: call `_requireDay` and `_requirePlanItem` (the item must
  belong to that day).
- `_replaceDay`: call `_requireDay` at the start; it then updates exactly one
  day. Do not change `_replaceDay`'s behavior for a valid day.
- `updatePlanItem`: keep `_dayIdForItem`; it already throws when the item is
  absent.
- Do not add a snapshot/write attempt before the throw; `_mutate` should not
  run at all for an invalid ID.

**Verify**: `flutter analyze --fatal-infos --fatal-warnings` → exit 0.

### Step 2: Add one negative test per mutator

In `test/data/app_data_controller_test.dart`, for each mutator (`updateExercise`,
`renameProgram`, `deleteProgram`, `renameDay`, `deleteDay`, `deletePlanItem`):
- Load an empty document (or seed one unrelated record).
- Call the mutator with an unknown ID, wrapping in `expectLater(..., throwsStateError)`.
- Assert the store's `saveCount` stayed 0 and its data is unchanged.
- For `deletePlanItem`, seed a day with one item and pass a different day ID;
  assert both the store and the controller state are unchanged.

Use a `MemoryAppDataStore` and `ProviderContainer.test` like the existing tests.
Do not assert on the error string beyond the type.

**Verify**: `flutter test test/data/app_data_controller_test.dart` → all pass.

### Step 3: Check the UI paths still report failure

Run the focused widget tests. If a stale editor test currently expects a
successful close, update it to expect the existing `saveFailed` snackbar and an
unchanged store. Do not add a new message.

**Verify**: `flutter test test/features/program_flows_test.dart test/features/exercise_library_test.dart test/features/history_test.dart` → all pass.

### Step 4: Run the gate

Run the table. If Flutter is unavailable, report `BLOCKED`; do not claim success.

## Test plan

- Every mutator with an unknown parent throws `StateError`, writes nothing,
  and leaves state unchanged.
- Valid mutations still pass the existing tests.
- A widget path that hits a stale ID shows the existing save-failed snackbar.

## Done criteria

- [ ] No in-scope mutator silently no-ops on an unknown ID.
- [ ] Unknown-ID calls throw before `_mutate` runs; `saveCount` stays 0.
- [ ] Existing happy-path and widget tests pass.
- [ ] Analyzer, format, and the full gate pass (or the prerequisite is `BLOCKED`).
- [ ] No out-of-scope files; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- A caller intentionally relies on a silent no-op (for example an idempotent
  delete retry); cite it before changing the contract.
- A widget test fails because the editor now stays open; that is the intended
  behavior, but report the exact test instead of weakening the check.
- The code does not match the excerpts (drift).

## Maintenance notes

- New mutators should use the same `_require*` pattern; a silent no-op is a
  correctness bug, not a convenience.
- This does not add optimistic concurrency: a stale but still-existing record
  still wins. The user-visible failure is only for a missing parent.
- A reviewer should verify that no write occurs before the existence check.
