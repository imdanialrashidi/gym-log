# Gym Log Brand Kit

Dark, calm, electric-blue. The mark is a 280° progress ring enclosing a
barbell, closed by a gold endpoint. It says "training, measured" without stock
gym imagery.

## Files

| File | Use |
|---|---|
| `logo-mark-2048.png` | Transparent mark for dark backgrounds, 2048 px |
| `logo_mark.png` | 1024 px app icon (also the documented source) |
| `app-icon-1024.png` / `app-icon-512.png` | Store listing, launcher, square avatar |
| `app-icon-full-bleed-1024.png` | Square source for Android adaptive masks |
| `logo-horizontal.png` | Website header logo, transparent, for dark backgrounds |
| `logo-horizontal-on-light.png` | Website header logo, transparent, for light backgrounds |
| `logo-horizontal-navy.png` | Ready-made navy panel version for decks and headers |
| `logo-stacked.png` | Square social/profile lockup |
| `website-hero-2400x1000.png` | Website hero banner |
| `social-card-1200x630.png` | Open Graph / social preview |
| `favicon-512.png`, `favicon-180.png`, `favicon-32.png` | Web favicon / Apple touch icon |

The Android launcher mipmaps in `android/app/src/main/res/mipmap-*` are
regenerated from `app-icon-full-bleed-1024.png`. Regenerate the kit with
`python3 tool/branding/render_branding.py` (Pillow + NumPy).

## Palette

| Role | Hex |
|---|---|
| Canvas | `#070B14` |
| Surface | `#0E1524` |
| Raised | `#162034` |
| Border | `#26344F` |
| Text | `#F4F7FF` |
| Secondary text | `#9AA9C4` |
| Action | `#5B9BFF` |
| Deep action | `#2F6BFF` |
| Gold | `#FFC857` |

The full handoff, including contrast ratios and CSS variables, is in
[`docs/PALETTE.md`](../../docs/PALETTE.md).

## Clear space and minimums

- Keep clear space equal to at least **15% of the mark's width** on every side.
- Website horizontal lockup: minimum **220 px** wide; below that use the mark
  or favicon.
- App icon: do not put the mark inside another rounded square; the asset
  already includes its own 23.5% corner radius.
- Full-bleed: use `app-icon-full-bleed-1024.png` only as the source for an
  adaptive-icon mask; never stretch it.
- Do not recolor the mark, add a second accent, or place the white wordmark on
  a light background. Use `logo-horizontal-on-light.png` there instead.
- The gold endpoint is the single warm highlight. Do not add more gold.

## Voice

Calm, precise, quietly confident. No hype, no neon overload, no bodybuilder
stock photography. One blue action per surface.
