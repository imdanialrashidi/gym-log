<!--
Spec source: Workout_Log_App_Business_and_Product_Specification_v1.0.md, section 27.
Copied verbatim; requirements are not reworded. Status labels are authoritative.
-->

## 27. Localization, RTL, and Persian Polish

(Your "Persian section" reply: all items included.)

| ID | Requirement | Pri | Notes |
|---|---|---|---|
| L10N-001 | Full RTL layout in Persian; use direction-aware spacing and alignment everywhere. | Must | Test every screen in both directions with screenshot/golden tests. |
| L10N-002 | All strings in resource files from day one, even before English is complete. | Must | CI check for missing keys. |
| L10N-003 | Font: **Vazirmatn** (OFL 1.1; designed for Persian/Arabic; its default build combines Roboto-derived Latin glyphs, with a Latin-free variant also available [S23]). | Must | **Needs verification:** whether digits align in columns (tabular figures). Test with weight/rep tables. |
| L10N-004 | Digit setting: Persian (۰۱۲۳۴۵۶۷۸۹) or Latin, applied consistently including charts. | Should | Input must accept both (see `LOG-010`). |
| L10N-005 | Jalali (Shamsi) date display with Persian month names; **store UTC only**. | Should | Never store Jalali strings in the database. |
| L10N-006 | Week start follows locale setting (Saturday for Persian by default, Assumption). | Should | Matters for weekly features in later phases. |
| L10N-007 | Units kg or lb as display preference. | Must | Canonical storage in grams. |
| L10N-008 | Persian text search normalization (ي/ی, ك/ک, ZWNJ). | Should | Needs Decision on exact rules. |
| L10N-009 | Chart axis direction in RTL. | Needs Decision | Recommendation: keep time progressing left to right on numeric charts and test with Persian labels; users may expect either. Ask 3 friends. |
| L10N-010 | Persian copy written by a native speaker, not machine-translated. | Must | Tone is calm and plain; avoid stiff literary Persian in buttons. |

---
