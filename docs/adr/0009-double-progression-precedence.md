# ADR-0009: Double-Progression Precedence and Ambiguities

- Status: Accepted 2026-10-22 as the implementation reading; owner may revisit
- Deciders: Project owner (product ambiguities remain owner decisions)
- Requirements: `INT-002`, `INT-001`, `EXR-007`, Section 19, scenarios A4/A5, D11

## Context

`INT-002` defines three double-progression rules and the app must show the
suggestion with its reason. Two points are ambiguous:

1. `INT-001` says a double-progression suggestion overrides prefill while the
   user has not changed it, but Section 19 says suggestions never auto-apply.
2. The rules depend on the last session's working sets "at the same working
   weight", which is undefined when those sets used different weights.

The optional RIR gate (D11) is off by default and is out of scope.

## Decision

### Precedence and visibility

- The suggestion is computed from the latest completed session containing the
  exercise, excluding the active session. Warm-ups are ignored.
- Target sets and the rep range come from the active session exercise snapshot;
  the increment comes from the exercise (`EXR-007`).
- A new unsaved row starts with the suggested weight and target reps instead of
  the `INT-001` prefill. The same values apply to every unsaved row of that
  exercise, because the rule target is per exercise.
- Each affected row shows a `Suggestion` label, the localized reason, its own
  last-session weight/reps, and a one-tap **Use last time** action that restores
  that row's prefill and hides the suggestion. Repeating the sentence keeps the
  reason attached to every applied value instead of leaving later rows with an
  unexplained suggestion.
- Nothing is written to history or the active session until the user taps the
  normal check action. This honors `INT-001` precedence for the draft while
  keeping Section 19's "no auto-apply" observable: the applied values are
  labeled, explained, and reversible before logging.
- The suggestion is snapshotted when the exercise card first appears in the
  active session. Editing the prior session in History updates the next
  session's suggestion, not the drafts already open in this one, so the banner
  and the editable values cannot diverge.

### Mixed working weights

If the last session's working sets do not all share one weight, the input
"same working weight" is undefined. The app produces **no suggestion** rather
than guessing, so no weight increase can occur. This is the conservative
reversible reading requested for this slice.

### Bodyweight

Weight `0` is reps-only: the app never suggests a weight increase. Rule C
still holds at the range minimum when a set fell below it; otherwise the target
is `weakest + 1`, which may exceed the range maximum because there is no load
to add. At the stored repetition limit no suggestion is produced.

### Rule order and no-suggestion cases

The implementation checks Rule A, then the below-minimum hold, then Rule B.
The spec lists Rule C after Rule B, but a below-minimum set must not receive an
"add reps" target below the range; scenario A5 requires the hold.

No suggestion is returned for a first session, a missing rep range, or no
working sets. Missing target sets disable only Rule A, because "at least S
sets" cannot be evaluated; the rep-based rules still run. If Rule A cannot run
and the weakest set already reached the top of the range (or the stored
repetition cap for bodyweight), there is no progression left to suggest, so
the result is no suggestion rather than a downgrade. A suggestion whose weight
would exceed the stored maximum is suppressed.

## Consequences

- Suggestion values are drafts, never logged data; reverting needs no write.
- Mixed-weight history is treated as insufficient evidence, which may show
  fewer suggestions than a heuristic would.
- Bodyweight targets can leave the configured rep range at the top end.
- The core returns structured reason codes with numeric/canonical parameters;
  only the app layer formats them, so Persian and English share one rule
  source.

## Alternatives considered

- **Apply silently and rely on an undo snackbar:** conflicts with Section 19
  because the reason would not be visible before logging.
- **Show a banner but leave fields at prefill:** conflicts with `INT-001`
  precedence and makes the suggestion easy to miss.
- **Pick the heaviest or most common weight from mixed sets:** invents a
  working weight and can increase load ambiguously, so it is not conservative.

## Revisit when

- The owner decides a different precedence between `INT-001` and Section 19.
- Mixed-weight history needs a defined normalization rule.
- Bodyweight progression should stay inside the configured range.
- The optional RIR gate (D11) is enabled.
