<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, preamble and section 0.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

# [PROJECT NAME — TBD] — Business & Product Specification

**Working file name:** `Workout_Log_App_Business_and_Product_Specification_v1.0.md`
**Product in one line:** A fast, offline, no-account Android app for logging bodybuilding workouts (weight, reps, RIR), with rule-based smart suggestions, Persian-first design, and safe data export/import.

---

## 0. Document Control

| Field | Value |
|---|---|
| Version | 1.0 (Draft for owner approval) |
| Date | 2026-10-18 |
| Owner | Project owner (personal, open-source project) |
| Intended audience | Owner, AI coding agents, friends/collaborators on GitHub |
| Confidentiality | Public-safe. Contains no secrets. Never put signing keys or passwords in this file. |
| Language | English. Persian UI strings appear where they define product behavior. |
| Supersedes | Nothing. This is the first scope document. |
| Pending input | **Owner's agent Workflow Guide has not been received yet.** Section 24 is a placeholder that will be aligned to it. |

### 0.1 How to use this document

1. This file is the **single source of truth** for what is in and out of the product. If something is not here, it is not in scope.
2. Every requirement has an ID (e.g. `LOG-003`). AI agents should work **one requirement ID at a time**, and each task should reference the ID and its acceptance criteria.
3. Anything labeled **Recommendation**, **Assumption**, or **Needs Decision** is **not** a commitment until the owner approves it.
4. Section 28 lists every open decision. Resolve those first; most of them are quick.

### 0.2 Status labels used throughout

| Label | Meaning |
|---|---|
| **Confirmed** | Explicitly stated or approved by the owner in this conversation. |
| **Assumption** | Needed to continue, not yet verified or approved. |
| **Recommendation** | Expert advice, not yet approved. |
| **Needs Decision** | Material open question. |
| **Out of Scope** | Explicitly excluded from the current phase. |
| **Future Phase** | Valuable, intentionally deferred. |
| **Verified** | Checked against a cited source (see Section 38). |
| **Unverified** | Could not be confirmed in this research pass. Treat as a hypothesis. |

Priority uses MoSCoW: **Must / Should / Could / Won't (this phase)**.

### 0.3 Corrections to earlier advice in this conversation

Transparency matters, so these are stated plainly:

- I earlier tied the finding "RIR estimates are more accurate near failure" to Zourdos et al. (2016). That is imprecise. Zourdos et al. introduced the RIR-based RPE scale [S18]. The accuracy evidence comes from the Halperin et al. scoping review and meta-analysis (*Sports Medicine*, 2022) [S19].
- I earlier mentioned Room for the database. Because you chose **Flutter**, the equivalent recommendation is **Drift** (SQLite), which has comparable migration tooling [S11].
- I earlier mentioned Baseline Profiles. That is an Android-native technique. I have not verified its usefulness for Flutter apps, so it is **removed** from this spec and replaced by measurable performance budgets (Section 22).
- I mapped your numbered replies (1 to 7) to the numbered **sections** of my previous message, not to its final decision list. See Section 1.2 for how each was interpreted. Please correct any mismatch.

---
