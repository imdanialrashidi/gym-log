# Agent Harness Operating Playbook

Detailed operating model for non-trivial DSH sessions. `AGENTS.md` stays a short map and points here instead of duplicating rules. Everything below uses DSH-native tools; install nothing.

Workflow source: [dsh-workflow](https://github.com/imdanialrashidi/dsh-workflow) v0.1 (commit `93c9281`). The six runtime skills are vendored under `.dsh/skills/` so the project is self-contained; project-specific commands and non-negotiables stay in `AGENTS.md` and the docs below.

## Design principles

1. **Intent steers; the agent finishes.** Convert the request into observable acceptance criteria, then execute reversible implementation and evidence gathering without intermediate approval loops.
2. **Repository knowledge is the system of record.** Durable product, architecture, quality, decision, and execution state belongs in versioned repository artifacts rather than chat memory.
3. **Progressive disclosure beats giant prompts.** Keep always-loaded instructions small and retrieve code, docs, skills, and external facts just in time.
4. **Native DSH tools beat bolted-on tooling.** Use the filesystem, shell, search, web, todo, skill, and subagent tools the runtime exposes. Do not add plugins, MCP servers, or a parallel orchestration system. Browser, LSP, and debugger tools are optional: when a runtime does not expose one, mark the dependent criterion `UNPROVEN` or unexecuted rather than inventing evidence.
5. **Prefer mechanical constraints over repeated prose.** If an invariant can be linted, tested, typed, validated, or blocked by tooling, encode it there.
6. **Evaluation needs a contract.** Independent review is most useful when it judges explicit observable criteria, not vague taste.
7. **Complexity must earn its cost.** Add agents, skills, loops, or persistent artifacts only for demonstrated failure modes.

## Execution protocol

### 1. Classify the task

- Quick: `quick-fix` — one direct patch, one targeted proof, scoped diff review.
- Standard: `spec` only when requirements are unresolved, then `build` → `verify` → `review`.
- Complex: plan in the conversation, track phases with `todo_write`, and use durable `docs/exec-plans/active/` state only when work must cross sessions.
- High risk: threat-boundary analysis, negative-path proof, a `review` pass plus independent review with a fresh-context `subagent` when available, recovery notes, and the full gate. A named human owner remains accountable.

### 2. Establish the acceptance contract

For Standard or larger work, write a compact contract before editing:

```text
Goal:
Non-goals:
Acceptance:
- A1 ... -> proof: ...
- A2 ... -> proof: ...
- A3 ... -> proof: ...
```

Good criteria describe user-visible or externally observable behavior. Avoid implementation trivia such as exact internal function names unless the public contract requires them.

Additional rules:

- Bug: capture the failure or a precise characterization before changing code when practical, using a focused test or a `bash` reproduction.
- Performance: capture a reproducible baseline and target.
- UI: include the critical user journey plus important loading/error/empty/permission states, and the accepted `docs/DESIGN.md` thesis for visually significant work. Use widget/golden tests and a real device or browser tool when the runtime provides one; appearance claims without runtime evidence are `UNPROVEN`.
- Security/data: include rejection/tampering/idempotency/ownership evidence where relevant.
- Do not accept placeholder buttons, stub handlers, fake persistence, TODO implementations, or display-only controls as satisfying functional criteria.

Keep ordinary contracts compact and in context. Complex or multi-session contracts belong in an execution plan.

The agent derives the contract from available evidence. It asks via `ask_user_question` only when no safe reversible interpretation exists; ordinary product, implementation, naming, tooling, and test choices are agent-owned.

### 3. Discover with a context budget

Start from identifiers, not bulk context. Prefer in this order:

1. repository map and relevant project docs;
2. `glob`/`grep` and analyzer/IDE diagnostics when the runtime exposes them, before bulk reading for anything a language server or compiler knows;
3. focused source ranges and affected tests;
4. `bash` runs (`flutter test`, `dart analyze`, project scripts) for runtime truth;
5. `web_search` + `web_fetch` for current upstream issues, advisories, regressions, or release notes.

Large reads summarize instead of dumping; use exact search and focused ranges rather than walking files linearly.

Use a `subagent` scout only when the relevant surface or cross-module flow is genuinely unclear. Otherwise investigate directly. Do not delegate the same discovery twice. One primary writer owns the worktree.

### 4. Implement one coherent vertical slice

Prefer a complete end-to-end behavior over many half-finished layers.

During implementation:

- use the narrowest reliable verification after meaningful edits (`verify`, affected lane);
- map the affected contracts/dependencies and nearest tests before editing; use analyzer diagnostics or exact search for exported symbols;
- when tests change, use `test-design` and apply its value questions; `no new test` is valid when existing evidence is already sufficient;
- preserve existing architectural boundaries; avoid speculative abstractions;
- keep data validation at boundaries; keep business rules testable outside UI/transport code where appropriate;
- do not clean unrelated code merely because it is nearby.

### 5. Evaluate independently

After the slice is functionally complete and targeted checks pass, classify risk Low / Medium / High from actual scope and impact (see `docs/QUALITY.md#project-verification-lanes`) and evaluate against the acceptance contract. Keep Low lightweight; require stronger proof for behavioral, architectural, security-sensitive, Git, CI/CD, and release-workflow changes; keep a human owner accountable for High-risk outcomes.

Load `review` for non-trivial user-facing, cross-module, production-bug, or material-regression work, and for all High-risk changes. For High-risk work, add independent review with a fresh-context `subagent` when the runtime provides it; provide the repository path, base/head, acceptance criteria, finding schema, and a read-only instruction. Never use `subagent_fork` for independence because it inherits history. If independent review is unavailable, perform a disciplined self-review and report independent review as unexecuted — do not claim it happened.

For UI behavior, use the real application, widget/golden tests, or a browser tool when available; interaction evidence comes before screenshots. Judge the rendered result against `docs/DESIGN.md` hard gates and quality budgets. If pixels cannot be inspected, mark appearance-dependent criteria `UNPROVEN`.

The evaluator should answer:

- Which acceptance criterion is proven?
- Which criterion is not proven or fails?
- Is any accepted functionality stubbed or only visually represented?
- Did the change introduce a regression outside the narrow happy path?
- What is the smallest evidence-backed fix?

Default to at most **two evaluator/repair rounds**. Re-review only the new diff after each fix; do not repeat resolved findings without new evidence. If a BLOCKER or MAJOR issue remains after two evidence-driven repair rounds, stop repeating the same loop: change the approach (re-characterize, shrink scope, change tool, or reassess the contract) or report `BLOCKED` with the exact prerequisite and recovery step.

When a recurring, reproducible failure reveals a missing rule, update the smallest appropriate existing contract or skill (prefer `docs/QUALITY.md`, `docs/HARNESS.md`, or the matching `.dsh/skills/*`) in one concise addition and keep shared instructions progressively disclosed. Do not add a benchmark framework, telemetry system, new dependency, or extra agent unless the existing architecture clearly requires it.

### 6. Verify and report evidence

Load `verify` and use its focused, integration, negative-path, and manual/runtime checks matched to the risk tier. Reuse `scripts/verify.sh` and existing CI; do not create a duplicate verification system. Map every acceptance criterion to evidence:

- passed;
- failed;
- blocked by prerequisite;
- unproven;
- not executed.

These are distinct statuses — never merge them. `UNPROVEN` is not ready. Never report a check as passed unless its command was executed and its result was observed.

The final report states the risk tier, files changed, verification commands actually run with observed results, unresolved findings, and any remaining `UNPROVEN` or `BLOCKED` items.

### Memory, context, and continuity

- There is no persistent memory tool across sessions. Durable facts belong in the repository: decisions in `docs/adr/`, contracts in `docs/`, and cross-session state in `docs/exec-plans/active/`. Never store secrets, credentials, or personal data.
- `todo_write` tracks multi-step work inside the current session. Update it when scope changes; do not use it as a substitute for an execution plan.
- Before context pressure or a deliberate handoff, update the active execution plan with the current goal, decisions, evidence, next action, and what must not be overwritten. A fresh session reads the plan, the working tree, and the actual checks; the plan is a pointer, not authority.
- Plan shape: Goal / Non-goals / Acceptance contract (checkboxes + proof) / Confirmed current state / Relevant surface / Decisions / Evidence (command → result) / Next actions / Risks-blockers / Handoff (changed, remaining, do-not-overwrite, first action). No pasted transcripts or giant logs.

### 7. Deliver (local-only on `main`)

Local-only: work directly on `main`, leave the proven change uncommitted in the working tree, and report its state per `docs/GIT_POLICY.md`. Never commit, push, branch, PR, merge, release, or publish. No delivery script exists.

## Failure-recovery ladder

If the same approach fails twice without new evidence, climb — do not loop:

1. **Re-characterize:** reproduce the failure more precisely (focused test, minimal repro, narrower log) before changing anything else.
2. **Shrink scope:** cut the slice to the smallest still-meaningful behavior and re-prove it.
3. **Change the tool:** analyzer diagnostics instead of guessing, focused `bash` run instead of a speculative script, `review`/fresh `subagent` for an independent verdict.
4. **Reassess the contract:** the criterion may be wrong, unmeasurable, or blocked by a genuine prerequisite — say so, mark it `BLOCKED`/`UNPROVEN`, and finish reachable work.
5. **Durable state:** for Complex work, write the current state into `docs/exec-plans/active/` and continue in a fresh session.
