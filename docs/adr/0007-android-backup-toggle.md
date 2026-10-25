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

## Amendment 2026-10-25: enforced-off policy row

Android Auto Backup is controlled by the build-time manifest
(`android:allowBackup`, `fullBackupContent`, and the data-extraction rules) and
the system settings; an app has no runtime API to opt a device into or out of
Auto Backup. `DAT-007` and acceptance scenario A18 require the release manifest
to keep backup disabled, and the release guard fails otherwise. A toggle that
persisted a preference and changed nothing would be a display-only control.

The implemented resolution is a visible `Allow Android backup` switch-style row
that is **off and non-interactive** on every build, with a hint that data
leaves the device only through JSON export. It reports the policy enforced by
the manifest guard rather than pretending to change it. The export reminder and
manual export/import remain the backup path. Revisit this amendment only with a
verified platform mechanism that can change the backed-up payload at runtime
and an explicit change to the A18/DAT-007 manifest guard.

Verification: `test/features/about_test.dart` asserts the row is off and
disabled; `android/app/build.gradle.kts` `verifyReleaseManifest` fails when
`allowBackup`, `fullBackupContent`, or the extraction rules are weakened;
`test/manifest_permissions_test.dart` pins the source manifest.
