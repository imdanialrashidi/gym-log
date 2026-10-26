# Plan 009: Give the guard suite a repeatable self-check

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- tool scripts docs` and
> `git diff --stat 852445e..HEAD -- tool scripts docs`.
> Preserve unrelated uncommitted changes.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 008 (the new workflow-pin guard and signing-guard refactor)
- **Category**: tests/DX
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

The l10n, directionality, calendar-boundary, destructive-reset, changelog, and
signing-material guards are load-bearing non-negotiables implemented as regex
text scans. They are “proven” only by a human temporarily introducing a
violation and reverting it. The destructive-reset guard silently `continue`s
when `lib/` is missing and still prints “guard passed” after scanning zero
files. A rename, a regex edit, or a missing root can silently disable a control
while the canonical gate stays green. This plan adds a self-check that copies
the guard-relevant tree to a temp directory, runs every guard on a clean copy,
and then introduces one known violation per guard and asserts a non-zero exit.
It also makes the destructive guard fail closed when its roots are absent.

## Current state

- `tool/guards/check_no_destructive_reset.dart:10-18` — missing roots are
  skipped; `:45-53` — it prints “passed” even when nothing was scanned.
- `tool/guards/check_l10n.dart`, `check_fa_review_sheet.dart`,
  `check_calendar_boundary.dart`, `check_directionality.dart`,
  `check_changelog.dart`, `check_no_signing_material.dart` — all read relative
  paths (`lib/`, `docs/`, `pubspec.yaml`, `CHANGELOG.md`) and exit non-zero on
  a finding; none has a repeatable negative test.
- `scripts/project-verify.sh` runs the guards in one `step` block.
- `docs/QUALITY.md:240-261` — guard table and the “proven by temporarily
  introducing the violation” paragraph.
- `tool/release/selfcheck.sh` — the only existing repeatable self-check; use
  its shell style (`set -Eeuo pipefail`, `mktemp -d`, `trap`).

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Self-check | `tool/guards/selfcheck.sh` | exit 0; prints one PASS line per guard |
| Destructive guard | `dart run tool/guards/check_no_destructive_reset.dart` | exit 0 on the real tree |
| Full gate | `bash scripts/verify.sh` | exit 0 |
| Shell syntax | `bash -n tool/guards/selfcheck.sh` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed tool` | exit 0 |

## Scope

**In scope**:
- `tool/guards/selfcheck.sh` (create)
- `tool/guards/check_no_destructive_reset.dart`
- `scripts/project-verify.sh`
- `docs/QUALITY.md` (guard/self-check paragraph)
- Any guard script only if a missing-root or cwd assumption blocks the
  self-check; keep those edits minimal.

**Out of scope**:
- Rewriting every guard to accept a `--root` flag.
- Adding new l10n/direction/calendar rules.
- Running the self-check on every developer keystroke; it runs in the project
  lane.
- Testing the release packaging tools (already covered by
  `tool/release/selfcheck.sh`).

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Make the destructive guard fail closed

In `check_no_destructive_reset.dart`, change a missing root from `continue` to
a violation:

```dart
if (!root.existsSync()) {
  violations.add('required scan root is missing: ${root.path}');
  continue;
}
```

Keep the existing pattern list. Update the failure text to explain that a
missing root means the guard cannot prove the invariant. Add a `--root` option
only if a test needs it; the self-check below uses a copied tree, so it does
not.

**Verify**: `dart run tool/guards/check_no_destructive_reset.dart` → exit 0 on
the real tree; a temp tree without `lib/` exits 1 (the self-check covers this).

### Step 2: Add the self-check script

Create `tool/guards/selfcheck.sh` with the same shell style as
`tool/release/selfcheck.sh`:

```sh
#!/usr/bin/env bash
# Runs every guard on a clean copy, then introduces one known violation per
# guard and requires a non-zero exit. No source file in the repository is
# modified: all mutations happen in a mktemp copy.
set -Eeuo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
```

`make_tree()` copies the guard inputs into `$tmp/case`:
`lib`, `packages`, `tool/toolchain.env`, `docs/l10n`, `docs/spec` if the
changelog/fa guard needs it, `pubspec.yaml`, `CHANGELOG.md`, and `.github` if
the plan-008 workflow guard exists. Do not copy `build/`, `.git/`,
`.dart_tool/`, or the test goldens (they are irrelevant and large).

`run_guard(name)` runs `(cd "$case" && dart run "$repo/tool/guards/$name")`
and asserts exit 0. `expect_fail(name, label)` runs the same and asserts a
non-zero exit; if it exits 0, print `FAIL: $name did not detect $label` and
exit 1.

Cases, each on a fresh `make_tree`:
1. Clean copy: every guard passes.
2. l10n: remove `aboutTitle` from `app_fa.arb` (use `python3 -c` JSON editing);
   `check_l10n` fails.
3. fa review: delete the `aboutTitle` row from `docs/l10n/fa-review-sheet.md`;
   `check_fa_review_sheet` fails.
4. directionality: append `lib/features/guard_fixture.dart` containing
   `EdgeInsets.only(left: 8)`; `check_directionality` fails.
5. calendar: append a file importing `package:shamsi_date/shamsi_date.dart`;
   `check_calendar_boundary` fails.
6. destructive: append `void x() { deleteDatabase('x'); }`; the guard fails.
7. missing root: remove `lib` from a copy; the destructive guard fails.
8. signing: create `release.b64` with fake text; `check_no_signing_material`
   fails (this assumes plan 008's broadened rule; if plan 008 is not done,
   use `fake.jks` instead and note it).
9. changelog: remove the `Build:` line from the newest entry;
   `check_changelog` fails.
10. If plan 008's `check_workflow_pins.dart` exists, change a `uses:` to
    `@v4` and assert it fails.

Print one `PASS: <guard> (<case>)` line per case and a final
`Guard self-check passed.`

**Verify**: `bash -n tool/guards/selfcheck.sh` → exit 0; `tool/guards/selfcheck.sh` → exit 0 with all cases.

### Step 3: Wire it into the project lane

Add a `step "Guard self-check"` + `tool/guards/selfcheck.sh` to
`scripts/project-verify.sh` after the individual guards and before the tests.
Add a sentence to `docs/QUALITY.md` that the self-check proves detection (not
just a clean run) and that it is part of the gate.

**Verify**: `bash scripts/project-verify.sh` → reaches the self-check and
passes (other steps may be unavailable in the environment; report that).

### Step 4: Run the gate

Run the table. If Flutter/Dart are unavailable, report `BLOCKED`; do not claim
the self-check ran.

## Test plan

- Self-check clean run passes all guards.
- One known violation per guard fails; the failure is attributed to the right
  guard.
- Missing `lib/` fails the destructive guard instead of passing.
- The self-check leaves the repository untouched (`git status --short` before
  and after are identical apart from the planned files).

## Done criteria

- [ ] `tool/guards/selfcheck.sh` exists, is executable, and exits 0.
- [ ] Every guard has at least one negative fixture that makes it exit non-zero.
- [ ] The destructive guard fails when a scan root is missing.
- [ ] `scripts/project-verify.sh` runs the self-check; `docs/QUALITY.md` says so.
- [ ] `git status` shows no mutation from the self-check.
- [ ] Full gate passes, or the missing prerequisite is `BLOCKED`; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- A guard cannot be exercised from a copied tree without a code change beyond
  the scope; report which guard and why instead of weakening the fixture.
- The copied tree needs a dependency or network access to run a guard.
- A negative fixture fails for the wrong reason (for example a missing file
  instead of the intended violation); fix the fixture, do not accept a false
  green.
- The self-check is too slow for the gate (more than a few seconds); reduce
  copies, do not remove cases.

## Maintenance notes

- Add a new case whenever a guard is added or its failure mode changes.
- The self-check is a control, not a replacement for the real guards; never
  skip it to get a green gate.
- Keep fixture mutations in the temp copy; a self-check that edits the
  repository is a bug.
- A reviewer should check that `trap` removes the temp directory even on
  failure and that no secret-like fixture is committed.
