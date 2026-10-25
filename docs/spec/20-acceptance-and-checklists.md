<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 37.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 37. Acceptance Criteria, Test Scenarios, and Checklists

### 37.1 Pre-implementation checklist

- [ ] D1 (Workflow Guide) received and Section 24 reconciled
- [ ] D2 name chosen and cleared (37.3); **applicationId decided**
- [ ] D3 license chosen
- [ ] Reference device selected (D5)
- [ ] Signing plan written and backups created (23.5)
- [ ] E0 survey done
- [ ] Flutter SDK version chosen and pinned
- [ ] Repository created with `AGENTS.md`, this spec, CI skeleton

### 37.2 Key acceptance scenarios

| # | Scenario | Expected result |
|---|---|---|
| A1 | Fresh install, device in Persian | UI in Persian, RTL, dark theme, no sign-in, empty exercise list with prompt |
| A2 | Create exercise "Bench Press", log 3 sets, kill app, reopen | Session and 3 sets intact (`LOG-009`) |
| A3 | Next session, open same exercise | Weight, reps, RIR prefilled from last session (`INT-001`) |
| A4 | All 3 sets hit the top of the rep range last time | Suggestion to add weight with a reason (`INT-002`) |
| A5 | One set fell below the range minimum | Suggestion to hold with a reason |
| A6 | Log a heavier set than ever before | PR badge shown; the first-ever set shows none |
| A7 | Warm-up set heavier than any working set | Not counted as a PR; excluded from volume |
| A8 | Tap lookup on "bench press" | Browser opens an image search for "bench press" (`EXR-004`) |
| A9 | Enter weight with Persian digits | Parsed correctly (`LOG-010`) |
| A10 | Switch kg ↔ lb repeatedly | Stored values unchanged; display round-trips (`SET-003`) |
| A11 | Export, wipe app data, import | Full equality with original (`IO-004`) |
| A12 | Import truncated JSON | Rejected; no data change (`IO-002`) |
| A13 | Import file from a newer app version | Rejected with "update the app" message |
| A14 | Install previous APK with data, then install new APK over it | All data intact (`DAT-008`) |
| A15 | Simulated failed migration | Snapshot exists; Safe Mode shown; original DB untouched (`DAT-003/004`) |
| A16 | Attach session photo | Stored privately, no GPS metadata, not in JSON export (`PHO-002/003`) |
| A17 | Device with large font size | Set rows remain usable (`NFR-A11Y-001`) |
| A18 | Inspect release manifest | No INTERNET permission; Auto Backup disabled (`NFR-ARCH-001`, `DAT-007`) |

### 37.3 Name clearance checklist

- [ ] GitHub username/repo available
- [ ] Google Play, Cafe Bazaar, Myket, F-Droid searches show no confusing match
- [ ] Domain and social handles available
- [ ] Trademark databases searched for your jurisdiction (not a legal opinion)
- [ ] Pronunciation and spelling tested with 5 friends
- [ ] Persian meaning and connotations checked by a native speaker

### 37.4 Delivery checklist (each release)

- [ ] All tests pass in CI, including migrations and fixtures
- [ ] New fixture export added for this version
- [ ] Upgrade drill passed on a real device
- [ ] Performance budgets verified (profile mode)
- [ ] Manifest checked (permissions, backup)
- [ ] Signed with the permanent key; checksums generated
- [ ] CHANGELOG updated, including any schema change
- [ ] Release notes written in plain English and Persian
- [ ] Marked as pre-release first when schema changed

---
