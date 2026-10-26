# Git Policy (local-only on main)

## Default: local working tree on `main`, no publication

All work happens locally in the working tree on branch `main`. Never create another branch, fork, or worktree for routine work.

Never commit, push, publish, open a PR, merge, release, or deploy. Leave the proven change uncommitted in the working tree and report its state. Read-only inspection (`git status`, `git diff`, `git log`) remains allowed.

## Prohibited

- `commit`, `push`, `pull` that publishes, `merge`, `rebase`, branch creation/deletion/switching, `stash`, `clean`, `reset`, `checkout` away from a dirty worktree, hook bypass (`--no-verify`), force flags, tag following, or submodule publication.
- The old `ai-changes` lane and its `omp-pr` delivery helper are gone and must not be reintroduced. This project has no delivery or team-publication lane.
- Never switch away from a dirty user worktree, discard staged changes, stash user work, publish unknown local commits, or include secrets in code/logs/artifacts.

## Allowed routine

1. Confirm `main` and a clean scoped starting point: `git status --short --branch`, `git diff --stat`.
2. Edit directly on `main` in the working tree. Preserve unrelated staged/unstaged work.
3. Verify locally with the cheapest faithful checks. Do not publish a failing, unverified, secret-bearing, or unresolved BLOCKER/MAJOR change.
4. Review the complete diff (`git diff`, `git diff --check`). Report result, changed files, exact checks/results, and remaining risks. No commit SHA or PR URL exists by design.
