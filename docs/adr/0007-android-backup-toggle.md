# ADR-0007: Android Backup Toggle

- Status: Accepted 2026-10-21
- Deciders: Project owner
- Requirements: `DAT-007`, `SET-004`, `PHO-003`, `NFR-PRV-001`

## Context

`DAT-007` recommends disabling Android Auto Backup for the database and photos because it conflicts with the local-first principle. It leaves an optional "Allow Android backup" setting as **Needs Decision**, with a recommendation of a visible toggle defaulting to off.

The owner selected a visible toggle, default off.

## Decision

- Settings shows a visible "Allow Android backup" toggle.
- The default is **off** on a fresh install.
- When off, Android Auto Backup is disabled for the database and photos through the manifest and data-extraction rules.
- The export reminder remains the primary backup prompt; the About/setup guidance explains manual export/import for moving phones.
- The toggle must actually change the applicable backup behavior; a display-only control is not acceptable.
- JSON export still never includes photos (`PHO-003`, ADR-0006).

The exact scope of Android backup when the toggle is on (whether photos are included) is **not decided here**. `PHO-003`'s default exclusion remains until the owner decides otherwise.

## Consequences

- The privacy-preserving state is the default.
- Backup rules need automated checks: default off, toggle persistence, and the resulting manifest/data-extraction behavior.
- Moving to a new phone without Android backup requires export/import, which is documented in the app and README.

## Alternatives considered

- Hidden, always off: stricter, but denies users a deliberate convenience choice.
- Always on: conflicts with the local-first default and the owner decision.

## Verification

- Fresh install: toggle is off and Auto Backup is disabled for the protected data.
- Toggle changes the effective behavior and survives restart.
- Export contains no photos regardless of the toggle.
- Export reminder still follows `SET-004`.
