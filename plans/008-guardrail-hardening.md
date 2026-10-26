# Plan 008: Harden the secret, CI, and performance guardrails

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. This repository
> is local-only on `main`: do not branch, commit, push, or open a PR.
>
> **Drift check (run first)**: `git status --short -- tool .github scripts docs test` and
> `git diff --stat 852445e..HEAD -- tool .github scripts docs test`.
> Preserve unrelated uncommitted changes.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW-MED
- **Depends on**: 004 for the benchmark IDs (do that plan first)
- **Category**: security/DX
- **Planned at**: commit `852445e`, 2026-10-25 (dirty working tree)

## Why this matters

Three controls look stronger than they are. The signing-material guard only
matches double-quoted Gradle passwords and a short list of filenames, so a
conventional `signing.properties`, a base64 key named `release.b64`, or a
`.pem` key passes while the guard prints “no keystore or private key.” The
quality workflow resolves `actions/checkout`, `setup-java`, and `cache` from
movable tags with the checkout credential persisted, while the release workflow
already pins SHAs. The performance runner iterates only the entries present in
`thresholds.json`, so deleting an entry silently removes it from the gate while
printing success; its budgets are also far above the recorded medians. These
are cheap, mechanical fixes that make the existing claims true.

## Current state

- `tool/guards/check_no_signing_material.dart:17-28` — extensions and the
  quoted-password regex; `:43-57` — filename and content selection.
- `.gitignore:33-40` — ignores `android/key.properties`, `*.jks`, `*.keystore`,
  `*.jks.b64`, `*.keystore.b64`, `*.p12`, `*.pfx`, `release-keystore*`.
- `docs/QUALITY.md:254` — claims the guard catches a literal signing password.
- `.github/workflows/quality.yml:28-31,47` — mutable tags; no
  `persist-credentials: false`.
- `.github/workflows/release.yml:35-41` — pinned SHAs and
  `persist-credentials: false`; reuse them.
- `tool/benchmarks/run_benchmarks.dart:70-115` — iterates `thresholds.json`
  entries and prints success at `:140`; `thresholds.json:8,14,20` — budgets;
  `docs/perf/benchmark-baseline.json:18,29,40` — medians.
- `scripts/project-verify.sh` — runs the guards and benchmarks; add the new
  checks there and mirror them in `docs/QUALITY.md`.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Signing guard | `dart run tool/guards/check_no_signing_material.dart` | passes on the clean tree |
| L10n/other guards | `dart run tool/guards/check_l10n.dart` (and the other guard commands in `scripts/project-verify.sh`) | pass |
| Benchmarks | `dart run tool/benchmarks/run_benchmarks.dart` | all pass; new metric IDs reported |
| Workflow syntax | `python3 -c "import yaml,sys; [yaml.safe_load(open(p)) for p in sys.argv[1:]]" .github/workflows/quality.yml .github/workflows/release.yml` | exit 0 (PyYAML available; otherwise use a parser already in the toolchain and record it) |
| Analyze/format | `flutter analyze --fatal-infos --fatal-warnings`; `dart format --output=none --set-exit-if-changed tool lib test` | exit 0 |
| Full gate | `bash scripts/verify.sh` | exit 0 |

## Scope

**In scope**:
- `tool/guards/check_no_signing_material.dart`
- `.gitignore`
- `.github/workflows/quality.yml`
- `tool/benchmarks/run_benchmarks.dart`, `tool/benchmarks/thresholds.json`
- `tool/guards/check_workflow_pins.dart` (create) and `scripts/project-verify.sh`
- `docs/QUALITY.md` guard table/prose, `docs/perf/README.md`, `docs/perf/RESULTS.md`
- Focused tests for the guard and the benchmark coverage check.

**Out of scope**:
- Changing the release workflow beyond reusing its pinned SHAs.
- Adding a secret-scanning service or a new dependency.
- Rotating any real key; there is no key in the tree.
- Changing the spec budgets (`NFR-PERF-003/005/006`); the regression gate is an
  additional, stricter floor (see Step 3).

## Git workflow

- Work directly on `main`; preserve unrelated changes.
- Do not branch, commit, push, or open a PR.

## Steps

### Step 1: Broaden the signing-material guard

In `check_no_signing_material.dart`:
- Filenames: add `.pem`, `.key`, `.p8`, `.b64` (any name), `signing.properties`,
  `keystore.properties`, and `release-keystore*`; keep the existing names.
- Content: read `.properties`, `.env`, `.sh`, `.pem`, `.key`, and `.b64` files.
  Keep the private-key block match; add an unquoted-password match for:
  `storePassword`, `keyPassword`, `GYM_LOG_KEYSTORE_PASSWORD`,
  `GYM_LOG_KEY_PASSWORD` followed by `=` or `:` and a value that does not start
  with `$`, `${`, or `<`. Do not flag documentation placeholders.
- Keep the guard path-free in its output (file path only, never the value).
- Refactor the scan into `List<String> scanForSigningMaterial(Directory root)`
  so a test can call it on a temp directory; `main` keeps `Directory.current`
  and prints/exits as today.
- Add `test/guards/signing_material_guard_test.dart` (create the directory if
  needed) that imports the guard, builds a temp tree, and asserts:
  - clean tree → empty findings;
  - `signing.properties` with an unquoted password → finding;
  - `release.b64` → finding;
  - `id_rsa.pem` with a private-key block → finding;
  - a docs file with the literal placeholder `GYM_LOG_KEYSTORE_PASSWORD=<from password manager>`
    is not a finding.
  Guard tests may need `flutter test` (the repo has `flutter_test`); use
  `dart:io` temp dirs and `addTearDown`.

**Verify**: `dart run tool/guards/check_no_signing_material.dart` → passes on the clean tree, and the new test passes.

### Step 2: Pin the quality workflow

In `quality.yml`:
- Use the same full-SHA `actions/checkout` and `actions/setup-java` as
  `release.yml` (`11d5960a326750d5838078e36cf38b85af677262` and
  `cf277c60eb25467037889841efdb72551f06f6c3`).
- Resolve `actions/cache@v4` to its current commit:
  `git ls-remote https://github.com/actions/cache refs/tags/v4` and use the
  40-hex SHA (record the tag in a trailing comment). If the network is
  unavailable, STOP and report; do not leave `@v4`.
- Add `persist-credentials: false` under checkout's `with`.
- Add a short comment at the top: “Actions must be pinned to a full commit
  SHA; see `docs/QUALITY.md`.”

**Verify**: `git diff -- .github/workflows/quality.yml` shows three SHAs and
`persist-credentials: false`; the YAML still parses.

### Step 3: Add a pin/toolchain guard

Create `tool/guards/check_workflow_pins.dart` (Dart, `dart:io` only):
- Read `.github/workflows/*.yml`.
- For every `uses:` line, require `@[0-9a-f]{40}` (ignore local `./` paths).
- Read `tool/toolchain.env` and both workflows; assert `FLUTTER_VERSION`,
  `FLUTTER_ARCHIVE`, and `FLUTTER_SHA256` match the env file, and that
  `.flutter-version` matches `FLUTTER_VERSION`.
- Exit 1 with a `FAIL:` message per violation; exit 0 with a one-line summary.
- Add it to `scripts/project-verify.sh` next to the other guards, and add a row
  to the `docs/QUALITY.md` guard table.

Add a focused test if the guard has non-trivial parsing; otherwise the guard’s
clean-run plus a temporary failing edit (then revert) is the proof. Do not
commit the temporary edit.

**Verify**: `dart run tool/guards/check_workflow_pins.dart` → passes; introduce
a temporary `@v4` and confirm exit 1, then revert.

### Step 4: Make the performance gate unable to skip

In `run_benchmarks.dart`:
- Define the expected metric IDs in code:
  `{ 'NFR-PERF-003': 'prefill_query', 'NFR-PERF-005': 'chart_aggregation',
  'NFR-PERF-006': 'export_json' }` plus any metrics added by plan 004
  (`single_set_pr`, `full_pr_map`, `document_validation`).
- Before running, assert every expected ID appears exactly once in
  `thresholds.json` and that the referenced metric exists in `benchmarks`; if
  not, print `FAIL: expected benchmark missing` and exit 1.
- Keep the spec `budgetMs` comparison. Add an optional `regressionBudgetMs` per
  entry, and fail when the median exceeds **either** budget.
- Derive `regressionBudgetMs` from the recorded baseline with a documented
  margin: `max(1, ceil(baselineP90 * 3))` for each metric, rounded to a
  sensible unit. Update `thresholds.json` with those values and a comment in
  `docs/perf/README.md` explaining that they are regression floors, not the
  spec budgets. Do not set a floor below the measured noise; if a CI run
  flakes, raise the margin and record why.
- Update `docs/perf/RESULTS.md` with a before/after table (spec budget,
  regression budget, recorded median/p90).
- Add a negative test: a temporary thresholds file missing `prefill_query`
  must exit non-zero. Do not leave the temp file.

**Verify**: `dart run tool/benchmarks/run_benchmarks.dart` → all pass and the
runner names all expected metrics; the missing-metric temp run exits 1.

### Step 5: Update docs and run the gate

Update `docs/QUALITY.md` (guard table and the “proven by temporarily
introducing” paragraph), `docs/perf/README.md`, and `docs/perf/RESULTS.md`.
Run the full table. If CI is unavailable, report the local result only.

## Test plan

- Signing guard: clean, unquoted password, `.b64` key, private-key `.pem`,
  documentation placeholder.
- Workflow guard: clean pass; a `@v4` and a mismatched Flutter SHA fail.
- Benchmark runner: missing expected metric fails; median above either budget
  fails; clean pass prints all IDs.
- Existing guards/tests stay green.

## Done criteria

- [ ] The signing guard detects unquoted properties passwords, `.b64`, `.pem`,
  and alternate properties filenames; the new guard test passes.
- [ ] `quality.yml` uses full SHAs for all three actions and
  `persist-credentials: false`.
- [ ] `check_workflow_pins.dart` passes and is in `scripts/project-verify.sh`.
- [ ] The benchmark runner fails when an expected metric is absent or either
  budget is exceeded; all metrics are reported.
- [ ] `bash scripts/verify.sh` passes; docs updated; `plans/README.md` row updated.
- [ ] No out-of-scope files; no secret value is printed anywhere.

## STOP conditions

Stop and report if:
- Resolving the `actions/cache` tag needs network access that is unavailable;
  do not guess a SHA.
- A regression budget flakes on the first recorded CI run; report the numbers
  and propose a margin instead of removing the check.
- Broadening the guard produces a false positive on a legitimate repository
  file; adjust the rule narrowly and record the case, do not add a blanket
  exception.
- The release workflow's SHAs have changed upstream; do not copy a stale SHA
  without confirming it is the current reviewed commit.

## Maintenance notes

- The guard is a backstop, not a substitute for keeping keys outside the
  repository. Any real leak still requires rotation.
- Pinned action SHAs must be updated deliberately (Dependabot or an owner
  review), not by moving a tag.
- Regression budgets are derived from the committed baseline; refresh the
  baseline and the floors together after an intentional optimization.
- A reviewer should verify the guard test’s temp files never contain a real
  key and that no value is printed.
