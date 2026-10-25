<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 19.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 19. Intelligence Specification (Rule-Based, Offline, Explainable)

All logic lives in a **pure-Dart domain module** with no Flutter or database imports, so it can be tested in milliseconds and cannot be broken by UI changes. Every suggestion returns a **value plus a reason string** in the active language. Suggestions never auto-apply; the user is always in control.

**Safety framing (Recommendation):** Suggestions are training-log guidance, not medical or coaching advice. The About screen says so. The app never uses the word "AI" for these features.

### 19.1 `INT-001` Prefill from last session (Must, Confirmed)

- **Rule:** When a set row is created for exercise E, prefill weight, reps, and RIR from the **same set index** of E's most recent previous session (working sets only). If that index does not exist, use the **last working set** of that session. If no history exists, leave empty.
- **Precedence:** If a double-progression suggestion exists (`INT-002`) and the user has not changed it, the suggestion overrides the prefill for weight and target reps.
- **Edge cases:** warm-ups ignored; archived exercises still prefill; unit changes convert via canonical storage; a session with only warm-ups yields no prefill.
- **AC:** Unit tests cover first session, fewer sets than last time, more sets than last time, warm-ups only, and mixed units.

### 19.2 `INT-002` Double progression suggestion (Must, Confirmed; de-scope candidate)

The method is: work within a rep range, add reps at the same weight until every working set reaches the top of the range, then add weight and return to the bottom of the range [S10][S22].

- **Inputs:** plan item (target sets S, rep range [min, max]), last session's working sets for that exercise at the **same working weight**.
- **Rule A, increase weight:** If the last session had at least S working sets, and **every** one reached `max` reps → suggest `weight + increment`, target reps = `min`. Reason: "All N sets reached {max} reps last time, so add {increment}."
- **Rule B, add reps:** Else, suggest the **same weight**, target reps = `min(weakest set's reps + 1, max)`. Reason: "Your weakest set was {r} reps; aim for {r+1}."
- **Rule C, hold:** If any working set fell below `min`, suggest the **same weight**, target = `min`. Reason: "Below {min} reps last time; keep the weight and rebuild."
- **No suggestion:** first session; no rep range defined; no working sets last time.
- **Increment:** per-exercise setting; default 2.5 kg or 5 lb (Assumption).
- **Bodyweight (weight = 0):** reps-only progression; no weight suggestion.
- **Optional RIR gate (Could):** do not suggest a weight increase if logged RIR was high (e.g. ≥ 4) on the top sets, since that may mean the weight was too light to count as a hard set. Off by default. Threshold needs a decision.
- **Explicitly not included:** automatic deloads, periodization, set-count changes (Future Phase).
- **AC:** Table-driven unit tests with at least 25 cases (all-at-max, one set short, below min, unit change, mixed weights across sets, bodyweight, missing sets, warm-ups). Reason text is verified in both languages.

### 19.3 `INT-003` Personal records and estimated 1RM (Must, Confirmed)

- **PR types:** (1) heaviest weight for ≥ 1 rep; (2) most reps at a given weight; (3) highest estimated 1RM.
- **e1RM formula (Recommendation):** Epley, `e1RM = weight × (1 + reps / 30)` [S21]. It is common and simple, but any such equation is an **estimate**, and accuracy generally degrades at higher rep counts (roughly above 10) [S21]. These accuracy claims come from secondary and preprint sources; verify with primary literature before presenting numbers as precise.
- **Display rules:** compute and display for reps 1 to 10 normally; show 11 to 12 with a "less reliable" hint; do **not** compute above 12 (thresholds are Assumptions, Needs Decision). Always label "estimated".
- **RIR note:** Version 1 ignores RIR in e1RM. A "reps + RIR" effective-reps variant is a Future Phase idea that would need validation.
- **Rules:** warm-ups excluded; a tie is not a PR; the first-ever set of an exercise is a baseline, not a PR (no confetti on the first log).
- **AC:** Unit tests cover ties, warm-ups, first session, unit conversion, reps above threshold, and deletion of the PR set (PR status recalculates).

### 19.4 Science notes for the UI copy (Verified where cited)

- The RIR-based RPE scale (RPE 10 = 0 RIR, RPE 9 = 1 RIR, and so on) was introduced for resistance training by Zourdos et al. (2016) [S18].
- People are, on average, reasonably accurate at predicting repetitions to failure, roughly one repetition off on average; accuracy tends to improve closer to failure, with heavier loads, and when sets are 12 reps or fewer [S19]. **UI implication:** show RIR as the user's own estimate and show trends, never imply it is exact.
- Higher weekly set volume per muscle is associated with greater hypertrophy in meta-analytic data, with limits in the available evidence [S20]. **UI implication (Future Phase):** present weekly volume as information, not a prescription.

---
