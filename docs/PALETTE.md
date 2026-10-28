# Gym Log Color Palette

_[نسخهٔ فارسی در پایان همین فایل](#پالت-فارسی)_

Single-page handoff reference for **Obsidian Telemetry**, the app's achromatic
instrument palette. The app is dark-only; there is no light UI theme. The
canonical values live in
[`lib/app/theme/app_tokens.dart`](../lib/app/theme/app_tokens.dart), and the
measured pairs are guarded by
[`test/theme/contrast_test.dart`](../test/theme/contrast_test.dart). This file
mirrors that source so a designer, a store listing, or a new screen can use the
same values without opening Dart.

Style in one line: **black instrument face, machined zinc surfaces, 1 px
structure, and pure white as the only strike-point.**

## Core surfaces

| Token | Hex | RGB | Role | White text | Secondary text | Muted text |
|---|---|---|---:|---:|---:|---:|
| `background` | `#09090B` | `9, 9, 11` | App canvas, page background | 19.90:1 | 7.76:1 | 6.27:1 |
| `surface` | `#121214` | `18, 18, 20` | Cards, sheets, app bar, navigation | 18.71:1 | 7.30:1 | 5.89:1 |
| `surface2` | `#18181B` | `24, 24, 27` | Inputs, raised controls, saved rows | 17.72:1 | 6.91:1 | 5.58:1 |
| `surface3` | `#201F22` | `32, 31, 34` | Pressed/selected recess, tracks | 16.40:1 | 6.40:1 | 5.17:1 |
| `surface4` | `#2A2A2C` | `42, 42, 44` | Utility fill, snackbar | 14.32:1 | 5.59:1 | 4.51:1 |
| `outline` | `#27272A` | `39, 39, 42` | Decorative panel/dividing hairline — **not a control boundary** | — | — | — |

`outline` is never a button border, input boundary, focus ring, or the only
state signal. It measures 1.34:1 on the canvas.

## Text, actions, and controls

| Token | Hex | RGB | Role | Contrast |
|---|---|---|---:|---:|
| `textPrimary` | `#FFFFFF` | `255, 255, 255` | Primary text, hero metrics, white strike-point | 19.90:1 on canvas |
| `textSecondary` | `#A1A1AA` | `161, 161, 170` | Supporting copy, labels, secondary metrics | 7.76:1 on canvas |
| `textMuted` | `#8E9192` | `142, 145, 146` | Micro-labels, passive indices, units | 6.27:1 on canvas; 4.51:1 on `surface4` |
| `outlineStrong` | `#71717A` | `113, 113, 122` | Interactive control boundary; **not text** | 4.12:1 on canvas, 3.87:1 on surface, 3.67:1 on surface2, 3.39:1 on surface3; 2.96:1 on surface4 (do not use there) |
| `accent` | `#FFFFFF` | `255, 255, 255` | The single action, focus, and selected state | 19.90:1 on canvas |
| `onAccent` | `#09090B` | `9, 9, 11` | Text/icon on a white fill | 19.90:1 |

There is exactly **one** action signal: pure white. A screen may have one
white-filled primary action; secondary actions are outline buttons with a
`#71717A` boundary.

## Semantic aliases

The implementation keeps semantic names so product code reads clearly, but
every alias resolves to the same achromatic scale. Meaning must be carried by
text, icons, stroke weight, or inversion.

| Token | Hex | Role |
|---|---|---|
| `highlight` | `#FFFFFF` | Personal records; rendered as a white filled badge with a `PR` label and trophy glyph |
| `danger` | `#FFFFFF` | Errors and destructive actions; rendered with a 2 px white stroke, an icon, and a text message. No red |
| `onDanger` | `#09090B` | Text on a white destructive fill |
| `info` | `#A1A1AA` | Passive hints; no hue |
| `onInfo` | `#09090B` | Text on an info fill |
| `weight` | `#A1A1AA` | Body-weight readout; differentiated by label and dash pattern |
| `accentDeep` | `#A1A1AA` | Legacy alias for decorative borders/readouts; gradients are no longer used |

## Geometry, spacing, motion

| Token | Value |
|---|---|
| Space scale | 4, 8, 16, 24, 32, 40, 48 dp |
| Card / control / pill radius | **0 dp** |
| Panel and divider hairline | 1 px `#27272A` |
| Focus / active stroke | 1–2 px `#FFFFFF` |
| Minimum touch target | 48 dp |
| Minimum clear space around the mark | 15% of the mark width |
| Fast / normal / slow motion | 150 / 200 / 300 ms |
| Page padding | 16 dp below 360 dp width; 24 dp otherwise |

Panels are separated by fill steps and hairlines, not shadows, blur, or
gradients. Status chips, nav indicators, toggles, and every other control are
squares. Respect reduced motion: state changes apply immediately.

## Ready-to-paste CSS

```css
:root {
  /* surfaces */
  --gl-background: #09090b;
  --gl-surface: #121214;
  --gl-surface-2: #18181b;
  --gl-surface-3: #201f22;
  --gl-surface-4: #2a2a2c;
  --gl-hairline: #27272a;
  --gl-control-outline: #71717a;

  /* text */
  --gl-text-primary: #ffffff;
  --gl-text-secondary: #a1a1aa;
  --gl-text-muted: #8e9192;

  /* action and aliases */
  --gl-accent: #ffffff;
  --gl-on-accent: #09090b;
  --gl-highlight: #ffffff;
  --gl-danger: #ffffff;
  --gl-info: #a1a1aa;
  --gl-weight: #a1a1aa;

  /* structure */
  --gl-radius: 0px;
  --gl-hairline-width: 1px;
}
```

## Do / do not

- **Do** keep the canvas black and let the numbers and structure lead.
- **Do** use `#FFFFFF` for the one primary action, focus, and selected state.
- **Do** use `outlineStrong` for interactive control boundaries and `outline`
  only for panel structure.
- **Do** check any new text pair at **≥ 4.5:1** and any new control boundary at
  **≥ 3:1** before shipping.
- **Do** keep touch targets at **≥ 48 dp** and preserve meaning without color.
- **Do not** add red/green/blue/gold/purple state colors, a second action hue,
  gradients, glows, shadows, or rounded panels.
- **Do not** use `#71717A` for small text.
- **Do not** use `outline` as a button border or focus ring.
- **Do not** use color as the only difference between two states.

## پالت فارسی

پالت تک‌صفحه‌ای اپ برای تحویل به طراح یا ساخت صفحهٔ تازه. اپ فقط حالت تیره
دارد و مرجع نهایی کد در `lib/app/theme/app_tokens.dart` است؛ نسبت‌های کنتراست
با `test/theme/contrast_test.dart` بررسی می‌شوند.

| نقش | کد رنگ | کاربرد |
|---|---|---|
| پس‌زمینه | `#09090B` | بوم اصلی صفحه |
| سطح ۱ | `#121214` | کارت، شیت، نوار بالا و پایین |
| سطح ۲ | `#18181B` | ورودی، کنترل برجسته، ست ثبت‌شده |
| سطح ۳ | `#201F22` | حالت فشرده/انتخاب‌شده، ریل پیشرفت |
| سطح ۴ | `#2A2A2C` | پرکنندهٔ سودمند، اسنک‌بار |
| خط تزئینی | `#27272A` | فقط ساختار و جداکننده؛ هرگز تنها نشانگر کنترل نباشد |
| کادر کنترل | `#71717A` | دور دکمه و ورودی؛ متن ریز نه |
| متن اصلی | `#FFFFFF` | متن و اعداد بزرگ، تنها اقدام سفید |
| متن دوم | `#A1A1AA` | برچسب، راهنما، توضیح |
| متن کم‌رنگ | `#8E9192` | ریزبرچسب، واحد، شاخص غیرفعال |
| روی سفید | `#09090B` | متن/آیکن روی دکمهٔ سفید |
| رکورد شخصی | `#FFFFFF` | نشان سفید با برچسب PR و آیکن؛ بدون طلایی |
| خطر | `#FFFFFF` | خطای متنی + خط ۲ پیکسلی + آیکن؛ بدون قرمز |
| اطلاعات | `#A1A1AA` | راهنمای غیرفعال، بدون رنگ |
| وزن بدن | `#A1A1AA` | فقط خوانش وزن؛ با برچسب و خط‌چین از سری تمرین جدا می‌شود |

قاعده‌ها: متن حداقل کنتراست ۴.۵ به ۱، کنترل‌های غیرمتنی حداقل ۳ به ۱،
لمس حداقل ۴۸ دی‌پی، گوشه‌های صفر، بدون گرادیان/سایه/هاله، و هیچ معنایی فقط
با رنگ منتقل نشود. یک صفحه، یک اقدام سفید.

---

Last measured: 2026-10-28 (WCAG 2.x relative luminance). Update this file,
`docs/DESIGN.md`, and `lib/app/theme/app_tokens.dart` together when a token
changes.
