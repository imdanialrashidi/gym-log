# Performance results

Last micro-benchmark baseline: **2026-10-25** on the pinned Flutter 3.47.7 /
Dart 3.13.5 Linux x64 workstation. Raw artifact:
[`benchmark-baseline.json`](benchmark-baseline.json). Device row status:
**UNPROVEN** until the owner runs [REFERENCE_DEVICE.md](REFERENCE_DEVICE.md).

## CI micro-benchmarks (10,000-set fixture)

Command (same conditions for every rerun):

```sh
dart run tool/benchmarks/run_benchmarks.dart --output docs/perf/benchmark-baseline.json
```

3 warm-up runs, 15 measured runs, median compared with the budget.

| ID | Metric | Median | p90 | Budget | Result | Scope |
|---|---|---:|---:|---:|---|---|
| `NFR-PERF-003` | Prefill query, exercise with 10,000 logged sets | 0.083 ms | 0.112 ms | 50 ms | **PASS** | Automated fixture benchmark (the spec's required method) |
| `NFR-PERF-005` | Chart aggregation, 1,000 points | 1.348 ms | 3.653 ms | 200 ms | **PASS (proxy)** | Aggregation only; first paint needs the device trace |
| `NFR-PERF-006` | JSON export, 10,000 sets | 25.619 ms | 34.972 ms | 3000 ms | **PASS (proxy)** | Codec only; UI responsiveness needs the device |

No optimization was claimed in this slice. This is the recorded baseline: after
a scoped optimization, rerun the exact command above and compare medians/p90 in
the JSON. A shorter or different fixture invalidates the comparison.

A same-condition rerun inside the full gate measured 0.070 ms / 1.436 ms /
19.905 ms for the same three benchmarks; the variation is normal runner noise
and every median stays far below its budget.

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

## Current blockers to closing the device rows

- Reference device: **Needs Decision** (owner). No emulator result may be
  substituted.
- The permanent `applicationId` is still a placeholder, so a permanent-key
  profile APK cannot be produced; the profile measurement can use the debug key,
  but the release checklist still waits for the owner decision.
- Owner name/date/sign-off fields stay blank until an actual run.
