# Plan 002: Make Replace/restore honest and expose the pre-import data snapshot

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- lib test docs` and
> `git diff --stat 852445e..HEAD -- lib test docs`.
> The working tree already contains unrelated uncommitted workflow and
> recovery edits, including `restoreFromBackup`; preserve them. Compare the
> excerpts below with the live files; on a mismatch, treat it as a STOP
> condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: data safety
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

Every Replace import writes a copy of the current JSON document to an
app-private `backups/` folder before overwriting it. The code and
`docs/ARCHITECTURE.md` call that copy a recovery point, but there is no reader
or UI for it: the only recovery action offered is importing a user-selected
file. A user who picks the wrong Replace file cannot get the previous records
back. Worse, Replace and the new restore-from-backup path prune every photo
whose session is not in the imported document, while the copy says only that
photos are “not included” and that “a snapshot is saved first.” Photos are
deleted permanently and are not in the snapshot. This plan adds a visible,
confirmed restore for the data snapshots and makes the photo deletion explicit
in both locales. It deliberately does not add a photo trash/undo system; the
copy must stop implying that photos are recoverable.

## Current state

- `lib/data/app_data_store.dart:10-18` — `AppDataStore` exposes only `load`,
  `save`, and `snapshot`; no list/load of snapshots.
- `lib/data/app_data_store.dart:91-142` — `JsonAppDataStore.snapshot()` writes
  `backups/gym_log_data-<UTC>.json` and keeps the newest three. The JSON
  document is the only thing copied.
- `lib/data/app_data_controller.dart:74-89` — Replace calls `_mutate(...,
  snapshotFirst: true)` then `_prunePhotos`; `:114-134` — `restoreFromBackup`
  does the same after writing the recovery document.
- `lib/data/photo_storage.dart:414-426` — photos are separate app-private
  files; `pruneAndLoad` deletes every file whose session/exercise is not in
  the current identity set.
- `lib/features/settings/presentation/backup_section.dart:322` and `:486` —
  the only warning is “Photos are not included in JSON backups.”
- `lib/core/l10n/app_en.arb:422` — Replace copy: “Replaces all current data. A
  snapshot is saved first.” `app_fa.arb:238` is the equivalent.
- `docs/ARCHITECTURE.md:9` — says the private `backups/` folder holds
  pre-Replace snapshots; there is no restore path.
- Existing tests: `test/data/app_data_store_test.dart` covers snapshot
  retention; `test/data/import_transaction_test.dart:264-305` covers
  `restoreFromBackup`; `test/features/backup_settings_test.dart:329-441`
  covers the recovery widget tests. Use these as patterns.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Store tests | `flutter test test/data/app_data_store_test.dart` | all pass |
| Import transaction tests | `flutter test test/data/import_transaction_test.dart` | all pass |
| Backup widget tests | `flutter test test/features/backup_settings_test.dart` | all pass |
| Generate l10n | `flutter gen-l10n` | exit 0 |
| fa review sheet | `dart run tool/fa_review_sheet.dart` then `dart run tool/guards/check_fa_review_sheet.dart` | sheet regenerated; guard passes |
| l10n guard | `dart run tool/guards/check_l10n.dart` | passes |
| Analyze | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test` | exit 0 |
| Full gate | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope**:
- `lib/data/app_data_store.dart`
- `lib/data/app_data_controller.dart` (add the restore method/provider only)
- `lib/features/settings/presentation/backup_section.dart`
- `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_fa.arb`,
  `docs/l10n/fa-review-sheet.md` (generated)
- `test/data/app_data_store_test.dart`,
  `test/data/import_transaction_test.dart`,
  `test/features/backup_settings_test.dart`,
  `test/support/memory_app_data_store.dart`,
  `test/support/failing_app_data_store.dart`
- `docs/ARCHITECTURE.md` (the snapshot sentence only)

**Out of scope**:
- A photo trash/undo system or changing ADR-0006's photo-exclusion policy.
- Changing the JSON backup format.
- Restoring snapshots from the corrupt-document recovery screen; that path
  keeps using `restoreFromBackup` with a user-selected file.
- Any change to exported JSON contents.

## Git workflow

- Work directly on `main`; preserve unrelated working-tree changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Add snapshot metadata to the store interface

In `app_data_store.dart`, add a public value class and two methods:

```dart
class DataSnapshotInfo {
  const DataSnapshotInfo({required this.fileName, required this.savedAt});
  final String fileName;
  final DateTime savedAt;
}
```

Add to `AppDataStore`:

```dart
Future<List<DataSnapshotInfo>> listSnapshots();
Future<AppData> loadSnapshot(String fileName);
```

`listSnapshots` returns newest first, only files directly in `backups/`
matching the existing `gym_log_data-` prefix and `.json` suffix. Use
`await file.stat()` for `savedAt`; do not trust a clock encoded in the name.
`loadSnapshot` must reject any name containing `/`, `\`, `..`, or not matching
`^gym_log_data-.+\.json$`; resolve it under `backups/`, read the JSON, decode
it, and call `AppData.fromJson`. Wrap parse/read failures in
`DataStoreException` with a path-free message.

**Verify**: `flutter analyze --fatal-infos --fatal-warnings` → exit 0.

### Step 2: Implement the methods in `JsonAppDataStore`

Factor the `backups/` path calculation into a private helper used by
`snapshot()` and the new methods. `listSnapshots` must return an empty list
when the directory is absent (fresh install), not throw. `loadSnapshot` must
not create directories. Keep the existing three-snapshot retention untouched.

**Verify**: add store tests first (Step 6) and run them after this step.

### Step 3: Add the controller restore method

In `AppDataController`, add:

```dart
Future<void> restoreSnapshot(String fileName) async {
  final AppData restored = await ref
      .read(appDataStoreProvider)
      .loadSnapshot(fileName);
  await _mutate((AppData _) => restored, snapshotFirst: true);
  await _prunePhotos(state.requireValue);
}
```

The snapshot is loaded before the mutation chain so a corrupt snapshot writes
nothing. `snapshotFirst: true` snapshots the current document before the
restore, so the restore itself is reversible. Do not call this when the
controller has no value; the Settings entry point only renders when data is
loaded.

**Verify**: `flutter analyze --fatal-infos --fatal-warnings` → exit 0.

### Step 4: Add the Settings UI

In `BackupSection`:
- Add a provider for the list, e.g.
  `final FutureProvider<List<DataSnapshotInfo>> dataSnapshotsProvider = FutureProvider((ref) => ref.watch(appDataStoreProvider).listSnapshots());`
  in `lib/data/app_data_controller.dart` (import it in the UI).
- In `build`, after the import tile, watch the provider. When it has a
  non-empty list, render a subheader `l10n.previousDataVersions` and one
  `ListTile` per snapshot showing
  `context.formatDate(info.savedAt, style: AppDateStyle.dateTime)`.
- Tapping a tile opens a confirmation `AlertDialog` with the snapshot date,
  `l10n.restoreSnapshotBody`, and the explicit warning
  `l10n.restoreSnapshotPhotosWarning`; confirm calls
  `ref.read(appDataControllerProvider.notifier).restoreSnapshot(info.fileName)`,
  then `ref.invalidate(dataSnapshotsProvider)` and
  `ref.invalidate(photoIndexProvider)`, and shows `l10n.importCompleted`.
- Reuse the existing `_busy` flag and error snackbar pattern; on a store
  failure show `l10n.restoreBackupFailed` (already exists) and do not clear
  the list.
- Invalidate `dataSnapshotsProvider` after every successful Replace import and
  after `restoreFromBackup`, not only after a snapshot restore, so the newly
  written pre-Replace copy appears without a screen rebuild.
- Do not add a restore action to the corrupt-document `BackupRecoverySection`
  in this plan.

### Step 5: Make the destructive photo side effect explicit

Update both ARB files and regenerate:
- Change `importReplaceHint` to state that current data is replaced, a JSON
  snapshot of the data file is saved first, and photos are deleted (not in the
  snapshot).
- Change `importPhotosExcluded` to “Photos are not included in JSON backups;
  Replace and restore delete photos that are not in the selected file.”
- Add `previousDataVersions`, `restoreSnapshotBody`,
  `restoreSnapshotPhotosWarning`, and `restoreSnapshotTitle` with fa/en text.
- Update `restoreBackupHint` to mention that the kept copy is the unreadable
  data file, not a photo backup.
- Run `flutter gen-l10n`, `dart run tool/fa_review_sheet.dart`, and
  `dart run tool/guards/check_fa_review_sheet.dart`.

### Step 6: Extend the test support stores and tests

- `MemoryAppDataStore`: add a `List<DataSnapshotInfo> snapshots` list with a
  helper to seed one, implement `listSnapshots`/`loadSnapshot`, and keep
  current behavior when empty.
- `FailingAppDataStore`: delegate the two methods; add optional
  `failLoadSnapshot` injection.
- `app_data_store_test.dart`: list returns newest first; empty when absent;
  load returns the saved document; a bad name (`../x`) and a corrupt JSON file
  throw `DataStoreException`; `snapshot()`+`listSnapshots()` after a Replace
  preserves the three-newest rule.
- `import_transaction_test.dart`: restoring a snapshot calls `snapshot` once,
  saves once, publishes the restored data, and leaves the store unchanged when
  the snapshot load fails.
- `backup_settings_test.dart`: after a Replace, the snapshot list renders;
  confirming restores the previous data; canceling writes nothing; the
  confirmation text contains the photo-deletion warning in en and fa.

### Step 7: Update the architecture sentence

In `docs/ARCHITECTURE.md:9`, replace “The private `backups/` folder now holds
pre-Replace import snapshots (last three)” with a sentence saying the last
three data-file snapshots are restorable from Settings, that they contain only
the JSON document, and that Replace/restore delete excluded photos. Do not
change requirement statuses.

### Step 8: Run the focused tests and the full gate

Run every command in the table. If Flutter/Dart are unavailable, report
`BLOCKED` with the missing prerequisite; do not claim success.

## Test plan

- Store: empty list, ordering, retention, valid load, traversal/corrupt
  rejection.
- Controller: restore publishes after save, snapshots current first, failed
  snapshot leaves state and store unchanged.
- Widget: list rendering, confirmation, cancel, error, fa/en warning text.
- Existing tests: `backup_settings_test.dart`, `import_transaction_test.dart`,
  `app_data_store_test.dart`, `photo_import_prune_test.dart` must stay green.

## Done criteria

- [ ] `AppDataStore` has `listSnapshots`/`loadSnapshot`; `JsonAppDataStore` implements them and rejects unsafe names.
- [ ] Settings lists up to three snapshots after a Replace and restores the selected one after confirmation.
- [ ] Restoring snapshots the current document first; a failed restore writes nothing.
- [ ] Both locales explicitly warn that Replace/restore delete photos and that the snapshot is data-only.
- [ ] `app_data_store_test.dart`, `import_transaction_test.dart`, `backup_settings_test.dart` pass with the new cases.
- [ ] `dart run tool/guards/check_l10n.dart`, `check_fa_review_sheet.dart`, `flutter analyze`, and the format check pass.
- [ ] `bash scripts/verify.sh` passes, or the missing prerequisite is reported as `BLOCKED`.
- [ ] No out-of-scope files modified; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- Restoring a snapshot cannot be made safe without copying photos (the plan
  explicitly does not implement photo recovery).
- A store test shows the existing retention logic would delete the snapshot
  just selected (do not change retention in this plan).
- The l10n guard or fa review sheet cannot be regenerated in the environment;
  report `BLOCKED`, do not hand-edit generated files.
- The code does not match the excerpts (drift).

## Maintenance notes

- This restores data only. If a future change adds a photo trash or includes
  photos in a snapshot, update the confirmation copy and ADR-0006 together.
- The list is read on each Settings build; three small files is acceptable. If
  snapshot parsing ever moves into the list, keep it off the UI isolate.
- A reviewer should scrutinize path validation in `loadSnapshot` and the
  snapshot-before-restore ordering.
