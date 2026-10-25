#!/usr/bin/env bash
# Name the signed APK and generate/verify its SHA-256 checksum (DAT-005).
#
# Usage: tool/release/package_apk.sh <apk> <version> <output-dir>
# Version is the tag without the leading v, e.g. 1.2.3.
set -Eeuo pipefail

if [[ $# -ne 3 ]]; then
  printf 'Usage: %s <apk> <version> <output-dir>\n' "$0" >&2
  exit 64
fi

apk="$1"
version="$2"
output_dir="$3"

[[ -f "$apk" ]] || {
  printf 'FAIL: APK not found: %s\n' "$apk" >&2
  exit 1
}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  printf 'FAIL: version "%s" is not X.Y.Z.\n' "$version" >&2
  exit 1
}
command -v sha256sum >/dev/null 2>&1 || {
  printf 'FAIL: sha256sum is required.\n' >&2
  exit 1
}

mkdir -p "$output_dir"
named="gym-log-v$version.apk"
cp "$apk" "$output_dir/$named"
(
  cd "$output_dir"
  sha256sum "$named" > "$named.sha256"
  sha256sum -c "$named.sha256"
)

printf 'Packaged %s\n' "$output_dir/$named"
printf 'Checksum %s\n' "$output_dir/$named.sha256"
