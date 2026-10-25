<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 18.5.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

### 18.5 Photos (`PHO`)

| ID | Requirement | Pri | Status | Acceptance criteria |
|---|---|---|---|---|
| PHO-001 | Optionally attach up to N photos (default 3) to a session, from camera or gallery. | Should | Confirmed (feature); N is Assumption | AC: Uses the system picker/camera intent so the app needs no broad storage permission [S27]. |
| PHO-002 | Photos are stored in app-private storage, downscaled, and location metadata is stripped. | Should | Recommendation | AC: Stored copy has no GPS EXIF data (test with a geotagged sample). |
| PHO-003 | Photos are excluded from Android Auto Backup and from JSON export by default. | Should | Recommendation | AC: Verified in manifest/backup rules. JSON export notes that photos are not included. |
| PHO-004 | Optional ZIP "full archive" export including photos. | Could | Assumption | |
| PHO-005 | Deleting a session deletes its photo files. | Should | Recommendation | AC: No orphan files remain (verified by a test that scans the photo directory). |
