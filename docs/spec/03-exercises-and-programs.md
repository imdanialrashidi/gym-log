<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 18 intro, 18.1-18.2.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 18. Functional Requirements

Format per requirement: **ID, description, priority, status, acceptance criteria (AC)**. User for all: the lifter. Preconditions: app installed. "Edge" lists notable edge cases.

### 18.1 Exercises (`EXR`)

| ID | Requirement | Pri | Status | Acceptance criteria and edge cases |
|---|---|---|---|---|
| EXR-001 | Create, edit, archive exercises. Fields: name (required), optional search term, optional muscle group, optional default rep range, optional photo. | Must | Confirmed | AC: A new exercise appears in the picker immediately. Archiving hides it from pickers but preserves history. Edge: duplicate names allowed with warning; names with Persian/Latin mixed text display correctly. |
| EXR-002 | App starts with an empty exercise list. | Must | Confirmed | AC: Fresh install shows zero exercises and a clear "Add your first exercise" prompt. |
| EXR-003 | Exercise picker supports search by name. | Must | Recommendation | AC: Typing "ben" filters to "Bench Press" case-insensitively; Persian text also matches; Persian/Arabic character variants (ي/ی, ك/ک) match each other (Needs Decision: normalization rules). |
| EXR-004 | **Lookup button** opens an image search for the exercise's search term (or name if empty) in the external browser. | Must | Confirmed | AC: Tapping on "bench press" opens the browser on an image-search results page for "bench press". Query is URL-encoded. If no browser is available, a non-blocking message is shown. App holds no INTERNET permission in release builds (to be verified in the built APK). |
| EXR-005 | Optional user-picked photo per exercise (from gallery or camera). | Should | Confirmed | AC: Photo shows in exercise detail and picker row. Stored in app-private storage, downscaled. Removing the exercise's photo deletes the file. |
| EXR-006 | Muscle-group tag (single primary, optional). | Should | Assumption | AC: Selectable from a fixed list. Not required. Included in export. |
| EXR-007 | Per-exercise weight increment setting. | Should | Assumption | AC: Used by steppers and progression suggestion. |

### 18.2 Programs and plans (`PLAN`)

| ID | Requirement | Pri | Status | Acceptance criteria |
|---|---|---|---|---|
| PLAN-001 | Create programs containing ordered days; each day contains ordered plan items. | Must | Confirmed (structure chosen "a") | AC: Reordering persists. Deleting a program does not delete logged history (history references exercises, not programs). |
| PLAN-002 | A plan item has: exercise, target sets, **rep range (min and max)**. | Must | Confirmed | AC: Min ≤ max enforced; 1 ≤ min; sensible upper limits (e.g. 100) validated. |
| PLAN-003 | Optional target RIR per plan item (single value or range). | Could | Assumption | AC: Displayed on the workout screen; used for color hints only. |
| PLAN-004 | Start a session from a program day, or start an empty session. | Must | Confirmed | AC: Planned exercises are pre-listed; user can add extra exercises mid-session. |
| PLAN-005 | Export and import a **single program** (template only) as JSON. | Should | Assumption | AC: Importing creates a new program with no history. |
