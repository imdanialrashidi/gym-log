# Specification Index

Seed date: 2026-10-21. Source: `Workout_Log_App_Business_and_Product_Specification_v1.0.md`, version 1.0 (Draft for owner approval, dated 2026-10-18).

This directory is the product source of truth for scope and behavior. The spec is split by module and copied verbatim: requirement IDs, statuses, and acceptance-criteria text are unchanged. `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, and `docs/DESIGN.md` distill it; `docs/adr/` records only the owner decisions listed below.

## Precedence

1. The current accepted task request and its criteria govern that task.
2. This directory governs product scope and behavior; work by requirement ID.
3. `AGENTS.md`, `docs/HARNESS.md`, `docs/QUALITY.md`, and `.dsh/skills/` govern process and delivery. Where the spec's Section 24 (or another process statement) conflicts with the DSH Workflow, the workflow wins; every conflict is listed in [91-workflow-reconciliation.md](91-workflow-reconciliation.md).
4. Code, tests, and docs must not silently diverge from a requirement. Report a material conflict instead of choosing a side.

Only rows labeled **Confirmed** are commitments. **Assumption**, **Recommendation**, **Needs Decision**, **Out of Scope**, **Future Phase**, **Verified**, and **Unverified** keep their spec meaning unless an owner decision below explicitly resolves that item.

## Modules

| File | Module | Spec content | Requirement prefixes |
|---|---|---|---|
| [00-document-control.md](00-document-control.md) | Document control | Preamble and Section 0 | — |
| [01-product-context.md](01-product-context.md) | Product context | Sections 1–11 | — |
| [02-scope-and-ux.md](02-scope-and-ux.md) | Scope and UX | Sections 12–17 | — |
| [03-exercises-and-programs.md](03-exercises-and-programs.md) | Exercises and programs | Section 18 intro, 18.1–18.2 | `EXR`, `PLAN` |
| [04-logging.md](04-logging.md) | Logging | Section 18.3 | `LOG` |
| [05-history-and-progress.md](05-history-and-progress.md) | History and progress | Section 18.4 | `HIS`, `PRG` |
| [06-photos.md](06-photos.md) | Photos | Section 18.5 | `PHO` |
| [07-import-and-export.md](07-import-and-export.md) | Import and export | Section 18.6 | `IO` |
| [08-settings-and-ui.md](08-settings-and-ui.md) | Settings and UI | Section 18.7 | `UI`, `SET` |
| [09-intelligence.md](09-intelligence.md) | Rule-based intelligence | Section 19 | `INT` |
| [10-non-functional-requirements.md](10-non-functional-requirements.md) | Non-functional requirements | Section 20 | `NFR` |
| [11-data-model.md](11-data-model.md) | Data model | Section 21 | — |
| [12-performance.md](12-performance.md) | Performance budgets | Section 22 | `NFR-PERF` |
| [13-data-safety.md](13-data-safety.md) | Data safety and release integrity | Section 23 | `DAT` |
| [14-localization.md](14-localization.md) | Localization and RTL | Section 27 | `L10N` |
| [15-architecture.md](15-architecture.md) | Architecture | Section 25 | — |
| [16-tech-stack.md](16-tech-stack.md) | Technology stack | Section 26 | — |
| [17-branding-and-gtm.md](17-branding-and-gtm.md) | Branding, copy, and distribution | Sections 29–32 | — |
| [18-roadmap-budget-and-metrics.md](18-roadmap-budget-and-metrics.md) | Roadmap, budget, and metrics | Sections 33–34 and 36 | — |
| [19-risks.md](19-risks.md) | Risks | Section 35 | — |
| [20-acceptance-and-checklists.md](20-acceptance-and-checklists.md) | Acceptance scenarios and checklists | Section 37 | — |
| [21-open-decisions.md](21-open-decisions.md) | Open decisions | Section 28 | — |
| [22-sources-and-glossary.md](22-sources-and-glossary.md) | Sources and glossary | Section 38 | — |
| [90-legacy-agent-operating-model.md](90-legacy-agent-operating-model.md) | Legacy agent model | Section 24 (superseded, verbatim) | — |
| [91-workflow-reconciliation.md](91-workflow-reconciliation.md) | Workflow reconciliation (formerly OMP) | Conflicts and retained rules | — |

## Requirement ID to milestone map

Milestones are defined in [18-roadmap-budget-and-metrics.md](18-roadmap-budget-and-metrics.md) (Section 33). Milestones describe sequencing, not a change in priority or status. A requirement marked `Could`, `Assumption`, or `Recommendation` stays non-committal in its listed milestone.

| Milestone | Requirement IDs | Notes |
|---|---|---|
| **M0 Foundation** | `DAT-007`, `L10N-001`, `L10N-002`, `L10N-003`, `NFR-ARCH-001`, `NFR-COMP-001`, `NFR-MNT-001`, `NFR-PRV-001`, `NFR-SEC-001`, `SET-001`, `UI-001` | Scaffold, pinned SDK, theme and l10n skeletons, release manifest posture. |
| **M1 Data layer** | `DAT-001`, `DAT-002`, `DAT-003`, `DAT-004`, `NFR-REL-001`, `NFR-PERF-003` | Migrations, snapshots, Safe Mode, prefill-query benchmark. |
| **M2 Exercises and programs** | `EXR-001`, `EXR-002`, `EXR-003`, `EXR-004`, `EXR-006`, `EXR-007`, `PLAN-001`, `PLAN-002`, `PLAN-003`, `L10N-008` | Unconfirmed items in this row are not commitments. |
| **M3 Session logging** | `HIS-001`, `HIS-002`, `INT-001`, `LOG-001`, `LOG-002`, `LOG-003`, `LOG-004`, `LOG-005`, `LOG-006`, `LOG-007`, `LOG-008`, `LOG-009`, `LOG-010`, `NFR-PERF-002`, `PLAN-004`, `SET-003`, `UI-002` | Includes history, editing, notes, and rest timer per the task pack; unconfirmed items keep their spec status. Gate G1 applies. |
| **M4 Progress** | `INT-003`, `L10N-009`, `NFR-PERF-005`, `PRG-001`, `PRG-002`, `PRG-003`, `PRG-004`, `PRG-005` | The volume-chart item is Should/Recommendation and may be deferred. The RTL axis decision is recorded in ADR-0005. |
| **M5 Double progression** | `INT-002` | Only after gate G2. |
| **M6 Export and import** | `DAT-006`, `IO-001`, `IO-002`, `IO-003`, `IO-004`, `IO-005`, `IO-006`, `IO-007`, `PLAN-005`, `SET-004` | Unconfirmed items in this row keep their spec status. Gate G3 applies. |
| **M7 Localization polish** | `L10N-004`, `L10N-005`, `L10N-006`, `L10N-007`, `L10N-010`, `NFR-A11Y-001`, `SET-002`, `SET-006`, `UI-003` | Unconfirmed items in this row are not commitments. |
| **M8 Photos** | `EXR-005`, `PHO-001`, `PHO-002`, `PHO-003`, `PHO-004`, `PHO-005` | The export exclusion is exercised in M6; M8 owns backup exclusion. The ZIP item remains Could. |
| **M9 Hardening and release** | `DAT-005`, `DAT-008`, `NFR-PERF-001`, `NFR-PERF-004`, `NFR-PERF-006`, `NFR-SIZE-001`, `SET-005` | Signing plan starts in M0; release identity, upgrade drill, budgets, checksums, and About land here. Gate G4 applies. |

Section 20 keeps the source's summary row `NFR-PERF-001..005`; Section 22 defines the individual budgets, including `NFR-PERF-006`. This is the source's structure, not a duplicate requirement. The Section 22 table is authoritative for budget values.

## Owner decisions applied

These decisions were supplied by the owner on 2026-10-21. Each has a short ADR. They resolve only the named point; the verbatim spec row keeps its original label and is not edited.

The workflow-guide decision (D1) is resolved by adopting the DSH Workflow. Section 24 is retained verbatim for traceability and superseded in [91-workflow-reconciliation.md](91-workflow-reconciliation.md).

| Decision | Value | ADR |
|---|---|---|
| State management and routing | `flutter_riverpod` + `go_router`; verify license, maintenance, Android 7+ support, and size before pinning exact versions | [ADR-0001](../adr/0001-state-management-and-routing.md) |
| Weight storage | Integer grams, canonical kilograms | [ADR-0002](../adr/0002-weight-storage-integer-grams.md) |
| Import modes | Merge (default) and Replace; Replace takes a snapshot first | [ADR-0003](../adr/0003-import-modes-merge-and-replace.md) |
| e1RM display | Normal for 1–10 reps, "less reliable" for 11–12, hidden above 12 | [ADR-0004](../adr/0004-e1rm-display-thresholds.md) |
| RTL chart time axis | Time progresses left to right, including in RTL | [ADR-0005](../adr/0005-rtl-chart-time-axis.md) |
| Session photos | Maximum 3 per session; excluded from JSON export | [ADR-0006](../adr/0006-session-photos.md) |
| Android backup | Visible "Allow Android backup" toggle, default off | [ADR-0007](../adr/0007-android-backup-toggle.md) |

## Open decisions

Items marked **Assumption** or **Could** are included because they are not commitments; they are not **Needs Decision** unless the status says so.

| Decision | Status | Current value / next action |
|---|---|---|
| Project name | **Needs Decision** | TBD. Must be cleared before the first public release (Section 29.2 and 37.3). |
| `applicationId` | **Needs Decision** | TBD. A placeholder is allowed until the first release; it is permanent after release (Section 23.5). |
| License | **Needs Decision** | TBD. Verify dependency licenses when chosen (Vazirmatn OFL 1.1; `shamsi_date` BSD-3-Clause is a candidate, not a pin). |
| Reference device | **Needs Decision** | TBD. All device performance budgets are `UNPROVEN` until selected (Section 22.1). |
| Donation platform | **Needs Decision** | Depends on the owner's legal and practical constraints (Section 28 D13). The app only opens an external link. |
| Distribution beyond GitHub | **Needs Decision** | GitHub Releases is Confirmed. F-Droid, Cafe Bazaar, and Myket are undecided (Section 28 D12). |
| Target RIR per plan item | **Assumption**, Could | `PLAN-003`; not a commitment. |
| Muscle-group tag | **Assumption**, Should | `EXR-006`; not a commitment. |
| Rest timer | **Assumption**, Should | `LOG-008`; in-app only first (Section 28 D8). |
| Optional RIR gate | **Needs Decision** | Off by default; threshold undecided (Section 19.2 and D11). |
| Photos in a separate ZIP | **Could** | `PHO-004`; JSON export excludes photos by owner decision. ZIP is not decided. |
| CSV history export | **Could**, Future Phase | `IO-007`. |
| Light theme | **Could**, Assumption | `UI-003`; not in the MVP commitment. |
| Persian search normalization rules | **Needs Decision** | `EXR-003`, `L10N-008`; the AC names the variants, the exact rule set is open (D15). |

The M4 chart spike resolved the chart-rendering choice outside the owner-decision table: a custom painter was selected over `fl_chart` and recorded in [ADR-0008](../adr/0008-chart-rendering.md).

The 2026-10-26 owner-requested extensions (body-weight check-ins and weekly
trend, weekly summary, dashboard, RIR explainer, post-workout summary, weekly
goals, plate calculator, night-session visual system, post-workout cat, Persian voice) are
documented with local IDs
in [PRODUCT.md](../PRODUCT.md#owner-requested-extensions-2026-10-26) and
[DESIGN.md](../DESIGN.md#owner-requested-extensions). The 2026-10-28 Obsidian
Telemetry rebrand supersedes the night-session description; the current visual
contract is [DESIGN.md](../DESIGN.md) and [PALETTE.md](../PALETTE.md). These
local extensions do not edit, relabel, or renumber a spec requirement row.

## Verification invariant

The split is mechanically checked: extract all 85 requirement IDs from the source (expanding the `NFR-PERF` summary row and including the six Section 22 budget IDs and `NFR-A11Y-001`), assert set equality with this map, and assert every requirement-definition row or heading appears exactly once across the module files with unchanged text. Module bodies match their source sections verbatim apart from the added header comment and file-boundary whitespace. Re-run that check whenever the spec is updated; never "fix" a mismatch by rewording a requirement.
