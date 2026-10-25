<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 22.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 22. Performance Engineering

You asked for "very high performance". That needs numbers, otherwise it cannot be tested. **All numbers below are Recommendations/Assumptions** to be calibrated on a real reference device.

### 22.1 Reference device (Needs Decision)

Pick one real, modest phone you or a friend owns (e.g. Android 8 to 11, about 3 GB RAM). Budgets are measured there, not on an emulator or a flagship.

### 22.2 Budgets

| ID | Metric | Proposed budget | How measured |
|---|---|---|---|
| NFR-PERF-001 | Cold start to interactive Workout screen | ≤ 1.5 s on reference device | Profile-mode run, stopwatch/trace; repeat 10×, take median |
| NFR-PERF-002 | Tap ✓ to visible confirmation | ≤ 100 ms | Profile-mode trace |
| NFR-PERF-003 | Prefill query for an exercise with 10,000 logged sets | ≤ 50 ms | Automated micro-benchmark on fixture DB |
| NFR-PERF-004 | History list scroll with 10,000 sets | No visible jank; frame build and raster times within 16 ms for the large majority of frames | DevTools performance overlay, profile mode |
| NFR-PERF-005 | Chart render with 1,000 points | ≤ 200 ms first paint | Profile-mode trace |
| NFR-PERF-006 | JSON export of 10,000 sets | UI stays responsive; completes in a few seconds | Manual and automated |

### 22.3 Design measures that make the budgets achievable

- **Rendering:** Flutter's Impeller renderer is the default on Android API 29+ per the official docs, with OpenGL ES fallback behavior for older devices documented by the engine team [S12]. Android 7 to 9 devices therefore take a different rendering path; **test the reference device on that path** if your friends have older phones.
- **Always measure in profile mode on a physical device**, never in debug mode.
- **Database:** indexed queries; query only what the screen shows; use streams scoped to the visible data; run heavy work (export, import validation, chart aggregation) off the UI thread/isolate.
- **UI:** lazy list builders; `const` widgets; narrow state subscriptions so tapping ✓ rebuilds one row, not the screen.
- **Images:** downscale on save; request decoded size close to display size.
- **Fonts and assets:** ship only the needed Vazirmatn weights; no bundled images or videos.
- **Startup:** do no migration, import, or heavy init before the first frame (migrations run only when the schema version changed, and show a progress screen if they take noticeable time).
- **Release performance gate:** a manual checklist per release (Section 37) plus automated DB micro-benchmarks in CI.

---
