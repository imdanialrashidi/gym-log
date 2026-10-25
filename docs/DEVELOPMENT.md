# Development

Android-only Flutter app. The working tree is the deliverable; this repository
does not commit, push, branch, or release from an agent session.

## Pinned toolchain

| Tool | Pin | Source |
|---|---|---|
| Flutter | `3.47.7` stable | [Flutter release archive](https://docs.flutter.dev/release/archive?tab=linux) / [release JSON](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json) |
| Dart | `3.13.5` | Bundled with Flutter 3.47.7 |
| Java | Temurin 21 (`21.0.12.1+1`) | [Adoptium](https://adoptium.net/) |
| Gradle / AGP / Kotlin | `9.3.1` / `9.1.0` / `2.4.0` | Flutter 3.47.7 Android template |
| Android SDK platform | `android-36` | Android SDK Manager |
| Android build tools | `36.0.0` | Android SDK Manager |
| NDK | `28.2.13676358` | Android SDK Manager; Flutter 3.47 provisions it even without native plugins |
| Android minSdk | `24` | `NFR-COMP-001` |
| compileSdk / targetSdk | `36` | Flutter 3.47.7 template |

The exact Flutter version is also in `.flutter-version` and
`tool/toolchain.env`; `scripts/check_toolchain.sh` refuses a different version.
Dependency pins and their license/maintenance/size review are in
[DEPENDENCIES.md](DEPENDENCIES.md).

## First-time setup

1. Install the pinned Flutter SDK, JDK 21, and Android SDK components above
   (including NDK 28.2.13676358).
2. Point Flutter at the SDK if it is not already configured:

   ```sh
   flutter config --android-sdk "$ANDROID_SDK_ROOT"
   flutter config --no-analytics
   ```

3. Resolve dependencies and generate localization sources:

   ```sh
   flutter pub get
   (cd packages/lift_core && dart pub get)
   flutter gen-l10n
   ```

## Commands

Run the same lane locally that CI runs:

```sh
bash scripts/verify.sh
```

`scripts/verify.sh` runs the template self-checks and then
`scripts/project-verify.sh`, which executes:

```sh
scripts/check_toolchain.sh
flutter pub get
(cd packages/lift_core && dart pub get)
flutter gen-l10n
dart format --output=none --set-exit-if-changed \
  lib/app lib/core/calendar lib/core/l10n/digit_style_scope.dart \
  lib/core/l10n/l10n.dart lib/core/widgets lib/data lib/features lib/main.dart \
  test tool packages/lift_core
flutter analyze --fatal-infos --fatal-warnings
(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)
dart run tool/guards/check_l10n.dart
dart run tool/guards/check_fa_review_sheet.dart
dart run tool/guards/check_directionality.dart
dart run tool/guards/check_calendar_boundary.dart
dart run tool/guards/check_no_destructive_reset.dart
(cd packages/lift_core && dart test)
flutter test
flutter build apk --debug
(cd android && ./gradlew --console=plain :app:verifyReleaseManifest)
```

The debug APK is written to
`build/app/outputs/flutter-apk/app-debug.apk`.

Useful focused commands:

```sh
flutter test test/app_shell_test.dart
flutter test test/theme/contrast_test.dart --reporter expanded
flutter test --update-goldens test/app_shell_golden_test.dart
(cd packages/lift_core && dart test)
```

Golden files are under `test/goldens/` and are generated on Linux with the
pinned Flutter/Vazirmatn assets. Regenerate only after an intentional visual
change, then review the image diff. `test/golden_coverage_test.dart` enforces an
LTR/RTL pair for every screen state.

Regenerate the native-speaker review sheet after changing fa copy:

```sh
dart run tool/fa_review_sheet.dart
dart run tool/guards/check_fa_review_sheet.dart
```

## Export fixtures and backups

The JSON format, validation limits, Merge policy, and the per-release fixture
procedure are in [EXPORT_FORMAT.md](EXPORT_FORMAT.md). `flutter test` imports
every file under `test/fixtures/export/`; a new release adds
`test/fixtures/export/v<version>.json` exported from the app. Never edit or
delete an older fixture. Focused commands:

```sh
flutter test test/data/backup_round_trip_test.dart
flutter test test/data/backup_import_rejection_test.dart
flutter test test/data/import_transaction_test.dart
flutter test test/features/backup_settings_test.dart
flutter test test/features/export_reminder_ui_test.dart
```

The real Android save/open picker and device UI responsiveness are `UNPROVEN`
on this workstation; `IO-006` and the 10,000-set UI budget need the reference
device.

## Android release guard

`applicationId` is the placeholder `com.example.gym_log` until the owner
decides the permanent identity. Release builds are intentionally refused:

```sh
flutter build apk --release
# FAIL: Release build refused: applicationId 'com.example.gym_log' is a placeholder.
```

The Gradle guard also verifies the merged release manifest has no `INTERNET`
permission and has Android backup disabled. Debug/profile manifests keep the
Flutter development `INTERNET` permission; release does not. Do not add a
release workflow or signing material until the owner supplies the permanent
applicationId and signing plan.

## Network-restricted workstation note

The canonical commands above use official endpoints. If this workstation's
network returns 404/403 for `dl.google.com` and `storage.googleapis.com`, use
official mirrors for local runs only (do not commit mirror configuration):

```sh
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

If `sdkmanager` cannot reach the Android repository, install the pinned SDK
packages from the Google CDN mirror
`https://redirector.gvt1.com/edgedl/android/repository/` instead.

If Gradle cannot reach Google Maven, a user-level init script can rewrite the
existing `google()` repository URL to the Google CDN mirror
`https://redirector.gvt1.com/edgedl/android/maven2/` for local runs. Do not
add a new repository in that script: the included Flutter tools build sets
`FAIL_ON_PROJECT_REPOS`. Do not commit mirror configuration; CI uses the
official endpoints.

## Known M0 limits

- Device locales whose language is `fa` start in Persian RTL; `en` devices
  start in English LTR; any other device language falls back to English. The
  explicit fallback is locked by a widget test.
- The language choice is held in memory; there is no preferences store yet.
  Switching applies without restart (the accepted `SET-001` criterion), but
  the choice does not survive process death.
- Persian scaffold copy still needs native review (`L10N-010`).
- Tabular-figure alignment for numeric columns is unverified until set rows
  exist (`L10N-003`).
- Device-only criteria remain `UNPROVEN`; see [QUALITY.md](QUALITY.md).

## Data and secrets

- No secrets, signing keys, keystores, or passwords in the repository, logs,
  prompts, screenshots, or artifacts.
- Release builds must have no `INTERNET` permission, no analytics, ads, crash
  reporting, or Firebase.
- Never add a destructive database reset (`DAT-002`); the guard fails the gate.
