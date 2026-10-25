# ADR-0004: e1RM Display Thresholds

- Status: Accepted 2026-10-21
- Deciders: Project owner
- Requirements: `INT-003`, `PRG-002`

## Context

`INT-003` defines PR detection and estimated 1RM. It recommends the Epley formula and proposes display thresholds as **Assumptions/Needs Decision**: show normally for 1–10 reps, show 11–12 with a "less reliable" hint, and do not compute above 12.

The owner selected those thresholds.

## Decision

- Compute and show e1RM normally for 1–10 reps.
- Show 11–12 reps with a visible "less reliable" hint.
- Do not compute e1RM above 12 reps.
- Always label the value "estimated".
- Exclude warm-up sets.
- A tie is not a PR; the first-ever set is a baseline, not a PR; deleting the record set recalculates PR status.
- Version 1 ignores RIR in e1RM.

The Epley formula remains the spec's **Recommendation**, not a separate owner decision: `e1RM = weight × (1 + reps / 30)`. Implementation may verify the formula against the cited sources before treating it as fixed.

## Consequences

- Charts and PR badges must share the same thresholds and labels.
- Above 12 reps the UI shows no e1RM rather than a misleading number.
- Boundary behavior at 10, 11, 12, and 13 is testable.

## Alternatives considered

- Show e1RM for every rep count: rejected because accuracy degrades and the spec hides it above 12.
- Hide above 10: safer but discards the accepted 11–12 hint band.

## Verification

- Table-driven tests at reps 10, 11, 12, and 13.
- Both kg and lb inputs.
- Warm-ups excluded; tie is not a PR; first set is a baseline; deletion recalculates.
