# ADR-0005: Chart Time Axis in RTL

- Status: Accepted 2026-10-21
- Deciders: Project owner
- Requirements: `L10N-009`, `PRG-001`, `PRG-002`, `PRG-003`

## Context

`L10N-009` leaves chart axis direction in RTL as **Needs Decision**. The spec recommends keeping time progressing left to right on numeric charts and testing with Persian labels.

The owner selected left-to-right time.

## Decision

- Time progresses left to right on charts in both LTR and RTL layouts.
- The chart's surrounding layout still mirrors for RTL; only the time axis direction is fixed.
- Persian labels use the active locale and must not be clipped.
- Do not mirror the data axis as a whole.

## Consequences

- Chart data preparation does not depend on text direction.
- RTL golden tests must prove that labels, tooltips, and legends mirror where appropriate while the time axis stays left to right.
- The decision is testable with Persian labels and a known ordered series.

## Alternatives considered

- Mirrored time axis: may match some readers' expectations but contradicts the owner decision and makes progress harder to compare across locales.

## Verification

- LTR and RTL goldens with Persian labels.
- A label-clipping check at the supported width.
- The first point is on the left and the last point on the right in both directions.

## Revisit when

- Friend testing shows the axis is consistently misread. Reopening this requires the owner.
