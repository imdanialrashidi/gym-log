# Plan 001: Preserve canonical grams when a weight field is confirmed unchanged

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- lib packages/lift_core test` and
> `git diff --stat 852445e..HEAD -- lib packages/lift_core test`.
> The working tree already contains unrelated uncommitted workflow and
> corrupt-document-recovery edits; do not revert them. Compare the excerpts
> below with the live files; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: LOW-MED
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

`formatWeight` displays at most two decimals, and `parseWeightInput` parses
that display text back to grams. That round-trip is exact only for the
*displayed* value, not for arbitrary canonical grams. In pound mode, 2 500 g
renders as `5.51` and parses back to 2 499 g; 100 000 g renders as `220.46` and
parses back to 99 999 g. The app therefore silently mutates stored weights and
increments whenever a field is confirmed without being edited: logging a
prefilled set, editing only RIR or the warm-up flag, renaming an exercise, or
confirming the default-increment dialog. Those grams feed PR detection and
double-progression increments, so the corruption is invisible but material.
The fix is to keep the original integer grams while the field still shows the
original formatted text, and to parse only when the user actually changed it.

## Current state

- `packages/lift_core/lib/src/weight.dart:81-151` — `parseWeightInput`; `:167-192` — `formatWeight`; the file comment at `:7-13` limits the round-trip guarantee to the displayed value.
- `lib/features/workout/presentation/set_row.dart:129-150` — `_applyInitialValues` formats grams into the text field; `:217` — `_parsedWeight` always parses the text; `:254-262` — `_stepWeight` formats a new value; `:290-314` — `_check` parses before calling `onLog`.
- `lib/features/workout/presentation/set_edit_dialog.dart:34-36` — seeds the weight field with formatted text; `:52-77` — parses it on Save.
- `lib/features/exercises/presentation/exercise_editor_screen.dart:61-66` — seeds the increment field with formatted text; `:112-118` — `_incrementGrams()` parses it; `:178-201` — writes that value on save.
- `lib/features/settings/presentation/settings_screen.dart:334-356` — opens the default-increment dialog; `:413-433` — seeds and parses the default increment. Confirming unchanged currently pins an explicit `defaultIncrementGrams` and loses the `null` “follow the unit” default.
- `packages/lift_core/test/weight_test.dart` — existing parser/format table tests; add cases there.
- `test/features/workout_test.dart` — existing widget test that logs a prefilled set; use its `MemoryAppDataStore` / `pumpGymLogApp` pattern.

Repo conventions: pure domain logic belongs in `packages/lift_core`; UI imports it. Use `//` comments only where the intent is not obvious. Formatting is enforced by `dart format`.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| lift_core tests | `(cd packages/lift_core && dart test)` | all pass |
| Focused weight tests | `(cd packages/lift_core && dart test test/weight_test.dart)` | all pass |
| Workout widget tests | `flutter test test/features/workout_test.dart` | all pass |
| Settings widget tests | `flutter test test/features/settings_localization_test.dart` | all pass |
| Analyze | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| Analyze domain | `(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed packages/lift_core/lib packages/lift_core/test lib test` | exit 0 |
| Full gate (final) | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope** (only these files):
- `packages/lift_core/lib/src/weight.dart`
- `packages/lift_core/test/weight_test.dart`
- `lib/features/workout/presentation/set_row.dart`
- `lib/features/workout/presentation/set_edit_dialog.dart`
- `lib/features/exercises/presentation/exercise_editor_screen.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- The focused test files listed in the test plan.

**Out of scope**:
- Changing `formatWeight` precision or the canonical-gram storage decision (ADR-0002).
- Changing `parseWeightInput`'s validation rules.
- Refactoring unrelated numeric fields (reps, RIR, target sets).
- Touching generated l10n files.

## Git workflow

- Work directly on `main` in the existing working tree; preserve unrelated changes.
- Do not create a branch, commit, push, or open a PR (`docs/GIT_POLICY.md`).
- Report the diff (`git diff --stat` and the focused diff) at the end.

## Steps

### Step 1: Add a pure “unchanged display keeps canonical grams” parser

In `weight.dart`, add a public function beside `parseWeightInput`:

```dart
/// Parses a weight field, but returns [originalGrams] exactly when the text
/// still equals the canonical value's two-decimal display.
///
/// This preserves integer-gram identity across a no-op editor confirmation.
/// Display rounding is not an input: only a changed string is reparsed.
WeightParseResult parseWeightField(
  String input, {
  required WeightUnit unit,
  int? originalGrams,
}) {
  if (originalGrams != null) {
    final String normalized = normalizeDigits(input).trim();
    if (normalized == formatWeight(originalGrams, unit)) {
      return WeightParseResult.valid(originalGrams);
    }
  }
  return parseWeightInput(input, unit);
}
```

Export it automatically through the existing `export 'src/weight.dart';` in
`packages/lift_core/lib/lift_core.dart` (no edit needed). Do not change
`parseWeightInput` or `formatWeight`.

**Verify**: `(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)` → exit 0.

### Step 2: Add failing regression tests for the pure helper

In `packages/lift_core/test/weight_test.dart`, add a group
`parseWeightField` with a table covering both units:
- `2500`, `99999`, `100000`, `80500`, `453592`, `1000000` grams and the
  maximum supported weight; for each, `parseWeightField(formatWeight(g, unit),
  unit: unit, originalGrams: g).grams == g` for `kg` and `lb`.
- The same inputs with Persian-digit text (`applyDigitStyle(..., DigitStyle.persian)`).
- A changed value (`2500` → `"5.52"` in lb) parses to the typed value, not the
  original.
- An invalid typed value still reports the same `NumberProblem` as
  `parseWeightInput`.
- `originalGrams == null` behaves exactly like `parseWeightInput`.

Run the test before wiring the UI. It should pass for the helper; the UI tests
in Steps 4–7 are the ones that fail on current behavior.

**Verify**: `(cd packages/lift_core && dart test test/weight_test.dart)` → all pass.

### Step 3: Use the helper in the set row

In `set_row.dart`:
- Add `int? _canonicalWeightGrams;` to `_SetRowState`.
- In `_applyInitialValues`, after computing `weightGrams`, set
  `_canonicalWeightGrams = weightGrams`.
- In `_revertSuggestion`, set `_canonicalWeightGrams = widget.initialWeightGrams`.
- In `_stepWeight`, after computing `next`, set `_canonicalWeightGrams = next`
  before writing `_weight.text`.
- Set the weight `TextField`'s `onChanged` (around line 621) to clear
  `_canonicalWeightGrams` when the user edits:
  `onChanged: (_) => setState(() { _weightError = null; _canonicalWeightGrams = null; })`.
  Do not add this to programmatic controller writes.
- Change `_parsedWeight` to:
  `parseWeightField(_weight.text, unit: widget.unit, originalGrams: _canonicalWeightGrams)`.
- In `didUpdateWidget`, when the unit changes for an unsaved row, preserve the
  canonical value instead of reparsing the old text: format
  `_canonicalWeightGrams` in the new unit when it is non-null; only parse the
  typed text when canonical is null. Saved rows already use
  `saved.weightGrams`; set `_canonicalWeightGrams = saved.weightGrams` there.

**Verify**: `flutter analyze --fatal-infos --fatal-warnings` → exit 0.

### Step 4: Use the helper in the set-edit dialog

In `set_edit_dialog.dart`, replace the parse in `_save` with:

```dart
final WeightParseResult weight = parseWeightField(
  _weight.text,
  unit: widget.unit,
  originalGrams: widget.set.weightGrams,
);
```

Do not change the RIR/warm-up handling. When only RIR or warm-up changed, the
weight text is unchanged, so the original grams are returned.

**Verify**: `flutter test test/features/history_test.dart test/features/workout_test.dart` → all pass after the new test in Step 8.

### Step 5: Use the helper in the exercise editor

In `exercise_editor_screen.dart`:
- Add `int? _originalIncrementGrams;`.
- In `_initialize`, set it to
  `exercise?.incrementGrams ?? data.settings.incrementFor(_unit)`.
- Change `_incrementGrams()` to use
  `parseWeightField(_increment.text, unit: _unit, originalGrams: _originalIncrementGrams)`.
- Keep the `grams > 0` check; a bodyweight-style zero increment is still invalid.

**Verify**: `flutter test test/features/exercise_library_test.dart` → all pass.

### Step 6: Use the helper in the settings default-increment dialog

In `settings_screen.dart`:
- `_DefaultIncrementDialogState._save` uses
  `parseWeightField(_value.text, unit: widget.unit, originalGrams: widget.initialGrams)`.
- In `_editDefaultIncrement`, before calling `setDefaultIncrementGrams`, read
  `final int? explicit = ref.read(appDataControllerProvider).requireValue.settings.defaultIncrementGrams;`
  and return early when `grams == currentGrams && explicit == null`. This keeps
  the `null` “follow the unit default” state when the dialog is confirmed
  unchanged; if the owner explicitly types the same number, the no-op is
  harmless.
- The dialog still returns `int?`; `null` remains cancel.

**Verify**: `flutter test test/features/settings_localization_test.dart` → all pass.

### Step 7: Add the UI regression tests

Add focused widget tests, using the existing support helpers:
- `test/features/workout_test.dart`: seed a completed session with a set at
  `100000` g, switch settings to pounds, start a new session from the same day,
  leave the prefilled fields untouched, tap the check action, and assert the
  stored set is exactly `100000` g (not `99999`).
- `test/features/history_test.dart`: open a session detail, edit a set, select
  a different RIR only, save, and assert the weight grams are unchanged.
- `test/features/exercise_library_test.dart`: edit an exercise name only in
  pound mode and assert `incrementGrams` is unchanged.
- `test/features/settings_localization_test.dart`: open the default-increment
  dialog and confirm unchanged; assert
  `data.settings.defaultIncrementGrams` is still `null` (when it started null).

Each test must use the real `AppDataController` and `MemoryAppDataStore` (as
the existing tests do), not a hand-built fake success.

**Verify**: the four focused test commands above → all pass.

### Step 8: Run the affected lane and full gate

Run the commands in “Commands you will need”. If the full gate cannot run
because Flutter/Dart are unavailable, report `BLOCKED` with the exact missing
prerequisite; do not claim the gate passed.

## Test plan

- Pure table test: exact canonical round-trip for kg/lb at boundary values and
  Persian-digit text; changed input parses; invalid input still invalid.
- Widget regression tests: prefilled set confirmation, RIR-only edit,
  exercise rename, unchanged default-increment dialog.
- Existing tests that must stay green: `weight_test.dart`,
  `workout_test.dart`, `history_test.dart`, `exercise_library_test.dart`,
  `settings_localization_test.dart`, and the golden tests (no intentional
  visual change; do not regenerate goldens).

## Done criteria

- [ ] `(cd packages/lift_core && dart test)` exits 0; the new `parseWeightField` table passes.
- [ ] The four focused widget test files exit 0 with the new regression cases.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` exits 0.
- [ ] `(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)` exits 0.
- [ ] `dart format --output=none --set-exit-if-changed …` exits 0 over the changed paths.
- [ ] A stored `100000` g set remains `100000` after logging a prefilled lb row and after an RIR-only edit.
- [ ] No file outside the in-scope list is modified (`git status`), excluding unrelated pre-existing changes.
- [ ] `plans/README.md` status row updated unless a reviewer maintains it.

## STOP conditions

Stop and report if:
- The live code at the cited locations does not match the excerpts (drift).
- `formatWeight`/`parseWeightInput` semantics differ from the examples above.
- A focused test cannot be written without changing an out-of-scope file.
- The full gate fails for a reason unrelated to this change; report the
  unrelated failure rather than editing unrelated code.
- You are tempted to change the display precision or the storage unit to make
  the round-trip exact; that is out of scope (`ADR-0002`).

## Maintenance notes

- Every future weight editor must use `parseWeightField` when it seeds a field
  from canonical grams; a raw `parseWeightInput` on a formatted field
  reintroduces the bug.
- A reviewer should check that no `parseWeightInput(_weight.text` remains in a
  save path that was seeded from `formatWeight`.
- Display-unit switching must never rewrite stored grams; the tests above are
  the guard.
