#!/usr/bin/env python3
"""Render the Gym Log branding kit.

The in-app emblem is painted in `lib/app/theme/brand_mark.dart`; this script
recreates the same geometry at print/web resolution so the downloaded assets
match the product. It is intentionally a development tool: the generated PNGs
in `assets/branding/` are the deliverable.

Requirements: Python 3, Pillow, NumPy.
Run from the repository root:

    python3 tool/branding/render_branding.py
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "branding"
FONT_BOLD = ROOT / "assets" / "fonts" / "Vazirmatn-Bold.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "Vazirmatn-Regular.ttf"

BACKGROUND = "#070B14"
SURFACE = "#0E1524"
OUTLINE = "#26344F"
TEXT_PRIMARY = "#F4F7FF"
TEXT_SECONDARY = "#9AA9C4"
ACCENT = "#5B9BFF"
ACCENT_DEEP = "#2F6BFF"
HIGHLIGHT = "#FFC857"
HERO_TOP = "#172C54"
HERO_BOTTOM = "#070B14"
LIGHT_TEXT = "#0B1220"
LIGHT_SECONDARY = "#4B5B76"


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    return (*rgb(value), alpha)


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def linear_gradient(
    width: int,
    height: int,
    start: str,
    end: str,
    direction: tuple[float, float] = (1, 1),
) -> Image.Image:
    """A smooth two-stop gradient with an arbitrary diagonal direction."""
    yy, xx = np.mgrid[0:height, 0:width].astype(np.float32)
    dx, dy = direction
    if dx == 0 and dy == 0:
        dx = dy = 1
    projection = (xx / max(1, width - 1)) * dx + (yy / max(1, height - 1)) * dy
    low = min(0.0, dx) + min(0.0, dy)
    high = max(dx, 0.0) + max(dy, 0.0)
    projection = (projection - low) / max(1e-6, high - low)
    projection = np.clip(projection, 0, 1)[..., None]
    start_rgb = np.array(rgb(start), dtype=np.float32)
    end_rgb = np.array(rgb(end), dtype=np.float32)
    data = start_rgb + (end_rgb - start_rgb) * projection
    return Image.fromarray(np.uint8(data), mode="RGB").convert("RGBA")


def radial_glow(
    width: int,
    height: int,
    center: tuple[float, float],
    radius: float,
    color: str,
    alpha: int,
) -> Image.Image:
    yy, xx = np.mgrid[0:height, 0:width].astype(np.float32)
    distance = np.sqrt((xx - center[0]) ** 2 + (yy - center[1]) ** 2) / max(1.0, radius)
    strength = np.clip(1.0 - distance, 0, 1) ** 2 * alpha
    data = np.zeros((height, width, 4), dtype=np.uint8)
    data[..., 0] = rgb(color)[0]
    data[..., 1] = rgb(color)[1]
    data[..., 2] = rgb(color)[2]
    data[..., 3] = np.uint8(np.clip(strength, 0, 255))
    return Image.fromarray(data, mode="RGBA")


def rounded_mask(width: int, height: int, radius: int, square: bool = False) -> Image.Image:
    mask = Image.new("L", (width, height), 0)
    if square:
        mask.paste(255, (0, 0, width, height))
    else:
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, width - 1, height - 1),
            radius=radius,
            fill=255,
        )
    return mask


def gradient_rounded_rect(
    width: int,
    height: int,
    radius: int,
    top: str,
    bottom: str,
) -> Image.Image:
    gradient = linear_gradient(width, height, top, bottom, direction=(0.2, 1))
    mask = rounded_mask(width, height, radius)
    result = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    result.paste(gradient, (0, 0), mask)
    return result


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size=max(1, int(size)))


def tracked_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    typeface: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int, int],
    tracking: float = 0,
    anchor: str = "ls",
) -> float:
    """Draw text with letter spacing and return its total width."""
    if tracking == 0:
        draw.text(xy, text, font=typeface, fill=fill, anchor=anchor)
        return draw.textlength(text, font=typeface)
    total = sum(draw.textlength(char, font=typeface) for char in text)
    total += tracking * max(0, len(text) - 1)
    x, y = xy
    if anchor == "ms":
        x -= total / 2
    elif anchor == "rs":
        x -= total
    for char in text:
        draw.text((x, y), char, font=typeface, fill=fill, anchor="ls")
        x += draw.textlength(char, font=typeface) + tracking
    return total


def draw_ring(canvas: Image.Image, cx: float, cy: float, size: float) -> None:
    """The 280-degree electric-blue ring, with a small gold endpoint."""
    ring = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(ring)
    radius = size * 0.305
    stroke = max(2, int(size * 0.042))
    box = (cx - radius, cy - radius, cx + radius, cy + radius)
    start_degrees = 132.0
    sweep_degrees = 280.0
    # Inset both ends under their caps/bead so the flat arc cut never shows.
    draw_start = start_degrees + 1.5
    draw_sweep = sweep_degrees - 3.5
    segments = 420
    start_rgb = rgb(ACCENT)
    end_rgb = rgb(ACCENT_DEEP)
    for index in range(segments):
        t0 = index / segments
        t1 = (index + 1) / segments
        angle0 = draw_start + draw_sweep * t0
        angle1 = draw_start + draw_sweep * t1 + 0.35
        color = (*lerp(start_rgb, end_rgb, t0), 255)
        draw.arc(box, angle0, angle1, fill=color, width=stroke)
    # Rounded caps: the gold endpoint is drawn later on top.
    cap = stroke * 0.58
    x = cx + radius * math.cos(math.radians(start_degrees))
    y = cy + radius * math.sin(math.radians(start_degrees))
    draw.ellipse((x - cap, y - cap, x + cap, y + cap), fill=rgba(ACCENT))
    canvas.alpha_composite(ring)


def draw_bar(canvas: Image.Image, cx: float, cy: float, size: float) -> None:
    width = int(size * 0.404)
    height = int(size * 0.066)
    bar = gradient_rounded_rect(
        width,
        height,
        max(2, int(size * 0.026)),
        ACCENT,
        ACCENT_DEEP,
    )
    canvas.alpha_composite(bar, (int(cx - width / 2), int(cy - height / 2)))


def draw_plate(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    size: float,
    left: float,
    top: float,
    right: float,
    bottom: float,
    radius: float,
    fill: tuple[int, int, int, int],
) -> None:
    draw.rounded_rectangle(
        (
            cx + left * size,
            cy + top * size,
            cx + right * size,
            cy + bottom * size,
        ),
        radius=max(1, size * radius),
        fill=fill,
    )


def draw_barbell(canvas: Image.Image, cx: float, cy: float, size: float) -> None:
    draw_bar(canvas, cx, cy, size)
    draw = ImageDraw.Draw(canvas)
    white = rgba(TEXT_PRIMARY)
    # Inner collars, outer plates, then inner plates: the same order as the app.
    for sign in (-1, 1):
        draw_plate(draw, cx, cy, size, sign * 0.101 - 0.024, -0.048, sign * 0.101 + 0.024, 0.048, 0.014, white)
    for sign in (-1, 1):
        draw_plate(draw, cx, cy, size, sign * 0.21 - 0.030, -0.117, sign * 0.21 + 0.030, 0.117, 0.022, white)
    for sign in (-1, 1):
        draw_plate(draw, cx, cy, size, sign * 0.14 - 0.023, -0.089, sign * 0.14 + 0.023, 0.089, 0.016, white)


def draw_gold_dot(
    canvas: Image.Image,
    cx: float,
    cy: float,
    size: float,
    glow: bool = True,
) -> None:
    end_angle = math.radians(132 + 280)
    radius = size * 0.305
    x = cx + radius * math.cos(end_angle)
    y = cy + radius * math.sin(end_angle)
    dot_radius = size * 0.038
    if glow:
        halo = radial_glow(
            canvas.width,
            canvas.height,
            (x, y),
            dot_radius * 2.2,
            HIGHLIGHT,
            90,
        )
        canvas.alpha_composite(halo)
    ImageDraw.Draw(canvas).ellipse(
        (x - dot_radius, y - dot_radius, x + dot_radius, y + dot_radius),
        fill=rgba(HIGHLIGHT),
    )


def draw_mark(
    canvas: Image.Image,
    cx: float,
    cy: float,
    size: float,
    with_tile: bool = False,
    square_tile: bool = False,
) -> None:
    if with_tile:
        radius = 0 if square_tile else int(size * 0.235)
        tile = gradient_rounded_rect(
            int(size),
            int(size),
            radius,
            HERO_TOP,
            HERO_BOTTOM,
        )
        glow = radial_glow(
            int(size),
            int(size),
            (size / 2, size / 2),
            size * 0.34,
            ACCENT_DEEP,
            58,
        )
        tile.alpha_composite(glow)
        if not square_tile:
            tile = clip_rounded(tile, radius)
        border = Image.new("RGBA", tile.size, (0, 0, 0, 0))
        ImageDraw.Draw(border).rounded_rectangle(
            (1, 1, tile.width - 2, tile.height - 2),
            radius=radius,
            outline=rgba(OUTLINE, 165),
            width=max(1, int(size * 0.003)),
        )
        tile.alpha_composite(border)
        canvas.alpha_composite(tile, (int(cx - size / 2), int(cy - size / 2)))
    draw_ring(canvas, cx, cy, size)
    draw_barbell(canvas, cx, cy, size)
    draw_gold_dot(canvas, cx, cy, size, glow=with_tile)


def downsample(image: Image.Image, width: int, height: int) -> Image.Image:
    return image.resize((width, height), Image.Resampling.LANCZOS)


def clip_rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = rounded_mask(image.width, image.height, radius)
    clipped = Image.new("RGBA", image.size, (0, 0, 0, 0))
    clipped.paste(image, (0, 0), mask)
    return clipped


def crop_transparent(image: Image.Image, padding: int) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.width, bbox[2] + padding)
    bottom = min(image.height, bbox[3] + padding)
    return image.crop((left, top, right, bottom))


def save(image: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    image.save(OUT / name, format="PNG", optimize=True)


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
    canvas = Image.new("RGBA", (work, work), (0, 0, 0, 0))
    draw_mark(canvas, work / 2, work / 2, work, with_tile=True)
    icon = downsample(canvas, final, final)
    save(icon, "logo_mark.png")
    save(icon, "app-icon-1024.png")
    save(downsample(icon, 512, 512), "app-icon-512.png")
    save(downsample(icon, 512, 512), "favicon-512.png")
    save(downsample(icon, 180, 180), "favicon-180.png")
    save(downsample(icon, 32, 32), "favicon-32.png")

    # Full-bleed source for launcher masks. Same artwork without the rounded
    # corner so an adaptive-icon mask can do the cropping.
    canvas = Image.new("RGBA", (work, work), (0, 0, 0, 0))
    draw_mark(canvas, work / 2, work / 2, work, with_tile=True, square_tile=True)
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
        target = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}" / "ic_launcher.png"
        source.resize((size, size), Image.Resampling.LANCZOS).save(
            target,
            format="PNG",
            optimize=True,
        )


def draw_wordmark_block(
    draw: ImageDraw.ImageDraw,
    x: float,
    baseline: float,
    wordmark_size: int,
    tagline_size: int,
    dark: bool,
) -> None:
    primary = rgba(TEXT_PRIMARY if dark else LIGHT_TEXT)
    secondary = rgba(TEXT_SECONDARY if dark else LIGHT_SECONDARY)
    bold = font(FONT_BOLD, wordmark_size)
    tagline_font = font(FONT_REGULAR, tagline_size)
    tracked_text(draw, (x, baseline), "Gym Log", bold, primary, tracking=-wordmark_size * 0.018)
    tracked_text(
        draw,
        (x + 2, baseline + wordmark_size * 0.72),
        "YOUR TRAINING, MEASURED.",
        tagline_font,
        secondary,
        tracking=tagline_size * 0.18,
    )


def render_horizontal(name: str, dark: bool, background: str | None = None) -> None:
    width, height = 2400, 720
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
    if background is not None:
        panel = gradient_rounded_rect(
            work_w,
            work_h,
            int(56 * scale),
            HERO_TOP,
            HERO_BOTTOM,
        )
        glow = radial_glow(
            work_w,
            work_h,
            (work_w * 0.18, work_h * 0.18),
            work_w * 0.5,
            ACCENT_DEEP,
            46,
        )
        panel.alpha_composite(clip_rounded(glow, int(56 * scale)))
        border = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
        ImageDraw.Draw(border).rounded_rectangle(
            (1, 1, work_w - 2, work_h - 2),
            radius=int(56 * scale),
            outline=rgba(OUTLINE, 180),
            width=max(1, int(2 * scale)),
        )
        panel.alpha_composite(border)
        canvas.alpha_composite(panel)

    mark_size = 560 * scale
    mark_center = (110 * scale + mark_size / 2, work_h / 2)
    draw_mark(
        canvas,
        mark_center[0],
        mark_center[1],
        mark_size,
        with_tile=not dark,
    )
    draw = ImageDraw.Draw(canvas)
    draw_wordmark_block(
        draw,
        x=760 * scale,
        baseline=work_h / 2 + 24 * scale,
        wordmark_size=210 * scale,
        tagline_size=44 * scale,
        dark=dark,
    )
    result = downsample(canvas, width, height)
    if background is None:
        result = crop_transparent(result, 56)
    save(result, name)


def render_stacked() -> None:
    width, height = 1600, 1600
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
    mark_size = 640 * scale
    draw_mark(canvas, work_w / 2, 625 * scale, mark_size)
    draw = ImageDraw.Draw(canvas)
    draw_wordmark_block(
        draw,
        x=0,
        baseline=1145 * scale,
        wordmark_size=170 * scale,
        tagline_size=38 * scale,
        dark=True,
    )
    # Center the wordmark block over the mark.
    bbox = draw.textbbox((0, 0), "Gym Log", font=font(FONT_BOLD, 170 * scale))
    text_width = bbox[2] - bbox[0]
    # Re-render at the correct centered x using a clear layer.
    canvas = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
    draw_mark(canvas, work_w / 2, 625 * scale, mark_size)
    draw = ImageDraw.Draw(canvas)
    draw_wordmark_block(
        draw,
        x=(work_w - text_width) / 2,
        baseline=1145 * scale,
        wordmark_size=170 * scale,
        tagline_size=38 * scale,
        dark=True,
    )
    save(downsample(canvas, width, height), "logo-stacked.png")


def render_social() -> None:
    width, height = 1200, 630
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = gradient_rounded_rect(work_w, work_h, 0, HERO_TOP, BACKGROUND)
    canvas.alpha_composite(
        radial_glow(work_w, work_h, (work_w * 0.1, work_h * 0.1), work_w * 0.55, ACCENT_DEEP, 58)
    )
    canvas.alpha_composite(
        radial_glow(work_w, work_h, (work_w * 0.85, work_h * 0.9), work_w * 0.4, ACCENT, 34)
    )
    border = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
    ImageDraw.Draw(border).rectangle(
        (1, 1, work_w - 2, work_h - 2),
        outline=rgba(OUTLINE, 160),
        width=max(1, int(2 * scale)),
    )
    canvas.alpha_composite(border)

    mark_size = 250 * scale
    draw_mark(canvas, 90 * scale + mark_size / 2, work_h / 2, mark_size)
    draw = ImageDraw.Draw(canvas)
    draw_wordmark_block(
        draw,
        x=390 * scale,
        baseline=310 * scale,
        wordmark_size=104 * scale,
        tagline_size=26 * scale,
        dark=True,
    )
    secondary = font(FONT_REGULAR, 20 * scale)
    tracked_text(
        draw,
        (390 * scale, 520 * scale),
        "OFFLINE  ·  NO ACCOUNT  ·  PERSIAN-FIRST",
        secondary,
        rgba(TEXT_SECONDARY),
        tracking=2 * scale,
    )
    save(downsample(canvas, width, height), "social-card-1200x630.png")


def render_hero() -> None:
    width, height = 2400, 1000
    scale = 2
    work_w, work_h = width * scale, height * scale
    canvas = gradient_rounded_rect(
        work_w,
        work_h,
        int(64 * scale),
        HERO_TOP,
        BACKGROUND,
    )
    radius = int(64 * scale)
    canvas.alpha_composite(
        clip_rounded(
            radial_glow(work_w, work_h, (work_w * 0.18, work_h * 0.2), work_w * 0.5, ACCENT_DEEP, 60),
            radius,
        )
    )
    canvas.alpha_composite(
        clip_rounded(
            radial_glow(work_w, work_h, (work_w * 0.85, work_h * 0.9), work_w * 0.35, ACCENT, 28),
            radius,
        )
    )
    grid = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
    grid_draw = ImageDraw.Draw(grid)
    step = 64 * scale
    for x in range(0, work_w, step):
        grid_draw.line((x, 0, x, work_h), fill=rgba(OUTLINE, 20), width=1)
    for y in range(0, work_h, step):
        grid_draw.line((0, y, work_w, y), fill=rgba(OUTLINE, 20), width=1)
    canvas.alpha_composite(clip_rounded(grid, radius))
    border = Image.new("RGBA", (work_w, work_h), (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle(
        (1, 1, work_w - 2, work_h - 2),
        radius=int(64 * scale),
        outline=rgba(OUTLINE, 190),
        width=max(1, int(2 * scale)),
    )
    canvas.alpha_composite(border)

    mark_size = 600 * scale
    draw_mark(canvas, 170 * scale + mark_size / 2, work_h / 2, mark_size)
    draw = ImageDraw.Draw(canvas)
    label_font = font(FONT_BOLD, 28 * scale)
    tracked_text(
        draw,
        (860 * scale, 335 * scale),
        "LOCAL-FIRST WORKOUT LOG",
        label_font,
        rgba(ACCENT),
        tracking=5 * scale,
    )
    draw_wordmark_block(
        draw,
        x=855 * scale,
        baseline=510 * scale,
        wordmark_size=190 * scale,
        tagline_size=42 * scale,
        dark=True,
    )
    features_font = font(FONT_REGULAR, 28 * scale)
    tracked_text(
        draw,
        (860 * scale, 700 * scale),
        "OFFLINE  ·  NO ACCOUNT  ·  PERSIAN + ENGLISH",
        features_font,
        rgba(TEXT_SECONDARY),
        tracking=2 * scale,
    )
    save(downsample(canvas, width, height), "website-hero-2400x1000.png")


def write_readme() -> None:
    readme = """# Gym Log Brand Kit

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
"""
    (OUT / "README.md").write_text(readme, encoding="utf-8")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    render_mark()
    render_app_icon()
    render_android_mipmaps()
    render_horizontal("logo-horizontal.png", dark=True)
    render_horizontal("logo-horizontal-on-light.png", dark=False)
    render_horizontal("logo-horizontal-navy.png", dark=True, background=SURFACE)
    render_stacked()
    render_social()
    render_hero()
    write_readme()
    print(f"Wrote branding assets to {OUT}")


if __name__ == "__main__":
    main()
