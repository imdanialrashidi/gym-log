<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 18.6.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

### 18.6 Import and export (`IO`)

| ID | Requirement | Pri | Status | Acceptance criteria |
|---|---|---|---|---|
| IO-001 | **Full JSON export**: exercises, programs, sessions, sets, settings relevant to data, with `schemaVersion`, `appVersion`, `exportedAt` (UTC). | Must | Confirmed | AC: Export of a 10,000-set database completes without blocking the UI. File opens as valid JSON. |
| IO-002 | **Validated JSON import** with a dry-run summary ("will add 3 exercises, 120 sessions…") before committing. | Must | Confirmed (validated import under data safety) | AC: Invalid or truncated files are rejected with a clear message and **no data change**. Newer `schemaVersion` than supported is rejected with an "update the app" message. |
| IO-003 | Import modes: **Merge** (default) and **Replace**. Replace takes an automatic snapshot first. | Must | Needs Decision (recommended) | AC: Merge never overwrites existing records silently; duplicates are detected by stable IDs. |
| IO-004 | **Round-trip guarantee**: export → import into an empty DB → export produces equivalent content. | Must | Recommendation | AC: Automated test passes in CI. |
| IO-005 | **Historical-fixture guarantee**: an export from every released version is stored in the repo and must import successfully in all later versions. | Must | Recommendation | AC: CI fails if any fixture fails to import. |
| IO-006 | Export via the Android share/save UI (no broad storage permission). | Must | Recommendation | |
| IO-007 | CSV history export. | Could | Assumption | UTF-8 with BOM so Persian opens correctly in Excel (Unverified in this pass; test with Excel). |
