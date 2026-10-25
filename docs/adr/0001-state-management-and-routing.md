# ADR-0001: State Management and Routing

- Status: Accepted 2026-10-21; exact pinning is conditional on verification
- Deciders: Project owner
- Requirements: `NFR-MNT-001`, Section 25.2, Section 26

## Context

The spec marks state management and navigation as **Needs Decision** (Section 25.2). It lists `flutter_riverpod` and `go_router` as candidates and requires every package's current version, license, maintenance status, Android 7+ support, and size to be verified before an exact pin (Section 26).

The owner selected Riverpod + go_router, subject to that verification.

## Decision

Use `flutter_riverpod` for state management and dependency wiring, and `go_router` for navigation.

This ADR does **not** pin versions. At M0, before adding either package:

1. Verify the current version, license, maintenance status, Android 7+ support, and size from official sources.
2. Record the result in the dependency ledger required by `AGENTS.md`.
3. Pin exact versions only after the record exists.

If verification fails, stop and return the choice to the owner. Do not silently substitute another state or routing package.

## Consequences

- Feature controllers and repository access are testable outside widgets.
- Navigation is declarative and can be exercised without a widget tree in tests.
- Two dependencies enter the supply-chain review instead of one.
- No second state-management or routing framework is added.

## Alternatives considered

- Bloc: more ceremony for this app's size (spec Section 25.2).
- Provider: less structured for testable feature controllers.
- Navigator 2 directly: more wiring than the app needs.

## Revisit when

- License, maintenance, or Android 7+ support fails verification at pin time.
- A future Flutter release makes either package incompatible with the pinned SDK.
- The owner accepts a replacement decision.
