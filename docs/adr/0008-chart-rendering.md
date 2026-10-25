# ADR-0008: Chart Rendering — Custom Painter

- Status: Accepted 2026-10-21
- Deciders: Engineering (M4 spike)
- Requirements: `PRG-001`, `PRG-002`, `PRG-003`, `NFR-PERF-005`, `L10N-009`
- Related: ADR-0005 (RTL time axis), Section 25.2

## Context

The progress charts need best-set weight, estimated 1RM, reps, and RIR over time; 1,000-point rendering; gaps for missing values; and a fixed left-to-right time axis in RTL layouts with Persian labels. The spec leaves the chart library open between `fl_chart` and a custom painter and asks for a measured spike.

## Spike

A throwaway Flutter web app rendered the same synthetic series in both implementations: 1,000 points, 27 gaps, 320×180 plot, Persian labels, RTL surrounding layout, disabled animation, and a fixed left-to-right time axis.

- Build: Flutter `3.47.7` profile web build (`flutter build web --profile`), Chrome `155.0.8059.39`, CanvasKit on Linux x86-64.
- Measurement: seven mount/paint cycles per page load; wall time from `setState` until `SchedulerBinding.endOfFrame`, i.e. after the browser frame completed. Two independent page loads per implementation.
- The spike lived in `/tmp` and was not added to this repository.

| Implementation | Load 1 first / median | Load 2 first / median | 200 ms budget |
|---|---:|---:|---|
| Custom painter | 29.90 ms / 16.40 ms | 19.70 ms / 18.80 ms | PASS on this workstation |
| `fl_chart` 1.3.0 | 42.70 ms / 27.00 ms | 28.60 ms / 23.70 ms | PASS on this workstation |

The custom painter was consistently faster. Both satisfy `NFR-PERF-005` in this environment, but this is **not** the reference-device measurement: no Android reference device is selected, so `NFR-PERF-005` remains `UNPROVEN` for release acceptance.

RTL observation: both implementations kept the data left to right. At 320 px with Persian date labels, `fl_chart`'s bottom titles clipped/truncated at both edges; the custom chart's labels are ordinary widgets with bounded width and ellipsis, and the LTR/RTL goldens show them uncut.

Dependency check for `fl_chart` 1.3.0 (fetched from pub.dev metadata and archive):

- License: MIT.
- Maintenance: published 2026-10-21; active, but the newest release was same-day, so the exact API is new.
- Runtime package size: 21,118,071-byte archive; 856 KiB `lib/`; adds `equatable` 3.0.0 (`vector_math` is already in the Flutter graph).
- Minimums: Dart ≥3.6.2, Flutter ≥3.27.4 (compatible with the pinned SDK).

## Decision

Render progress charts with a Flutter `CustomPainter` and small surrounding widgets. Do not add `fl_chart` or another chart dependency.

Reasons:

1. No new third-party code, license review, or supply-chain surface for four line charts.
2. The time axis stays explicitly left to right in RTL without depending on a library's text-direction behavior.
3. Gaps are explicit: a `null` value ends the current path segment, so missing RIR or e1RM never becomes zero.
4. Axis labels are widgets, so Persian labels can ellipsize inside their allocated space instead of clipping.
5. The measured first paint was lower with no animation/framework overhead.

## Consequences

- Chart code owns axes, gaps, markers, and semantics; it is covered by data-preparation tests, widget tests, and LTR/RTL goldens.
- Volume charts, tooltips, zoom, or interactive crosshairs would require more custom work. Revisit this decision if those become required; `fl_chart` remains the fallback candidate.
- Re-measure `NFR-PERF-005` on the owner-selected reference device before claiming the release budget.

## Verification

- Spike output: the table above is the recorded summary of the `SPIKE_RESULT` logs; the raw logs and throwaway app lived in `/tmp` and are not committed.
- Production chart: `test/features/progress_test.dart`, `test/progress_golden_test.dart`.
- RTL time direction: `progress-chart-weight-axis-first`/`-last` position assertion in the widget test and the Persian golden.
- Gaps: `packages/lift_core/test/progress_test.dart` asserts `null` RIR and above-threshold e1RM points.
