"""Builds one backdrop per big-map region (chapters 2-4) from the painted art.

Every chapter used to show the same painting in all nine regions. With image
generation unavailable, each region instead gets its own composition from the
four existing paintings: a different crop/zoom/flip, then a gradient map into
that region's palette (blended with the original so detail survives), an
optional water/haze overlay and a vignette. Output: assets/backgrounds/regions/
<region>.png at 1536x864, the size MDSBigRoom tiles.

Usage: python tools/build_region_backdrops.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "backgrounds"
OUT = SRC / "regions"
W, H = 1536, 864

# Gradient-map palettes: shadow -> mid -> light -> highlight.
P = {
    "ruin_teal": [(8, 12, 16), (34, 58, 62), (112, 140, 136), (214, 222, 208)],
    "ruin_rust": [(14, 8, 8), (70, 36, 30), (150, 104, 84), (232, 210, 180)],
    "ruin_moss": [(8, 12, 8), (36, 56, 38), (110, 138, 96), (212, 226, 190)],
    "ruin_gold": [(12, 10, 8), (64, 48, 30), (170, 136, 84), (246, 226, 170)],
    "ruin_blood": [(12, 4, 6), (76, 16, 22), (170, 62, 58), (240, 190, 170)],
    "ruin_violet": [(10, 8, 16), (44, 34, 66), (122, 106, 150), (220, 210, 236)],
    "sea_deep": [(2, 6, 14), (10, 34, 60), (52, 110, 140), (180, 226, 236)],
    "sea_teal": [(2, 10, 12), (8, 50, 56), (40, 132, 128), (180, 236, 220)],
    "sea_ink": [(2, 4, 10), (16, 22, 48), (70, 86, 140), (200, 210, 240)],
    "sea_bio": [(2, 8, 10), (12, 40, 52), (40, 150, 150), (200, 255, 236)],
    "sea_wreck": [(6, 8, 10), (34, 40, 46), (100, 112, 116), (210, 214, 206)],
    "stage_red": [(10, 4, 4), (70, 14, 18), (170, 60, 50), (246, 210, 160)],
    "stage_gold": [(10, 8, 4), (58, 38, 16), (166, 120, 56), (250, 226, 160)],
    "stage_teal": [(4, 8, 10), (20, 46, 50), (80, 150, 140), (220, 240, 220)],
    "stage_bone": [(10, 8, 8), (52, 40, 38), (150, 132, 120), (240, 232, 214)],
    "stage_violet": [(8, 4, 12), (46, 20, 58), (140, 80, 140), (240, 200, 230)],
}

# region: (source painting, crop box as fractions (x0, y0, x1, y1), flip,
#          palette, palette strength, overlay)
REGIONS = {
    # Chapter 2 · Breathing Ruins
    "ch2_entry": ("breathing_ruins", (0.0, 0.0, 1.0, 1.0), False, "ruin_teal", 0.25, None),
    "ch2_branch_a": ("breathing_ruins", (0.42, 0.18, 1.0, 0.85), True, "ruin_moss", 0.55, None),
    "ch2_branch_b": ("breathing_ruins", (0.0, 0.08, 0.6, 0.86), False, "ruin_rust", 0.55, None),
    "ch2_hub": ("ink_archive", (0.0, 0.0, 1.0, 1.0), False, "ruin_teal", 0.7, "haze"),
    "ch2_well": ("ink_archive", (0.0, 0.1, 0.7, 0.9), True, "ruin_teal", 0.7, "dark"),
    "ch2_vault": ("ink_archive", (0.15, 0.05, 0.85, 0.85), True, "ruin_gold", 0.65, "glow"),
    "ch2_event": ("breathing_ruins", (0.0, 0.0, 1.0, 1.0), True, "ruin_violet", 0.6, "haze"),
    "ch2_elite": ("breathing_ruins", (0.2, 0.05, 0.85, 0.8), True, "ruin_blood", 0.55, "dark"),
    "ch2_boss": ("breathing_ruins", (0.45, 0.0, 1.0, 0.6), False, "ruin_blood", 0.7, "vignette"),
    # Chapter 3 · Lightless Sea
    "ch3_entry": ("lightless_sea", (0.0, 0.0, 1.0, 1.0), False, "sea_deep", 0.2, None),
    "ch3_branch_a": ("lightless_sea", (0.0, 0.05, 0.6, 0.85), False, "sea_ink", 0.55, None),
    "ch3_branch_b": ("breathing_ruins", (0.0, 0.0, 1.0, 1.0), True, "sea_teal", 0.85, "water"),
    "ch3_hub": ("smiling_theater", (0.0, 0.0, 1.0, 1.0), False, "sea_teal", 0.75, "water"),
    "ch3_well": ("ink_archive", (0.2, 0.0, 0.8, 0.8), False, "sea_bio", 0.85, "water"),
    "ch3_vault": ("ink_archive", (0.0, 0.0, 1.0, 1.0), True, "sea_teal", 0.8, "water"),
    "ch3_event": ("lightless_sea", (0.45, 0.12, 0.92, 0.72), True, "sea_wreck", 0.6, "haze"),
    "ch3_elite": ("breathing_ruins", (0.3, 0.0, 0.95, 0.75), False, "sea_ink", 0.85, "water"),
    "ch3_boss": ("lightless_sea", (0.55, 0.0, 1.0, 0.55), False, "sea_ink", 0.5, "vignette"),
    # Chapter 4 · Smiling Theater
    "ch4_entry": ("smiling_theater", (0.0, 0.0, 1.0, 1.0), False, "stage_red", 0.2, None),
    "ch4_branch_a": ("smiling_theater", (0.0, 0.05, 0.4, 0.75), False, "stage_red", 0.45, None),
    "ch4_branch_b": ("smiling_theater", (0.62, 0.0, 1.0, 0.7), False, "stage_gold", 0.55, None),
    "ch4_hub": ("ink_archive", (0.0, 0.0, 1.0, 1.0), True, "stage_gold", 0.75, "glow"),
    "ch4_well": ("smiling_theater", (0.0, 0.0, 1.0, 1.0), True, "stage_teal", 0.65, "dark"),
    "ch4_vault": ("ink_archive", (0.1, 0.05, 0.9, 0.9), False, "stage_bone", 0.7, "haze"),
    "ch4_event": ("lightless_sea", (0.0, 0.0, 1.0, 1.0), True, "stage_violet", 0.75, "haze"),
    "ch4_elite": ("breathing_ruins", (0.0, 0.0, 1.0, 1.0), False, "stage_red", 0.8, "dark"),
    "ch4_boss": ("smiling_theater", (0.2, 0.15, 0.8, 0.85), False, "stage_red", 0.6, "vignette"),
}


def gradient_lut(stops):
    lut = []
    n = len(stops) - 1
    for i in range(256):
        t = i / 255 * n
        k = min(int(t), n - 1)
        f = t - k
        a, b = stops[k], stops[k + 1]
        lut.append(tuple(int(a[c] + (b[c] - a[c]) * f) for c in range(3)))
    return lut


def gradient_map(img: Image.Image, stops) -> Image.Image:
    lum = img.convert("L")
    lut = gradient_lut(stops)
    r = lum.point([c[0] for c in lut])
    g = lum.point([c[1] for c in lut])
    b = lum.point([c[2] for c in lut])
    return Image.merge("RGB", (r, g, b))


def crop_scaled(img: Image.Image, box) -> Image.Image:
    x0, y0, x1, y1 = box
    w, h = img.size
    # Keep 16:9: grow the shorter side of the box around its centre.
    cw, ch = (x1 - x0) * w, (y1 - y0) * h
    target = W / H
    if cw / ch > target:
        ch = cw / target
    else:
        cw = ch * target
    cx, cy = (x0 + x1) / 2 * w, (y0 + y1) / 2 * h
    left = max(0.0, min(w - cw, cx - cw / 2))
    top = max(0.0, min(h - ch, cy - ch / 2))
    region = img.crop((int(left), int(top), int(left + min(cw, w)), int(top + min(ch, h))))
    out = region.resize((W, H), Image.LANCZOS)
    if region.width < W:
        out = out.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
    return out


def overlay(img: Image.Image, kind: str | None, palette) -> Image.Image:
    if kind is None:
        return img
    w, h = img.size
    if kind == "dark":
        return ImageEnhance.Brightness(img).enhance(0.78)
    if kind in ("haze", "glow", "water", "vignette"):
        layer = Image.new("RGB", (w, h), palette[1])
        mask = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(mask)
        if kind == "haze":
            for y in range(h):
                d.line([(0, y), (w, y)], fill=int(70 * (y / h) ** 1.5))
            img = Image.composite(layer, img, mask)
        elif kind == "glow":
            glow = Image.new("RGB", (w, h), palette[3])
            for r in range(420, 0, -6):
                d.ellipse([w / 2 - r * 1.6, h * 0.38 - r, w / 2 + r * 1.6, h * 0.38 + r],
                          fill=int(60 * (1 - r / 420)))
            img = Image.composite(glow, img, mask)
        elif kind == "water":
            # Caustic bands and a sinking blue haze: drowned architecture.
            for y in range(h):
                d.line([(0, y), (w, y)], fill=int(40 + 90 * (y / h)))
            img = Image.composite(layer, img, mask)
            caustic = Image.new("L", (w, h), 0)
            cd = ImageDraw.Draw(caustic)
            for i in range(7):
                x = (i * 263 + 90) % w
                cd.polygon([(x, 0), (x + 70, 0), (x + 260, h), (x + 140, h)], fill=14)
            caustic = caustic.filter(ImageFilter.GaussianBlur(48))
            light = Image.new("RGB", (w, h), palette[3])
            img = Image.composite(light, img, caustic)
        elif kind == "vignette":
            for r in range(10):
                pass
    # Vignette on every variant keeps edges quiet behind the HUD panels.
    vig = Image.new("L", (w, h), 0)
    vd = ImageDraw.Draw(vig)
    for i in range(60):
        a = int(i * (110 if kind == "vignette" else 60) / 60)
        vd.rectangle([i * 6, i * 4, w - i * 6, h - i * 4], outline=None)
    edge = Image.new("L", (w, h), 255)
    inner = Image.new("L", (w, h), 0)
    ImageDraw.Draw(inner).ellipse([-w * 0.15, -h * 0.25, w * 1.15, h * 1.25], fill=255)
    inner = inner.filter(ImageFilter.GaussianBlur(120))
    strength = 0.55 if kind == "vignette" else 0.3
    mask = ImageChops.subtract(edge, inner).point(lambda v: int(v * strength))
    return Image.composite(Image.new("RGB", (w, h), (0, 0, 0)), img, mask)


def build(name, spec) -> Image.Image:
    source, box, flip, palette_name, strength, kind = spec
    img = Image.open(SRC / f"{source}.png").convert("RGB")
    img = crop_scaled(img, box)
    if flip:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    palette = P[palette_name]
    mapped = gradient_map(img, palette)
    img = Image.blend(img, mapped, strength)
    return overlay(img, kind, palette)


# Tall regions get one painting that fills the whole room height instead of
# a mirrored stack (the mirror showed a reflected moon in every shaft). The
# rows above the base composition are architecture bands from other paintings,
# feathered together and sinking into darkness toward the ceiling.
TALL = {"well": 2160, "elite": 2160, "boss": 2160}
DEFAULT_HEIGHT = 1440
EXTENSIONS = {
    2: [("ink_archive", (0.0, 0.0, 1.0, 0.7), True), ("breathing_ruins", (0.0, 0.0, 1.0, 0.55), False)],
    3: [("ink_archive", (0.0, 0.0, 1.0, 0.7), False), ("breathing_ruins", (0.2, 0.0, 1.0, 0.6), True)],
    4: [("smiling_theater", (0.0, 0.0, 1.0, 0.55), True), ("ink_archive", (0.0, 0.0, 1.0, 0.7), False)],
}
FEATHER = 180


def region_height(name: str) -> int:
    return TALL.get(name.split("_", 1)[1], DEFAULT_HEIGHT)


def band(source, box, flip, palette, strength, height) -> Image.Image:
    img = Image.open(SRC / f"{source}.png").convert("RGB")
    img = crop_scaled(img, box)
    if flip:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    img = Image.blend(img, gradient_map(img, palette), max(strength, 0.6))
    return img.resize((W, height), Image.LANCZOS)


def vertical_mask(height: int, feather_top: int, feather_bottom: int) -> Image.Image:
    mask = Image.new("L", (W, height), 255)
    d = ImageDraw.Draw(mask)
    for y in range(feather_top):
        d.line([(0, y), (W, y)], fill=int(255 * y / max(feather_top, 1)))
    for y in range(feather_bottom):
        d.line([(0, height - 1 - y), (W, height - 1 - y)], fill=int(255 * y / max(feather_bottom, 1)))
    return mask


def build_tall(name, spec) -> Image.Image:
    base = build(name, spec)
    total = region_height(name)
    canvas = Image.new("RGB", (W, total), (0, 0, 0))
    ext_h = total - H
    chapter = int(name[2])
    palette = P[spec[3]]
    parts = EXTENSIONS[chapter]
    # Abstract haze above the base: the base's top-edge colours fading to the
    # palette's darkest tone, with soft fog and a few faint light shafts. No
    # recognisable shapes, so nothing reads as a copy or a stretched moon.
    import random as _random
    rng = _random.Random(sum(map(ord, name)))
    ext_total = ext_h + FEATHER
    edge = base.crop((0, 0, W, 24)).resize((W, 1), Image.BOX).resize((W, ext_total), Image.BICUBIC)
    edge = edge.filter(ImageFilter.GaussianBlur(40))
    dark = Image.new("RGB", (W, ext_total), palette[0])
    ramp = Image.new("L", (W, ext_total), 0)
    rd = ImageDraw.Draw(ramp)
    for yy in range(ext_total):
        rd.line([(0, yy), (W, yy)], fill=int(255 * (yy / ext_total) ** 0.8))
    ext = Image.composite(edge, dark, ramp)
    noise = Image.effect_noise((W // 16, ext_total // 16), 60).resize((W, ext_total), Image.BICUBIC)
    noise = noise.filter(ImageFilter.GaussianBlur(24))
    fog = Image.new("RGB", (W, ext_total), palette[2])
    ext = Image.composite(fog, ext, noise.point(lambda v: max(0, v - 118) // 3))
    shafts = Image.new("L", (W, ext_total), 0)
    sd = ImageDraw.Draw(shafts)
    for _ in range(4):
        x = rng.randint(0, W)
        sd.polygon([(x, 0), (x + 60, 0), (x + 200, ext_total), (x + 80, ext_total)], fill=18)
    shafts = shafts.filter(ImageFilter.GaussianBlur(50))
    ext = Image.composite(Image.new("RGB", (W, ext_total), palette[3]), ext, shafts)
    canvas.paste(ext, (0, 0))
    canvas.paste(base, (0, ext_h), vertical_mask(H, FEATHER, 0))
    # Darkness ramp toward the ceiling.
    shade = Image.new("L", (W, total), 0)
    d = ImageDraw.Draw(shade)
    for yy in range(ext_h):
        d.line([(0, yy), (W, yy)], fill=int(230 * (1 - yy / ext_h) ** 1.4))
    return Image.composite(Image.new("RGB", (W, total), palette[0]), canvas, shade)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, spec in REGIONS.items():
        out = OUT / f"{name}.webp"
        build_tall(name, spec).save(out, quality=86, method=6)
        print("wrote", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
