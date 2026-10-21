---
description: Verify the accepted change local-only on main without commit, push, PR, or deploy
argument-hint: "[release scope or execution plan]"
---

Ship this change when its acceptance contract is proven. Scope:

$ARGUMENTS

Use only the local-only scope in `docs/GIT_POLICY.md`. Work directly on `main`, never commit, push, branch, PR, merge, release, deploy, publish packages, change production, or rewrite unrelated code.

1. Read `AGENTS.md`, `docs/QUALITY.md`, `docs/GIT_POLICY.md`, and the accepted goal/active execution plan when one exists. For user-facing work also read `docs/DESIGN.md`.
2. Inspect the full working-tree diff and reconstruct the required acceptance criteria.
3. Reject readiness if accepted functionality is stubbed, display-only, backed by fake persistence, or lacks required proof.
4. Confirm no secret, private specification, generated artifact, debug bypass, unrelated change, or accidental workflow-policy modification is included.
5. For meaningful user-facing changes, require real `browser`-tool evidence for the critical journey when the application can run safely. For material visual work, require named desktop/mobile/demanding-state evidence and all hard gates in `docs/DESIGN.md`.
6. Require an independent evidence-focused pass (`/review`; plus `/advisor on` for High-risk work only — second model, extra cost) for non-trivial user-facing, cross-module, production-bug, or material-regression changes, and for all High-risk changes (security-sensitive, auth/access, money, secrets/privacy, schema/migration/deletion, public API, concurrency, Git/CI/CD, release workflow). No unresolved BLOCKER/MAJOR finding may remain. On re-review, check only the new diff; do not repeat resolved findings without new evidence.
7. Load `/skill:verify`, classify risk Low / Medium / High from actual scope and impact, and run the matching lane — Low stays lightweight, High requires the full gate (`scripts/verify.sh` plus existing CI, never a duplicate system) with a human owner accountable. Run the full gate once more when the task class or final readiness requires it.
8. Map every required criterion to `PASS`, `FAIL`, `UNPROVEN`, or `BLOCKED` with exact evidence. `UNPROVEN` is not ready.
9. If an active execution plan exists, update its final evidence/status. Mark/move it complete only when all required criteria are proven.
10. Leave the verified change uncommitted on `main` and report its working-tree state. Never commit, push, branch, PR, or run `scripts/omp-pr.mjs`. If blocked, preserve the diff and state the exact recovery step.

Return:

- verdict: `READY`, `READY WITH KNOWN LIMITATIONS`, or `NOT READY`;
- risk tier (Low / Medium / High) with scope reason;
- acceptance criterion → evidence/status;
- exact verification commands actually run and observed results (never claimed-only), plus what was not run and why;
- independent review status and any unresolved findings;
- changed files and working-tree state (uncommitted on `main`; no commit/PR by design);
- known limitations, remaining risks, and explicit `UNPROVEN`/`BLOCKED` items (none means none);
- rollback/recovery note where relevant;
- remaining owner action: review the working tree when needed.
