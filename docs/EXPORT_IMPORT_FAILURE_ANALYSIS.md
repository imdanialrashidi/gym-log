# Export and Import Failure-Path Analysis

Requirements: `IO-001`–`IO-006`, `DAT-006`, `SET-004`, `PHO-003`;
scenarios A11–A13; ADR-0003. This analysis precedes the M6 implementation and
is the threat model the tests and validation limits enforce.

## Data flow and trust boundary

```text
export
  AppData (in memory) -> pure encoder in an isolate -> UTF-8 JSON text
  -> system save/create-document UI -> user-chosen file
  -> successful write marks the export time in local reminder metadata

import
  system open-document UI -> UTF-8 bytes (32 MiB cap) -> pure parser/validator
  in an isolate -> BackupDocument -> dry-run Merge/Replace preview
  -> user confirmation -> one atomic store write
  (Replace: private snapshot first)
```

The imported file is untrusted input. Validation happens before any in-memory
state change or store write. The UI never parses JSON itself. Photo data, ZIP
archives, CSV, and other apps' formats are out of scope (`PHO-003`).

## Merge conflict policy (proposed and implemented at M6; owner confirmation pending)

- **Default: Merge.** Existing data is never deleted or overwritten.
- Same top-level ID (exercise, program, session) with identical canonical
  content: unchanged, counted, not written.
- Same top-level ID with different content: the **existing local record wins**;
  the incoming record is skipped and counted as a conflict. This is the ADR-0003
  policy that replaces the previously open decision.
- A new record whose nested IDs collide with any existing record (across all
  entity types) is skipped as one conflict, so global ID uniqueness is never
  weakened by renaming or merging records.
- A new program/session is added only if every exercise it references exists in
  the merged exercise set. A reference that cannot resolve after conflicts is
  skipped with its parent and counted as a conflict.
- If local data already has an active session, an incoming active session is
  skipped as a conflict. Replace still accepts the incoming active session
  because the local document is removed.
- The dry-run summary reports added, unchanged, and conflict counts. Commit
  re-plans Merge against the current state and refuses to write if the counts no
  longer match the preview (concurrent change), asking the user to review again.
- Merge applies the file's settings only when the local database contains no
  training data (exercises, programs, or sessions); otherwise local settings
  win. Replace always applies the file's settings. This keeps Merge from
  silently overwriting a configured device and still makes
  export → import into an empty database → export equivalent (`IO-004`).
- Replace is explicit, requires a second confirmation, and snapshots the
  current document before writing. It is a single atomic write; the snapshot is
  the recovery point.

## Failure paths and controls

| Failure | Scenario | Control | Test |
|---|---|---|---|
| Truncated file | Transfer interrupted or storage truncated | `jsonDecode` failure maps to `corrupt`; no write | `backup_test.dart` truncated case; DB byte check |
| Corrupt/mistyped file | Invalid JSON or wrong field types | Root/type checks; model readers; typed `BackupError` | corrupt + mistyped cases |
| Hostile file | Deep nesting, huge strings, invalid shape, control/bidi text in headers or IDs | 32 MiB UTF-8 cap, nesting-depth cap, strict JSON types, bounded printable-ASCII IDs/header strings, bounded lists by file size | nesting case; header/ID character cases |
| Oversized file | Extremely large export or a generated file | Gateway refuses >32 MiB before decode; parser repeats the size check and enforces a 500,000-container budget before decoding | oversized and dense-container cases |
| Duplicate IDs | Same ID within exercises/programs/days/items/sessions/session exercises/sets | Pre-pass detects duplicates before the aggregate is created and before any state change; `BackupError.duplicateId` | duplicate-id case |
| Orphan references | Plan item or session exercise names a missing exercise | Pre-pass checks exercise references; `BackupError.orphanReference` | orphan-reference case |
| Deleted plan-day reference | A historical session points at a day deleted after the workout | `Session.programDayId` is validated for ID shape only; history may legitimately outlive a program, so existence is not required | parser/merge tests use valid historical references |
| Absurd values | Negative/huge weight, zero/oversized reps or RIR, invalid set index, oversized increment, out-of-range timestamps, overlong notes | Independent range pre-checks plus model invariants; `BackupError.absurdValue` | absurd-value cases |
| Broad storage permission | A later manifest change adds external-storage/media access | Release Gradle guard rejects broad storage permissions; manifest test asserts their absence | `verifyReleaseManifest`; manifest guard test |
| Newer `schemaVersion` | File from a future app | Reject with the “update the app” error (`newerVersion`); never attempt partial parsing | newer-version case (A13) |
| Unsupported older version | Unknown format version below 1 | Reject with `unsupportedVersion` | parser test |
| Interrupted import | App/process dies before or during commit | Parse and preview mutate nothing; commit is one temp-file write + rename. Replace snapshots before writing; a failed save restores the previous in-memory state | injected store failure; byte-identical test |
| Interrupted export | User cancels the system picker or the write fails | No app data changes; reminder time is updated only after a successful save | fake gateway cancellation test |
| Disk full / write failure | Save or snapshot fails | Store throws `DataStoreException`; no partial document; Replace aborts before data write if snapshot fails | injected snapshot/save failure |
| Concurrent mutation | A CRUD operation happens between preview and commit | Import runs through the serialized controller chain; Merge re-plans and aborts on a count mismatch | controller preview/commit test |
| Multiple active sessions | Merge would produce two active sessions | Local active session wins; incoming active session is a conflict | merge policy test |
| Corrupt reminder metadata | Local meta file unreadable | Reminder is non-critical: default to visible policy state; never blocks app start or export | store test |
| Clock skew | Export time in the future | Negative elapsed time never triggers the banner | reminder policy test |
| Photos | User expects photos in JSON | Format contains no photo fields; UI and docs state that photos are not included | schema test |

## Limits

- Maximum import/export text: **32 MiB** UTF-8. A 10,000-set document is far
  below this; a larger real document gets a clear “too large” message rather
  than an unbounded allocation.
- Maximum JSON nesting depth: **64**, and maximum decoded containers
  (objects + arrays): **500,000**. The scan is string-aware and runs before
  decoding, so a dense file cannot amplify into millions of decoded objects.
- Maximum exercise increment: **1,000,000 g** (1000 kg), matching the maximum
  set weight. This prevents arithmetic overflow in progression/prefill.
- Timestamps must fall between **1970-01-01** and **2200-01-01** UTC. This is a
  sanity bound, not a display rule.
- Existing model ranges remain authoritative: weight `0..1,000,000 g`, reps
  `1..1000`, RIR `0..5`, set index `< 100`, target sets `1..100`, rep range
  `1 <= min <= max <= 100`, notes `<= 2000` characters.
- `schemaVersion` is the **backup format** version, currently `1`. It is
  independent of the internal document version. Unknown fields are ignored;
  removing or changing meaning requires a new format version.
- IDs are 1–128 characters from `A-Z a-z 0-9 . _ -`; `appVersion` and
  `generator` are 1–64 characters from `A-Z a-z 0-9 . + _ -`. This keeps
  control and bidi characters out of validation/preview copy.
- The parser accepts only UTC `exportedAt` values (`Z` or zero offset).
- Export uses stable IDs and explicit `null` for every optional field.

## Recovery notes

- Invalid import: original database remains byte-identical; the user can retry
  with another file.
- Replace: snapshot in the app-private `backups/` directory, last three kept.
  The copy is flushed through a temporary file and atomically renamed; the
  just-created snapshot is excluded from retention pruning, so a backwards wall
  clock cannot delete the recovery point. The snapshot is the pre-replace
  internal document for support/manual recovery; users should also keep a prior
  JSON export because the snapshot is not exposed through the import picker.
- Merge: the operation is additive and atomic; a failed save leaves the
  previous document in place.
- Export: the app-private document is untouched; a canceled picker only leaves
  the in-app reminder due.

## Residual risks / device-only proof

- Real Android document-picker and save-sheet behavior (`IO-006`) and the
  10,000-set UI responsiveness on a reference device (`NFR-PERF-006`) remain
  `UNPROVEN` on this workstation. Widget tests fake the system gateway; the
  pure codec is measured separately.
- JSON duplicate keys collapse in `jsonDecode` (last value wins). The format
  cannot express duplicate keys as distinct records; IDs, not object keys, are
  identity. This is documented rather than silently treated as supported.
- A future additive format change must add a fixture and keep older fixtures
  importing; unknown fields are ignored for that forward-compatibility reason.
