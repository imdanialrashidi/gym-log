# Dependency Ledger

Every direct dependency is pinned exactly. The lockfiles pin the full graph.
This record was verified on 2026-10-25 from official release metadata and the
package archives; update it before changing a pin.

## Application dependencies

| Package | Pin | License | Maintenance (official source) | Archive size | Android 7+ / API 24 | Rationale |
|---|---|---:|---|---:|---|---|
| Flutter SDK | `3.47.7` stable (Dart `3.13.5`) | BSD-3-Clause | Stable release 2026-10-08; current stable at pin time ([release JSON](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json)) | 1,578,092,224 B archive | Flutter 3.47 floor is API 24 | Confirmed framework; pinned SDK |
| `flutter_riverpod` | `3.4.3` | MIT | Published 2026-09-03; active, verified publisher `dash-overflow.net` ([pub.dev](https://pub.dev/packages/flutter_riverpod)) | 58,054 B | Pure Dart/Flutter; no Android-specific floor | Owner decision ADR-0001 |
| `go_router` | `18.1.1` | BSD-3-Clause | Published 2026-10-20; Flutter team, feature-complete/stable ([pub.dev](https://pub.dev/packages/go_router)) | 342,653 B | Pure Dart/Flutter; Flutter 3.44+ | Owner decision ADR-0001 |
| `image` | `4.12.0` | MIT | Published 2026-10-11; active upstream, Brendan Duncan ([pub.dev](https://pub.dev/packages/image), [source](https://github.com/brendan-duncan/image)) | 527,636 B | Pure Dart; no Android floor | `PHO-002`: deterministic decode, downscale, and re-encode with every EXIF/GPS directory cleared |
| `image_picker` | `1.2.4` | BSD-3-Clause | Published 2026-10-06; Flutter team, current latest ([pub.dev](https://pub.dev/packages/image_picker), [source](https://github.com/flutter/packages/tree/main/packages/image_picker/image_picker)) | 281,031 B | Android implementation `image_picker_android 0.8.13+25`, `minSdk 24`; no manifest permissions | `PHO-001`/`EXR-005`: system gallery/camera intents and `retrieveLostData()` recovery; Android resize plus app re-encode |
| `intl` | `0.20.3` | BSD-3-Clause | Published 2026-06-25; Dart team ([pub.dev](https://pub.dev/packages/intl)) | 302,642 B | Pure Dart | ARB message generation |
| `url_launcher` | `6.3.2` | BSD-3-Clause | Published 2025-07-10; Flutter team; latest `6.3.3` published 2026-10-02 ([pub.dev](https://pub.dev/packages/url_launcher)) | 194,701 B | Pure plugin; Android implementation has no API-24 floor | `EXR-004` external-browser image lookup; no `canLaunchUrl`/`<queries>` dependency |
| `path_provider` | `2.1.6` | BSD-3-Clause | Published 2026-06-15; Flutter team; current latest ([pub.dev](https://pub.dev/packages/path_provider)) | 163,311 B | Pure plugin; Android implementation has no API-24 floor | Resolves the app-private data document directory |
| `path_provider_android` | `2.2.23` | BSD-3-Clause | Published 2026-03-25; Flutter team ([pub.dev](https://pub.dev/packages/path_provider_android)) | 20,698 B | Traditional Gradle plugin, `compileSdk = flutter.compileSdkVersion` | Pinned directly: 2.3.x pulls `jni`, whose Gradle plugin hardcodes compileSdk 35 while this toolchain ships platform 36 |
| `shamsi_date` | `1.1.1` | BSD-3-Clause | Published 2025; latest 1.1.1 with modest but active maintenance; GitHub tag `v1.1.1` verified 2026-10-23 ([pub.dev](https://pub.dev/packages/shamsi_date), [source](https://github.com/FatulM/shamsi_date)) | 30,232 B | Pure Dart; no Android-specific floor | `L10N-005` Jalali display; wrapped behind `CalendarService` so features never import it |
| `uuid` | `4.6.0` | MIT | Published 2026-07-15; current latest; active ([pub.dev](https://pub.dev/packages/uuid)) | 251,325 B | Pure Dart | Stable string IDs for exercises, programs, days, and plan items (Section 21) |
| `material_ui` | `1.8.0` | BSD-3-Clause | Published 2026-10-20; Flutter team, current standalone Material library ([pub.dev](https://pub.dev/packages/material_ui)) | 3,447,636 B | Pure Flutter; Flutter 3.47 | Flutter 3.47 standalone Material library; required by `go_router` 18.1.1 and the app |
| `cupertino_ui` | `1.1.4` (transitive) | BSD-3-Clause | Published 2026-10-20; Flutter team ([pub.dev](https://pub.dev/packages/cupertino_ui)) | 985,754 B | Pure Flutter; Flutter 3.47 | Material/Cupertino localization delegate dependency |
| `cupertino_icons` | `2.0.0` | MIT | Published 2026-09-29; Flutter team ([pub.dev](https://pub.dev/packages/cupertino_icons)) | 343,075 B | Asset package; API-independent | Cupertino icon font referenced by the standalone Material/Cupertino stack |
| `flutter_localizations` | Flutter SDK `3.47.7` | BSD-3-Clause | Ships with the pinned SDK | — | Same as Flutter | Generated ARB code; app uses `material_ui` delegates |
| Vazirmatn (Regular 400, Medium 500, Bold 700) | `v33.003` | SIL OFL 1.1 | Latest tagged release 2022-06-22; no newer tagged release found at pin time ([GitHub](https://github.com/rastikerdar/vazirmatn/releases/tag/v33.003)) | 13,047,191 B ZIP; 3 TTFs ~361 KB total | Font asset, API-independent | `L10N-003`; only used weights shipped; tabular-figure alignment remains `UNPROVEN` until set rows exist |

## Development dependencies

| Package | Pin | License | Maintenance | Archive size |
|---|---|---:|---|---:|
| `flutter_lints` | `6.0.0` | BSD-3-Clause | Published 2025-05-27; verified `flutter.dev` ([pub.dev](https://pub.dev/packages/flutter_lints)) | 4,980 B |
| `test` | `1.33.0` | BSD-3-Clause | Published 2026-10-09; verified `dart.dev` ([pub.dev](https://pub.dev/packages/test)) | 371,083 B |
| `lints` | `6.1.0` | BSD-3-Clause | Published 2026-02; verified `dart.dev` ([pub.dev](https://pub.dev/packages/lints)) | 18,120 B |

`test` and `lints` are used only by the pure Dart `packages/lift_core` package.
They are pinned in that package's `pubspec.yaml` and lockfile.

## Build toolchain

| Tool | Pin | License | Notes |
|---|---:|---|---|
| Gradle wrapper | `9.3.1` | Apache-2.0 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | `9.1.0` | Apache-2.0 | `android/settings.gradle.kts` |
| Kotlin Android plugin | `2.4.0` | Apache-2.0 | `android/settings.gradle.kts` |
| Android SDK platform 36 / build tools 36.0.0 | `36` / `36.0.0` | Android SDK terms; NOTICE files in SDK | `NFR-COMP-001` requires minSdk 24 |
| NDK | `28.2.13676358` (r28c) | Android SDK terms; NOTICE files in NDK | 722,261,334 B archive; Flutter 3.47 provisions it for Android builds even without native plugins |
| Temurin JDK | `21.0.12.1+1` | GPLv2 + Classpath Exception | `java -version` verified locally |
| Material Icons | Bundled with Flutter 3.47.7 | Apache-2.0 | `uses-material-design: true` |

## Size observations

- Font payload: Regular 122,752 B; Medium 122,656 B; Bold 123,036 B.
- Direct runtime package archives total about 5.3 MB download size; the larger
  share is the standalone Material library, followed by the pure-Dart image library. Development-only packages add
  about 0.4 MB.
- Transitive pins (versions and SHA-256 hashes) are in `pubspec.lock` and
  `packages/lift_core/pubspec.lock`; only direct dependencies were
  size-reviewed. The release APK size target is not set until the first
  measured release build (`NFR-SIZE-001`).
