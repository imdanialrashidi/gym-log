# Performance evidence

Budgets come from spec Section 22 (`NFR-PERF-001`–`NFR-PERF-006`). Two kinds of
evidence exist, and they are not interchangeable:

| Kind | Where | What it can prove |
|---|---|---|
| CI micro-benchmarks | `tool/benchmarks/`, this folder | Pure Dart work: prefill, chart aggregation, JSON encoding on the deterministic 10,000-set fixture. Runs on every gate and fails on a budget regression. |
| Reference-device run | [REFERENCE_DEVICE.md](REFERENCE_DEVICE.md) | Cold start, tap latency, scroll smoothness, chart first paint, export responsiveness. Profile mode on the owner's physical device only. |

An emulator, debug build, or CI timing never satisfies a device budget. A
device budget without an owner-measured result is `UNPROVEN`, not passed.

## CI micro-benchmarks

```sh
dart run tool/benchmarks/run_benchmarks.dart
```

- Fixture: `tool/benchmarks/benchmark_fixture.dart` — 1,000 finished sessions,
  10 sets each, one exercise (10,000 logged sets), 1,000 chart points. It is
  deterministic; no random values or clock reads.
- Measurement: 3 warm-up runs, then 15 measured runs; the **median** is
  compared with the budget. The harness exits non-zero when any median exceeds
  its budget (`tool/benchmarks/thresholds.json`).
- Budgets: prefill ≤ 50 ms (`NFR-PERF-003`), chart aggregation ≤ 200 ms
  (`NFR-PERF-005`, aggregation proxy only), JSON export ≤ 3000 ms
  (`NFR-PERF-006`, codec proxy only).
- Record a baseline on the same pinned Dart/Flutter and fixture:

  ```sh
  dart run tool/benchmarks/run_benchmarks.dart \
    --output docs/perf/benchmark-baseline.json
  ```

- After an optimization, rerun with the same command and the same fixture, then
  compare medians and p90 in the JSON. Do not compare runs made with a different
  fixture, iteration count, or Dart version. The current baseline and the
  budgets' status are in [RESULTS.md](RESULTS.md).

The gate runs the harness through `scripts/project-verify.sh`, so a threshold
regression fails CI. The fixture shape itself is pinned by
`test/perf/benchmark_fixture_test.dart`. To seed a physical device for the
device budgets, write the same fixture as a valid backup and import it:

```sh
dart run tool/benchmarks/write_device_fixture.dart --output build/benchmark-10k.json
```

## Device budgets

Owner selection of the reference device and the full profile-mode procedure are
in [REFERENCE_DEVICE.md](REFERENCE_DEVICE.md). Until the owner records results,
`NFR-PERF-001`, `002`, `004`, and the device portions of `005`/`006` remain
`UNPROVEN` with the exact owner step recorded in [RESULTS.md](RESULTS.md).
