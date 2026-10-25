# Reference-device runbook

Owner procedure for `NFR-PERF-001`–`NFR-PERF-006`. It exists so an unmeasured
budget is a documented owner step, never an agent guess. Agents must not claim a
device result from an emulator, a debug build, or the CI micro-benchmarks.

## 1. Choose and record the device (Needs Decision)

Pick one real, modest phone the owner or a friend owns: Android 8–11, about
3 GB RAM, not a flagship. The same device must be used for every release until
the owner deliberately replaces it.

Record in [RESULTS.md](RESULTS.md):

- model, Android version, RAM, and whether it uses Impeller or the older
  OpenGL ES rendering path;
- build identity: app version, build number, commit/tag, profile APK SHA-256;
- date and owner name.

Budgets measured anywhere else do not count.

## 2. Build and install profile mode

```sh
flutter build apk --profile
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

- Use the profile build, never debug.
- Close other apps, keep the device charging, and leave battery saver off.
- For a release run, sign the APK with the permanent key; the profile build can
  use the debug key because this run measures performance, not updates.
- Do not change screen brightness or animation scale between runs.

## 3. Cold start to interactive Workout (`NFR-PERF-001`, ≤ 1.5 s, median of 10)

For each of 10 runs:

```sh
adb shell am force-stop <applicationId>
sleep 3
flutter run --profile --trace-startup
```

Read `timeToFirstFrameMicros` (or the first Workout frame in the DevTools
timeline) for each run. Record all 10 values, take the median, and compare with
1.5 s. Starting the app from the launcher by hand is acceptable if the start
intent is otherwise identical every time.

## 4. Tap ✓ to visible confirmation (`NFR-PERF-002`, ≤ 100 ms)

1. `flutter run --profile`, attach DevTools, open **Performance** and start
   recording.
2. In an active workout, tap ✓ on a prefilled set and stop recording after the
   confirmation is visible.
3. Read the build and raster time of the confirmation frame.
4. Repeat 10 times; record the median.

## 5. History scroll with 10,000 sets (`NFR-PERF-004`)

1. Generate the valid JSON fixture and import it on the device:

   ```sh
   dart run tool/benchmarks/write_device_fixture.dart \
     --output build/benchmark-10k.json
   ```

   Copy the file to the device, then Settings → Import data. It contains 1,000
   sessions and 10,000 synthetic sets; 1,000 chart points become available for
   the chart step.
2. Open History and enable the performance overlay (or record a DevTools
   timeline).
3. Scroll continuously for 10 seconds.
4. Record the number of frames, the frames whose build+raster exceeded 16 ms,
   and the worst frame. The budget passes when the large majority of frames stay
   within 16 ms and no visible jank is observed.

## 6. Chart first paint with 1,000 points (`NFR-PERF-005`, ≤ 200 ms)

1. Have an exercise with 1,000 finished sessions (the benchmark fixture is
   suitable).
2. Start a DevTools timeline recording, open Progress detail for that exercise,
   and stop when the first chart frame is visible.
3. Record tap-to-first-chart-frame time; repeat 5 times; take the median.

## 7. JSON export with 10,000 sets (`NFR-PERF-006`)

1. With 10,000 sets present, start a stopwatch and the performance overlay, then
   tap **Export data**.
2. Stop when the save UI opens and again when "Backup saved." appears.
3. Confirm the UI stayed responsive (no long blocking frame) while the JSON was
   encoded off the UI thread.
4. Repeat 3 times and record the times and any observed freeze.

"Completes in a few seconds" is the budget wording; record the actual values
rather than choosing a number after the fact.

## 8. Record and hand off

1. Fill the reference-device table in [RESULTS.md](RESULTS.md): measured value,
   device, date, result `PASS`/`FAIL`.
2. Attach the raw traces or a link to them if available.
3. For a release, copy the table row into the release checklist in
   [docs/RELEASE.md](../RELEASE.md) and do not call the release done while a
   required row is `UNPROVEN`.
4. If a budget fails, record it as `FAIL` and open a scoped optimization; add a
   baseline with `--output`, make one change, and re-measure under the same
   conditions before claiming an improvement.

## Owner checklist

- [ ] Reference device selected and recorded in RESULTS.md.
- [ ] Profile APK SHA-256 and build identity recorded.
- [ ] Cold start measured 10×; median recorded.
- [ ] Tap-to-confirmation measured 10×; median recorded.
- [ ] History scroll recorded with 10,000 sets; jank assessed.
- [ ] Chart first paint measured 5×; median recorded.
- [ ] Export measured 3×; responsiveness observed.
- [ ] Every row has `PASS`, `FAIL`, or `UNPROVEN`; no budget is called passed
      without a value from this device.
- [ ] Failing budgets have a scoped follow-up and no release claim.
