# Export Format and Historical Fixtures

Requirements: `IO-001`–`IO-006`, `DAT-006`, `PHO-003`. Failure analysis:
[EXPORT_IMPORT_FAILURE_ANALYSIS.md](EXPORT_IMPORT_FAILURE_ANALYSIS.md). Merge
policy: [ADR-0003](adr/0003-import-modes-merge-and-replace.md).

## Format

JSON object, UTF-8, compact on export. `schemaVersion` is the **backup format**
version (`1` today), independent of the internal app-document version.

```json
{
  "schemaVersion": 1,
  "appVersion": "0.1.0",
  "exportedAt": "2026-10-22T12:00:00.000Z",
  "generator": "gym-log",
  "exercises": [],
  "programs": [],
  "sessions": [],
  "settings": {
    "weightUnit": "kilograms",
    "digitStyle": "persian",
    "defaultIncrementGrams": 5000,
    "restTimerEnabled": false,
    "restTimerDurationSeconds": 90,
    "weeklySessionGoal": 3,
    "weeklySetGoal": 12
  }
}
```

Rules:

- Stable UUID strings identify every exercise, program, day, plan item,
  session, session exercise, set, and body-weight check-in. Array position is
  never identity.
- `bodyWeights` is an optional additive array of
  `{id, weightGrams, recordedAt}`. It is omitted while empty, so every
  historical fixture keeps round-tripping byte-for-byte; older readers that do
  not know the field ignore it. A check-in weight must be 20,000–500,000 g
  (20–500 kg) and `recordedAt` is UTC ISO-8601. The app updates the current
  week's reading in place, but import accepts any valid list and the weekly
  series always picks the latest reading inside each local week.
- The on-device document is currently schema **v4** (v3 plus optional
  `weeklySessionGoal` / `weeklySetGoal` in settings). Versions 1–3 are read with
  empty/default newer fields and written back as v4; no collection is
  discarded. The backup `schemaVersion` stays `1` because this is additive.
- Optional values are written explicitly as `null`:
  `searchTerm`, `muscleGroup`, `defaultRepMin`, `defaultRepMax`, `archivedAt`,
  `endedAt`, `programDayId`, `note`, `targetSets`, `repMin`, `repMax`, `rir`.
- `exportedAt` is UTC ISO-8601 (`Z` or zero offset). Dates are never
  Jalali strings (`L10N-005`).
- `digitStyle` (`persian`/`latin`), `defaultIncrementGrams`, and the two
  weekly-goal integers are optional settings; a file without them keeps the
  locale-derived digit default, the unit default increment, and no goal. A
  session target is 1–14, a working-set target is 1–200; both are coaching
  targets, never stored training totals.
- IDs are 1–128 characters from `A-Z a-z 0-9 . _ -`. `appVersion` and
  `generator` are 1–64 characters from `A-Z a-z 0-9 . + _ -`. Control and bidi
  characters are rejected so they cannot enter validation or preview copy.
- Free text and ordering are bounded at import: exercise names, program names,
  and day names are at most 120 characters, `searchTerm` is at most 200
  characters, and every `sortOrder` (program day, plan item, session exercise)
  is between 0 and 1,000,000. These are generous UI/import limits, not database
  limits. A document already on the device with a longer name still loads; the
  editor only enforces the bound for new edits, so the user can shorten it.
- Unknown fields are ignored on import. Removing or changing the meaning of a
  field requires a new backup `schemaVersion`; additive fields may stay in the
  same version because older readers ignore them.
- No photos, file paths, EXIF, ZIP payloads, CSV, or other apps' formats.
- A file with a newer `schemaVersion` is rejected with an “update the app”
  message before any data is touched.

## Import validation

The parser rejects, with a typed error and a localized fa/en message:

- empty, oversized (>32 MiB UTF-8, >500,000 JSON containers), deeply nested
  (>64 levels), truncated, or invalid JSON;
- a non-object root, missing/typed header fields, non-UTC `exportedAt`;
- unsupported or newer `schemaVersion`;
- mistyped entity fields, duplicate IDs anywhere in the document, plan-item or
  session-exercise references to a missing exercise, multiple active sessions;
- out-of-range numeric values (including increments above 1,000,000 g, and
  body weights outside 20–500 kg), note length, and timestamps outside
  1970–2200.

Merge is the default and never overwrites. It restores settings only when the
local database has no training data; otherwise local settings win. Replace
always applies the file's settings. Both modes commit in one atomic write. The
dry-run summary reports what will be added, what is unchanged, and how many
same-ID/different-content records keep the local version.

## Historical fixture policy

`test/fixtures/export/` contains one real export per **released** app version:

```text
test/fixtures/export/v0.1.0.json
test/fixtures/export/v0.2.0.json
```

`test/data/backup_round_trip_test.dart` discovers every `*.json` in that
directory and imports it on every `flutter test` run (and therefore in CI).
The test fails if any fixture is unreadable, invalid, or no longer round-trips
to its exact content. A release is blocked while a fixture fails.

### Adding a fixture for a release

1. Build the release candidate and create representative data on a device:
   exercises, a program with days/items, at least one finished session with
   sets/notes, and non-kg settings.
2. Export from the app through the system save UI.
3. Store the file unchanged as `test/fixtures/export/v<version>.json`
   (for example `v0.2.0.json`). Exports are compact JSON; do not hand-edit or
   reformat the file.
4. Run `flutter test test/data/backup_round_trip_test.dart` and then the full
   `bash scripts/verify.sh` lane.
5. Never delete or rewrite an older fixture. New code must keep importing it;
   a format change adds a new `schemaVersion`, a new fixture, and an import path
   for the old version.

Fixture files contain only the owner-approved test data described above. Never
put secrets, signing material, personal notes, or device paths in a fixture.
