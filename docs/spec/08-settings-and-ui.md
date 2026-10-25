<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 18.7.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

### 18.7 Settings and UI (`SET`, `UI`)

| ID | Requirement | Pri | Status | Acceptance criteria |
|---|---|---|---|---|
| UI-001 | Dark theme by default; first launch is dark regardless of system theme. | Must | Confirmed | AC: Verified on a device set to light mode. |
| UI-002 | No onboarding wall; no sign-in; first set loggable within 60 seconds. | Must | Confirmed | Measured in friend test (Section 36). |
| UI-003 | Light theme. | Could | Assumption | |
| SET-001 | Language: Persian or English; default follows device (Persian if device is Persian). | Must | Confirmed | AC: Switching language applies without restart and mirrors layout correctly. |
| SET-002 | Digit style: Persian or Latin. | Should | Confirmed (Persian section) | |
| SET-003 | Units: kg or lb, display only; data stored canonically (Section 21). | Must | Confirmed | AC: Switching units never changes stored data; round-trips are lossless. |
| SET-004 | Export reminder banner after 30 days without export (in-app, no notification permission). | Should | Confirmed (reminder) | AC: Banner appears only when there is data; dismissible; snooze option. |
| SET-005 | About screen: version, license, source link, donate link, privacy statement. | Must | Confirmed (donate) | AC: Links open externally. |
| SET-006 | Search engine choice for lookup (default Google). | Could | Assumption | |

---
