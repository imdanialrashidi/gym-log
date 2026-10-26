# Gym Log Color Palette

_[نسخهٔ فارسی در پایان همین فایل](#پالت-فارسی)_

Single-page handoff reference for the **night-session** palette. The app is
dark-only; there is no light theme. The canonical values live in
[`lib/app/theme/app_tokens.dart`](../lib/app/theme/app_tokens.dart), and the
measured pairs are guarded by
[`test/theme/contrast_test.dart`](../test/theme/contrast_test.dart). This file
mirrors that source so a designer, a store listing, or a new screen can use the
same colors without opening Dart.

Style in one line: **near-black navy canvas, one electric-blue light, soft
rounded instrument panels, numbers as the hero.**

## Core surfaces

| Token | Hex | RGB | Role | White text | Secondary text |
|---|---|---|---:|---:|---:|
| `background` | `#070B14` | `7, 11, 20` | App canvas, page background | 18.36:1 | 8.29:1 |
| `surface` | `#0E1524` | `14, 21, 36` | Cards, sheets, navigation bar | 17.02:1 | 7.68:1 |
| `surface2` | `#162034` | `22, 32, 52` | Raised card, input field, saved row | 15.19:1 | 6.86:1 |
| `surface3` | `#1F2B42` | `31, 43, 66` | Pressed/selected surface, snackbar | 13.22:1 | 5.97:1 |
| `outline` | `#26344F` | `38, 52, 79` | Hairline borders and dividers — **decorative only** | — | — |

`outline` is never a control boundary, focus ring, or the only state signal.
Use `accent` for focus and selection.

## Text and actions

| Token | Hex | RGB | Role | Contrast |
|---|---|---|---:|---:|
| `textPrimary` | `#F4F7FF` | `244, 247, 255` | Primary text, big numbers | 18.36:1 on canvas |
| `textSecondary` | `#9AA9C4` | `154, 169, 196` | Labels, hints, supporting copy | 8.29:1 on canvas |
| `accent` | `#5B9BFF` | `91, 155, 255` | The single action color; links, focus, selected state | 7.10:1 on canvas, 5.87:1 on `surface2` |
| `accentDeep` | `#2F6BFF` | `47, 107, 255` | Gradient/decorative companion; **never small text** | — |
| `onAccent` | `#061024` | `6, 16, 36` | Text/icon on an accent fill | 6.84:1 on `accent` |

Use **one** accent action per surface. Do not introduce a second action hue.

## Semantic colors

| Token | Hex | RGB | Role | Contrast on canvas |
|---|---|---|---:|---:|
| `highlight` | `#FFC857` | `255, 200, 87` | Personal records, gold brand marker, celebratory emphasis | 12.79:1 |
| `danger` | `#FF6B7A` | `255, 107, 122` | Errors, destructive actions | 7.16:1 |
| `info` | `#6EE7F9` | `110, 231, 249` | Hints, rest progress, charts | 13.55:1 |
| `weight` | `#A78BFA` | `167, 139, 250` | Body-weight series only, distinct from training volume | 7.23:1 |

Semantic colors never carry meaning alone: pair them with text, an icon, or a
pattern (PR label + gold, error text + red, RIR number + selected fill).

## Gradients

| Name | Stops | Use |
|---|---|---|
| `AppGradients.hero` | `#172C54` → `#0C1628` (55%) → `#0E1524` | Active-session hero, weekly hero |
| `AppGradients.accent` | `#5B9BFF` → `#2F6BFF` | Decorative accent fills |
| `AppGradients.weight` | `#A78BFA` → `#6EE7F9` | Body-weight chart area |
| `AppGradients.gold` | `#FFD98A` → `#FFC857` | PR seal / brand marker |
| `AppGradients.surface` | `#152038` → `#0E1524` | Top-lit raised surfaces |

Every gradient sits on a solid role that carries contrast; text never depends
on a gradient stop. On the hero gradient the worst stop still gives
`textPrimary` 12.85:1, `textSecondary` 5.80:1, and `accent` 4.97:1.

## Spacing, shape, motion

| Token | Value |
|---|---|
| Space scale | 4, 8, 16, 24, 32, 40, 48 dp |
| Card radius | 20 dp |
| Control radius | 12–16 dp |
| Pill | 999 dp |
| Minimum touch target | 48 dp |
| Fast / normal / slow motion | 150 / 200 / 300 ms |
| Page padding | 16 dp below 360 dp width; 24 dp otherwise |

Panels are raised by fill and a 1 dp translucent border, not by shadows.
Rounded panels, pill status chips, tabular figures for every changing number.
Respect reduced motion: state changes apply immediately.

## Ready-to-paste CSS

```css
:root {
  /* surfaces */
  --gl-background: #070b14;
  --gl-surface: #0e1524;
  --gl-surface-2: #162034;
  --gl-surface-3: #1f2b42;
  --gl-outline: #26344f;

  /* text */
  --gl-text-primary: #f4f7ff;
  --gl-text-secondary: #9aa9c4;

  /* action */
  --gl-accent: #5b9bff;
  --gl-accent-deep: #2f6bff;
  --gl-on-accent: #061024;

  /* semantics */
  --gl-highlight: #ffc857;
  --gl-danger: #ff6b7a;
  --gl-info: #6ee7f9;
  --gl-weight: #a78bfa;

  /* gradients */
  --gl-hero: linear-gradient(135deg, #172c54, #0c1628 55%, #0e1524);
  --gl-gold: linear-gradient(135deg, #ffd98a, #ffc857);
  --gl-weight-series: linear-gradient(135deg, #a78bfa, #6ee7f9);
}
```

## Do / do not

- **Do** keep the canvas near-black and let the numbers lead.
- **Do** use `accent` for the one primary action and focus state.
- **Do** check any new text pair at **≥ 4.5:1** before shipping.
- **Do** keep non-text controls at **≥ 3:1** and touch targets at **≥ 48 dp**.
- **Do not** add neon, purple/blue gradient text, or a second action color.
- **Do not** use `outline` as a button border or focus ring.
- **Do not** use `accentDeep` for small text.
- **Do not** use color as the only difference between two states.

## پالت فارسی

پالت تک‌صفحه‌ای اپ، برای تحویل به طراح یا ساخت صفحهٔ تازه. اپ فقط حالت تیره
دارد و مرجع نهایی کد در `lib/app/theme/app_tokens.dart` است؛ نسبت‌های کنتراست
با `test/theme/contrast_test.dart` بررسی می‌شوند.

| نقش | کد رنگ | کاربرد |
|---|---|---|
| پس‌زمینه | `#070B14` | بوم اصلی صفحه |
| سطح ۱ | `#0E1524` | کارت، شیت، نوار پایین |
| سطح ۲ | `#162034` | ورودی، کارت برجسته، ست ثبت‌شده |
| سطح ۳ | `#1F2B42` | حالت فشرده/انتخاب‌شده، اسنک‌بار |
| خط دور | `#26344F` | فقط خط تزئینی؛ هرگز تنها نشانگر وضعیت نباشد |
| متن اصلی | `#F4F7FF` | متن و اعداد بزرگ |
| متن دوم | `#9AA9C4` | برچسب، راهنما، توضیح |
| اکسنت | `#5B9BFF` | تنها رنگ اقدام، لینک، فوکوس |
| اکسنت تیره | `#2F6BFF` | فقط گرادیان و تزئین؛ متن ریز نه |
| روی اکسنت | `#061024` | متن/آیکن روی دکمهٔ آبی |
| هایلایت | `#FFC857` | رکورد شخصی، نشان طلایی برند |
| خطر | `#FF6B7A` | خطا و اقدام حذفی |
| اطلاعات | `#6EE7F9` | راهنما، پیشرفت استراحت، نمودار |
| وزن بدن | `#A78BFA` | فقط سری وزن بدن، جدا از حجم تمرین |

قاعده‌ها: متن حداقل کنتراست ۴.۵ به ۱، کنترل‌های غیرمتنی حداقل ۳ به ۱،
لمس حداقل ۴۸ دی‌پی، و هیچ معنایی فقط با رنگ منتقل نشود. یک صفحه، یک اقدام
آبی. برای هر رنگ تازه، اول کنتراست را اندازه بگیر و بعد استفاده کن.

---

Last measured: 2026-10-26 (WCAG 2.x relative luminance). Update this file and
`docs/DESIGN.md` together when a token changes.
