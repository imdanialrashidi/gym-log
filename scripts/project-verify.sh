#!/usr/bin/env bash
# Project verification lane. Keep this list in sync with docs/QUALITY.md.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# flutter_tester talks to a local WebSocket. Never route localhost through an
# HTTP proxy; external package/build traffic keeps the existing proxy.
export NO_PROXY="${NO_PROXY:+$NO_PROXY,}localhost,127.0.0.1,::1"
export no_proxy="${no_proxy:+$no_proxy,}localhost,127.0.0.1,::1"

step() { printf '\n==> %s\n' "$1"; }

step "Pinned toolchain"
scripts/check_toolchain.sh

step "Resolve dependencies"
flutter pub get
(cd packages/lift_core && dart pub get)

step "Generate localizations"
flutter gen-l10n

step "Format check"
dart format --output=none --set-exit-if-changed \
  lib/app lib/core/calendar lib/core/links lib/core/l10n/digit_style_scope.dart lib/core/l10n/l10n.dart lib/core/widgets lib/data lib/features \
  lib/main.dart \
  test tool packages/lift_core

step "Static analysis"
flutter analyze --fatal-infos --fatal-warnings
(cd packages/lift_core && dart analyze --fatal-infos --fatal-warnings)

step "Localization and data-safety guards"
dart run tool/guards/check_l10n.dart
dart run tool/guards/check_fa_review_sheet.dart
dart run tool/guards/check_directionality.dart
dart run tool/guards/check_calendar_boundary.dart
dart run tool/guards/check_no_destructive_reset.dart
dart run tool/guards/check_changelog.dart
dart run tool/guards/check_no_signing_material.dart

step "Tests"
(cd packages/lift_core && dart test)
flutter test

step "Performance micro-benchmarks"
dart run tool/benchmarks/run_benchmarks.dart

step "Android debug build"
flutter build apk --debug

step "Release tooling self-check"
tool/release/selfcheck.sh

step "Release manifest guard"
(cd android && ./gradlew --console=plain :app:verifyReleaseManifest)

printf '\nProject verification passed.\n'
