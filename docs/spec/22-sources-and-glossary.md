<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 38.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 38. Sources and Research Notes

Accessed 2026-10-18. Reliability notes are given where a source is a vendor, a competitor, a forum, or a preprint. Several competitor sources are published by competing products and may favor their own offering.

**Competitors and market**
- [S1] Boostcamp, "Best Workout Apps in 2026" (vendor-published, updated July 2026): https://www.boostcamp.app/best/workout-apps
- [S2] SensAI, "Hevy Review 2026" (competing product's blog): https://www.sensai.fit/blog/hevy-review-2026
- [S3] SensAI, "Fitness App Pricing 2026" (same caveat; page states July 2026 verification): https://www.sensai.fit/blog/fitness-app-pricing-free-tier-comparison
- [S4] JEFIT, "Fitbod vs Strong vs Jefit vs Hevy" (published by JEFIT, which discloses it; facts dated September 2026): https://www.jefit.com/blog/fitbod-vs-strong-vs-jefit-vs-hevy
- [S5] WhistleOut, FitNotes review: https://www.whistleout.com/CellPhones/Apps/fitnotes-app-review
- [S6] AlternativeTo, FitNotes (crowd-edited; licensing and language fields): https://alternativeto.net/software/fitnotes/about
- [S7] BGR, essential Android fitness apps (FitNotes CSV export): https://bgr.com/2021999/essential-android-apps-fitness-workout-tracking/
- [S8] wger Flutter app: https://f-droid.org/packages/de.wger.flutter/ and https://github.com/AmanNegi/flutter
- [S9] Community discussion mentioning open-source trackers (low reliability): https://lemm.ee/post/2780423
- [S10] Boostcamp, Auto Progression: https://www.boostcamp.app/features/auto-progression
- [S28] Name collisions: https://setgraph.app/features/workout-log , https://marlvel.ai/api/llm/apps/health-fitness/tamrena-smart-workout-log , https://mwm.ai/apps/gym-log/871239624 , https://apps.apple.com/us/app/id6455539422 , https://apps.apple.com/us/app/-/id6737412732
- [S29] Cafe Bazaar developer pages (search was inconclusive): https://cafebazaar.ir/developer/leap-fitness-group

**Technical**
- [S11] Drift migrations and migration tests: https://drift.simonbinder.eu/docs/migrations/ and https://drift.simonbinder.eu/docs/migrations/tests/
- [S12] Flutter Impeller docs: https://docs.flutter.dev/perf/impeller.md ; Impeller on Android (engine doc): https://github.com/flutter/engine/blob/main/impeller/docs/android.md
- [S13] Shorebird Flutter version table (third-party mirror; verify on flutter.dev): https://docs.shorebird.dev/getting-started/flutter-version.md
- [S14] Flutter minimum Android SDK 24: https://github.com/flutter/packages/pull/10470/files and https://flutter.googlesource.com/mirrors/flutter/+show/11e8feb1334128284fe4cfa8ee30815bdbc7f619/docs/platforms/android/Update-Android-MinSdk-Version.md
- [S15] Android update/signing certificate behavior (secondary explanation; the official signing page was referenced by forum posts but not fetched here): https://codemia.io/knowledge-hub/path/how_to_deal_with_install_parse_failed_inconsistent_certificates_without_uninstall ; official page to verify: https://developer.android.com/studio/publish/app-signing
- [S16] `url_launcher` documentation: https://pub.dev/documentation/url_launcher/latest/
- [S17] Android Auto Backup (official): https://developer.android.com/identity/data/autobackup
- [S27] `image_picker` documentation: https://pub.dev/documentation/image_picker/latest/
- [S24] `shamsi_date` third-party health snapshot (verify on pub.dev): https://mcp.depscope.dev/pkg/pub/shamsi_date
- [S23] Vazirmatn font repository (OFL 1.1): https://github.com/rastikerdar/vazirmatn
- [S26] F-Droid inclusion policy: https://f-droid.org/wiki/page/Inclusion_Policy
- [S25] GitHub trade controls: https://docs.github.com/en/site-policy/other-site-policies/github-and-trade-controls ; earlier restrictions reporting: https://www.computing.co.uk/news/3079708/github-blocks-developers

**Training science**
- [S18] Zourdos et al. (2016), *J Strength Cond Res* 30(1):267-275, RIR-based RPE scale: https://openrepository.aut.ac.nz/items/efef3b25-6701-4fb5-bb82-55fcd2a26027/full ; Helms et al. (2016), *Strength Cond J* 38(4):42-49: https://ro.ecu.edu.au/ecuworkspost2013/2114
- [S19] Halperin et al. (2022), *Sports Med* 52(2):377-390, accuracy of predicting repetitions to failure: https://pubmed.ncbi.nlm.nih.gov/34542869/
- [S20] Schoenfeld, Ogborn, Krieger (published online 2016), *J Sports Sci*, weekly volume and hypertrophy meta-analysis: https://paulogentil.com/pdf/Dose-response%20relationship%20between%20weekly%20resistance%20training%20volume%20and%20increases%20in%20muscle%20mass%20-%20A%20systematic%20review%20and%20metaanalysis.pdf ; author summary: https://biolayne.com/reps/issue-31/the-king-of-volume-metas/ ; frequency meta-analysis record: https://lida.sport-iat.de/ta/Record/4052540?lng=en
- [S21] e1RM equations and accuracy (secondary and preprint sources; verify with primary literature before precise claims): https://dev.to/ffmicheck/the-two-1rm-formulas-that-give-different-answers-and-which-one-to-trust-8ib , https://sportscategory.info/en/articles/one-rep-max , https://arxiv.org/pdf/2603.17495v1.pdf
- [S22] Double progression explainers (practitioner sources): https://rippedbody.com/progression/ , https://setgraph.app/articles/double-progression-the-smarter-way-to-add-reps-and-weight

### 38.1 What I could not verify (treat as hypotheses)

- Whether a mature free, open-source, offline, Persian-first lifting log already exists (E0).
- Cafe Bazaar and Myket developer requirements, re-signing behavior, and policies.
- Current free CI minutes for public repositories.
- Whether Vazirmatn digits align as tabular figures.
- Google Images query parameters and any region-specific behavior of the search URL: confirm by testing on a device.
- Whether Excel opens UTF-8-with-BOM Persian CSV correctly on your setup.
- Package licenses, versions, and maintenance status for every candidate dependency (to be checked at lock time).
- Current availability of donation platforms for your situation.

### 38.2 Glossary

| Term | Meaning |
|---|---|
| **RIR** | Reps in reserve: how many more reps you could have done |
| **Rep range** | Target interval of reps per set (e.g. 8 to 12) |
| **Double progression** | Add reps at a fixed weight until the top of the range on all sets, then add weight |
| **e1RM** | Estimated one-rep max, calculated from weight and reps |
| **PR** | Personal record |
| **Working set** | A non-warm-up set that counts toward volume and progression |
| **Migration** | A tested script that upgrades the database structure between app versions |
| **Safe Mode** | Recovery screen shown when the database cannot be opened or migrated |
| **applicationId** | Permanent Android package identifier; cannot change without becoming a different app |
| **Impeller** | Flutter's current rendering engine |
| **Jalali (Shamsi)** | The Persian solar calendar |
| **OFL** | SIL Open Font License |

---

*End of document. Version 1.0 (Draft). This file is the project's source of truth once the owner approves it and resolves the items in Section 28.*
