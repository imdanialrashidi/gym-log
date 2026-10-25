<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, sections 12-17.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 12. Product Scope

Scope is defined by three buckets (MVP, Future Phase, Out of Scope) and by MoSCoW priority. Each bucket is exclusive: an item appears in exactly one.

### 12.1 Original requirement traceability

| # | Your original requirement | Where it lives | Notes |
|---|---|---|---|
| 1 | Easy, text-based logging | `LOG-*` | **Changed by you:** numeric fields and chips, no text parsing |
| 2 | Rep range | `PLAN-002`, `LOG-004` | Planned range per exercise |
| 3 | RIR | `LOG-005` | Logged per set; optional |
| 4 | Google search for exercise | `EXR-004` | Image search for the exercise name |
| 5 | Export / import | `IO-*` | JSON backup/restore |
| 6 | Modern, dark by default | `UI-*` | Section 29.4 |
| 7 | Very high performance | `NFR-PERF-*` | Section 22 |
| 8 | Fully local, no complex backend | `NFR-ARCH-001` | No server |
| 9 | Extremely simple | `UI-001`, `UI-002` | Few screens, no onboarding wall |
| 10 | Extensible codebase | Section 25, `NFR-MNT-*` | |
| 11 | Updates never harm users | `DAT-*` | Section 23 |
| 12 | Android | Constraint | Flutter, phones only |
| 13 | Image per exercise | `EXR-005` | Optional, user-picked |
| New | Track exercise with some intelligence | `INT-*` | Rule-based, explainable |
| New | Name visible in many places | Section 29.3 | |
| New | Optional per-session photos | `PHO-*` | |

---

## 13. MVP Definition (Release 1.0)

The MVP is "everything the owner confirmed", sequenced so it can be shipped in slices (Section 33). It contains:

**Core logging:** exercises (create/edit, muscle group, optional search term, optional photo); programs with days and planned sets and rep ranges; session logging with weight, reps, RIR, warm-up flag, notes; history; per-exercise progress charts.

**Smart (rule-based, offline):** prefill from last session; double-progression suggestion; PR detection with estimated 1RM.

**Data safety:** versioned migrations with tests; pre-migration snapshot; JSON export; validated JSON import; Auto Backup off by default; export reminder.

**Localization:** Persian (RTL) and English, Persian/Latin digits setting, Jalali date display, kg/lb.

**Optional media:** per-session photos; per-exercise photo.

**Distribution:** signed APK on GitHub Releases.

**De-scope gate (Recommendation):** if the schedule slips, ship 1.0 with prefill and PR detection, and move double progression to 1.1. Everything else listed here stays in 1.0.

---

## 14. Future Phases

| Phase | Item | Status |
|---|---|---|
| 1.1 to 1.x | CSV history export (for spreadsheets) | Future Phase |
| 1.x | Plateau detection (several sessions without progress) | Future Phase |
| 1.x | Weekly volume per muscle group (needs muscle-group tags; display as information, not prescription [S20]) | Future Phase |
| 1.x | Deload suggestions based on RIR and performance trend | Future Phase |
| 1.x | Plate calculator | Future Phase |
| 1.x | Side-by-side photo comparison | Future Phase |
| 1.x | Biometric lock for photos | Future Phase |
| 2.x | Supersets (adds data-model complexity) | Future Phase |
| 2.x | Bodyweight tracking | Future Phase |
| 2.x | Import from other apps' CSV exports | Future Phase |
| 2.x | Home-screen widget, wear support | Future Phase |
| 2.x | iOS | Future Phase |

---

## 15. Explicit Out-of-Scope Items (this phase)

| Item | Status | Reason |
|---|---|---|
| LLM or any AI model, online or offline | **Out of Scope** (Confirmed) | Conflicts with local, free, no-backend principles |
| Free-text set entry and parsing (e.g. `80x8@2`) | **Out of Scope** (Confirmed) | Owner chose numeric fields |
| Accounts, cloud sync, social features | **Out of Scope** | Local-first principle |
| Bundled exercise library with images or videos | **Out of Scope** (Confirmed) | No assets; user starts empty |
| Ads, subscriptions, in-app purchases | **Out of Scope** (Confirmed free) | Brand promise |
| Analytics, crash-reporting SDKs, Firebase | **Out of Scope** (Recommendation) | Privacy; also incompatible with F-Droid [S26] |
| In-app auto-updater | **Out of Scope** (Recommendation) | Needs network permission; adds risk |
| Nutrition, calories, cardio, GPS | **Out of Scope** | Not a lifting-log job |
| Tablet-optimized layouts, iOS, web | **Out of Scope** (Confirmed phone-only Android) | |

---

## 16. Feature Prioritization (MoSCoW)

| Priority | Features |
|---|---|
| **Must** | Exercise CRUD; program/day/plan items with rep range; session logging (weight, reps, RIR); prefill from last session; history; per-exercise charts; PR detection with e1RM; exercise image search; JSON export and validated import; migrations with tests; pre-migration snapshot; dark theme; Persian RTL plus English; kg/lb; signed releases |
| **Should** | Double-progression suggestion (de-scope candidate); warm-up flag; notes; rest timer (in-app); muscle-group tag; per-exercise photo; per-session photos; export reminder banner; Persian/Latin digit setting; Jalali dates |
| **Could** | Target RIR per plan item; CSV export; search engine choice; "video search" shortcut; full archive export with photos (ZIP); light theme |
| **Won't (this phase)** | Section 15 items |

> **Assumption:** Target RIR per plan item, muscle-group tag, warm-up flag, notes, and rest timer were not explicitly answered. They are scoped as above. A muscle-group tag is cheap now and avoids a schema migration later.

---

## 17. Information Architecture, Screens, and Logging Flow

### 17.1 Navigation (Recommendation)

Bottom navigation with four tabs, plus Settings from a top icon:

| Tab | Purpose |
|---|---|
| **Workout** | Start or continue today's session; the logging screen |
| **Programs** | Programs → days → plan items; exercise library |
| **History** | Calendar and list of past sessions |
| **Progress** | Per-exercise charts and PRs |

### 17.2 Screen inventory

1. Workout (today / active session)
2. Exercise picker and creator
3. Exercise detail (history, chart, PRs, lookup button, photo)
4. Program list, program editor, day editor, plan-item editor
5. History list and session detail
6. Progress overview and exercise chart
7. Settings (language, digits, units, theme, increments, backup/export, import, about, donate)
8. Photo viewer for a session
9. Safe-mode / migration-error screen (Section 23)

### 17.3 Logging speed budget (Recommendation, measurable)

| Action | Budget |
|---|---|
| Open app to ready-to-log screen | Shown with last state, no blocking spinners |
| Log a repeated set (prefilled) | **1 tap** |
| Log a set with a changed weight | **2 to 3 taps** (stepper) or tap-to-type |
| Add RIR | **1 tap** on a chip (0, 1, 2, 3, 4, 5+) |
| Look up an exercise image | **1 tap**, opens browser |

### 17.4 Set row design (Confirmed concept: selectable numeric fields)

Each set row has: weight field with − and + steppers; reps field with − and +; RIR chips; a ✓ button; a warm-up toggle. Fields accept typing as well as steppers. Increment sizes are configurable per exercise (default 2.5 kg or 5 lb, Assumption).

---
