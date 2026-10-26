# Plan 010: Make the repository status and contract docs truthful

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- AGENTS.md docs lib/app/app_info.dart` and
> `git diff --stat 852445e..HEAD -- AGENTS.md docs lib/app/app_info.dart`.
> The working tree already contains uncommitted workflow edits; preserve them.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: docs
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

The documents agents and reviewers load first describe an older project.
`AGENTS.md` (always loaded) still says this is an M0 scaffold and that product
features are later milestones, although the app is at M9 with a JSON data
store, sessions, charts, photos, and backup. `docs/ARCHITECTURE.md` says data,
domain, and feature layers remain target architecture and asserts
`drift_schemas/` snapshots and migration tests that do not exist.
`docs/DEVELOPMENT.md` still says not to add the release workflow that exists and
keeps an M0 limits section that says tabular figures are unverified “until set
rows exist.” `docs/QUALITY.md` mandates migration tests with no database. These
are not cosmetic: a fresh agent will mis-scope work, and a reviewer can cite a
control that is not wired. This plan makes the status and current-state claims
match the code while preserving every requirement status and every genuine
target-design statement as target design.

## Current state

- `AGENTS.md:7` — “The M0 scaffold exists … database and product features remain
  later milestones.”
- `docs/ARCHITECTURE.md:3` — “data, domain, and feature layers remain target
  architecture”; `:8` — main modules list ends at M8; `:25` — target layout
  includes `integration_test/` and `drift_schemas/`; `:114` — operational
  baseline says `drift_schemas/` holds snapshots and migration tests run in CI.
- `docs/DEVELOPMENT.md:146-148` — “Do not add a release workflow or signing
  material until …”; `:172-185` — “Known M0 limits” says tabular figures are
  unverified until set rows exist.
- `docs/QUALITY.md:13-57` — cumulative M0–M9 status (keep); `:104` — mandatory
  migration tests; `:207` — “Canonical M0 commands” heading.
- `docs/DEPENDENCIES.md:26` — Vazirmatn row says tabular-figure alignment
  remains unverified until set rows exist; `:24` — `cupertino_icons` rationale
  says it is referenced by the stack (no Dart usage exists).
- `lib/app/app_info.dart:1-2` — comment says `test/data/app_info_test.dart`
  enforces the version pair; that file does not exist.
- `.github/workflows/release.yml` and `docs/RELEASE.md` — the release workflow
  exists and is documented; `docs/DEVELOPMENT.md` contradicts it.
- No `drift_schemas/`, `integration_test/`, Drift dependency, or migration
  tests exist (`pubspec.yaml`, repository tree).

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Doc links | `python3 -c` link checker or `git diff --check` (see below) | exit 0 |
| Whitespace | `git diff --check` | exit 0 |
| Docs lane | Inspect the scoped diff; no app gate required for docs-only work (`docs/QUALITY.md` “Documentation” lane) | scoped, no broken links |
| Full gate (optional) | `bash scripts/verify.sh` | exit 0 |

Use the repository’s documentation lane: docs-only work does not require the
Flutter gate. Do not run a build just to edit prose.

## Scope

**In scope**:
- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/DEVELOPMENT.md`
- `docs/QUALITY.md`
- `docs/DEPENDENCIES.md`
- `lib/app/app_info.dart` (comment only)

**Out of scope**:
- Changing any requirement status or acceptance criterion in `docs/spec/`.
- Implementing Drift, Safe Mode, or migration tests; this plan only labels them
  truthfully.
- The release workflow or signing behavior.
- Removing dependencies (the `cupertino_icons` cleanup is a separate
  quick-fix; only fix its ledger note here).
- Rewriting the cumulative milestone history in `docs/QUALITY.md`.

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Correct the always-loaded map

Replace `AGENTS.md:7` with the README’s current status in one or two sentences:
M9 hardening/release engineering, the four-tab fa/en RTL app, the interim
JSON document store in `lib/data/`, and the shipped exercise/program/logging/
history/progress/backup/photo slices. State that Drift, migration snapshots,
and Safe Mode are **target design, not implemented**. Keep the rest of the
file unchanged: the non-negotiables, workflow, and commands are current.

**Verify**: read the paragraph and compare it with `README.md:7-27`; no
requirement ID is asserted.

### Step 2: Correct `docs/ARCHITECTURE.md`

- Line 3: say the M0 scaffold is the origin, and the M2–M9 feature layers and
  the interim JSON document store are implemented; Drift/Safe Mode remain
  target architecture.
- Line 8: add the implemented M9 surfaces (About, backup policy row,
  benchmarks, release workflow) and keep M2–M8.
- Line 25: leave the target layout block, but label `integration_test/` and
  `drift_schemas/` as target directories that do not exist yet. Do not imply
  they are present.
- Line 114: change “Migrations: `drift_schemas/` holds one snapshot per version;
  migration tests run in CI…” to “**Target design (not implemented):** when the
  Drift layer lands, `drift_schemas/` will hold one snapshot per version and
  migration tests will run in CI. The current store is the JSON document; the
  pre-Replace data snapshot is the only current snapshot control.”
- Keep the “When the M1 Drift layer lands it must import this document” rule.

**Verify**: the only remaining claims about migration tests/snapshots are
labelled target design; no code claim is removed that is actually true.

### Step 3: Correct `docs/DEVELOPMENT.md`

- Replace the “Do not add a release workflow…” paragraph with a pointer to
  `.github/workflows/release.yml` and `docs/RELEASE.md`, and state that release
  builds are refused while the `applicationId` is the placeholder or signing
  secrets are absent. Do not claim a release has been performed.
- Retitle “Known M0 limits” to “Known current limits” and update:
  - remove the “until set rows exist” tabular-figure claim, or restate it as
    “device tabular-figure rendering remains unverified (`L10N-003`)”;
  - keep the device-only `UNPROVEN` items and the real-picker/backup gaps;
  - keep the language-choice-in-memory limit if it is still true (verify in
    `lib/app/locale_override.dart`).
- Do not change the command list; it is current.

**Verify**: `grep -n "release workflow\|Known M0\|until set rows" docs/DEVELOPMENT.md` returns no contradictory M0 wording.

### Step 4: Correct `docs/QUALITY.md` without deleting the milestone history

- Leave the M0–M9 paragraphs as history; add one sentence that the project is
  at M9 and Drift/Safe Mode are not implemented.
- In “Mandatory test scope”, mark the migration bullet “**When the Drift layer
  lands (target design)**” and state that JSON import/export and the current
  data-snapshot tests are the active mandatory evidence.
- Rename “Canonical M0 commands” to “Canonical project commands”.
- In the guard table/prose, keep the manual-mutation proof wording until plan
  009 lands; if plan 009 is already done, point at the self-check.

**Verify**: no sentence requires a migration test that cannot exist today;
the active mandatory scopes remain intact.

### Step 5: Fix the small stale references

- `docs/DEPENDENCIES.md:26`: replace “tabular-figure alignment remains
  `UNPROVEN` until set rows exist” with the current status (device rendering
  unverified; set rows and goldens exist). Do not remove the dependency rows.
- `docs/DEPENDENCIES.md:24`: correct the `cupertino_icons` rationale to say it
  is a direct pin not referenced by the app’s Dart code; leave removal for a
  separate quick-fix.
- `lib/app/app_info.dart:1-2`: replace the nonexistent
  `test/data/app_info_test.dart` reference with the real coverage:
  `test/data/export_reminder_test.dart:20` reads the pubspec version and
  compares it with `appVersion`. Comment-only change.

**Verify**: `grep -rn "app_info_test" lib test docs` returns no match.

### Step 6: Run the documentation lane

- `git diff --check` → exit 0.
- Read the scoped diff and verify every internal link still resolves (the
  files already link each other).
- Confirm no `docs/spec/` file, requirement status, or acceptance text changed.
- Optionally run `bash scripts/verify.sh` if the environment has Flutter; it is
  not required for a docs-only change, but it is the strongest proof.

**Verify**: `git status --short` lists only the in-scope files (plus unrelated
pre-existing changes); `git diff -- docs/spec` is empty.

## Test plan

- No runtime tests; docs-only lane.
- Check every updated claim against the code: `README.md`, `pubspec.yaml`,
  repository tree, `.github/workflows/release.yml`, and
  `lib/app/locale_override.dart`.
- `git diff --check`; manual link review.

## Done criteria

- [ ] `AGENTS.md` describes the M9 status and the interim JSON store; Drift/Safe Mode are labelled future.
- [ ] `ARCHITECTURE.md` no longer claims Drift snapshots/migration tests are implemented.
- [ ] `DEVELOPMENT.md` no longer forbids the existing release workflow and has no stale “until set rows exist” limit.
- [ ] `QUALITY.md` marks migration tests as target design and uses “Canonical project commands”.
- [ ] `app_info.dart` references the real version test; no `app_info_test` mention remains.
- [ ] `DEPENDENCIES.md` font row is current; no requirement status changed.
- [ ] `git diff --check` passes; `git diff -- docs/spec` is empty; `plans/README.md` row updated.

## STOP conditions

Stop and report if:
- A status claim is actually enforced by a tool in a way this survey missed;
  cite the tool and do not downgrade a real control.
- The user/owner has an active plan that intentionally treats Drift as
  implemented; do not contradict it.
- A doc edit would change a requirement status; that is out of scope.
- The working tree’s uncommitted workflow edits conflict with a paragraph;
  preserve them and report the conflict.

## Maintenance notes

- Update `AGENTS.md` and the status paragraph at each milestone; it is loaded
  every session and is the highest-leverage doc.
- Keep target design explicitly labelled; the spec’s Recommendation/Assumption
  statuses still govern acceptance.
- When Drift lands, move the migration claims from target design to current and
  add the real snapshot/test links; do not delete the history.
