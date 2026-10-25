<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 25.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 25. Recommended Architecture

### 25.1 Overview (Recommendation)

```
lib/
  app/            bootstrap, router, theme, DI wiring
  core/           db setup, l10n, units, calendar service, input normalizers
  data/           Drift tables, DAOs, repositories, export/import, photo storage
  features/       workout/ programs/ exercises/ history/ progress/ settings/ photos/
packages/
  lift_core/      PURE DART: entities, progression engine, e1RM, PR detector
test/             unit, migration, fixtures (historical exports), golden tests
integration_test/ key user flows
drift_schemas/    committed schema snapshots (one per version)
docs/             spec/ and adr/
AGENTS.md
```

- **Layers:** UI (widgets) → feature controllers (state) → repository interfaces → Drift data layer. Domain logic in `lift_core` has no outward dependencies.
- **Adding a feature** means adding a folder under `features/`, optionally a table via an additive migration, and optionally a pure function in `lift_core`. That is what "no hassle" looks like in practice.

### 25.2 Alternatives considered

| Decision | Chosen | Alternatives | Trade-off |
|---|---|---|---|
| UI framework | **Flutter** (Confirmed) | Native Kotlin + Compose | Flutter gives one codebase and fast iteration; native gives the smallest app and deepest platform integration. Your choice is respected. |
| Database | **Drift (SQLite)** | sqflite, NoSQL options | Drift's typed queries, streams, and generated migration tests [S11] directly serve requirement 11. Alternatives lack comparable migration tooling (Unverified; check at implementation time). |
| State | **Riverpod** (Needs Decision) | Bloc, Provider | Riverpod is testable and widely used; Bloc is more ceremony. Agent familiarity favors either. |
| Navigation | **go_router** (Needs Decision) | Navigator 2 direct | Declarative, well supported; verify maintenance at lock time. |
| Charts | Evaluate **fl_chart** vs custom painter (Needs Decision) | Commercial chart suites (license cost) | Spike in the charts milestone: 1,000-point render test and RTL behavior. |
| Backend | **None** (Confirmed) | Firebase, custom API | Violates local-first requirement. |

---
