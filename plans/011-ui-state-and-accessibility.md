# Plan 011: Fix the small UI state and accessibility defects

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
- **Depends on**: 001 (set-row error state) and 002 (backup dialog) for the
  files they touch; run it after both
- **Category**: UI/accessibility
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

Five small, concrete defects survive the audit: (1) two quick rest-duration
taps both compute from the same build snapshot, so they coalesce into one
15-second step; (2) the rest countdown is a live region that changes every
second, which can make a screen reader announce the timer for the whole rest;
(3) set-row validation errors are stored as localized strings, so switching
language leaves the old-language error on screen until the field changes;
(4) the backup/restore error dialog has non-scrollable content that can clip at
200% text; and (5) the plan-item editor silently ignores Save when both rep
fields are empty because both validators accept the both-empty case. Each is
small, user-visible, and has a focused test.

## Current state

- `lib/features/settings/presentation/settings_screen.dart:236-245` and
  `:263-272` — the ± buttons pass `data.settings.restTimerDurationSeconds ± 15`
  from the current build; `:377-389` — the async setter clamps and awaits the
  write with no pending state.
- `lib/data/app_data_controller.dart:418-427` — `setRestTimerDurationSeconds`
  validates 5–3600.
- `lib/features/workout/presentation/rest_timer.dart:129-130` — `Semantics(liveRegion: true)`
  wraps the whole banner; `:154-161` — the text is the per-second countdown;
  `:65-80` — the controller publishes every second.
- `lib/features/workout/presentation/set_row.dart:95-97` — `_weightError`,
  `_repsError`, `_saveError` are `String?`; `:296-301` and `:337` — assigned
  from `l10n` at failure time; `:113-127` — `didChangeDependencies` reacts to
  digit style but not locale.
- `lib/features/settings/presentation/backup_section.dart:512-517` —
  `_showBackupError` uses `AlertDialog(content: Text(message))`; the restore
  preview already uses `SingleChildScrollView` at `:454-457`.
- `lib/features/programs/presentation/plan_item_editor_screen.dart:69-94` —
  the rep validators return `null` when both fields are empty; `:107-119` —
  `_save` returns silently when a parsed field is null.
- Existing patterns: `test/features/rest_timer_test.dart`,
  `test/features/settings_localization_test.dart`,
  `test/features/backup_settings_test.dart`,
  `test/features/program_flows_test.dart`.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Rest timer tests | `flutter test test/features/rest_timer_test.dart` | all pass |
| Settings tests | `flutter test test/features/settings_localization_test.dart` | all pass |
| Workout tests | `flutter test test/features/workout_test.dart` | all pass |
| Backup tests | `flutter test test/features/backup_settings_test.dart` | all pass |
| Program tests | `flutter test test/features/program_flows_test.dart` | all pass |
| Analyze | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test` | exit 0 |
| Full gate | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope**:
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/data/app_data_controller.dart` (the relative rest-duration setter)
- `lib/features/workout/presentation/rest_timer.dart`
- `lib/features/workout/presentation/set_row.dart`
- `lib/features/settings/presentation/backup_section.dart`
- `lib/features/programs/presentation/plan_item_editor_screen.dart`
- Focused widget tests listed above and
  `test/data/app_data_controller_test.dart`.

**Out of scope**:
- Redesigning the rest timer, adding notifications, or persisting the timer.
- Changing the 5–3600 duration bounds.
- Changing the set-row validation rules or copy, except storing the problem
  instead of the localized string.
- Changing the import/restore flow; plan 002 owns it.
- Adding a new dependency.

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Make rest-duration changes relative and serialized

Add to `AppDataController`:

```dart
Future<void> adjustRestTimerDurationSeconds(int delta) {
  return _mutate((AppData data) {
    final int next = (data.settings.restTimerDurationSeconds + delta).clamp(
      minimumRestTimerSeconds,
      maximumRestTimerSeconds,
    );
    return data.copyWith(
      settings: data.settings.copyWith(restTimerDurationSeconds: next),
    );
  });
}
```

Because `_mutate` serializes, two taps are applied in order and each sees the
previous result. Change the Settings ± handlers to pass `-15`/`+15` instead of
an absolute value. Keep `setRestTimerDurationSeconds` for any non-UI caller and
keep its validation. The buttons may stay enabled; two taps now produce two
steps.

Add a controller test: seed 30 s, call `adjustRestTimerDurationSeconds(15)`
twice without awaiting the first, await both, and assert 60 s; at 5 s, a
`-15` clamps to 5 s.

**Verify**: `flutter test test/data/app_data_controller_test.dart test/features/rest_timer_test.dart` → all pass.

### Step 2: Stop announcing every tick

In `rest_timer.dart`, make the live region depend on completion:
- `Semantics(liveRegion: timer.finished, ...)`.
- Give the ticking text a stable semantic label such as
  `l10n.restTimerRunning(...)` without the per-second value, or wrap the
  countdown `Text` in `ExcludeSemantics` and put the value in the visible text
  only. Keep the final “rest complete” announcement.
- Do not remove the banner's visual countdown or the Stop action.

Add a widget test using a fake clock: while running, the banner has no live
region (or its semantic label does not contain the per-second text); when
finished, the complete state is a live region. If the test framework cannot
inspect `SemanticsData.liveRegion` directly, assert the semantics label and
document the limitation; do not claim a TalkBack result.

**Verify**: `flutter test test/features/rest_timer_test.dart` → all pass.

### Step 3: Localize set-row errors at build time

In `set_row.dart`:
- Replace `String? _weightError` / `_repsError` / `_saveError` with
  `NumberProblem? _weightProblem`, `NumberProblem? _repsProblem`, and
  `bool _saveFailed` (the save failure is a single existing message).
- In `_check`, store the problem enums; in `build`, map them through
  `_weightErrorText(context.l10n, problem)` + `context.digits`.
- For the save catch, set `_saveFailed = true`; build shows
  `context.l10n.saveFailed` (apply digits if needed).
- Clear the relevant problem when the user edits the field.
- Locale changes then re-render the current error in the new language and
  digit style without another failed submit.

Add a widget test: trigger an invalid weight, switch Settings to the other
language, return to the Workout tab, and assert the error text is in the new
language. Do not remount the route for the test.

**Verify**: `flutter test test/features/workout_test.dart test/features/settings_localization_test.dart` → all pass.

### Step 4: Make the backup error scrollable

In `backup_section.dart`, wrap `_showBackupError`'s `content` in
`SingleChildScrollView(child: Text(message))`, matching the restore preview.
Do not change the message mapping. Add a test at 200% text with a long
duplicate-ID message: the text is findable and the dialog does not overflow
(`tester.takeException()` is null). If the exact message is hard to trigger,
use the existing `backupErrorText` with a constructed `BackupError` and a
dialog harness.

**Verify**: `flutter test test/features/backup_settings_test.dart` → all pass.

### Step 5: Make the plan-item editor reject empty rep fields

In `plan_item_editor_screen.dart`, change `_validateRepMin` and
`_validateRepMax` so the both-empty case returns `l10n.errorEnterBothReps`
instead of `null` (the same key the exercise editor uses). Then `_save`'s
`if (sets == null || repMin == null || repMax == null) return;` becomes a
defensive branch only; the form prevents submission.

Add a widget test: open a new plan item, clear both rep fields, tap Save, and
assert both an error and that the editor stayed open / no store write
occurred. Keep the existing Persian/Latin input test green.

**Verify**: `flutter test test/features/program_flows_test.dart test/features/settings_localization_test.dart` → all pass.

### Step 6: Run the full gate

Run the table. If Flutter/Dart are unavailable, report `BLOCKED`; do not claim
a pass.

## Test plan

- Rest duration: two queued +15 taps produce +30; lower/upper clamp.
- Live region: running state is not a per-second live region; finished state
  is announced; Stop still works.
- Set-row error: language switch updates the visible error without a new
  submit.
- Backup error: long message scrolls at 200% text.
- Plan item: both-empty Save shows an error and does not close/write.

## Done criteria

- [ ] Two quick rest-duration taps each apply; values clamp to 5–3600.
- [ ] Only the finished rest state is a live region.
- [ ] Set-row errors are localized at build and follow a locale switch.
- [ ] Backup/restore error content scrolls.
- [ ] Empty plan-item rep fields show an error and do not silently no-op.
- [ ] Focused tests, analyzer, format, and the full gate pass (or the prerequisite is `BLOCKED`).
- [ ] No out-of-scope files; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- A semantics test cannot inspect live-region behavior and the behavior can
  only be asserted manually; mark the AT claim `UNPROVEN` and keep the code
  change, rather than inventing a result.
- The rest-duration relative setter conflicts with an existing caller that
  expects absolute semantics; report it before changing the contract.
- The set-row error state is also read outside `build`; refactor only with a
  test that covers that path.
- The live code does not match the excerpts (drift).

## Maintenance notes

- Functional/relative mutations are the pattern for any numeric control that
  can be tapped faster than a rebuild.
- Keep error state as data (problem/flag), not localized copy, so locale and
  digit-style changes are free.
- A reviewer should check the timer’s screen-reader behavior manually if a
  device is available; the code change alone does not prove an announcement
  policy.
