# ADR-0002: Weight Storage in Integer Grams

- Status: Accepted 2026-10-21
- Deciders: Project owner
- Requirements: `SET-003`, `L10N-007`, `LOG-001`, Section 21

## Context

The spec recommends storing weight as integer grams (canonical kilograms) and formatting for display. Display units are kg or lb and must never change stored data. Converting lb entries to kg and back must reproduce the value the user typed, including common plate weights such as 45 lb. Section 21 lists this as **Needs Decision**.

The owner selected integer grams.

## Decision

- Store every weight as an integer number of grams, canonical kilograms.
- Store per-exercise increments and progression arithmetic in grams as well.
- Convert to kg or lb only at the display and input boundaries.
- Use exactly one documented rounding rule at those boundaries; define it with the conversion code and test it.
- Never store a display unit, a floating-point kilogram value, or a formatted string as the source of truth.

Bodyweight sets use weight `0` grams, as allowed by `LOG-001`.

## Consequences

- Floating-point drift cannot change a logged set.
- Every conversion path needs round-trip tests, including 45 lb and repeated kg ↔ lb switches.
- Charts, PR detection, and progression all consume the same integer representation.

## Alternatives considered

- Double kilograms: simpler formatting, but vulnerable to drift and unit round-trip failures.
- Store the entered value plus its unit: duplicates the source of truth and complicates Merge import.

## Verification

- Property-style round-trip tests over the practical weight range.
- Explicit 45 lb and mixed-unit cases.
- Switching units repeatedly leaves stored values byte-identical.
- Database and export contain grams only.

## Revisit when

- A schema migration is required for a different representation; that migration needs its own ADR and owner approval.
