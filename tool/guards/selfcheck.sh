#!/usr/bin/env bash
# Runs every guard on a clean copy, then introduces one known violation per
# guard and requires a non-zero exit. No source file in the repository is
# modified: all mutations happen in a mktemp copy.
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
case_dir="$tmp/case"

guards=(
  check_l10n
  check_fa_review_sheet
  check_directionality
  check_calendar_boundary
  check_no_destructive_reset
  check_changelog
  check_no_signing_material
  check_workflow_pins
)

make_tree() {
  rm -rf "$case_dir"
  mkdir -p "$case_dir/packages/lift_core" "$case_dir/tool" "$case_dir/docs" \
    "$case_dir/.github"
  cp -R "$repo/lib" "$case_dir/lib"
  cp -R "$repo/packages/lift_core/lib" "$case_dir/packages/lift_core/lib"
  cp "$repo/tool/toolchain.env" "$case_dir/tool/toolchain.env"
  cp -R "$repo/docs/l10n" "$case_dir/docs/l10n"
  cp -R "$repo/.github/workflows" "$case_dir/.github/workflows"
  cp "$repo/pubspec.yaml" "$repo/CHANGELOG.md" "$repo/.flutter-version" \
    "$case_dir/"
}

run_guard() {
  local name="$1"
  (cd "$case_dir" && dart run "$repo/tool/guards/$name.dart")
}

expect_fail() {
  local name="$1" label="$2"
  if run_guard "$name" >/dev/null 2>&1; then
    printf 'FAIL: %s did not detect %s\n' "$name" "$label" >&2
    exit 1
  fi
  printf 'PASS: %s (%s)\n' "$name" "$label"
}

make_tree
for name in "${guards[@]}"; do
  if ! run_guard "$name" >/dev/null; then
    printf 'FAIL: clean run of %s failed; fix the tree before self-checking.\n' \
      "$name" >&2
    exit 1
  fi
done
printf 'PASS: clean tree (%s guards)\n' "${#guards[@]}"

make_tree
python3 - "$case_dir/lib/core/l10n/app_fa.arb" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding='utf-8') as handle:
    messages = json.load(handle)
messages.pop('aboutTitle', None)
with open(path, 'w', encoding='utf-8') as handle:
    json.dump(messages, handle, ensure_ascii=False, indent=2)
    handle.write('\n')
PY
expect_fail check_l10n "missing fa key"

make_tree
sed -i '/^| `aboutTitle` |/d' "$case_dir/docs/l10n/fa-review-sheet.md"
expect_fail check_fa_review_sheet "missing review-sheet row"

make_tree
cat > "$case_dir/lib/features/guard_fixture.dart" <<'DART'
import 'package:material_ui/material_ui.dart';

const EdgeInsets padding = EdgeInsets.only(left: 8);
DART
expect_fail check_directionality "hard-coded left padding"

make_tree
cat > "$case_dir/lib/features/guard_fixture.dart" <<'DART'
import 'package:shamsi_date/shamsi_date.dart';

DateTime now() => Jalali.now().toDateTime();
DART
expect_fail check_calendar_boundary "direct shamsi_date import"

make_tree
cat > "$case_dir/lib/guarded_fixture.dart" <<'DART'
void reset() {
  deleteDatabase('gym_log');
}
DART
expect_fail check_no_destructive_reset "database deletion"

make_tree
rm -rf "$case_dir/lib"
expect_fail check_no_destructive_reset "missing lib/ scan root"

make_tree
printf 'ZmFrZQ==\n' > "$case_dir/release.b64"
expect_fail check_no_signing_material "release.b64 key file"

make_tree
sed -i '0,/^Build:/{/^Build:/d}' "$case_dir/CHANGELOG.md"
expect_fail check_changelog "missing Build line"

make_tree
sed -i 's|@[0-9a-f]\{40\}|@v4|' "$case_dir/.github/workflows/quality.yml"
expect_fail check_workflow_pins "movable action tag"

make_tree
cat > "$case_dir/.github/workflows/static-fixture.yml" <<'YAML'
name: static-fixture
on: workflow_dispatch
permissions:
  contents: read
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
YAML
expect_fail check_workflow_pins "movable action tag in a non-Flutter workflow"

make_tree
sed -i '/^  FLUTTER_VERSION:/d' "$case_dir/.github/workflows/quality.yml"
expect_fail check_workflow_pins "missing Flutter toolchain pin"

printf 'Guard self-check passed.\n'
