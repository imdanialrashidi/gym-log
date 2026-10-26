# Performance results

Last micro-benchmark baseline: **2026-10-26** on the pinned Flutter 3.47.7 /
Dart 3.13.5 Linux x64 workstation. Raw artifact:
[`benchmark-baseline.json`](benchmark-baseline.json). Device row status:
**UNPROVEN** until the owner runs [REFERENCE_DEVICE.md](REFERENCE_DEVICE.md).

## CI micro-benchmarks (10,000-set fixture)

Command (same conditions for every rerun):

```sh
dart run tool/benchmarks/run_benchmarks.dart --output docs/perf/benchmark-baseline.json
```

3 warm-up runs, 15 measured runs, median compared with the budget.

| ID | Metric | Median | p90 | Spec budget | Regression floor | Result | Scope |
|---|---|---:|---:|---:|---:|---|---|
| `NFR-PERF-003` | Prefill query, exercise with 10,000 logged sets | 0.093 ms | 0.169 ms | 50 ms | 1 ms | **PASS** | Automated fixture benchmark (the spec's required method) |
| `NFR-PERF-005` | Chart aggregation, 1,000 points | 3.093 ms | 4.004 ms | 200 ms | 8 ms | **PASS (proxy)** | Aggregation only; first paint needs the device trace |
| `NFR-PERF-006` | JSON export, 10,000 sets | 21.615 ms | 26.880 ms | 3000 ms | 83 ms | **PASS (proxy)** | Codec only; UI responsiveness needs the device |
| `CI-PR-001` | PR types for the last set, single-set pass | 0.681 ms | 1.136 ms | 100 ms | 6 ms | **PASS** | Tap-path proxy; `NFR-PERF-002` stays `UNPROVEN` |
| `CI-PR-002` | Full PR map, 10,000 sets | 3.211 ms | 7.465 ms | 100 ms | 9 ms | **PASS** | Whole-scan baseline for `CI-PR-001` |
| `CI-MUT-001` | Whole-document validation (`copyWith`) | 0.763 ms | 0.848 ms | 100 ms | 4 ms | **PASS** | Runs on every mutation; not a device budget |
| `CI-STATS-001` | Weekly overview, 8 weeks + weight trend | 1.529 ms | 1.746 ms | 100 ms | 6 ms | **PASS** | Dashboard/progress derivation; not a device budget |

This baseline includes one scoped optimization: the weekly overview first
measured **8.388 ms** median (10.080 ms p90) with the 27 ms floor, then
`recentWeekStats` gained an early cutoff so sessions before the requested
window skip calendar arithmetic and bucketing. The same fixture and command
then measured **1.529 ms** median (1.746 ms p90), and the floor was tightened
to `max(1, ceil(1.746 × 3)) = 6 ms`. The tap path was also split so a committed
set rebuilds only its row plus that exercise's stat strip, not every row; this
is covered by the widget rebuild test rather than a wall-clock budget. This is
the recorded baseline: rerun the exact command above and compare medians/p90 in
the JSON. A shorter or different fixture invalidates the comparison.

The `export_json` median is below 50 ms, so the JSON encode stays on the UI
isolate in this slice: the codec is not the dominant per-tap cost, but it still
does not prove `NFR-PERF-002`. The single-set PR pass is about 4× cheaper than
the previous full-map scan (0.672 ms vs 2.766 ms), and the whole-document
validation measured 0.681 ms. None of these rows is a device measurement; the
tap-to-visible-confirmation budget remains **UNPROVEN**.

Regression floors are `max(1, ceil(baseline p90 × 3))` in whole milliseconds
from the committed baseline. They are an additional gate, not the spec budgets:
a median above either number fails the runner. A temporary thresholds file
without `prefill_query` was also run; the runner exited 1 with
`FAIL: expected benchmark missing or duplicated: NFR-PERF-003`.

### Red-before-green evidence for the threshold gate

A temporary 60 ms busy-wait was injected around the measured prefill call (then
reverted; no fault path remains in the source). The same command produced:

```text
ID            metric                   median        p90     budget  result
NFR-PERF-003  prefill_query         60.154 ms  60.609 ms      50 ms  FAIL
NFR-PERF-005  chart_aggregation      1.229 ms   3.135 ms     200 ms  PASS
NFR-PERF-006  export_json           24.797 ms  36.287 ms    3000 ms  PASS
Performance micro-benchmark budget exceeded. See docs/perf/.
BENCH_EXIT=1
```

The gate fails CI because `scripts/project-verify.sh` runs this harness.

## Device budgets

A budget is `PASS` only with an owner measurement on the selected reference
device in profile mode. Everything else below is `UNPROVEN`; the owner step is
the exact section of [REFERENCE_DEVICE.md](REFERENCE_DEVICE.md).

| ID | Budget | Status | Owner step |
|---|---|---|---|
| `NFR-PERF-001` | Cold start to interactive Workout ≤ 1.5 s (median of 10) | **UNPROVEN** | [Section 3](REFERENCE_DEVICE.md) after selecting a device in Section 1 |
| `NFR-PERF-002` | Tap ✓ to visible confirmation ≤ 100 ms | **UNPROVEN** | [Section 4](REFERENCE_DEVICE.md) |
| `NFR-PERF-003` | Prefill ≤ 50 ms on the 10,000-set fixture | **PASS** | Automated micro-benchmark above; the spec does not require a device for this budget |
| `NFR-PERF-004` | History scroll with 10,000 sets, large majority of frames ≤ 16 ms | **UNPROVEN** | [Section 5](REFERENCE_DEVICE.md) |
| `NFR-PERF-005` | Chart first paint with 1,000 points ≤ 200 ms | **UNPROVEN** | [Section 6](REFERENCE_DEVICE.md); CI aggregation proxy is not first paint |
| `NFR-PERF-006` | JSON export of 10,000 sets: UI responsive, a few seconds | **UNPROVEN** | [Section 7](REFERENCE_DEVICE.md); CI codec time is not UI responsiveness |

## Startup work (2026-10-26)

The startup path now resolves the app support directory once, starts the
document load before `runApp`, caches the single dark `ThemeData`, defers photo
recovery to after the first frame, and shows a static skeleton instead of a
continuously repainting spinner. The document load is consumed once by the
controller and an explicit retry reads it again. These are structural changes,
not a device measurement: `NFR-PERF-001` stays **UNPROVEN** until the
reference-device profile run records cold start to the interactive Workout
screen.

## Current blockers to closing the device rows

- Reference device: **Needs Decision** (owner). No emulator result may be
  substituted.
- The permanent `applicationId` is still a placeholder, so a permanent-key
  profile APK cannot be produced; the profile measurement can use the debug key,
  but the release checklist still waits for the owner decision.
- Owner name/date/sign-off fields stay blank until an actual run.
