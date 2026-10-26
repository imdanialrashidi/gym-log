# Workflow Reconciliation

The spec's Section 24 predates the adopted DSH Workflow and calls itself a placeholder. The DSH Workflow is the adopted process. This file records every process conflict, the resolution, and the spec rules that survive unchanged. It began as the OMP reconciliation; OMP was superseded by the DSH Workflow on 2026-10-25, and the resolutions below carry over unchanged. It does not change product behavior or any requirement status.

## Precedence

- **Product scope and behavior:** the verbatim spec modules in this directory, read by requirement ID.
- **Workflow, quality, and delivery:** `AGENTS.md`, `docs/HARNESS.md`, `docs/QUALITY.md`, `.dsh/skills/`, and `docs/GIT_POLICY.md`.
- **A specific task:** the current accepted request and its acceptance criteria, including its explicit non-goals.
- **Architecture and design:** `docs/ARCHITECTURE.md` and `docs/DESIGN.md`, distilled from the spec and the owner decisions in `docs/adr/`.

When a process statement in the spec conflicts with the DSH Workflow, the workflow wins. When a product requirement conflicts with a workflow rule, the product requirement still defines what the app must do; the workflow defines how an agent works.

## Conflicts and resolutions

| # | Spec position | Workflow position | Resolution |
|---|---|---|---|
| C1 | Section 0.1: this document is the "single source of truth"; if something is not here, it is not in scope. | `AGENTS.md` authority chain: current request and accepted criteria first, then the active plan, product/architecture/design contracts, quality policy, implementation/tests, docs, assumptions. | Split the claim. The spec is the source of truth for **product scope and behavior**. The current accepted task and the DSH Workflow govern **what an agent does now**. Neither silently overrides the other; a material conflict is reported. |
| C2 | Section 0.1: agents should work "one requirement ID at a time". | The workflow implements one coherent vertical slice; a slice may satisfy several related requirements. | Keep requirement IDs as the unit of traceability, not an artificial limit on slice size. Every touched ID is cited in the task and report. |
| C3 | Section 24.2.6: "Every task ends with: tests passing, lints clean, and a short note". | The workflow: no forced new tests; apply `test-design`'s value checks; `No new test` is valid; run the changed path, and a required criterion without evidence is `UNPROVEN`, not passed. | The workflow decides **whether to add tests**. The spec mandates tests for database migrations and update safety (`DAT-001`–`DAT-003`), JSON import/export and fixtures (`IO-001`–`IO-006`, `DAT-006`), and pure domain logic in `packages/lift_core` (`INT-001`–`INT-003`, unit conversion, input normalization, PR detection). The project additionally requires a Safe Mode test for the `DAT-004` Recommendation. Every task still runs its changed path and the applicable verification lane. "Lints clean" and the change/requirement note survive as workflow evidence and reporting requirements, which are stricter. |
| C4 | Section 24.3: CI runs format, analysis, tests, migration tests, fixture-import tests, and a debug build on every pull request; tagged releases run a signed build. | DSH `docs/GIT_POLICY.md`: local-only on `main`; never commit, push, branch, PR, merge, release, or deploy. | The workflow wins for agent actions. The CI checks and release steps remain project and owner gates; an agent may run the same checks locally and report the observed result, but must never claim CI ran or perform a release. This seed task changes no CI. |
| C5 | Section 24.1: `AGENTS.md` contains purpose, non-negotiable rules, build/test commands, folder map, and definition of done. | The DSH Workflow: `AGENTS.md` is a short always-loaded map; procedures belong in `docs/` and `.dsh/skills/`. | `AGENTS.md` keeps the map, the project non-negotiables, the target layout, and the mandatory-test scope. Commands appear when they exist; the definition of done stays in `docs/HARNESS.md` and `docs/QUALITY.md`. |
| C6 | Section 24 is a Recommendation to be aligned with a Workflow Guide that had not been received. | The DSH Workflow is the adopted workflow. | Section 24 is retained verbatim in [90-legacy-agent-operating-model.md](90-legacy-agent-operating-model.md) for traceability and is marked superseded. No process clause in it overrides the DSH Workflow. |
| C7 | Section 37.4: every release requires CI green, a new fixture, an upgrade drill, budget verification, signing, checksums, and a changelog. | The workflow: the agent never releases; a human owner is accountable; unproven criteria are reported as `UNPROVEN`/`BLOCKED`. | Retained as owner release gates. The agent prepares and verifies local evidence where possible and reports gaps explicitly. The gate is not weakened by the agent's inability to run it. |
| C8 | Section 24.2.3: never add or upgrade a dependency without recording license, maintenance status, and size, and pinning an exact version. | The workflow: new dependencies need a concrete benefit over platform capabilities; pinning and supply-chain caution are part of maintainability. | Compatible. Retained and strengthened in `AGENTS.md` and `docs/QUALITY.md`: exact pin plus license, maintenance status, and size recorded before adoption. |
| C9 | Section 24.2.6: a short note of what changed and which requirement IDs it satisfies. | The DSH final report: result, criterion-to-evidence mapping, checks actually run, risks, and remaining `UNPROVEN`/`BLOCKED` items. | Compatible. The workflow report is the stronger form and satisfies the note. |

## Retained non-negotiables

These are unchanged by the reconciliation and are enforced across `AGENTS.md`, `docs/ARCHITECTURE.md`, and `docs/QUALITY.md`:

1. Never edit an existing migration; only add a new step with tests (`DAT-001`).
2. Release builds declare no `INTERNET` permission; no analytics, ads, or crash-reporting SDKs (`NFR-ARCH-001`, `NFR-SEC-001`).
3. Every dependency is exact-pinned with license, maintenance status, and size recorded before adoption (`Section 24.2.3`, `NFR-MNT-001`).
4. Domain logic lives only in `packages/lift_core`, with no Flutter or database imports (`NFR-MNT-001`, Section 25.1).
5. Every user-facing string exists in both `fa` and `en` (`L10N-002`).
6. Never touch signing keys or secrets; never put them in the repository, logs, prompts, or artifacts (`DAT-005`, `NFR-PRV-001`).
7. No destructive database fallback (Confirmed `DAT-002`); failure targets Safe Mode (Recommendation `DAT-004`).
8. Data-safety requirements keep their spec status: migrations, no destructive fallback, and snapshot are Must; Safe Mode and the signing-key rules are Recommendations; export/import and release discipline are as labeled. No requirement is upgraded by this reconciliation.

## Test policy after reconciliation

- **Mandatory:** migrations and update safety, JSON import/export (including round-trip and historical fixtures), and `lift_core` domain logic. These are acceptance evidence, not optional coverage.
- **Conditional:** everywhere else, add a test only when it catches a plausible consumer-visible regression and existing evidence has a gap. A behavior-neutral docs change may have no new test.
- **Always:** run the changed path, inspect the diff, and map every accepted criterion to observed evidence. Passing checks must exercise the accepted behavior, never a mock of the authority or a hard-coded success.
