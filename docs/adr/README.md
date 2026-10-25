# Architecture Decision Records

Short records of decisions the owner made for this project. These are not a diary and do not restate the spec.

Only the owner decisions supplied on 2026-10-21 are recorded here. Product requirements, statuses, and acceptance criteria stay in `docs/spec/`. Unresolved items remain open in [the specification index](../spec/README.md#open-decisions).

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-state-management-and-routing.md) | Riverpod + go_router, pinned only after license/maintenance verification | Accepted, pinning conditional |
| [0002](0002-weight-storage-integer-grams.md) | Canonical weight stored as integer grams | Accepted |
| [0003](0003-import-modes-merge-and-replace.md) | Merge + Replace import; Replace snapshots first | Accepted, conflict policy still open |
| [0004](0004-e1rm-display-thresholds.md) | e1RM shown 1–10, "less reliable" 11–12, hidden above 12 | Accepted |
| [0005](0005-rtl-chart-time-axis.md) | Chart time axis left-to-right in RTL | Accepted |
| [0006](0006-session-photos.md) | Maximum 3 photos per session; excluded from JSON export | Accepted (storage/backup/deletion remain spec Recommendations) |
| [0007](0007-android-backup-toggle.md) | Visible Android backup toggle, default off | Accepted; amended 2026-10-25 (enforced-off policy row under the manifest guard) |
| [0008](0008-chart-rendering.md) | Custom-painter progress charts; no chart package | Accepted (2026-10-21 spike) |
| [0009](0009-double-progression-precedence.md) | Suggestion is a labeled, revertible draft; mixed weights produce no suggestion; bodyweight is reps-only | Accepted (2026-10-22 implementation reading) |

## Convention

- One decision per file; state the decision, its consequences, and what would justify revisiting it.
- Link the governing requirement IDs and the spec section.
- Never use an ADR to upgrade an `Assumption` or `Recommendation` into a commitment. If the spec still labels a point open, the ADR says so.
- Supersede an ADR with a new one; do not rewrite history.
