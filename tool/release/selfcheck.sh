#!/usr/bin/env bash
# Exercises the release packaging tools against the debug APK so checksum and
# certificate-mismatch detection fail closed without needing signing secrets.
set -Eeuo pipefail

apk="build/app/outputs/flutter-apk/app-debug.apk"
[[ -f "$apk" ]] || {
  printf 'FAIL: debug APK not found at %s; build it first.\n' "$apk" >&2
  exit 1
}

apksigner="${APKSIGNER:-}"
if [[ -z "$apksigner" ]]; then
  apksigner="$(command -v apksigner || true)"
fi
if [[ -z "$apksigner" ]]; then
  for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}"; do
    [[ -n "$sdk" && -d "$sdk/build-tools" ]] || continue
    apksigner="$(find "$sdk/build-tools" -type f -name apksigner | sort -V | tail -n 1)"
    [[ -n "$apksigner" ]] && break
  done
fi
if [[ -z "$apksigner" && -f android/local.properties ]]; then
  sdk="$(sed -n 's/^sdk\.dir=//p' android/local.properties | head -n 1)"
  if [[ -n "$sdk" && -d "$sdk/build-tools" ]]; then
    apksigner="$(find "$sdk/build-tools" -type f -name apksigner | sort -V | tail -n 1)"
  fi
fi
[[ -n "$apksigner" ]] || {
  printf 'FAIL: apksigner not found. Set APKSIGNER or ANDROID_HOME.\n' >&2
  exit 1
}

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

cert="$(
  "$apksigner" verify --print-certs "$apk" |
    sed -n 's/^Signer #1 certificate SHA-256 digest: //p' |
    head -n 1
)"

APKSIGNER="$apksigner" tool/release/verify_apk_certificate.sh "$apk" "$cert"

wrong="$(printf '%064d' 0)"
if APKSIGNER="$apksigner" tool/release/verify_apk_certificate.sh \
  "$apk" "$wrong" >/dev/null 2>&1; then
  printf 'FAIL: certificate mismatch was not detected.\n' >&2
  exit 1
fi
printf 'Self-check: wrong certificate is rejected.\n'

tool/release/package_apk.sh "$apk" 0.0.0 "$scratch"

printf 'x' >> "$scratch/gym-log-v0.0.0.apk"
if (cd "$scratch" && sha256sum -c gym-log-v0.0.0.apk.sha256 >/dev/null 2>&1); then
  printf 'FAIL: checksum mismatch was not detected.\n' >&2
  exit 1
fi
printf 'Self-check: checksum mismatch is rejected.\n'

printf 'Release tooling self-check passed.\n'
