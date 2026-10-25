<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 18.3.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

### 18.3 Logging (`LOG`)

| ID | Requirement | Pri | Status | Acceptance criteria and edge cases |
|---|---|---|---|---|
| LOG-001 | Log a set with weight, reps, and optional RIR via numeric fields. | Must | Confirmed | AC: Set is saved on ✓ and survives app kill. Edge: weight 0 allowed (bodyweight); reps must be ≥ 1; decimals allowed for weight (up to 2 places). |
| LOG-002 | **Prefill** (see `INT-001`). | Must | Confirmed | See Section 19. |
| LOG-003 | Warm-up flag per set. | Should | Assumption | AC: Warm-up sets are excluded from volume, PR, e1RM, and progression logic. |
| LOG-004 | Show target sets and rep range for each exercise during the session. | Must | Confirmed | AC: e.g. "3 × 8–12" visible; sets outside the range are neutral, not "wrong". |
| LOG-005 | RIR chips: 0, 1, 2, 3, 4, 5+; optional (can be left empty). | Must | Confirmed | AC: Empty RIR is stored as null and never defaulted silently. |
| LOG-006 | Edit and delete any logged set, in the active session or from history. | Must | Recommendation | AC: Deletion asks for confirmation or offers Undo for at least 5 seconds. |
| LOG-007 | Session and per-exercise notes. | Should | Assumption | AC: Plain text, up to a sensible limit; included in export. |
| LOG-008 | Rest timer (in-app), optional, configurable duration. | Should | Assumption | AC: Starts after a set is logged if enabled; vibrates on completion; does not block logging. Background notification is Could (Needs Decision: adds permission handling). |
| LOG-009 | Active session survives app restart and process death. | Must | Recommendation | AC: Kill the app mid-session; reopen; all logged sets and the active session are intact. |
| LOG-010 | Numeric input normalizes Persian/Arabic-Indic digits and decimal separators to canonical numbers. | Must | Recommendation | AC: "۸۰٫۵" and "80.5" both produce 80.5. Invalid input shows inline error, never crashes. |
