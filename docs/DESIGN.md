# Product Design Contract

Specific, short, durable. The visual and interaction source of truth shared by build, device QA, and review. M0 implements the dark shell and makes `lib/app/theme/app_tokens.dart` the canonical code token source; the palette table below mirrors those tokens and is checked by `test/theme/contrast_test.dart`.

Status: dark-first and Persian-first RTL are owner-confirmed (`UI-001`, `SET-001`, `L10N-001`). The palette, spacing, typography weights, and motion values are the implemented design contract. The 2026-10-26 night-session pass replaced the cut-corner training-ledger language with rounded navy panels, an electric-blue action color, ring progress, and a post-workout cat mascot; the dashboard, active workout, post-workout summary, weekly summary, Programs, Exercise library, History, Progress, and Settings all render the new surface. The spec status still governs product acceptance. Owner decisions in ADR-0004 through ADR-0007 are marked where they apply. Where a component or state depends on another Recommendation (for example Safe Mode, the rest timer, or the volume chart), the requirement's spec status still governs acceptance.

## Owner direction

- **Style:** a night-session instrument: near-black navy canvas, electric-blue light, rounded panels, generous spacing, large touch targets, numbers as the hero, minimal chrome.
- **Colors:** use the exact palette in the token table below; it is the implemented palette and the code token source is authoritative. Do not add a second palette.
- **Theme:** dark by default; first launch is dark regardless of the system theme.
- **Typography:** Vazirmatn for Persian and Latin, Regular/Medium/Bold only (OFL 1.1; verify the license at pin time).
- **Density and shape:** 8 dp spacing grid; panels use a 20 dp rounded corner and a 1 dp translucent hairline; controls use 12–16 dp radii; status chips, day pills, and nav indicators are pills; set rows stay tall enough for one-handed use.
- **Motion:** short and purposeful, about 150–200 ms; the post-workout check seal and the cat mascot are the two entrance animations and both respect reduced motion.
- **Surface language:** a night-session instrument, not a component gallery: a soft blue glow behind rounded navy panels, one electric-blue action per surface, thin ring gauges for weekly progress, and calm data density.
- **Locales:** Persian primary, RTL; English, LTR. Every user-facing string exists in both.
- **Must keep:** calm, precise, quietly confident tone; clear numbers; one-tap confirmation; full RTL mirroring.
- **Must avoid:** neon overload, stock bodybuilder imagery, gamification clutter, hype, exclamation marks in core UI, "AI" claims, and color as the only signal. The one playful exception is the post-workout cat's line and meow.
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

## Brand mark

- **Concept:** an electric-blue progress ring enclosing a barbell, closed by a gold marker. It says "training, measured" without stock gym imagery or text inside the icon.
- **Source of truth:** `assets/branding/logo_mark.png` (1024 px, generated for this project) and the full kit in [`assets/branding/`](../assets/branding/README.md). The Android launcher mipmaps are derived from `app-icon-full-bleed-1024.png`; the in-app lockup is painted by `BrandEmblem` in `lib/app/theme/brand_mark.dart` so it stays crisp at every text scale, costs no image decode, and cannot flash blank in goldens.
- **Rules:** keep ≥ 15% clear space around the emblem so launcher masks never crop it; use only tokens from the palette; the gold marker is the single highlight; never set the wordmark inside the icon. Use the transparent horizontal lockup at ≥ 220 px wide for the website, and the `on-light` variant on light backgrounds.
- **Kit:** `logo-mark-2048.png` (transparent mark), `logo-horizontal*.png` (website lockups), `logo-stacked.png` (profile avatar), `website-hero-2400x1000.png`, `social-card-1200x630.png`, and `favicon-*`; regenerate with `python3 tool/branding/render_branding.py`.

## Direction

- **Visual thesis:** a night session under one blue light. Deep navy canvas, soft blue halo, rounded instrument panels, and the numbers as the content; chrome recedes.
- **Signature element:** the set row — large weight and reps, steppers, RIR chips, and one unmistakable check action — plus the round weekly ring and the post-workout cat.
- **What must feel familiar:** standard Android navigation and system pickers; no novel gesture required to log a set.
- **What must never look generic:** the set row, the weekly ring, the week rail, the post-workout seal, the finish cat, and the restrained PR highlight; the app should not read as a reskinned template.

## Semantic tokens

A standalone handoff copy of the palette, including gradients, CSS variables,
and a Persian summary, is in [PALETTE.md](PALETTE.md). This section owns the
design intent; `lib/app/theme/app_tokens.dart` remains the canonical value
source. Update both together.

Measured 2026-10-26 using the WCAG 2.x relative-luminance formula. Text pairs below are ≥ 4.5:1; large text may use the 3:1 threshold but this project targets 4.5:1 for all text.

| Role / state | Theme | Exact value | Pair | Contrast proof |
|---|---|---|---|---|
| canvas / background | dark | `#070B14` | text primary `#F4F7FF` | 18.36:1 |
| canvas / background | dark | `#070B14` | text secondary `#9AA9C4` | 8.29:1 |
| surface (cards, set rows) | dark | `#0E1524` | text primary `#F4F7FF` | 17.02:1 |
| surface (cards, set rows) | dark | `#0E1524` | text secondary `#9AA9C4` | 7.68:1 |
| surface 2 (raised, inputs) | dark | `#162034` | text primary `#F4F7FF` | 15.19:1 |
| surface 2 (raised, inputs) | dark | `#162034` | text secondary `#9AA9C4` | 6.86:1 |
| surface 3 (saved rows, pressed) | dark | `#1F2B42` | text primary `#F4F7FF` | 13.22:1 |
| surface 3 (saved rows, pressed) | dark | `#1F2B42` | text secondary `#9AA9C4` | 5.97:1 |
| action / on-action | dark | accent `#5B9BFF` / on-accent `#061024` | pair | 6.84:1 |
| accent as text/link | dark | `#5B9BFF` | canvas `#070B14` | 7.10:1 |
| accent as text/link | dark | `#5B9BFF` | surface `#0E1524` | 6.58:1 |
| accent as text/link | dark | `#5B9BFF` | surface 2 `#162034` | 5.87:1 |
| accent as text/link | dark | `#5B9BFF` | surface 3 `#1F2B42` | 5.11:1 |
| highlight / PR | dark | `#FFC857` | canvas `#070B14` | 12.79:1 |
| highlight / PR | dark | `#FFC857` | surface `#0E1524` | 11.86:1 |
| highlight / PR | dark | `#FFC857` | surface 2 `#162034` | 10.58:1 |
| highlight / PR | dark | `#FFC857` | surface 3 `#1F2B42` | 9.21:1 |
| danger / error | dark | `#FF6B7A` | canvas `#070B14` | 7.16:1 |
| danger / error | dark | `#FF6B7A` | surface `#0E1524` | 6.63:1 |
| info / hint | dark | `#6EE7F9` | canvas `#070B14` | 13.55:1 |
| info / hint | dark | `#6EE7F9` | surface `#0E1524` | 12.56:1 |
| body weight / check-in | dark | `#A78BFA` | canvas `#070B14` | 7.23:1 |
| body weight / check-in | dark | `#A78BFA` | surface `#0E1524` | 6.70:1 |
| body weight / check-in | dark | `#A78BFA` | surface 2 `#162034` | 5.98:1 |
| body weight / check-in | dark | `#A78BFA` | surface 3 `#1F2B42` | 5.21:1 |
| on-color text | dark | background `#070B14` on danger `#FF6B7A` | pair | 7.16:1 |
| on-color text | dark | background `#070B14` on info `#6EE7F9` | pair | 13.55:1 |
| on-color text | dark | background `#070B14` on weight `#A78BFA` | pair | 7.23:1 |
| accent gradient companion | dark | `#2F6BFF` | decorative only; never small text | — |
| outline / divider | dark | `#26344F` | canvas `#070B14` | 1.58:1 — decorative only |
| outline / divider | dark | `#26344F` | surface `#0E1524` | 1.46:1 — decorative only |

Measured 2026-10-26 with the WCAG 2.x relative-luminance formula on the night-session palette. The hero gradient (`#172C54` → `#0C1628` → surface) is decorative and always sits under solid roles; the worst stop still gives text primary 12.85:1, secondary 5.80:1, and accent 4.97:1.

Hard rules:

- **Text contrast ≥ 4.5:1.** Re-measure any new pair before use.
- **Non-text controls ≥ 3:1** against their background. The outline token fails this and is **not** used as a control boundary, focus ring, or sole state indicator; use the accent for focus/active states.
- **Never color alone.** RIR chips always show their number; PR uses a label/icon as well as highlight; errors use text as well as danger; chart series carry labels or markers.
- **Touch targets ≥ 48 dp**, including steppers and RIR chips.
- **One source of truth.** When the code token source exists, update it and this table together; never maintain a competing palette.

## Typography

- Family: **Vazirmatn** for both Persian and Latin text. License: SIL Open Font License 1.1 (verify at pin time).
- Weights: **Regular, Medium, Bold** only; ship no unused weights (`NFR-SIZE-001`).
- Roles: large tabular numerals in set rows, the week hero, and the summary; body text; labels/hints; one display treatment where needed. Display sizes are 38/30/24 sp with tabular figures so the layout does not shimmer when numbers change.
- Exact sizes and leading belong to the code token source. Persian copy must be written or reviewed by a native speaker (`L10N-010`).
- Verify tabular-figure alignment for weight/repetition columns before locking the font build (`L10N-003`).
- Persian and Latin digits both appear; the digit setting changes display without changing stored data.

## Geometry and layout

- 8 dp spacing rhythm (4 dp halves for dense meta pills).
- Panels use a 20 dp rounded corner and a hairline border; controls use 12–16 dp radii; only true tokens (PR, status, day chips, nav indicator) may use a pill. No cut corners remain.
- 48 dp minimum touch target; set rows sized for one-handed use. Calendar day cells are 48 × 48 at 360 dp width; the history lane uses 8 dp page padding so seven columns fit without shrinking the target.
- Responsive page padding: 16 dp below 360 dp, 24 dp above; every screen also has to survive 200% text.
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
| Chart | best weight, e1RM, reps/RIR, volume | loading, empty, gaps for missing RIR, range filter | Time axis LTR; labels not clipped; gradient area, last-point emphasis |
| Brand lockup | emblem, emblem + wordmark, wordmark + tagline | default, 200% text (wordmark wraps below) | Painted emblem; no decode or asset flash |
| Week hero | dashboard card, summary card | empty week, current week, tapped | Week range, 2×2 stats, seven-day activity strip |
| Body-weight card | dashboard / progress / full screen | no check-in, check-in, same-week update, delete + Undo, 200% text | Latest reading, change chip, 12-week trend; one check-in per week updated in place |
| Weekly summary | current week + previous weeks | no training, weight change present/absent, muscle split empty | Session list, muscle bars, weight trend; total time and volume |
| Muscle split | bars by group | empty, one to many groups, unassigned | Numeric set count on every row; color is a grouping aid only |
| RIR explainer | bottom sheet | unselected/selected RIR, 200% text | Plain-language definition, 0–5+ scale, tip; one-line selected-value description in the row |
| Live workout bar | active session, rest running, rest complete | hidden, running, finished, restored after process death | Sticky above every tab; names the current exercise, set progress, rest countdown, and next set. In-app only (release builds declare no notification permission) |
| Week rail | dashboard | empty, one trained day, several, today, future | Bar height encodes working sets; every day has a text label |
| Weekly goal | dashboard block, settings row, sheet | no goal, one target, both, met, missed, streak | Sessions + working sets; each target has its own enable switch; never color alone; schema v4 |
| Post-workout summary | full screen | records, no records, previous session absent, reduced motion, 200% text | Finish cat and speech bubble, volume hero, grouped records, split, exercise breakdown, one way home |
| Plate calculator | bottom sheet | exact, remainder, below bar, no warm-up steps | Standard 20 kg/45 lb bar; mirrored plate stack and warm-up ramp |

Required journey states: loading, empty, error/retry, success, permission/offline where relevant. There are no network spinners in normal use because the app is offline.

## Motion, feedback, voice

- Transitions around 150–200 ms; purposeful, never blocking logging.
- The active-session elapsed time ticks once per second in a scoped label; that tick rebuilds only the clock, never the hero, stats, or set rows. The rest timer is the other live countdown; its bar is sticky, cancellable, and restores after process death.
- The saved row confirms inline next to its set number; the check action commits immediately and the row keeps its values.
- **Reduced motion:** when the platform requests reduced motion, apply state changes immediately, keep the PR highlight static, and show the post-workout cat without its entrance motion; never make an animation a prerequisite for feedback.
- A subtle highlight for a new PR; no confetti spam.
- Tapping check gives immediate visible confirmation; saved state is not a toast that disappears before it is read.
- Rest timer is in-app and never blocks logging; vibration on completion when enabled.
- Voice: short, plain sentences; calm; no hype; no "AI"; no guaranteed-results claims; no exclamation marks in core UI. The cat mascot is the single playful exception: "تمرین تموم شد!" and its meow.
- Errors explain what happened and what to do next in both languages. Empty states explain what is needed, not just "no data".

## Quality budgets

- **Accessibility:** WCAG 2.2 AA; text contrast ≥ 4.5:1, non-text controls ≥ 3:1, 48 dp targets, 200% text support, meaning never by color alone.
- **Keyboard and focus:** visible focus using the accent token (7.10:1 on canvas; ≥ 3:1 non-text indicator), logical focus order, and full operation without color; hardware-keyboard and accessibility focus are supported.
- **Performance:** cold start ≤ 1.5 s, tap-to-confirmation ≤ 100 ms, prefill query ≤ 50 ms with 10,000 sets, chart first paint ≤ 200 ms for 1,000 points, history scroll without visible jank, export responsive with 10,000 sets, and weekly overview derivation ≤ 100 ms (`CI-STATS-001`). All device measurements are `UNPROVEN` until the reference device is selected.
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

The 2026-10-26 owner pass adds the dashboard, body-weight trend, weekly summary, RIR explainer, and the refreshed palette; their goldens are `workout_start_*`, `weekly_summary_*`, and `body_weight_*` in both directions. The night-session pass of the same date restyles every route with the navy/electric-blue palette, rounded panels, the weekly ring, and the post-workout cat; the updated fa/en goldens are the visual proof, including `session_summary_*`, `workout_active_*`, `workout_pr_*`, and `workout_rest_*` for the live in-app rest countdown.

M9 adds the About screen and the Settings backup-policy row. About follows the same dark, low-chrome list treatment: version, app license, open-source licenses, source and donation links that open externally, a privacy statement, and a medical-advice notice. The backup row is an enforced-off switch-style status, not an operational toggle: Android Auto Backup is a manifest/build-time decision and `DAT-007`/A18 require it disabled, so the row states the effective policy and points to export/import for migration.

| Flow / screen | Critical states | Viewports/locales | Visual proof |
|---|---|---|---|
| Workout dashboard / active session | no data, planned days, weekly stats, prefilled rows, changed set, PR, live bar, rest running/completed, finish | phone; fa RTL + en LTR | goldens (including `workout_rest_*`) + tap-count, restore, and rebuild-scope tests |
| Exercise picker/creator | empty, search hit/miss, duplicate warning, archived hidden, lookup failure | phone; fa + en | goldens + widget test |
| Exercise detail | no data, chart, PRs, photo, lookup | phone; fa + en | goldens + widget test |
| Programs, days, plan items | empty, validation errors, reorder, delete confirmation | phone; fa + en | goldens + persistence test |
| History and session detail | empty, marked calendar, notes, photos, edit/undo | phone; fa + en | goldens + widget test |
| Progress overview and chart | empty, 1,000 points, missing RIR gaps, range filter | phone; fa + en | goldens + data-preparation test |
| Settings | language, digits, units, default increment, rest timer, backup policy, export/import, About entry | phone; fa + en | goldens + widget test |
| About | version, license, source/donate links, privacy, medical notice, license page | phone; fa + en | goldens + mocked-launcher widget test |
| Dashboard / workout start | no data, planned days, this-week stats, weight CTA | phone; fa + en | goldens + widget test |
| Body weight | empty, check-ins, weekly trend, same-week update, delete + Undo, 200% text | phone; fa + en | goldens + widget test |
| Weekly summary | no training, weight change, muscle split, previous weeks | phone; fa + en | goldens + widget test |
| Photo viewer | one to three photos, missing file, removal | phone; fa + en | goldens + directory test |
| Safe Mode | failed migration, newer database, cannot open | phone; fa + en | goldens + write-spy test |

## Owner-requested extensions

These extend the M9 product without editing a spec requirement row. They are
accepted product requirements for this working tree (owner request,
2026-10-26):

- **BODY-001 body-weight check-ins.** 20–500 kg, canonical grams, UTC time.
  One reading per week is updated in place; older weeks keep their own reading.
  Stored in the document schema (introduced in v3; current v4) and included in JSON backups when present.
- **BODY-002 weight trend.** Twelve-week weekly chart with gaps, latest reading,
  and change versus the previous check-in. The chart starts at the first
  check-in, not at an empty 12-week margin.
- **WEEK-001 weekly summary.** Current week plus recent weeks: sessions, volume,
  working sets, total time, weight change, and working sets by muscle group.
- **UI-004 dashboard and short explainers.** The Workout tab is a pre-session
  dashboard; set rows show the exercise's set/volume/time meta; RIR has an
  in-place "what is this?" sheet; the rest timer banner is sticky.
- **SUMMARY-001 post-workout summary.** Finishing a session opens a summary of volume, duration, working sets, exercise count, grouped new records, muscle split, per-exercise breakdown, and comparison with the previous session. The only new route is client-side; no session data is duplicated.
- **GOAL-001 weekly goals.** Optional session and working-set targets stored in settings (document schema v4), with current-week progress, a calm streak, a dashboard block, and one shared editor sheet used by the dashboard and Settings.
- **PLATE-001 plate calculator and warm-up ramp.** Standard 20 kg/45 lb bars, per-side plate stacks, exact/remainder status, and a bar-first 40/60/80% ramp. Pure domain math in `lift_core`; the sheet is launched per exercise.
- **UI-005 night-session visual language.** Rounded navy panels, a soft blue backdrop glow, electric-blue actions, a weekly progress ring, tabular display numerals, a custom week rail, and the post-workout seal on the dashboard, active workout, summary, Programs, Exercise library, History, Progress, and Settings. The superseded ledger surface (cut corners, ruled paper, sharp controls) is removed. Every changed screen keeps fa/en goldens and 200% text coverage.
- **UI-006 post-workout cat.** The session summary opens with a painted cat mascot that says `تمرین تموم شد!` / “Workout done!” and a one-line meow hint, with one entrance animation that respects reduced motion. It is decorative copy, not a new route or stored data.
- **L10N-011 Persian voice and terminology.** Workout/session is `تمرین`/`جلسه`, exercise is `حرکت`, logging is `ثبت`, and the RIR explainer is plain-language rather than literal. Persian copy uses a direct, calm voice; the native-speaker review sheet is regenerated from the ARB.
- **PERF-007 one-pass weekly aggregation.** The overview is computed once per
  document revision/calendar day, bucketing skips sessions before the window,
  and `CI-STATS-001` guards a 1.5 ms median (down from 8.4 ms on the first run).

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
| 2026-10-26 | Refreshed palette: near-black navy canvas, four surface levels, electric-blue accent, gold highlight, cyan info, lavender body-weight series | Measured WCAG pairs in the table above; contrast test extended to every text role; outline stays decorative-only | A pair fails or a new role is added without measurement |
| 2026-10-26 | Brand emblem: painted electric-blue progress ring + barbell + gold marker; launcher icon derived from the same geometry | Owner request; no image decode in the dashboard; goldens render the mark deterministically | Owner chooses a different mark or the launcher crop changes |
| 2026-10-26 | Body-weight check-ins are a separate entity (introduced in schema v3; current v4), one reading per week updated in place | `BODY-001`; weekly trend and change detection; migration/backup/merge tests; older documents read with an empty list | Owner wants arbitrary daily weight entries or a dedicated weight program |
| 2026-10-26 | Weekly overview and body-weight trend are derived, never stored | `WEEK-001`, `BODY-002`; one-pass aggregation with `CI-STATS-001`; no second source of truth | A stored aggregate becomes necessary for a measured performance reason |
| 2026-10-26 | Elapsed session time updates once per second in a scoped label only; the rest timer's sticky live bar is the other countdown | Owner reported the clock did not move; the tick is isolated so no hero, stat strip, or set row rebuilds per second; widget test proves the clock advances without a document write | A per-second rebuild of the whole logging surface becomes necessary |
| 2026-10-26 | The live workout notification is an in-app sticky bar across all four tabs, not a system notification | Owner request; the release manifest must declare no `POST_NOTIFICATIONS` (`SET-004`, release guard, manifest test), so a system notification would require an owner decision and a permission-policy change. The bar shows the exercise, set progress, rest countdown, completion, and next set; rest completion vibrates | Owner authorizes notification permission and revises the release posture |
| 2026-10-26 | A running rest countdown is stored in `rest_timer.json` beside the document and restored only while it is still in the future | Process-death survival (`LOG-009`); ephemeral UI state stays out of the training document and export; the marker is cleared on dismiss, completion, finish, and a new session | The timer becomes part of the persisted document or gains exercise/session context |
| 2026-10-26 | Saved set rows collapse into a compact summary; unsaved rows keep the full editor | Reduces active-workout scrolling and keeps the next set in reach; edit/delete stay in the row menu; the check action and prefilled flow are unchanged; all set-row keys and 48 dp targets remain | User testing shows inline editing of a saved set is needed more than compactness |
| 2026-10-26 | Startup resolves the app support directory once, preloads the document before `runApp`, caches the theme, and defers photo recovery to after the first frame | Removes duplicate platform-channel lookups and overlaps JSON load with engine startup; the cold-start device budget (`NFR-PERF-001`) stays `UNPROVEN` until the reference-device run | The reference-device trace shows another startup bottleneck |
| 2026-10-26 | History day cells are 48 dp at 360 dp width by using an 8 dp lane and 1 dp grid gaps | 48 dp touch target at the reference viewport; goldens regenerate | A smaller/larger reference width changes the column math |
| 2026-10-26 | Training-ledger surface language (superseded the same day): cut-corner panels, ruled backdrop, 4–6 dp controls, tabular display numerals | Owner request at the time; fa/en goldens and 200% text sweep | Superseded by the night-session redesign; no screen retains cut corners |
| 2026-10-26 | Night-session redesign: navy/electric-blue palette, 20 dp rounded panels, soft backdrop glow, weekly ring, blue nav pill | Owner reference (PulseFit-style dark fitness dashboard) and request to rewrite the design; fa/en goldens regenerated and reviewed; contrast test passes | Owner changes the reference direction or a measured contrast/performance failure appears |
| 2026-10-26 | Post-workout cat mascot with the Persian line `تمرین تموم شد!` and a meow hint | Owner request; shown on the summary route that already follows finishing a session; painted, no new asset or package; reduced motion respected | Owner wants a different mascot or a stored celebration setting |
| 2026-10-26 | Weekly goals live in settings, document schema v4, with no stored aggregates | `GOAL-001`; derived from the existing one-pass `WeekStats`; migration/backup tests | Goals need per-muscle targets or a different persistence model |
| 2026-10-26 | Plate math works in display-unit centi-units and returns canonical grams | `PLATE-001`; 135 lb must be exactly 45 lb per side; domain tests | Plate inventory becomes user-configurable |
| 2026-10-26 | Finishing a session routes to the summary instead of the dashboard | `SUMMARY-001`; finish-flow test and summary goldens | The summary becomes part of session detail only |
