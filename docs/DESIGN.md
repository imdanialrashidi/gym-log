# Product Design Contract

Specific, short, durable. The visual and interaction source of truth shared by build, device QA, and review. M0 implements the dark shell and makes `lib/app/theme/app_tokens.dart` the canonical code token source; the palette table below mirrors those tokens and is checked by `test/theme/contrast_test.dart`.

Status: dark-first and Persian-first RTL are owner-confirmed (`UI-001`, `SET-001`, `L10N-001`). The palette, spacing, typography weights, and motion values are the spec's design **Recommendation** and are the implemented M0 shell contract; the spec status still governs product acceptance. Owner decisions in ADR-0004 through ADR-0007 are marked where they apply. Where a component or state depends on another Recommendation (for example Safe Mode, the rest timer, or the volume chart), the requirement's spec status still governs acceptance.

## Owner direction

- **Style:** dark-first, high contrast, generous spacing, large touch targets, numbers as the hero, minimal chrome.
- **Colors:** use the exact palette in the token table below; it is the spec's proposed palette until the code token source exists. Do not add a second palette.
- **Theme:** dark by default; first launch is dark regardless of the system theme.
- **Typography:** Vazirmatn for Persian and Latin, Regular/Medium/Bold only (OFL 1.1; verify the license at pin time).
- **Density and shape:** 8 dp spacing grid; 12–16 dp corner radii; set rows tall enough for one-handed use.
- **Motion:** short and purposeful, about 150–200 ms.
- **Locales:** Persian primary, RTL; English, LTR. Every user-facing string exists in both.
- **Must keep:** calm, precise, quietly confident tone; clear numbers; one-tap confirmation; full RTL mirroring.
- **Must avoid:** neon overload, stock bodybuilder imagery, gamification clutter, hype, exclamation marks in core UI, "AI" claims, and color as the only signal.
- **Agent-proposed details:** exact type scale, icon set, elevation, and chart styling are implementation details; they must not contradict this contract.
- **Canonical code token source:** `lib/app/theme/app_tokens.dart`. It owns resolved values; this document owns intent and token mappings. Change both together and re-run the contrast test.

## Experience brief

- **Product/surface:** an offline Android workout log used between sets, often one-handed, sometimes in poor light.
- **Primary audience:** intermediate lifters training by rep ranges and RIR; Persian-first users first.
- **Single job of the logging surface:** record the set with as few taps as possible and show the next useful number.
- **Desired feeling before → after:** "I have to remember my numbers" → "the app already knows; I just confirm."
- **Success signal:** a prefilled set takes one tap; a changed weight takes at most three; the friend test is at least as fast as a notebook.

## Brand character

- Calm, not hype-driven.
- Precise, not clinical.
- Quietly confident, not boastful.
- Fast and respectful, not gamified.
- A well-kept training notebook, not a social feed.

## Direction

- **Visual thesis:** a dark instrument panel where the numbers are the content and chrome recedes.
- **Signature element:** the set row — large weight and reps, steppers, RIR chips, and one unmistakable check action.
- **What must feel familiar:** standard Android navigation and system pickers; no novel gesture required to log a set.
- **What must never look generic:** the set row and the restrained PR highlight; the app should not read as a reskinned template.

## Semantic tokens

Measured 2026-10-21 using the WCAG 2.x relative-luminance formula. Text pairs below are ≥ 4.5:1; large text may use the 3:1 threshold but this project targets 4.5:1 for all text.

| Role / state | Theme | Exact value | Pair | Contrast proof |
|---|---|---|---|---|
| canvas / background | dark | `#0E1116` | text primary `#E8EDF2` | 16.05:1 |
| canvas / background | dark | `#0E1116` | text secondary `#9AA7B5` | 7.72:1 |
| surface (cards, set rows) | dark | `#161B22` | text primary `#E8EDF2` | 14.68:1 |
| surface (cards, set rows) | dark | `#161B22` | text secondary `#9AA7B5` | 7.06:1 |
| surface 2 (raised, inputs) | dark | `#1F2630` | text primary `#E8EDF2` | 12.94:1 |
| surface 2 (raised, inputs) | dark | `#1F2630` | text secondary `#9AA7B5` | 6.22:1 |
| action / on-action | dark | accent `#3DDC97` | on-accent `#06251A` | 9.23:1 |
| accent as text/link | dark | `#3DDC97` | canvas `#0E1116` | 10.70:1 |
| accent as text/link | dark | `#3DDC97` | surface `#161B22` | 9.79:1 |
| highlight / PR | dark | `#FFC44D` | canvas `#0E1116` | 11.94:1 |
| highlight / PR | dark | `#FFC44D` | surface `#161B22` | 10.92:1 |
| danger / error | dark | `#FF6B6B` | canvas `#0E1116` | 6.81:1 |
| danger / error | dark | `#FF6B6B` | surface `#161B22` | 6.23:1 |
| info / hint | dark | `#6AA9FF` | canvas `#0E1116` | 7.86:1 |
| info / hint | dark | `#6AA9FF` | surface `#161B22` | 7.19:1 |
| outline / divider | dark | `#2A3340` | canvas `#0E1116` | 1.48:1 — decorative only |
| outline / divider | dark | `#2A3340` | surface `#161B22` | 1.36:1 — decorative only |

Hard rules:

- **Text contrast ≥ 4.5:1.** Re-measure any new pair before use.
- **Non-text controls ≥ 3:1** against their background. The outline token fails this and is **not** used as a control boundary, focus ring, or sole state indicator; use the accent for focus/active states.
- **Never color alone.** RIR chips always show their number; PR uses a label/icon as well as highlight; errors use text as well as danger; chart series carry labels or markers.
- **Touch targets ≥ 48 dp**, including steppers and RIR chips.
- **One source of truth.** When the code token source exists, update it and this table together; never maintain a competing palette.

## Typography

- Family: **Vazirmatn** for both Persian and Latin text. License: SIL Open Font License 1.1 (verify at pin time).
- Weights: **Regular, Medium, Bold** only; ship no unused weights (`NFR-SIZE-001`).
- Roles: large numerals in set rows and key stats; body text; labels/hints; one display treatment where needed.
- Exact sizes and leading belong to the code token source. Persian copy must be written or reviewed by a native speaker (`L10N-010`).
- Verify tabular-figure alignment for weight/repetition columns before locking the font build (`L10N-003`).
- Persian and Latin digits both appear; the digit setting changes display without changing stored data.

## Geometry and layout

- 8 dp spacing rhythm.
- 12–16 dp corner radii.
- 48 dp minimum touch target; set rows sized for one-handed use.
- Minimal chrome; the logging surface gives the set row the available width.
- RTL uses direction-aware spacing and alignment everywhere; do not hard-code left/right.
- Phones only. No tablet layout in this phase.

## Composition and responsiveness

- **Mobile composition:** one primary task per screen. The Workout tab is the logging surface; nothing competes with it.
- **Dense content:** set rows stay legible at large text; history and charts use lazy lists; no horizontal scrolling for primary actions.
- **Supported baseline:** Android API 24+ phones (Assumption: current Flutter floor); reference device TBD. Verify on a modest device, including the older-Android rendering path.
- **RTL/localization:** every screen has LTR and RTL goldens. Layout mirrors, but **chart time runs left to right in both directions** (ADR-0005). Persian labels must not clip.
- **Digits and calendar:** Persian/Latin digits are a display setting applied through one inherited scope, including chart labels; inputs accept both styles. Persian screens show Jalali dates with Persian month names; English screens keep Gregorian. Persian weeks start on Saturday (`L10N-004`–`L10N-006`).
- **Large text:** usable at 200% text scale; set rows remain operable; controls do not overlap.

## Components and states

| Component / pattern | Variants | Required states | Reuse or change |
|---|---|---|---|
| Set row | prefilled, edited, warm-up, bodyweight | default, focused/typing, invalid input, saved | One component; the core interaction |
| Weight/reps steppers | kg, lb, per-exercise increment | default, pressed, disabled at bound | Shared numeric control |
| RIR chips | 0–5+ | unselected, selected, empty/null | Always show the number |
| Check action | one per row | idle, saving, saved confirmation | Must commit immediately |
| PR badge | weight/reps/e1RM | hidden, visible; never on first set or warm-up | Subtle highlight, not confetti |
| Suggestion line | prefill, progression, hold | with reason; no suggestion | Reason in one sentence, localized |
| Empty state | no exercises, no history, no data for chart | clear prompt + one action | No bundled imagery |
| Export reminder | 30 days without export | hidden, visible, dismissed, snoozed | In-app banner only; only with data |
| Safe Mode | migration failed, database newer, cannot open | plain-language explanation, raw-DB export, diagnostics | Never writes to the database |
| Photo viewer | session photos, exercise photo | loading, empty, limit reached, missing file, delete confirmation | Max 3 session photos; private copy with no location metadata |
| History calendar | trained day marked | marked, unmarked, selected | Marking is not color-only |
| Chart | best weight, e1RM, reps/RIR, volume | loading, empty, gaps for missing RIR, range filter | Time axis LTR; labels not clipped |

Required journey states: loading, empty, error/retry, success, permission/offline where relevant. There are no network spinners in normal use because the app is offline.

## Motion, feedback, voice

- Transitions around 150–200 ms; purposeful, never blocking logging.
- **Reduced motion:** when the platform requests reduced motion, apply state changes immediately and keep the PR highlight static; never make an animation a prerequisite for feedback.
- A subtle highlight for a new PR; no confetti spam.
- Tapping check gives immediate visible confirmation; saved state is not a toast that disappears before it is read.
- Rest timer is in-app and never blocks logging; vibration on completion when enabled.
- Voice: short, plain sentences; calm; no hype; no "AI"; no guaranteed-results claims; no exclamation marks in core UI.
- Errors explain what happened and what to do next in both languages. Empty states explain what is needed, not just "no data".

## Quality budgets

- **Accessibility:** WCAG 2.2 AA; text contrast ≥ 4.5:1, non-text controls ≥ 3:1, 48 dp targets, 200% text support, meaning never by color alone.
- **Keyboard and focus:** visible focus using the accent token (10.70:1 on canvas; ≥ 3:1 non-text indicator), logical focus order, and full operation without color; hardware-keyboard and accessibility focus are supported.
- **Performance:** cold start ≤ 1.5 s, tap-to-confirmation ≤ 100 ms, prefill query ≤ 50 ms with 10,000 sets, chart first paint ≤ 200 ms for 1,000 points, history scroll without visible jank, export responsive with 10,000 sets. All device measurements are `UNPROVEN` until the reference device is selected.
- **Device:** profile mode on a physical device, never debug or an emulator; test the older-Android rendering path.
- **Visual proof:** LTR and RTL goldens for every screen, plus large-text and demanding-data states. Until implemented, screen acceptance is `UNPROVEN`.

## Screen acceptance

M0 implements the four-tab shell, the text-only empty states, and the
language control. M2 implements the exercise picker/creator and the
programs/days/plan-items planners described below. M3 implements the Workout
tab's start and active-session surfaces: program-day or empty start, target
sets/rep ranges, prefilled set rows with weight/reps steppers, optional RIR
chips, warm-up toggle, immediate check confirmation, add exercise/set, and
finish. M3 also implements the history list with a trained-day calendar,
session detail, session and per-exercise notes, set/session editing and
deletion, and the optional in-app rest timer banner. M4 adds the Progress tab
and exercise progress detail: best-set weight, estimated 1RM, reps, and RIR
series, a fixed left-to-right time axis in RTL, gaps for missing values, range
filter, empty states, and the subtle PR badge on logged sets. The M3 screens
have fa/en LTR/RTL goldens plus tap-count, rebuild-scope, 48 dp, and 200% text
tests; the M4 progress screens have fa/en LTR/RTL goldens plus data-preparation,
range/RTL, 1,000-point, 48 dp, 200% text, and PR-badge tests. M6 adds Settings
backup controls and the in-app export reminder: export through the system save
UI, a localized dry-run import dialog with Merge/Replace, clear rejection
messages, and a banner with export/later/dismiss actions. Device
share/picker behavior, the 10,000-set UI responsiveness on a physical device,
and device performance remain `UNPROVEN`.

M7 adds localization and accessibility polish: the Settings digit and default-increment controls, Persian/Latin digit rendering across every screen and chart, Jalali display behind `CalendarService` with Saturday week starts for Persian, LTR/RTL goldens for every route, a directionality guard for hard-coded left/right layout, 200% text/48 dp set-row and chart tests, and a native-speaker review sheet covering every fa string. The real-device large-font and contrast check (`NFR-A11Y-001`, A17) remains `UNPROVEN`.

M9 adds the About screen and the Settings backup-policy row. About follows the same dark, low-chrome list treatment: version, app license, open-source licenses, source and donation links that open externally, a privacy statement, and a medical-advice notice. The backup row is an enforced-off switch-style status, not an operational toggle: Android Auto Backup is a manifest/build-time decision and `DAT-007`/A18 require it disabled, so the row states the effective policy and points to export/import for migration.

| Flow / screen | Critical states | Viewports/locales | Visual proof |
|---|---|---|---|
| Workout / active session | empty start, prefilled rows, changed set, PR, rest timer, finish | phone; fa RTL + en LTR | goldens + tap-count test |
| Exercise picker/creator | empty, search hit/miss, duplicate warning, archived hidden, lookup failure | phone; fa + en | goldens + widget test |
| Exercise detail | no data, chart, PRs, photo, lookup | phone; fa + en | goldens + widget test |
| Programs, days, plan items | empty, validation errors, reorder, delete confirmation | phone; fa + en | goldens + persistence test |
| History and session detail | empty, marked calendar, notes, photos, edit/undo | phone; fa + en | goldens + widget test |
| Progress overview and chart | empty, 1,000 points, missing RIR gaps, range filter | phone; fa + en | goldens + data-preparation test |
| Settings | language, digits, units, default increment, rest timer, backup policy, export/import, About entry | phone; fa + en | goldens + widget test |
| About | version, license, source/donate links, privacy, medical notice, license page | phone; fa + en | goldens + mocked-launcher widget test |
| Photo viewer | one to three photos, missing file, removal | phone; fa + en | goldens + directory test |
| Safe Mode | failed migration, newer database, cannot open | phone; fa + en | goldens + write-spy test |

## Decision log

| Date | Decision | Evidence / rationale | Revisit when |
|---|---|---|---|
| 2026-10-21 | Dark-first; first launch dark regardless of system theme | Owner-confirmed `UI-001`; spec §29.4 | Owner changes the theme decision |
| 2026-10-21 | Palette and token roles recorded as above | Spec §29.4; measured WCAG ratios | A pair fails, or a new role is added without measurement |
| 2026-10-21 | 4.5:1 text, 3:1 non-text, 48 dp targets, never color alone | `NFR-A11Y-001`; project hard gates | An accepted accessibility target changes |
| 2026-10-21 | Chart time axis left to right, including RTL | Owner decision; ADR-0005 | User testing shows consistent misreading |
| 2026-10-21 | Vazirmatn Regular/Medium/Bold only | `L10N-003`; OFL 1.1; size target | License or tabular-figure check fails |
| 2026-10-21 | M0 shell uses the token source, dark-only theme, fa/en ARB, and four text-only tab empty states | `UI-001`, `SET-001`, `L10N-001`–`003`; contrast and RTL goldens pass | A token pair fails or the shell direction changes |
| 2026-10-21 | Session photos max 3; excluded from JSON export | Owner decision; ADR-0006 | Owner authorizes a ZIP archive |
| 2026-10-21 | Android backup toggle visible, default off | Owner decision; ADR-0007 | Owner changes the default |
| 2026-10-21 | Progress charts use a custom painter, no chart package | Measured 1,000-point/RTL spike; ADR-0008 | A required chart feature makes custom work uneconomical |
| 2026-10-22 | Reminder: visible after 30 days without export when data exists; “Later” snoozes 30 days; dismiss lasts until the next export; no notification permission | `SET-004`; ADR-0003; fake-clock policy/widget tests; manifest guard | Owner changes reminder timing or dismissal semantics |
| 2026-10-22 | Import dialog defaults to Merge, states the conflict policy, and requires explicit Replace | `IO-003`; ADR-0003 same-ID policy | A restore test shows Merge semantics are unsafe |
| 2026-10-23 | Persian UI shows Jalali dates; English shows Gregorian; Persian weeks start Saturday | `L10N-005`, `L10N-006`; `CalendarService`; independent conversion vectors | Calendar library or locale policy changes |
| 2026-10-23 | Digits default to the UI language; an explicit setting overrides everywhere including charts | `SET-002`, `L10N-004`; widget coverage sweep over every route | A digit-bearing surface is added |
| 2026-10-23 | Settings carries a default increment for new exercises; per-exercise values stay authoritative | `EXR-007`; Settings IA | A global increment becomes unnecessary or confusing |
| 2026-10-25 | Photos are deterministic app-private files outside the data document; session limit 3; viewer shows missing-file state | `PHO-001`–`PHO-003`, `PHO-005`, `EXR-005`, ADR-0006; directory and injected-failure tests | Photo storage or export policy changes |
| 2026-10-25 | About shows version, app license ("All rights reserved" until the owner publishes a license), open-source licenses, external source/donate links, privacy, and a not-medical-advice note | `SET-005`; mocked-launcher widget tests; Flutter `LicensePage` | Owner chooses a license or changes donation/source links |
| 2026-10-25 | The "Allow Android backup" row is an enforced-off status, not a runtime toggle | `DAT-007`, A18, ADR-0007 amendment; Auto Backup is manifest/build-time; release guard fails if backup is enabled | Android or the owner provides a verified runtime opt-in mechanism and the manifest guard is deliberately revised |
