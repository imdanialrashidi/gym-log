<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 26.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 26. Technology Stack and Tool Comparison

Package names below are **candidates**. At implementation time the agent must verify the current version, license, maintenance status, Android 7+ support, and size, then pin exact versions.

| Concern | Candidate | Notes |
|---|---|---|
| Flutter SDK | Current stable at project start, **pinned** | A Flutter release table (third-party mirror) lists 3.47.1 as the latest stable as of August 2026 and 3.44.9 from May 2026 [S13]. Verify on flutter.dev. The table and other sources indicate Material and Cupertino were being split into standalone packages around these releases (sources differ on the exact release) [S13]. **Pin the SDK and read release notes before upgrading.** |
| Min Android | API 24 | Flutter's own minimum SDK was raised to 24 [S14] |
| Database | `drift` + SQLite native bindings | Follow the current Drift setup docs [S11] |
| State | `flutter_riverpod` | Needs Decision |
| Routing | `go_router` | Needs Decision |
| Launching URLs | `url_launcher` | Launch in the external browser. On Android 11+, `canLaunchUrl` needs `<queries>` entries; simplest is to skip `canLaunchUrl` and handle a failed launch [S16] |
| Photos | `image_picker` | Uses system picker and camera intents; Android Photo Picker on Android 13+ [S27]. Handle "activity killed under memory pressure" via its lost-data API [S27] |
| File save/share | `share_plus` and/or a file picker | Needs verification; prefer system UI to avoid broad storage permission |
| Calendar | `shamsi_date` | BSD-3-Clause; 1.1.1; a third-party health snapshot shows modest maintenance activity [S24]. **Wrap behind a `CalendarService` interface** so it can be replaced by an in-house conversion without touching features |
| Localization | `intl` + Flutter localization | ARB files for fa and en |
| Charts | `fl_chart` or custom | See 25.2 |
| Font | Vazirmatn | SIL Open Font License 1.1 [S23] |

---
