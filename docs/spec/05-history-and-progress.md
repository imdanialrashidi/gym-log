<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 18.4.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

### 18.4 History and progress (`HIS`, `PRG`)

| ID | Requirement | Pri | Status | Acceptance criteria |
|---|---|---|---|---|
| HIS-001 | Session history list and calendar marking trained days. | Must | Confirmed (history) | AC: A day with a session is visibly marked; tapping opens session detail. |
| HIS-002 | Session detail shows exercises, sets, notes, photos. | Must | Recommendation | |
| PRG-001 | Per-exercise chart: best-set weight over time. | Must | Confirmed | AC: Renders for 1,000+ points without frame drops (see Section 22). Empty state explains what's needed. |
| PRG-002 | Per-exercise chart: estimated 1RM over time (labeled "estimated"). | Must | Confirmed | See `INT-003`. |
| PRG-003 | Per-exercise chart: reps and RIR trend. | Must | Confirmed (progress charts for reps and RIR) | AC: RIR missing values are gaps, not zeros. |
| PRG-004 | Session volume chart (sets × reps × weight, working sets only). | Should | Recommendation | AC: Label says "volume load". |
| PRG-005 | Date range filter (4 weeks, 12 weeks, 1 year, all). | Should | Recommendation | |
