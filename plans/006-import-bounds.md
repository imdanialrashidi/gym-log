# Plan 006: Bound imported names and ordering values

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- packages/lift_core lib test docs/EXPORT_FORMAT.md` and
> `git diff --stat 852445e..HEAD -- packages/lift_core lib test docs/EXPORT_FORMAT.md`.
> Preserve unrelated uncommitted changes.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: security/data integrity
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

The import boundary rejects duplicate IDs, orphan references, bad numbers, and
absurd timestamps, but it does not bound free text or `sortOrder`. A backup
with a ~30 MB exercise name (four JSON containers, far under the 32 MB file
cap) is accepted; every later mutation then re-encodes that string, search
normalizes it per keystroke, and every export carries it. A maximum-magnitude
`sortOrder` is accepted too; the next `Add day`/`Add item` computes
`last.sortOrder + 1` and wraps/overflows, producing an error or an unusable
order. Notes are already capped at 2 000 characters, which is the pattern to
follow. This plan adds shared bounds, enforces them at the untrusted import
boundary and in the editors, and keeps existing on-device documents loadable
(do not reject data the app itself created before this change).

## Current state

- `packages/lift_core/lib/src/exercise.dart:58-60` — name only trimmed;
  `:82-89` — search term only trimmed; construction has no length cap.
- `packages/lift_core/lib/src/program.dart:26-28` — plan-item `sortOrder >= 0`
  only; `:106-111` — day name trimmed and `sortOrder >= 0` only; `:157-160` —
  program name trimmed only.
- `packages/lift_core/lib/src/session.dart:25-31` — notes capped at
  `maximumNoteLength`; use this pattern.
- `packages/lift_core/lib/src/backup.dart:404-425` — identity/reference
  validation; `:544-594` — timestamp validation; no text or order bounds.
- `lib/data/app_data_controller.dart:240,328` — `last.sortOrder + 1`.
- `lib/features/exercises/presentation/exercise_editor_screen.dart` — name and
  search-term fields have validators but no `maxLength`.
- `lib/features/programs/presentation/dialogs` — names come through
  `showNameDialog` (`lib/core/widgets/dialogs.dart`) with no length limit.
- `docs/EXPORT_FORMAT.md:44-46` documents ID/header bounds; update it with the
  new text/order limits.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Domain tests | `(cd packages/lift_core && dart test)` | all pass |
| Backup tests | `(cd packages/lift_core && dart test test/backup_test.dart test/backup_merge_test.dart)` | all pass |
| Import widget tests | `flutter test test/features/backup_settings_test.dart test/data/backup_import_rejection_test.dart` | all pass |
| Analyze | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| Domain analyze | `(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed packages/lift_core/lib packages/lift_core/test lib test` | exit 0 |
| Full gate | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope**:
- `packages/lift_core/lib/src/exercise.dart`, `program.dart`,
  `json_reader.dart` only if a shared bounded reader is useful,
  `backup.dart`
- `packages/lift_core/test/backup_test.dart`,
  `packages/lift_core/test/library_models_test.dart`
- `lib/features/exercises/presentation/exercise_editor_screen.dart`
- `lib/core/widgets/dialogs.dart` (optional `maxLength`)
- `lib/data/app_data_controller.dart` (safe next sort order only)
- `test/data/backup_import_rejection_test.dart`,
  `test/features/backup_settings_test.dart`
- `docs/EXPORT_FORMAT.md`

**Out of scope**:
- Changing ID rules, timestamp bounds, or the 32 MB/depth/container budgets.
- Rejecting existing on-device documents with long names.
- A migration of existing data; long names already on the device stay until
  edited.
- Changing the search normalization rules.

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Define the bounds in `lift_core`

Add public constants, with a comment that they are generous UI/import bounds,
not database limits:
- `maximumExerciseNameLength = 120`
- `maximumSearchTermLength = 200`
- `maximumProgramNameLength = 120`
- `maximumDayNameLength = 120`
- `maximumSortOrder = 1000000` (enough for any realistic day/item count; keep
  ordering well inside 64-bit arithmetic)

Put them where the model lives (`exercise.dart` for names, `program.dart` for
order) or in a small `limits.dart` exported by `lift_core.dart`. Do not make
the existing constructors reject values above the cap yet: `AppData.fromJson`
is used to load the on-device document, and rejecting old data would turn a
working install into a recovery screen. The cap is enforced at import and at
the editing boundary.

**Verify**: `(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)` → exit 0.

### Step 2: Enforce the caps during backup validation

In `backup.dart`, after decoding the entity lists and before/inside
`_validateIdentityAndReferences`, add a validation pass with field paths:
- exercise `name` > max → `BackupError(BackupErrorCode.absurdValue, field:
  'exercises[i].name')`; `searchTerm` > max → same for
  `exercises[i].searchTerm`.
- program `name`, day `name` → `absurdValue` with their paths.
- every `sortOrder` (program day, plan item, session exercise) must be in
  `0..maximumSortOrder` → `invalidField`/`absurdValue` with the path.
- Do not use `value:` for user text; the error copy must not echo a name or
  note. Use only the field path.
- Ensure the checks run before `AppData(...)` can write anything; parse still
  has no side effects.

**Verify**: `(cd packages/lift_core && dart test test/backup_test.dart)` → all pass.

### Step 3: Make the next-order calculation safe

In `app_data_controller.dart:240` and `:328`, replace the raw `last + 1` with
a helper that:
- returns `0` for an empty list;
- returns `last + 1` when it is `<= maximumSortOrder`;
- throws a `StateError` with a clear message when the maximum is already used.
The UI already maps controller errors to “save failed”; a genuine exhausted
order should not silently wrap. Imported data can no longer reach the maximum,
but a hand-edited document can; the check prevents a negative order.

**Verify**: add a controller test that seeds a day/item at `maximumSortOrder`
and asserts `addDay`/`addPlanItem` throw rather than produce a negative order.

### Step 4: Bound the editors

- `ExerciseEditorScreen`: add `maxLength: maximumExerciseNameLength` to the
  name field and `maxLength: maximumSearchTermLength` to the search-term field;
  add validators that reject over-limit text if a paste bypasses the counter.
- `showNameDialog`: add an optional `maxLength` parameter and pass it from
  program/day creation/rename call sites (`programs_screen.dart`,
  `program_editor_screen.dart`, `day_editor_screen.dart`). Keep the default
  unlimited only if all call sites pass a cap; otherwise make it required and
  update every caller.
- Do not add a length error string for every field; use the existing
  name-required/validation copy if the validator fires. If a new message is
  needed, add both fa/en and regenerate the review sheet.

**Verify**: `flutter test test/features/exercise_library_test.dart test/features/program_flows_test.dart` → all pass.

### Step 5: Add rejection and compatibility tests

- `test/data/backup_import_rejection_test.dart`: for each bound, build a valid
  backup JSON with one over-limit value and assert:
  - `parseBackup` throws the expected `BackupError.code` and field path;
  - the store is untouched when the UI path is used (the existing test pattern
    uses `MemoryAppDataStore`);
  - fa/en error copy is shown (one case is enough; the guard already checks
    parity).
- `packages/lift_core/test/backup_test.dart`: the same at the pure boundary,
  including a `sortOrder` of `maximumSortOrder + 1` and a max-int value.
- Compatibility: write a v2 on-device JSON with an over-limit name and load it
  through `AppData.fromJson`; it must still load (the model is permissive) and
  the editor must allow shortening it. Do not add an import path for that
  document in this plan.
- `library_models_test.dart`: the constants exist and the safe helper behaves
  at the boundary.

**Verify**: `(cd packages/lift_core && dart test test/backup_test.dart test/library_models_test.dart)` and `flutter test test/data/backup_import_rejection_test.dart` → all pass.

### Step 6: Update the format docs and run the gate

Add the new bounds to `docs/EXPORT_FORMAT.md` next to the ID/header limits.
State that older documents with longer names remain loadable. Run the full
table.

## Test plan

- Over-limit name/search/program/day → rejected import with a path-only error.
- `sortOrder` at the maximum accepted; above it rejected.
- Safe next-order throws at the maximum rather than wrapping.
- Existing on-device document with an over-limit name still loads.
- Editor maxLength prevents creating a new over-limit value.

## Done criteria

- [ ] Bounds are defined once in `lift_core` and used by import validation and editors.
- [ ] Import rejects every over-limit field with a typed `BackupError` and no write.
- [ ] `AppData.fromJson` still loads an existing document with a long name.
- [ ] `addDay`/`addPlanItem` never wrap at the maximum order.
- [ ] New rejection/compat tests pass; analyzer, format, and the full gate pass (or the prerequisite is `BLOCKED`).
- [ ] `docs/EXPORT_FORMAT.md` lists the bounds; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- Enforcing a bound in a model constructor is the only way to make the import
  reject it; that would break old on-device loads, so propose a compatibility
  path instead.
- A legitimate exported history fixture exceeds a proposed bound; raise the
  bound rather than truncating data.
- A new user-facing error string is needed but the fa review sheet cannot be
  regenerated; report `BLOCKED`.
- The live code does not match the excerpts (drift).

## Maintenance notes

- Bounds apply to untrusted import and new edits, not to existing stored data.
  If a future migration rewrites the document, it must preserve or deliberately
  shorten old names, not fail the load.
- Any new sorted entity must use the same bounded-order helper.
- A reviewer should check the error paths never echo a name or note value.
