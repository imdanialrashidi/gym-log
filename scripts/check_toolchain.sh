#!/usr/bin/env bash
# Refuse to build with a Flutter or Dart version other than the pinned one.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../tool/toolchain.env
source "$ROOT_DIR/tool/toolchain.env"

if ! command -v flutter >/dev/null 2>&1; then
  printf 'BLOCKED: Flutter %s is not on PATH.\n' "$FLUTTER_VERSION" >&2
  printf 'Install Flutter %s (Dart %s) and retry:\n' \
    "$FLUTTER_VERSION" "$DART_VERSION" >&2
  printf '  https://docs.flutter.dev/release/archive?tab=linux\n' >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf 'BLOCKED: python3 is required to parse `flutter --version --machine`.\n' >&2
  exit 1
fi

if [[ -f "$ROOT_DIR/.flutter-version" ]]; then
  file_version="$(tr -d '[:space:]' < "$ROOT_DIR/.flutter-version")"
  if [[ "$file_version" != "$FLUTTER_VERSION" ]]; then
    printf 'FAIL: .flutter-version (%s) does not match tool/toolchain.env (%s).\n' \
      "$file_version" "$FLUTTER_VERSION" >&2
    exit 1
  fi
fi

version_json="$(flutter --version --machine)"
actual_flutter="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])' <<<"$version_json")"
actual_dart="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["dartSdkVersion"])' <<<"$version_json")"

if [[ "$actual_flutter" != "$FLUTTER_VERSION" ]]; then
  printf 'FAIL: Flutter %s is required, found %s.\n' \
    "$FLUTTER_VERSION" "$actual_flutter" >&2
  exit 1
fi

if [[ "$actual_dart" != "$DART_VERSION" ]]; then
  printf 'FAIL: Dart %s is required, found %s.\n' \
    "$DART_VERSION" "$actual_dart" >&2
  exit 1
fi

printf 'Toolchain OK: Flutter %s, Dart %s.\n' \
  "$actual_flutter" "$actual_dart"
