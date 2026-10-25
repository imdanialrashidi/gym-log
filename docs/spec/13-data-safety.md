<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 23.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 23. Data Safety, Updates, Backup, and Release Integrity

Your requirement 11 ("with every update, nothing unexpected happens to users") is the most important engineering requirement. Everything here is **Must** and **Confirmed** under your "add all" reply to the data-safety section, unless noted.

### 23.1 Versioned migrations with generated tests (`DAT-001`)

- Use **Drift**'s guided workflow: export the schema for every version into a committed folder, write step-by-step migrations, and run the generated migration tests [S11].
- **AC:** CI runs the migration test suite on every pull request. A schema change without a new schema snapshot and a migration step fails CI.
- **Agent rule:** agents may never edit an existing migration step. They may only add a new one.

### 23.2 No destructive fallback (`DAT-002`)

- The app must **never** delete and recreate the database to recover from a migration error.
- **AC:** A code search in CI for destructive-reset patterns fails the build. If a migration fails, the app enters **Safe Mode** (23.4).

### 23.3 Pre-migration snapshot (`DAT-003`)

- Before any migration runs, copy the database file (including any write-ahead-log files) to a private `backups/` folder with the old and new version numbers in the file name. Keep the last three (Assumption).
- **AC:** A test simulates a failing migration and confirms the snapshot exists and the original database is untouched.

### 23.4 Safe Mode (`DAT-004`, Recommendation)

- If the database cannot be opened or migrated, the app shows a dedicated screen: what happened in plain language, a button to **export the raw database file** for recovery, and a button to copy a diagnostic report. It never overwrites data.
- Also covers "database is newer than the app" (user installed an older APK). Android normally prevents version-code downgrades, but sideloaded builds can still conflict; handle it gracefully.

### 23.5 Stable signing identity (`DAT-005`)

- **Why it matters:** Android only treats a new APK as an update if it is signed with the same certificate as the installed app. A different certificate means the user must uninstall first, which **deletes local data** [S15]. For a local-only app, a lost or changed key is therefore a data-loss event for every user.
- **Rules (Recommendation):**
  1. Generate the release keystore once, offline.
  2. Store it in at least **two independent places** (e.g. an encrypted password-manager attachment plus an offline drive), along with its passwords.
  3. **Never commit it to Git**, and never paste it into a prompt for an AI agent.
  4. Decide the **applicationId** (the permanent package name) **before the first release**. It cannot be changed later without creating a different app. The display name can change; the applicationId cannot.
  5. Sign release APKs locally or in CI using secrets; keep the CI secret handling reviewed.
  6. Publish SHA-256 checksums with every GitHub release.
- **Distribution-channel caveat (Unverified in this pass):** if the same app is distributed through different channels that sign with different keys (for example a store that re-signs, or F-Droid building from source), users cannot update across channels without reinstalling. Verify each channel's signing behavior before adding it (Section 31).

### 23.6 Export and validated import (`DAT-006`)

- See `IO-001` to `IO-006`. The JSON file is the last line of defense, so it is tested more than any other feature: round-trip test, historical-fixture test, truncated/corrupt file test, wrong-version test, and import of a very large file.
- **Format rules:** top-level `schemaVersion`, `appVersion`, `exportedAt`; stable IDs; explicit `null`s; unknown fields ignored on import (forward-compatible); never rely on array position for identity.

### 23.7 Auto Backup posture (`DAT-007`)

- Android Auto Backup is **on by default** for apps that target Android 6.0 or higher and uploads app data to the user's Google Drive, with a 25 MB per-app limit; it also supports device-to-device transfer [S17]. That conflicts with your "nothing leaves the device" principle.
- **Recommendation (Confirmed under your "add all"):** disable Auto Backup in the manifest for the database and photos (for Android 12+ targets, use the data-extraction rules attribute [S17]), and rely on the **export reminder banner** (`SET-004`) and an easy **import on a new phone**.
- **Trade-off to communicate:** with Auto Backup off, moving to a new phone requires manual export and import. The About and onboarding hint should say so.
- **Needs Decision (optional):** a setting "Allow Android backup" defaulting to off, for users who prefer convenience over strict locality.

### 23.8 Release discipline (`DAT-008`)

- Semantic versioning; monotonically increasing version code; `CHANGELOG.md` entry per release including any schema change.
- **Upgrade drill before every release:** install the previous public APK on a real device, create realistic data, install the new APK over it, verify history, programs, charts, and an export/import round trip.
- Pre-release builds (marked as pre-release on GitHub) go to friends first.

---
