<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 20.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 20. Non-Functional Requirements

| ID | Requirement | Pri | Status | Acceptance criteria |
|---|---|---|---|---|
| NFR-ARCH-001 | No backend; all data on device. | Must | Confirmed | AC: Release APK declares no INTERNET permission (verify in built manifest; Flutter's debug template adds it only for debug/profile builds, which must be confirmed in the generated project). |
| NFR-PERF-001..005 | Performance budgets | Must | Confirmed (goal); numbers are Recommendations | See Section 22. |
| NFR-SEC-001 | No third-party SDKs for analytics, ads, or crash reporting. | Must | Recommendation | AC: Dependency review in CI/PR checklist. |
| NFR-PRV-001 | No data leaves the device except through user-initiated export or share. | Must | Confirmed principle | AC: Manifest and backup rules reviewed. |
| NFR-REL-001 | App never loses logged data on crash or kill. | Must | Recommendation | AC: Each set write is committed to the database immediately (no "save later" buffer). |
| NFR-MNT-001 | Feature-first structure; domain logic isolated; additive schema changes by default. | Must | Confirmed (extensibility) | Section 25. |
| NFR-A11Y-001 | Text contrast at least WCAG AA (4.5:1) and touch targets at least 48 dp. | Should | Recommendation | AC: Palette checked with a contrast tool; large-font setting does not break set rows. |
| NFR-COMP-001 | Works on Android 7.0+ (API 24+). | Must | Assumption | Flutter's current minimum is API 24 [S14]; older versions are unsupported by Flutter itself. |
| NFR-SIZE-001 | Release APK size target set after first build (Assumption: under 30 MB per ABI). | Could | Assumption | Measured; font weights limited to what is used. |

---
