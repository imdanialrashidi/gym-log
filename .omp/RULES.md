# Project sticky rules

Short, hard requirements. Long background belongs in `AGENTS.md`.

- Local-only on `main`: work uncommitted in the working tree on `main`. Never commit, push, branch, PR, merge, release, deploy, or mutate production. See `docs/GIT_POLICY.md`.
- Secrets stay out of code, logs, screenshots, fixtures, prompts, traces, and artifacts.
- No stubs, placeholder handlers, fake persistence, display-only controls, or TODO implementations as complete.
- Run the changed path before yielding; an unproven criterion is not passed.
- Never weaken, skip, or delete a valid test or control to get green.
