# Product Design Contract

Specific, short, durable. The visual and interaction source of truth shared by build, device QA, and review. `lib/app/theme/app_tokens.dart` is the canonical code token source; this document owns intent and token roles. The palette table below mirrors the code and is checked by `test/theme/contrast_test.dart`.

Status: dark-only, Persian-first RTL, and the achromatic **Obsidian Telemetry** system are owner-confirmed (`UI-001`, `SET-001`, `L10N-001`). The 2026-10-28 pass replaces the navy/electric-blue night-session language with a black, square, precision-instrument surface and a new identity. The dashboard, active workout, set rows, post-workout summary, weekly summary, Programs, Exercise library, History, Progress, Settings, About, and every sheet render the new system. The spec status still governs product acceptance. Owner decisions in ADR-0004 through ADR-0009 are marked where they apply.

## Owner direction

- **Style:** Obsidian Telemetry: machined matte zinc, optical-viewfinder framing, and strength training treated as measurable kinetic telemetry. Precision, not entertainment.
- **Colors:** achromatic only. Black canvas, zinc surface levels, hairline structure, white as the single strike-point, and neutral gray readouts. There is no second accent, no hue-coded state, no gradient, glow, blur, or drop shadow in the UI chrome.
- **Theme:** dark by default; first launch is dark regardless of the system theme. There is no light UI theme. A light logo lockup exists only for external light backgrounds.
- **Typography:** Vazirmatn for Persian and Latin, Regular / Medium / Bold only. The reference fonts (Geist and JetBrains Mono) were evaluated but not shipped: they do not cover Persian, and glyph-level fallback would split the interface. Their roles are reproduced with tabular figures, tight display tracking, and wide tracking on Latin micro-labels. See [Typography](#typography).
- **Density and shape:** 8 dp spacing grid, `0 dp` corner radius everywhere, 1 px hairlines, 48 dp minimum touch targets, and square controls. Panels are separated by structure, never by elevation effects.
- **Motion:** 150–200 ms, purposeful, and skipped or reduced when the platform asks for reduced motion. The active clock and rest timer are the only continuous updates.
- **Surface language:** an instrument panel, not a component gallery. A square session counter, hairline telemetry panels, a sparse week rail, a stamped finish seal, and white hairline data traces.
- **Locales:** Persian primary, RTL; English, LTR. Every user-facing string exists in both.
- **Must keep:** calm, precise, quietly confident tone; clear numbers; one-tap confirmation; full RTL mirroring; one-handed logging.
- **Must avoid:** neon, color-coded semantics, gradients, glows, shadows, rounded panels, pill chips, stock bodybuilder imagery, gamification clutter, hype, exclamation marks in core UI, "AI" claims, and color as the only signal. The line-art finish cat is the single deliberate levity exception.
- **Agent-proposed details:** exact type scale, icon set, hairline placement, and chart styling are implementation details; they must not contradict this contract.
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
- A well-kept training instrument, not a social feed.

## Brand mark

- **Concept:** **The Aperture.** A square machined frame holds a barbell; a calibration index in the top-left corner turns the frame into an optical instrument. It says "training, measured" without stock gym imagery, a progress circle, or text inside the mark.
- **Source of truth:** `assets/branding/logo-mark-2048.png` (transparent) and `logo_mark.png` (app icon). The in-app lockup is painted by `BrandEmblem` in `lib/app/theme/brand_mark.dart`, so it stays crisp at every text scale, costs no image decode, and cannot flash blank in goldens. The launcher mipmaps are derived from `app-icon-full-bleed-1024.png`.
- **Rules:** keep ≥ 15% clear space around the emblem; the mark is square and is never placed inside a rounded tile or circle; use white-on-dark or black-on-light only; never set the wordmark inside the mark; do not add a second accent. Use the transparent horizontal lockup at ≥ 220 px wide, and the `on-light` variant on light backgrounds.
- **Kit:** `logo-mark-2048.png`, `logo-horizontal.png`, `logo-horizontal-on-light.png`, `logo-horizontal-panel.png`, `logo-stacked.png`, `brand-sheet-1600x1200.png`, `website-hero-2400x1000.png`, `social-card-1200x630.png`, and `favicon-*`; regenerate with `python3 tool/branding/render_branding.py`. The full list and palette are in [`assets/branding/README.md`](../assets/branding/README.md).

## Direction

- **Visual thesis:** a black instrument face read under gym lighting. Zinc plates, 1 px structural rules, and white telemetry; chrome recedes.
- **Signature elements:** the square set row with one unmistakable white check action; the square week gauge with a linear meter; the dash-grid progress trace with a crosshair cursor; the stamped finish seal; the aperture mark.
- **What must feel familiar:** standard Android navigation and system pickers; no novel gesture required to log a set.
- **What must never look generic:** the set row, the week gauge, the stamped seal, the monochrome cat engraving, the sparse week rail, and the aperture mark. The app must not read as a reskinned Material template.

## Semantic tokens

A standalone handoff copy, including CSS variables and a Persian summary, is in [PALETTE.md](PALETTE.md).

The exact values are in `AppTokens`. Measured on 2026-10-28 with the WCAG 2.x relative-luminance formula. Text pairs target 4.5:1; non-text control boundaries target 3:1. Panel hairlines are decorative and deliberately lower.

| Role / state | Exact value | Pairs and measured contrast |
|---|---|---|
| canvas / background | `#09090B` | `textPrimary` 19.90:1 · `textSecondary` 7.76:1 · `textMuted` 6.27:1 |
| surface (cards, sheets, app bar) | `#121214` | `textPrimary` 18.71:1 · `textSecondary` 7.30:1 · `textMuted` 5.89:1 |
| surface 2 (raised controls, inputs) | `#18181B` | `textPrimary` 17.72:1 · `textSecondary` 6.91:1 · `textMuted` 5.58:1 |
| surface 3 (pressed/selected recess) | `#201F22` | `textPrimary` 16.40:1 · `textSecondary` 6.40:1 · `textMuted` 5.17:1 |
| surface 4 (utility fill) | `#2A2A2C` | `textPrimary` 14.32:1 · `textSecondary` 5.59:1 · `textMuted` 4.51:1 |
| decorative panel hairline | `#27272A` | 1.34:1 on canvas; never a control boundary or sole state signal |
| interactive control boundary | `#71717A` | 4.12:1 on canvas · 3.87:1 on surface · 3.67:1 on surface 2 · 3.39:1 on surface 3; not used on surface 4 (2.96:1) |
| primary text / numbers | `#FFFFFF` | 19.90:1 on canvas |
| secondary text | `#A1A1AA` | 7.76:1 on canvas |
| muted microcopy | `#8E9192` | 6.27:1 on canvas; `#71717A` is not used for small text because it measures 4.12:1 |
| action / on-action | `#FFFFFF` / `#09090B` | 19.90:1 |
| PR / destructive | `#FFFFFF` | 19.90:1 on canvas; always paired with the `PR` label, an icon, a 2 px stroke, or a text message |
| info / body-weight readout | `#A1A1AA` | 7.76:1 on canvas; series are distinguished by labels and dash patterns, not hue |

Hard rules:

- **Text contrast ≥ 4.5:1.** Re-measure any new pair before use. `textMuted` is the only gray small-text role; `#71717A` is a control boundary, not text.
- **Non-text controls ≥ 3:1.** Panel hairlines are decorative and must not be the only outline of an input, button, toggle, or selected state. Focus and active states use a 1–2 px white stroke.
- **Never color alone.** RIR chips always show their number; PR uses a filled white badge with a `PR` label and glyph; errors use text plus a 2 px stroke and icon; chart series carry labels and dash patterns.
- **No hue in chrome.** Do not add a red, green, blue, gold, or purple token for a new state. New states are expressed by luminance, inversion, stroke weight, icon, or label.
- **Touch targets ≥ 48 dp**, including steppers, RIR cells, square switches, and calendar cells.
- **One source of truth.** Update `AppTokens`, this table, and `test/theme/contrast_test.dart` together. Never maintain a competing palette.

## Typography

- Family: **Vazirmatn** for both Persian and Latin text. License: SIL Open Font License 1.1 (verify at pin time).
- Weights: **Regular 400, Medium 500, Bold 700** only. The theme uses no synthetic 600 weight. If 600 is ever needed, ship the real weight and record its size.
- The reference system's Geist/JetBrains Mono roles are retained as behavior: tight negative tracking on display numerals, tabular figures (`tnum` + `zero`) on every changing number, and wide tracking (`≈ 0.12 em`) on Latin micro-labels only. Persian letter spacing stays at 0.
- Roles: display/headline numbers (36/30/24/21 sp) for hero metrics; 16 sp body; 14 sp secondary; 10–11 sp micro-labels. Display sizes are tabular so the layout does not shimmer when numbers change.
- Exact sizes and leading belong to the code token source. Persian copy must be written or reviewed by a native speaker (`L10N-010`).
- Both Persian and Latin digits appear; the digit setting changes display without changing stored data. Do not force a Latin-only monospace font on Persian digits.

## Geometry and layout

- **Square hardlines:** every button, panel, input, chip, sheet, dialog, card, nav indicator, checkbox, and toggle uses `0 dp` corners. `radiusSmall = radiusMedium = radiusLarge = radiusPill = 0`.
- **Hairline physics:** all panels and partitions use a uniform 1 px `#27272A` stroke. Focus and active states switch to a crisp white 1–2 px stroke with no glow or blur.
- **Structure over elevation:** no shadows, no gradients, no backdrop blur, no ambient color. A surface is raised by stepping from `#09090B` to `#121214` / `#18181B` and by its border.
- **Spacing:** 8 dp rhythm with 4 dp halves; page padding 16 dp below 360 dp width and 24 dp otherwise. Section transitions use 24–40 dp; related readouts sit 4–8 dp apart.
- **Reticle accents:** short 1 px corner ticks or a 3 × 16 dp white index bar may mark section starts and high-priority viewports. They are structure, not decoration, and never replace a label.
- 48 dp minimum touch target; set rows sized for one-handed use. Calendar day cells are 48 × 48 at 360 dp width.
- RTL uses direction-aware spacing and alignment everywhere; do not hard-code left/right. Phones only; no tablet layout in this phase.

## Composition and responsiveness

- **Mobile composition:** one primary task per screen. The Workout tab is the logging surface; nothing competes with it.
- **Dense content:** set rows stay legible at large text; history and charts use lazy lists; no horizontal scrolling for primary actions.
- **Supported baseline:** Android API 24+ phones (Assumption: current Flutter floor); reference device TBD. Verify on a modest device, including the older-Android rendering path.
- **RTL/localization:** every screen has LTR and RTL goldens. Layout mirrors, but **chart time runs left to right in both directions** (ADR-0005). Persian labels must not clip.
- **Digits and calendar:** Persian/Latin digits are a display setting applied through one inherited scope, including chart labels; inputs accept both styles. Persian screens show Jalali dates with Persian month names; English screens keep Gregorian. Persian weeks start on Saturday (`L10N-004`–`L10N-006`).
- **Large text:** usable at 200% text scale; set rows remain operable; controls do not overlap; the square week gauge collapses its value/label block via `FittedBox` rather than overflowing.
- **Charts:** time always runs left to right, including RTL. A 1.5 px white trace, dashed `#27272A` coordinate rules at three levels, no area fill, square point markers under 60 points, and a white crosshair + diamond cursor at the last value. Missing values are gaps, not zeros.

## Components and states

| Component / pattern | Variants | Required states | Reuse or change |
|---|---|---|---|
| Set row | prefilled, edited, warm-up, bodyweight | default, focused/typing, invalid input, saved | One component; the core interaction. Saved rows flatten to surface 2 with a white hairline; the check action is a white 48 dp square with a black check |
| Weight/reps steppers | kg, lb, per-exercise increment | default, pressed, disabled at bound | Square number deck, white bottom rule on error |
| RIR chips | 0–5+ | unselected, selected, empty/null | 2 × 3 square cells; selected inverts to white with black text; always shows the number |
| Check action | one per row | idle, saving, saved confirmation | White filled square; commits immediately; spinner uses on-accent black |
| PR badge | weight/reps/e1RM | hidden, visible; never on first set or warm-up | White filled square with black `PR` label + trophy glyph; no gold |
| Suggestion line | prefill, progression, hold | with reason; no suggestion | Flat surface 2 strip with a 3 px white start rule; reason in one sentence |
| Empty state | no exercises, no history, no data for chart | clear prompt + one action | Text-only, no bundled imagery |
| Export reminder | 30 days without export | hidden, visible, dismissed, snoozed | In-app square banner; only with data |
| Safe Mode | migration failed, database newer, cannot open | plain-language explanation, raw-DB export, diagnostics | Never writes to the database |
| Photo viewer | session photos, exercise photo | loading, empty, limit reached, missing file, delete confirmation | Max 3 session photos; square chrome; user photo content may be any color |
| History calendar | trained day marked | marked, unmarked, selected | 48 dp square cells; marking uses a white border + check glyph, never color alone |
| Chart | best weight, e1RM, reps/RIR, volume | loading, empty, gaps for missing RIR, range filter | White hairline trace, dashed grid, no fill; time axis LTR; labels not clipped |
| Brand lockup | emblem, emblem + wordmark, wordmark + tagline | default, 200% text (wordmark wraps below) | Painted aperture; no decode or asset flash; uppercase tracked wordmark |
| Week gauge | dashboard | empty week, current week, tapped | 108 dp square plate: index mark, tabular session count, linear meter; no ring |
| Week rail | dashboard | empty, one trained day, several, today, future | 12 dp square bars; height encodes working sets; each day has a text label; today gets a white stroke |
| Weekly goal | dashboard block, settings row, sheet | no goal, one target, both, met, missed, streak | Sessions + working sets; each target has a square enable toggle; never color alone; schema v4 |
| Square toggle | rest timer, weekly goals, backup status | off, on, disabled | 44 × 24 track with an 18 dp square thumb; 48 dp target; semantics `toggled`; no Material pill |
| Post-workout summary | full screen | records, no records, previous session absent, reduced motion, 200% text | Square stamped check seal, volume hero, grouped records, split, breakdown, one way home |
| Finish cat | summary intro | default, reduced motion, 200% text | Monochrome engraved line cat with a square speech plate; the single levity exception; no color |
| Plate calculator | bottom sheet | exact, remainder, below bar, no warm-up steps | Standard 20 kg/45 lb bar; square plate glyphs and labels; warm-up ramp |
| Body-weight card | dashboard / progress / full screen | no check-in, check-in, same-week update, delete + Undo, 200% text | Latest reading, change chip with arrow glyph, white trend trace; one check-in per week updated in place |
| Weekly summary | current week + previous weeks | no training, weight change present/absent, muscle split empty | Session list, square muscle bars, weight trend; total time and volume |
| Muscle split | bars by group | empty, one to many groups, unassigned | Numeric set count on every row; the bar is a magnitude readout only |
| RIR explainer | bottom sheet | unselected/selected RIR, 200% text | Plain-language definition, 0–5+ scale, tip; one-line selected-value description |
| Live workout bar | active session, rest running, rest complete | hidden, running, finished, restored after process death | Sticky above every tab; square 8 dp status mark; names the exercise, set progress, rest countdown, and next set. In-app only (release builds declare no notification permission) |

Required journey states: loading, empty, error/retry, success, permission/offline where relevant. There are no network spinners in normal use because the app is offline.

## Motion, feedback, voice

- Transitions around 150–200 ms; purposeful, never blocking logging. No springy overshoot; state changes should read as mechanical switches, not bounces.
- The active-session elapsed time ticks once per second in a scoped label; that tick rebuilds only the clock, never the hero, stats, or set rows. The rest timer is the other live countdown; its bar is sticky, cancellable, and restores after process death.
- The saved row confirms inline next to its set number; the check action commits immediately and the row keeps its values.
- **Reduced motion:** when the platform requests reduced motion, apply state changes immediately, keep the PR badge static, and show the finish seal/cat without entrance motion; never make an animation a prerequisite for feedback.
- A white stamp or a filled badge for a new PR; no confetti, no gold, no glow.
- Tapping check gives immediate visible confirmation; saved state is not a toast that disappears before it is read.
- Rest timer is in-app and never blocks logging; vibration on completion when enabled.
- Voice: short, plain sentences; calm; no hype; no "AI"; no guaranteed-results claims; no exclamation marks in core UI. The line-art cat and its meow are the single playful exception.
- Errors explain what happened and what to do next in both languages. Empty states explain what is needed, not just "no data".

## Quality budgets

- **Accessibility:** WCAG 2.2 AA; text contrast ≥ 4.5:1, non-text controls ≥ 3:1, 48 dp targets, 200% text support, meaning never by color alone.
- **Keyboard and focus:** visible focus using a 2 px white stroke, logical focus order, and full operation without color; hardware-keyboard and accessibility focus are supported.
- **Performance:** cold start ≤ 1.5 s, tap-to-confirmation ≤ 100 ms, prefill query ≤ 50 ms with 10,000 sets, chart first paint ≤ 200 ms for 1,000 points, history scroll without visible jank, export responsive with 10,000 sets, and weekly overview derivation ≤ 100 ms (`CI-STATS-001`). All device measurements are `UNPROVEN` until the reference device is selected.
- **Device:** profile mode on a physical device, never debug or an emulator; test the older-Android rendering path.
- **Visual proof:** LTR and RTL goldens for every screen, plus large-text and demanding-data states. Until implemented, screen acceptance is `UNPROVEN`.

## Screen acceptance

The four-tab shell, exercise library, programs/days/plan items, active workout, history/session detail, progress, body weight, weekly summary, settings, About, photos, plate calculator, weekly goals, and the post-workout summary are implemented. The 2026-10-28 Obsidian pass regenerates the fa/en goldens for every route; `test/golden_coverage_test.dart` enforces that no screen loses either direction. The 200% text sweep passes as widget tests; keyboard focus uses the shared Material focus handling and is not separately swept in this pass. Device performance, real-device large-font/contrast, and screen acceptance on a physical phone remain `UNPROVEN`.

| Flow / screen | Critical states | Viewports/locales | Visual proof |
|---|---|---|---|
| Workout dashboard / active session | no data, planned days, weekly stats, prefilled rows, changed set, PR, live bar, rest running/completed, finish | phone; fa RTL + en LTR | goldens (including `workout_rest_*`) + tap-count, restore, and rebuild-scope tests |
| Exercise picker/creator | empty, search hit/miss, duplicate warning, archived hidden, lookup failure | phone; fa + en | goldens + widget test |
| Exercise detail | no data, chart, PRs, photo, lookup | phone; fa + en | goldens + widget test |
| Programs, days, plan items | empty, validation errors, reorder, delete confirmation | phone; fa + en | goldens + persistence test |
| History and session detail | empty, marked calendar, notes, photos, edit/undo | phone; fa + en | goldens + widget test |
| Progress overview and chart | empty, 1,000 points, missing RIR gaps, range filter | phone; fa + en | goldens + data-preparation test |
| Settings | language, digits, units, default increment, rest timer, square toggle, backup policy, export/import, About entry | phone; fa + en | goldens + widget test |
| About | brand lockup, version, license, source/donate links, privacy, medical notice, license page | phone; fa + en | goldens + mocked-launcher widget test |
| Dashboard / workout start | no data, planned days, this-week stats, weight CTA, square week gauge | phone; fa + en | goldens + widget test |
| Body weight | empty, check-ins, weekly trend, same-week update, delete + Undo, 200% text | phone; fa + en | goldens + widget test |
| Weekly summary | no training, weight change, muscle split, previous weeks | phone; fa + en | goldens + widget test |
| Photo viewer | one to three photos, missing file, removal | phone; fa + en | goldens + directory test |
| Safe Mode | failed migration, newer database, cannot open | phone; fa + en | goldens + write-spy test |

## Owner-requested extensions

These extend the M9 product without editing a spec requirement row. They are accepted product requirements for this working tree (owner request, 2026-10-26):

- **BODY-001 body-weight check-ins.** 20–500 kg, canonical grams, UTC time. One reading per week is updated in place; older weeks keep their own reading. Stored in the document schema (v3; current v4) and included in JSON backups when present.
- **BODY-002 weight trend.** Twelve-week weekly chart with gaps, latest reading, and change versus the previous check-in. The chart starts at the first check-in, not at an empty 12-week margin.
- **WEEK-001 weekly summary.** Current week plus recent weeks: sessions, volume, working sets, total time, weight change, and working sets by muscle group.
- **UI-004 dashboard and short explainers.** The Workout tab is a pre-session dashboard; set rows show the exercise's set/volume/time meta; RIR has an in-place "what is this?" sheet; the rest timer banner is sticky.
- **SUMMARY-001 post-workout summary.** Finishing a session opens a summary of volume, duration, working sets, exercise count, grouped new records, muscle split, per-exercise breakdown, and comparison with the previous session. The only new route is client-side; no session data is duplicated.
- **GOAL-001 weekly goals.** Optional session and working-set targets stored in settings (document schema v4), with current-week progress, a calm streak, a dashboard block, and one shared editor sheet used by the dashboard and Settings.
- **PLATE-001 plate calculator and warm-up ramp.** Standard 20 kg/45 lb bars, per-side plate stacks, exact/remainder status, and a bar-first 40/60/80% ramp. Pure domain math in `lift_core`; the sheet is launched per exercise.
- **UI-005 Obsidian Telemetry visual language.** Achromatic black/zinc surfaces, square hardlines, 1 px hairlines, white strike-point actions, the square week gauge, tabular display numerals, a hairline chart language, the stamped finish seal, and the engraved cat across the dashboard, active workout, summary, Programs, Exercise library, History, Progress, Settings, and About. The superseded navy/electric-blue night-session language is removed. Every changed screen keeps fa/en goldens and 200% text coverage.
- **UI-006 post-workout cat.** The session summary opens with a monochrome engraved cat that says `تمرین تموم شد!` / “Workout done!” and a one-line meow hint, with one entrance animation that respects reduced motion. It is the single playful exception in an otherwise technical system; no color is used.
- **L10N-011 Persian voice and terminology.** Workout/session is `تمرین`/`جلسه`, exercise is `حرکت`, logging is `ثبت`, and the RIR explainer is plain-language rather than literal. Persian copy uses a direct, calm voice; the native-speaker review sheet is regenerated from the ARB.
- **PERF-007 one-pass weekly aggregation.** The overview is computed once per document revision/calendar day, bucketing skips sessions before the window, and `CI-STATS-001` guards a 1.5 ms median.

## Decision log

The log is append-only. Rows marked superseded describe earlier owner directions and remain for traceability.

| Date | Decision | Evidence / rationale | Revisit when |
|---|---|---|---|
| 2026-10-21 | Dark-first; first launch dark regardless of system theme | Owner-confirmed `UI-001`; spec §29.4 | Owner changes the theme decision |
| 2026-10-21 | 4.5:1 text, 3:1 non-text, 48 dp targets, never color alone | `NFR-A11Y-001`; project hard gates | An accepted accessibility target changes |
| 2026-10-21 | Chart time axis left to right, including RTL | Owner decision; ADR-0005 | User testing shows consistent misreading |
| 2026-10-21 | Vazirmatn Regular/Medium/Bold only | `L10N-003`; OFL 1.1; size target | License or tabular-figure check fails |
| 2026-10-21 | Session photos max 3; excluded from JSON export | Owner decision; ADR-0006 | Owner authorizes a ZIP archive |
| 2026-10-21 | Android backup status visible, default off | Owner decision; ADR-0007 | Owner changes the default |
| 2026-10-21 | Progress charts use a custom painter, no chart package | Measured 1,000-point/RTL spike; ADR-0008 | A required chart feature makes custom work uneconomical |
| 2026-10-23 | Persian UI shows Jalali dates; English shows Gregorian; Persian weeks start Saturday | `L10N-005`, `L10N-006`; `CalendarService` | Calendar library or locale policy changes |
| 2026-10-25 | The "Allow Android backup" row is an enforced-off status, not a runtime toggle | `DAT-007`, A18; Auto Backup is manifest/build-time; release guard fails if enabled | A verified runtime opt-in exists and the guard is deliberately revised |
| 2026-10-26 | Body-weight check-ins are a separate entity (schema v3; current v4), one reading per week updated in place | `BODY-001`; weekly trend and change detection; migration/backup/merge tests | Owner wants arbitrary daily entries |
| 2026-10-26 | Weekly overview and body-weight trend are derived, never stored | `WEEK-001`, `BODY-002`; one-pass aggregation with `CI-STATS-001` | A stored aggregate becomes necessary for a measured performance reason |
| 2026-10-26 | The live workout bar is in-app, not a system notification | No `POST_NOTIFICATIONS` in release (`SET-004`, manifest test) | Owner authorizes notification permission and revises the release posture |
| 2026-10-26 | A rest countdown is stored in `rest_timer.json` and restored only while still in the future | Process-death survival (`LOG-009`); ephemeral state stays out of the export | The timer becomes part of the document |
| 2026-10-26 | Saved set rows collapse into a compact summary; unsaved rows keep the editor | Reduces scrolling; check action and prefill are unchanged | User testing shows inline editing is needed more |
| 2026-10-26 | History day cells are 48 dp at 360 dp width by using an 8 dp lane and 1 dp gaps | 48 dp target; goldens regenerate | Reference width changes the column math |
| 2026-10-26 | Superseded: navy/electric-blue night-session palette, rounded panels, glow, weekly ring, gold PR marker | Owner reference at the time; fa/en goldens and contrast test passed | Superseded 2026-10-28 by Obsidian Telemetry |
| 2026-10-28 | **Obsidian Telemetry:** achromatic black/zinc surfaces, 0 dp corners, 1 px structure, white strike-point, no gradient/shadow/blur/hue | Owner supplied the palette and asked to rewrite the design and branding; contrast test extended with control-boundary and square-geometry checks; fa/en goldens regenerated | A new owner palette or an accessibility failure |
| 2026-10-28 | **The Aperture mark:** square frame, calibration index, barbell; white-on-dark / black-on-light; no rounded tile | Owner asked for a logo/branding rewrite based on the palette; painted in `BrandEmblem` and rendered from the same geometry into the kit | Owner chooses a different mark or the launcher crop changes |
| 2026-10-28 | **Square toggle** replaces Material `Switch`; backup uses the disabled state | Material's pill switch cannot meet `roundedness: 0`; semantics, 48 dp target, and enforced-off behavior preserved; About test asserts the square control | A future Material API supports square shapes natively |
| 2026-10-28 | **Typography substitution:** Vazirmatn with tabular figures and tracked Latin micro-labels instead of Geist/JetBrains Mono | Persian coverage, single-family fallback, offline bundle, and no mixed-script metrics; the reference roles are preserved behaviorally | A licensed Persian+Latin mono family is selected and measured |
| 2026-10-28 | **Chart language:** white hairline, no fill, dashed grid, square point markers, crosshair+diamond cursor | Follows the reference telemetry spec; chart API drops the per-series color so hue cannot return | A multi-series chart needs a non-color distinguisher |
| 2026-10-28 | **Finish cat:** retained as a monochrome engraving with a square speech plate | User-facing personality retained without color; reduced motion respected; the single levity exception is documented | Owner wants a different mascot or a fully technical seal only |
