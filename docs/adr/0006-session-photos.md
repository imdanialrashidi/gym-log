# ADR-0006: Session Photos — Count and Export Exclusion

- Status: Accepted 2026-10-21; ZIP archive remains undecided
- Deciders: Project owner
- Requirements: `PHO-001`, `PHO-002`, `PHO-003`, `PHO-005`, `EXR-005`

## Context

`PHO-001` allows up to N photos per session with a default of 3, but N was an **Assumption**. `PHO-002`, `PHO-003`, and `PHO-005` set privacy and deletion expectations. The spec's D14 leaves a separate ZIP archive as **Could**.

The owner selected a maximum of 3 photos per session and exclusion from JSON export.

## Decision

Owner-decided:

- Allow up to **3** photos per session, from the system camera or gallery.
- Exclude photos from JSON export. The export states that photos are not included.

Design constraints retained from the spec (Recommendations, not upgraded to commitments by this ADR):

- Store copies in app-private storage, downscaled, with location metadata stripped (`PHO-002`).
- Exclude photos from Android Auto Backup by default (`PHO-003`).
- Deleting a session deletes its photo files; removing a photo deletes its file; no orphans remain (`PHO-005`).
- Refuse a fourth session photo with a clear reason (follows from the owner-decided limit of 3).
- Do not log image paths or image content.

A separate ZIP "full archive" remains **Could** and is not authorized by this ADR.

## Consequences

- Photo handling is a high-risk privacy path with mandatory failure-path tests.
- No broad storage permission is added; system picker/camera intents are used.
- The export schema has no photo payload.
- The storage, EXIF, backup-exclusion, and deletion rules remain spec Recommendations; implementation must not present them as owner commitments.

## Alternatives considered

- One photo per session: less useful for visual tracking.
- Unlimited: unbounded storage and a larger privacy surface.
- Include photos in the JSON export: rejected by the owner.

## Verification

- A geotagged sample produces a stored copy with no GPS EXIF.
- Photo directory scan finds no orphans after deletion.
- Export and backup rules exclude photos.
- A fourth photo is refused with a reason.
- Cancelled picks, unreadable images, low storage, and lost-activity recovery leave no partial files.
