<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 35.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 35. Risks

Severity and probability: H = high, M = medium, L = low.

| # | Risk | Sev | Prob | Mitigation |
|---|---|---|---|---|
| R1 | **Signing key lost or changed**, so users must uninstall and lose data [S15] | H | M | Section 23.5: two backups, no key in Git or prompts, decide applicationId early |
| R2 | **Migration bug destroys data** | H | M | Generated migration tests, snapshot before migrating, Safe Mode, upgrade drill [S11] |
| R3 | **Scope creep** | M | H | This spec, MoSCoW, de-scope gate, requirement IDs |
| R4 | **Agent errors**: invented APIs, wrong package versions, unreviewed dependencies | M | H | `AGENTS.md` rules, CI, small tasks, pinned versions, manual review of schema and import code |
| R5 | **Flutter ecosystem churn** (e.g. Material/Cupertino split, plugin changes) [S13] | M | M | Pin SDK, read release notes before upgrading, upgrade in a dedicated branch |
| R6 | **Persian/RTL/digit bugs** | M | H | Goldens in both directions, input normalizer tests, native-speaker review |
| R7 | **Date library maintenance** (`shamsi_date`) [S24] | L | M | `CalendarService` wrapper; unit tests on conversion; replace if needed |
| R8 | **Photo privacy leak** (backup, screenshots, share) | H | M | Excluded from Auto Backup and default export; EXIF stripped; private storage; optional lock later |
| R9 | **Platform/service access limits** (hosting, stores, payments) for your region | M | M | Verify per channel; keep local backups; avoid single points of failure |
| R10 | **Name collision or trademark issue** [S28] | M | M | Clearance checklist before release |
| R11 | **Suggestion mistaken for medical or coaching advice** | M | L | Explainable reasons, About disclaimer, suggestions are never auto-applied |
| R12 | **e1RM inaccuracy** at higher reps [S21] | L | M | "Estimated" label; hide above threshold |
| R13 | **Cross-channel signature mismatch** blocks updates | M | M | Verify each channel's signing; avoid mixing channels per user |
| R14 | **Low adoption** | L | M | Acceptable for stated goals; success defined by friends' use |
| R15 | **Supply-chain risk** from packages | M | L | Pin exact versions, review licenses and maintainers, minimal dependency count |
| R16 | **Poor performance on low-end phones** | M | M | Budgets on a real reference device; profile mode; test the older-Android rendering path [S12] |
| R17 | **Donation handling legal/practical issues** | M | M | Decide platform carefully; no in-app payment code |

---
