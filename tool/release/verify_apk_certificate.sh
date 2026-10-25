#!/usr/bin/env bash
# Compare an APK's signer certificate with the owner-recorded public SHA-256
# fingerprint. Catches a wrong-but-valid key before publishing: Android would
# treat it as a different app and force users to uninstall (DAT-005).
#
# Usage: tool/release/verify_apk_certificate.sh <apk> <expected-sha256>
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s <apk> <expected-sha256>\n' "$0" >&2
  exit 64
fi

apk="$1"
expected="$2"

[[ -f "$apk" ]] || {
  printf 'FAIL: APK not found: %s\n' "$apk" >&2
  exit 1
}

normalize() {
  printf '%s' "$1" | tr -d '[:space:]:' | tr '[:upper:]' '[:lower:]'
}

expected="$(normalize "$expected")"
[[ "$expected" =~ ^[0-9a-f]{64}$ ]] || {
  printf 'FAIL: expected certificate fingerprint must be 64 hex characters.\n' >&2
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

actual="$(
  "$apksigner" verify --print-certs "$apk" |
    sed -n 's/^Signer #1 certificate SHA-256 digest: //p' |
    head -n 1 |
    tr -d '[:space:]:' |
    tr '[:upper:]' '[:lower:]'
)"
[[ -n "$actual" ]] || {
  printf 'FAIL: no signer certificate found in %s.\n' "$apk" >&2
  exit 1
}

if [[ "$actual" != "$expected" ]]; then
  printf 'FAIL: certificate mismatch.\n' >&2
  printf '  expected: %s\n' "$expected" >&2
  printf '  actual:   %s\n' "$actual" >&2
  printf 'Publishing this APK would not be an update for installed users.\n' >&2
  exit 1
fi

printf 'APK certificate verified: %s\n' "$actual"
