# lift_core

Pure Dart domain layer for Gym Log: entities, progression, e1RM, PR detection,
unit conversion, and normalization.

Rules:

- No Flutter, database, platform, or UI imports (`NFR-MNT-001`).
- No dependency on `lib/` or `packages/` outside this package.

Run the package checks:

```sh
(cd packages/lift_core && dart pub get && dart analyze && dart test)
```
