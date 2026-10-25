# ADR-0003: Import Modes — Merge and Replace

- Status: Accepted 2026-10-21; same-ID conflict policy proposed and implemented 2026-10-22, owner confirmation pending
- Deciders: Project owner
- Requirements: `IO-002`, `IO-003`, `IO-004`, `DAT-006`

## Context

The spec lists import modes as **Needs Decision** and recommends Merge plus Replace, with Replace taking an automatic snapshot first. Merge must never overwrite existing records silently; duplicates are detected by stable IDs. Import validation must reject invalid, truncated, mistyped, orphaned, absurd-value, and newer-`schemaVersion` files without changing data.

The owner selected Merge + Replace, with Replace snapshotting first.

## Decision

- **Merge** is the default mode. It adds new records and uses stable UUIDs to detect duplicates.
- **Replace** is explicit. Before committing, it takes a snapshot through the existing database snapshot mechanism (the app-private `backups/` copy in `JsonAppDataStore`).
- The import runs as a single atomic transaction after a dry-run summary; a failure leaves the database unchanged.
- **Same-ID conflict policy (proposed 2026-10-22 at M6 implementation):** identical canonical content is unchanged; the same top-level ID with different content keeps the local record and skips the incoming one as a counted conflict. A new record is skipped if any of its nested IDs collides with an existing record, preserving global ID uniqueness. A new program/session is skipped if a referenced exercise cannot exist after conflicts. If local data has an active session, an incoming active session is skipped as a conflict. Merge never renames IDs or overwrites data. Merge applies the file's settings only when no local training data exists; otherwise local settings win. This makes Merge into an empty database round-trip equivalent (`IO-004`).
- The dry-run summary counts added, unchanged, and conflict records. Commit re-plans Merge and refuses to write if the counts no longer match the preview.
- A file with a newer `schemaVersion` is rejected with an "update the app" message. Unknown fields are ignored for forward compatibility.

## Consequences

- Import is a high-risk path and requires failure-path analysis, injected-failure tests, round-trip tests, and historical fixtures.
- Replace cannot partially apply; the pre-import snapshot is the recovery point.
- The dry-run summary must match what the commit actually adds.

## Alternatives considered

- Merge only: simpler, but cannot restore a full backup into a non-empty database.
- Replace only: loses data on an accidental import.
- Per-record prompts: rejected as too slow and ambiguous.

## Verification

- Merge never overwrites without an explicit decision; same-ID/different-content keeps the local record and reports a conflict.
- Replace creates a snapshot before writing and survives an injected mid-import failure.
- Invalid input leaves the database byte-identical.
- Dry-run counts equal committed counts; a concurrent change aborts the commit.
- Round-trip and every historical fixture import successfully.

## Revisit when

- The same-ID conflict policy is proposed and accepted at M6.
- A fixture or a real restore shows that Merge semantics are unsafe.
