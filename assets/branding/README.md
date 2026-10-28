# Gym Log Brand Kit

Obsidian Telemetry: an achromatic, machined instrument identity for a
Persian-first strength log. The mark is a square aperture holding a barbell,
with a calibration index in the top-left corner. No gradient, glow, circle, or
color accent is part of the identity.

## Files

| File | Use |
|---|---|
| `logo-mark-2048.png` | Transparent mark for dark backgrounds, 2048 px |
| `logo_mark.png` | 1024 px app icon (also the documented source) |
| `app-icon-1024.png` / `app-icon-512.png` | Store listing, launcher, square avatar |
| `app-icon-full-bleed-1024.png` | Square source for Android launcher masks |
| `logo-horizontal.png` | Website header logo, transparent, for dark backgrounds |
| `logo-horizontal-on-light.png` | Website header logo, transparent, for light backgrounds |
| `logo-horizontal-panel.png` | Ready-made chassis panel version for decks and headers |
| `logo-stacked.png` | Square social/profile lockup |
| `brand-sheet-1600x1200.png` | One-page mark, palette, and type reference |
| `website-hero-2400x1000.png` | Website hero banner |
| `social-card-1200x630.png` | Open Graph / social preview |
| `favicon-512.png`, `favicon-180.png`, `favicon-32.png` | Web favicon / Apple touch icon |

The Android launcher mipmaps in `android/app/src/main/res/mipmap-*` are
regenerated from `app-icon-full-bleed-1024.png`. Regenerate the kit with
`python3 tool/branding/render_branding.py` (Pillow).

## Palette

| Role | Hex |
|---|---|
| Canvas | `#09090B` |
| Surface | `#121214` |
| Raised surface | `#18181B` |
| Hairline | `#27272A` |
| Control outline | `#71717A` |
| Text | `#FFFFFF` |
| Secondary text | `#A1A1AA` |
| Muted text | `#8E9192` |

The full handoff, including contrast ratios, CSS variables, and the Persian
summary, is in [`docs/PALETTE.md`](../../docs/PALETTE.md).

## Clear space and minimums

- Keep clear space equal to at least **15% of the mark's width** on every side.
- Website horizontal lockup: minimum **220 px** wide; below that use the mark
  or favicon.
- The mark is square. Never put it inside a rounded tile, circle, or badge.
- Full-bleed: use `app-icon-full-bleed-1024.png` only as the source for a
  launcher mask; never stretch it.
- Do not recolor the mark. The only allowed variants are white-on-dark and
  black-on-light.
- Do not add a second accent, gradient, glow, or rounded corner.

## Voice

Calm, precise, quietly confident. Numbers and units are the content. No hype,
no neon, no bodybuilder stock photography, and no color-only state signals.
