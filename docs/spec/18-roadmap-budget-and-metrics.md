<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, sections 33-34 and 36.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 33. Implementation Roadmap and Milestones

**Effort estimates are ranges with Low confidence** (Assumption). They include agent-assisted coding, but mostly reflect **your review, testing, and device verification time**, which is usually the real bottleneck. Your weekly hours and any deadline were not provided.

| Milestone | Scope | Est. focused hours | Gate |
|---|---|---|---|
| **M0 Foundation** | Repo, `AGENTS.md`, CI, pinned Flutter, theme and l10n skeletons, applicationId and signing plan | 8 to 16 | Section 37.1 checklist done |
| **M1 Data layer** | Drift schema v1, DAOs, migration test harness, fixture harness, pre-migration snapshot, Safe Mode | 20 to 36 | Migration tests green in CI |
| **M2 Exercises and programs** | CRUD, picker, search, lookup button, plan items | 16 to 30 | |
| **M3 Session logging** | Set rows, prefill, kill-resilience, basic history | 24 to 44 | **G1:** friend test vs notebook (E1). Stop if slower. |
| **M4 Progress** | Charts, PR detection, e1RM | 18 to 34 | Chart spike (fl_chart vs custom) decided |
| **M5 Double progression** | Rules, reasons, tests | 8 to 16 | **G2:** de-scope check |
| **M6 Export/import** | JSON export, validated import, round-trip and fixtures, reminder | 18 to 32 | **G3:** corrupt-file and large-file tests pass |
| **M7 Localization polish** | RTL goldens, digits, Jalali, fonts | 16 to 30 | Native-speaker copy review |
| **M8 Photos** | Session and exercise photos, privacy handling | 10 to 20 | Privacy checks pass |
| **M9 Hardening and release** | Perf pass, upgrade drill, signing, README, checksums | 16 to 30 | **G4:** all budgets and drills pass |
| **Total** | | **154 to 288** | |

**Calendar scenarios (hours per week → duration):** 5 h → about 31 to 58 weeks; 10 h → about 15 to 29 weeks; 20 h → about 8 to 14 weeks.

**Critical path:** M0 → M1 → M3 → M6 → M9. M7 can run partly in parallel from M2 onward because strings are externalized from day one.

**Release slices:** 0.1 (M0 to M3, dogfood), 0.5 (through M6, friends), 1.0 (all).

**Specialist or outside review worth requesting:** native Persian copy review; accessibility check on a real device with large fonts; a second pair of eyes on the import parser (malformed input); license check; local advice on donations.

**Scope-fit check:** The full confirmed scope fits a hobby timeline only with phasing. If your weekly hours are low, ship 0.5 early and let 1.0 follow.

---

## 34. Budget and Cost Categories

No amounts were provided. Required spend is **$0** under this plan (Recommendation).

| Category | Required? | Notes |
|---|---|---|
| Development tools, GitHub, CI | No | Free tiers for public repos (verify limits) |
| AI agent tooling | Existing | Your current tools; no new purchase assumed |
| Test device(s) | Existing | Use what you and friends own |
| Domain and website | Optional | GitHub Pages or README may be enough; verify availability in your situation |
| Store accounts | Optional | Depends on channel (Section 31) |
| Keystore backup storage | Free | Two independent locations |
| Design assets (logo/icon) | Optional | Can be made in-house; keep fonts and icons license-clean |
| Professional Persian copy review | Optional | Friend or paid reviewer |

---

## 36. Success Metrics and Validation Experiments

There is **no telemetry**, so metrics are manual and honest.

### 36.1 Experiments

| ID | Experiment | Effort | Pass condition (Assumption) | If it fails |
|---|---|---|---|---|
| **E0** | **Store survey:** search Cafe Bazaar, Myket, Google Play, and F-Droid for Persian lifting logs; record name, price, Persian support, last update, features | 1 to 2 h | No mature, free, open-source, Persian-first equivalent with rep-range and RIR support | **Pivot:** contribute to the existing project or sharpen a differentiator |
| **E1** | **Baseline timing:** time logging 12 sets in a notebook, in FitNotes, and in the prototype | 1 h per tool | Prototype is at least as fast as the notebook; target 30% faster | Redesign set row before adding features |
| **E2** | **Friend pilot:** 3 to 5 friends for 2 weeks | 2 weeks | 3 of 4 friends log at least 3 sessions per week; **zero data-loss incidents** | Fix top issues; extend pilot |
| **E3** | **Upgrade drill:** install the previous APK, enter data, install the new one over it | 30 min per release | 100% pass for at least 3 consecutive pre-releases | Block release |
| **E4** | **Suggestion sanity:** compare double-progression output against 20 real sessions | 1 h | At least 80% judged sensible | Adjust rules; keep as hint only |
| **E5** | **Performance:** measure budgets on the reference device | 1 h per release | All Section 22 budgets met | Optimize before release |

### 36.2 30, 60, and 90-day plan (starting from kickoff)

- **Days 0 to 30:** E0, E1 baseline; M0 to M3; dogfood.
- **Days 31 to 60:** M4 to M6 progress; pre-release to friends; E2 begins; first upgrade drills.
- **Days 61 to 90:** polish, M7 to M9 as hours allow; E3 to E5; public 1.0 decision.
(At 5 h/week, 90 days gives roughly 65 hours, about a quarter to a third of the full scope; see Section 33 scenarios and adjust to your real hours.)

### 36.3 Success definition (Assumption, please adjust)

By day 90 or release: the owner and at least three friends use it as their main log; no data loss in any upgrade; budgets met; the public repository is understandable to a stranger in under five minutes.

---
