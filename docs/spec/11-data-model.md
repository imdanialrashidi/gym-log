<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 21.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 21. Data Model and Core Entities (Recommendation)

Principles: **additive evolution** (new nullable columns, new tables); **stable string IDs** (UUIDs) so merge-import and history fixtures work; **UTC timestamps** only (Jalali is a display concern); **canonical weight in kilograms**.

| Entity | Key fields |
|---|---|
| `Exercise` | `id`, `name`, `searchTerm?`, `muscleGroup?`, `defaultRepMin?`, `defaultRepMax?`, `incrementKg?`, `photoPath?`, `archivedAt?`, `createdAt` |
| `Program` | `id`, `name`, `createdAt`, `archivedAt?` |
| `ProgramDay` | `id`, `programId`, `name`, `sortOrder` |
| `PlanItem` | `id`, `dayId`, `exerciseId`, `sortOrder`, `targetSets`, `repMin`, `repMax`, `targetRirMin?`, `targetRirMax?` |
| `Session` | `id`, `startedAt`, `endedAt?`, `programDayId?`, `note?` |
| `SessionExercise` | `id`, `sessionId`, `exerciseId`, `sortOrder`, `note?` |
| `SetLog` | `id`, `sessionExerciseId`, `setIndex`, `weightGrams`, `reps`, `rir?`, `isWarmup`, `createdAt` |
| `SessionPhoto` | `id`, `sessionId`, `path`, `createdAt` |
| `AppMeta` | `key`, `value` (e.g. last export time) |

**Key decisions needed:**

- **Weight storage (Needs Decision, recommended):** store as **integer grams** (canonical kg) and format for display. This avoids floating-point drift. Converting lb entries to kg and back must round-trip to the value the user typed; add a test for common plate weights (e.g. 45 lb).
- **History references exercises, not plan items.** Deleting or editing a program must never change logged history.
- **Indexes:** at least on `SetLog(sessionExerciseId)` and `SessionExercise(exerciseId)`, plus `Session(startedAt)`, to keep prefill and charts fast (Section 22).
- **Personal records are derived, not stored**, in v1.0 (computed by query), to avoid a second source of truth. Cache only if measurement shows a need.

---
