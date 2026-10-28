#!/usr/bin/env python3
"""Render the Gym Log "Obsidian Telemetry" branding kit.

The in-app emblem is painted in `lib/app/theme/brand_mark.dart`; this script
recreates the same geometry at print/web resolution so the downloaded assets
match the product. It is intentionally a development tool: the generated PNGs
in `assets/branding/` are the deliverable.

Requirements: Python 3 and Pillow. No gradients, glows, rounded corners, or
color accents are used anywhere in the kit.
Run from the repository root:

    python3 tool/branding/render_branding.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "branding"
FONT_BOLD = ROOT / "assets" / "fonts" / "Vazirmatn-Bold.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "Vazirmatn-Regular.ttf"

BACKGROUND = "#09090B"
SURFACE = "#121214"
SURFACE_2 = "#18181B"
HAIRLINE = "#27272A"
OUTLINE = "#71717A"
TEXT_PRIMARY = "#FFFFFF"
TEXT_SECONDARY = "#A1A1AA"
TEXT_MUTED = "#8E9192"
ON_LIGHT = "#09090B"
ON_LIGHT_SECONDARY = "#52525B"

WORDMARK = "GYM LOG"
TAGLINE = "YOUR TRAINING, MEASURED."
DESCRIPTOR = "OFFLINE STRENGTH TELEMETRY"


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    return (*rgb(value), alpha)


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size=max(1, int(size)))


def measure_tracked(
    draw: ImageDraw.ImageDraw,
    text: str,
    typeface: ImageFont.FreeTypeFont,
    tracking: float = 0,
) -> float:
    return sum(draw.textlength(char, font=typeface) for char in text) + tracking * max(
        0, len(text) - 1
    )


def tracked_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    typeface: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int, int],
    tracking: float = 0,
    anchor: str = "ls",
) -> float:
    """Draw tracked text and return its total width."""
    total = measure_tracked(draw, text, typeface, tracking)
    x, y = xy
    if anchor.startswith("m"):
        x -= total / 2
    elif anchor.startswith("r"):
        x -= total
    for char in text:
        draw.text((x, y), char, font=typeface, fill=fill, anchor="ls")
        x += draw.textlength(char, font=typeface) + tracking
    return total


def draw_mark(
    canvas: Image.Image,
    cx: float,
    cy: float,
    size: float,
    color: str = TEXT_PRIMARY,
) -> None:
    """The square aperture: frame, calibration index, and barbell."""
    draw = ImageDraw.Draw(canvas)
    half = size / 2
    stroke = size * 0.042
    inset = size * 0.135
    outer = inset - stroke / 2
    draw.rectangle(
        (cx - half + outer, cy - half + outer, cx + half - outer, cy + half - outer),
        outline=rgba(color),
        width=max(1, round(stroke)),
    )

    # Calibration index, top-left inside the frame.
    index_left = cx - half + size * 0.200
    index_top = cy - half + size * 0.200
    draw.rectangle(
        (
            index_left,
            index_top,
            index_left + size * 0.048,
            index_top + size * 0.048,
        ),
        fill=rgba(color),
    )

    cy_bar = cy + size * 0.025
    # Outer plates.
    for sign in (-1, 1):
        plate_x = cx + sign * size * 0.215
        draw.rectangle(
            (
                plate_x - size * 0.0375,
                cy_bar - size * 0.150,
                plate_x + size * 0.0375,
                cy_bar + size * 0.150,
            ),
            fill=rgba(color),
        )
    # Inner collars.
    for sign in (-1, 1):
        collar_x = cx + sign * size * 0.135
        draw.rectangle(
            (
                collar_x - size * 0.019,
                cy_bar - size * 0.0875,
                collar_x + size * 0.019,
                cy_bar + size * 0.0875,
            ),
            fill=rgba(color),
        )
    # The bar ties the assembly together.
    draw.rectangle(
        (
            cx - size * 0.230,
            cy_bar - size * 0.030,
            cx + size * 0.230,
            cy_bar + size * 0.030,
        ),
        fill=rgba(color),
    )


def draw_wordmark_block(
    draw: ImageDraw.ImageDraw,
    x: float,
    wordmark_baseline: float,
    wordmark_size: int,
    tagline_size: int,
    color: str,
    secondary: str,
) -> float:
    bold = font(FONT_BOLD, wordmark_size)
    regular = font(FONT_REGULAR, tagline_size)
    width = tracked_text(
        draw,
        (x, wordmark_baseline),
        WORDMARK,
        bold,
        rgba(color),
        tracking=wordmark_size * 0.10,
    )
    tracked_text(
        draw,
        (x + 2, wordmark_baseline + tagline_size * 2.0),
        TAGLINE,
        regular,
        rgba(secondary),
        tracking=tagline_size * 0.16,
    )
    return width


def save(image: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    image.save(OUT / name, format="PNG", optimize=True)


def downsample(image: Image.Image, width: int, height: int) -> Image.Image:
    return image.resize((width, height), Image.Resampling.LANCZOS)


def render_mark() -> None:
    final = 2048
    scale = 2
    work = final * scale
    canvas = Image.new("RGBA", (work, work), (0, 0, 0, 0))
    draw_mark(canvas, work / 2, work / 2, work * 0.78)
    save(downsample(canvas, final, final), "logo-mark-2048.png")


def render_app_icon() -> None:
    final = 1024
    scale = 4
    work = final * scale
    canvas = Image.new("RGBA", (work, work), rgba(BACKGROUND))
    draw_mark(canvas, work / 2, work / 2, work * 0.70)
    icon = downsample(canvas, final, final)
    save(icon, "logo_mark.png")
    save(icon, "app-icon-1024.png")
    save(downsample(icon, 512, 512), "app-icon-512.png")
    save(downsample(icon, 512, 512), "favicon-512.png")
    save(downsample(icon, 180, 180), "favicon-180.png")
    save(downsample(icon, 32, 32), "favicon-32.png")

    # The system has no rounded tile, so the full-bleed source is the same
    # square artwork. It remains the documented source for launcher masks.
    canvas = Image.new("RGBA", (work, work), rgba(BACKGROUND))
    draw_mark(canvas, work / 2, work / 2, work * 0.70)
    save(downsample(canvas, final, final), "app-icon-full-bleed-1024.png")


def render_android_mipmaps() -> None:
    source = Image.open(OUT / "app-icon-full-bleed-1024.png").convert("RGB")
    sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    for density, size in sizes.items():
        target = (
            ROOT
            / "android"
            / "app"
            / "src"
            / "main"
            / "res"
            / f"mipmap-{density}"
            / "ic_launcher.png"
        )
        source.resize((size, size), Image.Resampling.LANCZOS).save(
            target,
            format="PNG",
            optimize=True,
        )


def render_horizontal(name: str, dark: bool, panel: bool = False) -> None:
    width, height = 2400, 720
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
    if panel:
        canvas.alpha_composite(
            Image.new("RGBA", (work_w, work_h), rgba(SURFACE)),
        )
        ImageDraw.Draw(canvas).rectangle(
            (1, 1, work_w - 2, work_h - 2),
            outline=rgba(HAIRLINE),
            width=max(1, scale),
        )

    color = TEXT_PRIMARY if dark else ON_LIGHT
    secondary = TEXT_SECONDARY if dark else ON_LIGHT_SECONDARY
    mark_size = 520 * scale
    draw_mark(
        canvas,
        110 * scale + mark_size / 2,
        work_h / 2,
        mark_size,
        color=color,
    )
    draw = ImageDraw.Draw(canvas)
    draw_wordmark_block(
        draw,
        x=780 * scale,
        wordmark_baseline=work_h / 2 + 20 * scale,
        wordmark_size=190 * scale,
        tagline_size=38 * scale,
        color=color,
        secondary=secondary,
    )
    result = downsample(canvas, width, height)
    if not panel:
        bbox = result.getchannel("A").getbbox()
        if bbox is not None:
            padding = 48
            result = result.crop(
                (
                    max(0, bbox[0] - padding),
                    max(0, bbox[1] - padding),
                    min(result.width, bbox[2] + padding),
                    min(result.height, bbox[3] + padding),
                )
            )
    save(result, name)


def render_stacked() -> None:
    width, height = 1600, 1600
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
    mark_size = 640 * scale
    draw_mark(canvas, work_w / 2, 620 * scale, mark_size)
    draw = ImageDraw.Draw(canvas)
    bold = font(FONT_BOLD, 170 * scale)
    wordmark_width = measure_tracked(
        draw,
        WORDMARK,
        bold,
        tracking=170 * scale * 0.10,
    )
    draw_wordmark_block(
        draw,
        x=(work_w - wordmark_width) / 2,
        wordmark_baseline=1120 * scale,
        wordmark_size=170 * scale,
        tagline_size=36 * scale,
        color=TEXT_PRIMARY,
        secondary=TEXT_SECONDARY,
    )
    save(downsample(canvas, width, height), "logo-stacked.png")


def draw_grid(
    draw: ImageDraw.ImageDraw,
    width: int,
    height: int,
    step: int,
    color: str,
    alpha: int,
) -> None:
    for x in range(step, width, step):
        draw.line((x, 0, x, height), fill=rgba(color, alpha), width=1)
    for y in range(step, height, step):
        draw.line((0, y, width, y), fill=rgba(color, alpha), width=1)


def render_social() -> None:
    width, height = 1200, 630
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = Image.new("RGBA", (work_w, work_h), rgba(BACKGROUND))
    draw = ImageDraw.Draw(canvas)
    draw_grid(draw, work_w, work_h, 60 * scale, HAIRLINE, 18)
    draw.rectangle(
        (24 * scale, 24 * scale, work_w - 24 * scale, work_h - 24 * scale),
        outline=rgba(HAIRLINE),
        width=scale,
    )

    micro = font(FONT_REGULAR, 17 * scale)
    tracked_text(
        draw,
        (58 * scale, 68 * scale),
        "GYM_LOG // BRAND_01",
        micro,
        rgba(TEXT_MUTED),
        tracking=2.4 * scale,
    )
    tracked_text(
        draw,
        (work_w - 58 * scale, 68 * scale),
        "OBSIDIAN TELEMETRY",
        micro,
        rgba(TEXT_MUTED),
        tracking=2.4 * scale,
        anchor="rs",
    )
    draw.line(
        (58 * scale, 92 * scale, work_w - 58 * scale, 92 * scale),
        fill=rgba(HAIRLINE),
        width=scale,
    )

    mark_size = 240 * scale
    draw_mark(
        canvas,
        58 * scale + mark_size / 2,
        300 * scale,
        mark_size,
    )
    draw = ImageDraw.Draw(canvas)
    draw_wordmark_block(
        draw,
        x=370 * scale,
        wordmark_baseline=330 * scale,
        wordmark_size=96 * scale,
        tagline_size=22 * scale,
        color=TEXT_PRIMARY,
        secondary=TEXT_SECONDARY,
    )
    features = font(FONT_REGULAR, 18 * scale)
    tracked_text(
        draw,
        (372 * scale, 480 * scale),
        "OFFLINE  ·  NO ACCOUNT  ·  PERSIAN-FIRST",
        features,
        rgba(TEXT_SECONDARY),
        tracking=2.2 * scale,
    )
    save(downsample(canvas, width, height), "social-card-1200x630.png")


def render_hero() -> None:
    width, height = 2400, 1000
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = Image.new("RGBA", (work_w, work_h), rgba(BACKGROUND))
    draw = ImageDraw.Draw(canvas)
    draw_grid(draw, work_w, work_h, 64 * scale, HAIRLINE, 16)
    draw.rectangle(
        (1, 1, work_w - 2, work_h - 2),
        outline=rgba(HAIRLINE),
        width=max(1, scale),
    )

    mark_size = 560 * scale
    draw_mark(
        canvas,
        160 * scale + mark_size / 2,
        work_h / 2,
        mark_size,
    )
    draw = ImageDraw.Draw(canvas)

    micro = font(FONT_REGULAR, 22 * scale)
    tracked_text(
        draw,
        (860 * scale, 300 * scale),
        DESCRIPTOR,
        micro,
        rgba(TEXT_MUTED),
        tracking=4.4 * scale,
    )
    draw_wordmark_block(
        draw,
        x=855 * scale,
        wordmark_baseline=540 * scale,
        wordmark_size=190 * scale,
        tagline_size=40 * scale,
        color=TEXT_PRIMARY,
        secondary=TEXT_SECONDARY,
    )
    features = font(FONT_REGULAR, 26 * scale)
    tracked_text(
        draw,
        (858 * scale, 720 * scale),
        "OFFLINE  ·  NO ACCOUNT  ·  PERSIAN + ENGLISH",
        features,
        rgba(TEXT_SECONDARY),
        tracking=2.4 * scale,
    )

    # Right-hand readout: a small system panel, not decoration.
    panel_left = 1870 * scale
    panel_top = 270 * scale
    panel_right = work_w - 150 * scale
    panel_bottom = 730 * scale
    draw.rectangle(
        (panel_left, panel_top, panel_right, panel_bottom),
        outline=rgba(HAIRLINE),
        width=max(1, scale),
    )
    label = font(FONT_REGULAR, 18 * scale)
    tracked_text(
        draw,
        (panel_left + 28 * scale, panel_top + 52 * scale),
        "SYSTEM / 01",
        label,
        rgba(TEXT_MUTED),
        tracking=3.0 * scale,
    )
    draw.line(
        (
            panel_left + 28 * scale,
            panel_top + 76 * scale,
            panel_right - 28 * scale,
            panel_top + 76 * scale,
        ),
        fill=rgba(HAIRLINE),
        width=scale,
    )
    rows = (
        ("STORAGE", "DEVICE"),
        ("NETWORK", "NONE"),
        ("ACCOUNT", "NONE"),
        ("LOCALES", "FA · EN"),
    )
    row_font = font(FONT_REGULAR, 21 * scale)
    for index, (key, value) in enumerate(rows):
        y = panel_top + (135 + index * 82) * scale
        tracked_text(
            draw,
            (panel_left + 28 * scale, y),
            key,
            label,
            rgba(TEXT_MUTED),
            tracking=2.0 * scale,
        )
        tracked_text(
            draw,
            (panel_right - 28 * scale, y),
            value,
            row_font,
            rgba(TEXT_PRIMARY),
            tracking=1.4 * scale,
            anchor="rs",
        )
        if index < len(rows) - 1:
            draw.line(
                (
                    panel_left + 28 * scale,
                    y + 26 * scale,
                    panel_right - 28 * scale,
                    y + 26 * scale,
                ),
                fill=rgba(SURFACE_2),
                width=scale,
            )

    save(downsample(canvas, width, height), "website-hero-2400x1000.png")


def render_brand_sheet() -> None:
    width, height = 1600, 1200
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = Image.new("RGBA", (work_w, work_h), rgba(BACKGROUND))
    draw = ImageDraw.Draw(canvas)
    draw_grid(draw, work_w, work_h, 80 * scale, HAIRLINE, 14)
    draw.rectangle(
        (1, 1, work_w - 2, work_h - 2),
        outline=rgba(HAIRLINE),
        width=max(1, scale),
    )

    micro = font(FONT_REGULAR, 18 * scale)
    tracked_text(
        draw,
        (64 * scale, 70 * scale),
        "GYM LOG / OBSIDIAN TELEMETRY",
        micro,
        rgba(TEXT_MUTED),
        tracking=2.8 * scale,
    )
    tracked_text(
        draw,
        (work_w - 64 * scale, 70 * scale),
        "BRAND SHEET / 01",
        micro,
        rgba(TEXT_MUTED),
        tracking=2.8 * scale,
        anchor="rs",
    )
    draw.line(
        (64 * scale, 96 * scale, work_w - 64 * scale, 96 * scale),
        fill=rgba(HAIRLINE),
        width=scale,
    )

    mark_size = 300 * scale
    draw_mark(canvas, 64 * scale + mark_size / 2, 300 * scale, mark_size)
    draw = ImageDraw.Draw(canvas)
    draw_wordmark_block(
        draw,
        x=64 * scale,
        wordmark_baseline=540 * scale,
        wordmark_size=74 * scale,
        tagline_size=18 * scale,
        color=TEXT_PRIMARY,
        secondary=TEXT_SECONDARY,
    )

    # Clear-space specimen, top right.
    clear_left = 1060 * scale
    clear_top = 150 * scale
    clear_size = 360 * scale
    dashed = ImageDraw.Draw(canvas)
    dash = 8 * scale
    for x in range(int(clear_left), int(clear_left + clear_size), dash * 2):
        dashed.line(
            (x, clear_top, min(x + dash, clear_left + clear_size), clear_top),
            fill=rgba(OUTLINE),
            width=scale,
        )
        dashed.line(
            (x, clear_top + clear_size, min(x + dash, clear_left + clear_size), clear_top + clear_size),
            fill=rgba(OUTLINE),
            width=scale,
        )
    for y in range(int(clear_top), int(clear_top + clear_size), dash * 2):
        dashed.line(
            (clear_left, y, clear_left, min(y + dash, clear_top + clear_size)),
            fill=rgba(OUTLINE),
            width=scale,
        )
        dashed.line(
            (clear_left + clear_size, y, clear_left + clear_size, min(y + dash, clear_top + clear_size)),
            fill=rgba(OUTLINE),
            width=scale,
        )
    specimen = clear_size * 0.70
    draw_mark(
        canvas,
        clear_left + clear_size / 2,
        clear_top + clear_size / 2,
        specimen,
    )
    draw = ImageDraw.Draw(canvas)
    tracked_text(
        draw,
        (clear_left, clear_top - 22 * scale),
        "CLEAR SPACE / 15% MIN",
        micro,
        rgba(TEXT_MUTED),
        tracking=2.0 * scale,
    )

    draw.line(
        (64 * scale, 630 * scale, work_w - 64 * scale, 630 * scale),
        fill=rgba(HAIRLINE),
        width=scale,
    )

    swatches = (
        ("BACKGROUND", BACKGROUND),
        ("SURFACE", SURFACE),
        ("SURFACE 2", SURFACE_2),
        ("HAIRLINE", HAIRLINE),
        ("OUTLINE", OUTLINE),
        ("TEXT MUTED", TEXT_MUTED),
        ("TEXT SECONDARY", TEXT_SECONDARY),
        ("STRIKE", TEXT_PRIMARY),
    )
    label = font(FONT_REGULAR, 17 * scale)
    for index, (name, value) in enumerate(swatches):
        column = index % 4
        row = index // 4
        x = (64 + column * 380) * scale
        y = (690 + row * 78) * scale
        draw.rectangle(
            (x, y - 30 * scale, x + 44 * scale, y + 8 * scale),
            fill=rgba(value),
            outline=rgba(HAIRLINE),
            width=scale,
        )
        tracked_text(
            draw,
            (x + 62 * scale, y - 18 * scale),
            name,
            label,
            rgba(TEXT_SECONDARY),
            tracking=1.2 * scale,
        )
        tracked_text(
            draw,
            (x + 62 * scale, y + 4 * scale),
            value.upper(),
            label,
            rgba(TEXT_MUTED),
            tracking=1.2 * scale,
        )

    draw.line(
        (64 * scale, 1020 * scale, work_w - 64 * scale, 1020 * scale),
        fill=rgba(HAIRLINE),
        width=scale,
    )
    typeface = font(FONT_BOLD, 44 * scale)
    tracked_text(
        draw,
        (64 * scale, 1090 * scale),
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        typeface,
        rgba(TEXT_PRIMARY),
        tracking=1.2 * scale,
    )
    tracked_text(
        draw,
        (64 * scale, 1145 * scale),
        "0123456789  ·  KG  ·  RIR  ·  FA / EN",
        label,
        rgba(TEXT_SECONDARY),
        tracking=2.0 * scale,
    )

    save(downsample(canvas, width, height), "brand-sheet-1600x1200.png")


def write_readme() -> None:
    readme = f"""# Gym Log Brand Kit

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
| Canvas | `{BACKGROUND}` |
| Surface | `{SURFACE}` |
| Raised surface | `{SURFACE_2}` |
| Hairline | `{HAIRLINE}` |
| Control outline | `{OUTLINE}` |
| Text | `{TEXT_PRIMARY}` |
| Secondary text | `{TEXT_SECONDARY}` |
| Muted text | `{TEXT_MUTED}` |

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
"""
    (OUT / "README.md").write_text(readme, encoding="utf-8")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    render_mark()
    render_app_icon()
    render_android_mipmaps()
    render_horizontal("logo-horizontal.png", dark=True)
    render_horizontal("logo-horizontal-on-light.png", dark=False)
    render_horizontal("logo-horizontal-panel.png", dark=True, panel=True)
    render_stacked()
    render_social()
    render_hero()
    render_brand_sheet()
    write_readme()
    print(f"Wrote branding assets to {OUT}")


if __name__ == "__main__":
    main()
