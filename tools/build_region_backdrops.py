"""Builds one backdrop per big-map region (chapters 2-4) from the painted art.

Since 1.0 the sources are the artist's region paintings (art_inbox/
ch<c>_<theme>_far.png, four themes per chapter). Each of the nine regions of
a chapter picks a theme; regions that share a theme get a different flip and
a light gradient-map tint so neighbours never look identical.

Rooms are 1536 px tiles wide and 1440 px (default) or 2160 px (shaft, elite,
boss) tall. Shaft themes were painted 2160 px tall and are used as-is. The
864 px paintings are scaled 1.25x and anchored at the bottom; the rows above
fade into a soft haze of the painting's own top colours. Output:
assets/backgrounds/regions/<region>.webp. The matching transparent mid layer
for each region is chosen by RoomDressing.REGION_THEMES.

Usage: python tools/build_region_backdrops.py
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art_inbox"
OUT = ROOT / "assets" / "backgrounds" / "regions"
W = 1536
BASE_SCALE = 1.25

# Gradient-map palettes: shadow -> mid -> light -> highlight.
P = {
    "ruin_moss": [(8, 12, 8), (36, 56, 38), (110, 138, 96), (212, 226, 190)],
    "ruin_rust": [(14, 8, 8), (70, 36, 30), (150, 104, 84), (232, 210, 180)],
    "ruin_gold": [(12, 10, 8), (64, 48, 30), (170, 136, 84), (246, 226, 170)],
    "ruin_blood": [(12, 4, 6), (76, 16, 22), (170, 62, 58), (240, 190, 170)],
    "ruin_violet": [(10, 8, 16), (44, 34, 66), (122, 106, 150), (220, 210, 236)],
    "sea_ink": [(2, 4, 10), (16, 22, 48), (70, 86, 140), (200, 210, 240)],
    "sea_teal": [(2, 10, 12), (8, 50, 56), (40, 132, 128), (180, 236, 220)],
    "sea_bio": [(2, 8, 10), (12, 40, 52), (40, 150, 150), (200, 255, 236)],
    "sea_wreck": [(6, 8, 10), (34, 40, 46), (100, 112, 116), (210, 214, 206)],
    "stage_red": [(10, 4, 4), (70, 14, 18), (170, 60, 50), (246, 210, 160)],
    "stage_gold": [(10, 8, 4), (58, 38, 16), (166, 120, 56), (250, 226, 160)],
    "stage_bone": [(10, 8, 8), (52, 40, 38), (150, 132, 120), (240, 232, 214)],
    "stage_violet": [(8, 4, 12), (46, 20, 58), (140, 80, 140), (240, 200, 230)],
}

# region: (theme, flip, palette or None, palette strength, mood)
REGIONS = {
    "ch2_entry": ("ruins", False, None, 0.0, None),
    "ch2_branch_a": ("ruins", True, "ruin_moss", 0.22, None),
    "ch2_branch_b": ("vault", True, "ruin_rust", 0.22, None),
    "ch2_hub": ("vault", False, None, 0.0, "haze"),
    "ch2_well": ("well", False, None, 0.0, None),
    "ch2_vault": ("vault", False, "ruin_gold", 0.28, "glow"),
    "ch2_event": ("ruins", True, "ruin_violet", 0.3, "haze"),
    "ch2_elite": ("boss", True, "ruin_blood", 0.28, "dark"),
    "ch2_boss": ("boss", False, None, 0.0, None),
    "ch3_entry": ("shore", False, None, 0.0, None),
    "ch3_branch_a": ("shore", True, "sea_ink", 0.25, None),
    "ch3_branch_b": ("library", True, "sea_teal", 0.2, None),
    "ch3_hub": ("library", False, None, 0.0, "haze"),
    "ch3_well": ("well", False, None, 0.0, None),
    "ch3_vault": ("library", False, "sea_bio", 0.28, "glow"),
    "ch3_event": ("shore", True, "sea_wreck", 0.3, "haze"),
    "ch3_elite": ("boss", True, "sea_ink", 0.28, "dark"),
    "ch3_boss": ("boss", False, None, 0.0, None),
    "ch4_entry": ("stage", False, None, 0.0, None),
    "ch4_branch_a": ("seats", False, None, 0.0, None),
    "ch4_branch_b": ("seats", True, "stage_gold", 0.2, None),
    "ch4_hub": ("stage", True, "stage_gold", 0.15, "haze"),
    "ch4_well": ("fly", False, None, 0.0, None),
    "ch4_vault": ("seats", False, "stage_bone", 0.28, "haze"),
    "ch4_event": ("stage", True, "stage_violet", 0.3, "haze"),
    "ch4_elite": ("boss", True, "stage_red", 0.25, "dark"),
    "ch4_boss": ("boss", False, None, 0.0, None),
}
TALL = {"well": 2160, "elite": 2160, "boss": 2160}
DEFAULT_HEIGHT = 1440
FEATHER = 200


def gradient_map(img: Image.Image, stops) -> Image.Image:
    lum = img.convert("L")
    n = len(stops) - 1
    lut = []
    for i in range(256):
        t = i / 255 * n
        k = min(int(t), n - 1)
        f = t - k
        a, b = stops[k], stops[k + 1]
        lut.append(tuple(int(a[c] + (b[c] - a[c]) * f) for c in range(3)))
    return Image.merge("RGB", [lum.point([c[ch] for c in lut]) for ch in range(3)])


def mood(img: Image.Image, kind: str | None, palette) -> Image.Image:
    w, h = img.size
    if kind == "dark":
        return Image.blend(img, Image.new("RGB", (w, h), (0, 0, 0)), 0.22)
    if kind == "haze":
        mask = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(mask)
        for y in range(h):
            d.line([(0, y), (w, y)], fill=int(60 * (y / h) ** 1.6))
        return Image.composite(Image.new("RGB", (w, h), (palette or [(20, 24, 32)] * 2)[1]), img, mask)
    if kind == "glow":
        mask = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(mask)
        for r in range(420, 0, -6):
            d.ellipse([w / 2 - r * 1.6, h * 0.42 - r, w / 2 + r * 1.6, h * 0.42 + r], fill=int(46 * (1 - r / 420)))
        return Image.composite(Image.new("RGB", (w, h), (palette or [(255, 230, 170)] * 4)[3]), img, mask)
    return img


def base_image(name: str, spec) -> Image.Image:
    theme, flip, palette_name, strength, kind = spec
    chapter = int(name[2])
    img = Image.open(SRC / f"ch{chapter}_{theme}_far.png").convert("RGB")
    if img.height < 1500:
        scaled = img.resize((int(img.width * BASE_SCALE), int(img.height * BASE_SCALE)), Image.LANCZOS)
        left = (scaled.width - W) // 2
        img = scaled.crop((left, 0, left + W, scaled.height))
    if flip:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    palette = P.get(palette_name) if palette_name else None
    if palette and strength > 0.0:
        img = Image.blend(img, gradient_map(img, palette), strength)
    return mood(img, kind, palette)


def region_height(name: str) -> int:
    return TALL.get(name.split("_", 1)[1], DEFAULT_HEIGHT)


def build(name, spec) -> Image.Image:
    base = base_image(name, spec)
    total = region_height(name)
    if base.height >= total:
        return base.crop((0, base.height - total, W, base.height))
    ext_h = total - base.height
    ext_total = ext_h + FEATHER
    rng = random.Random(sum(map(ord, name)))
    # The painting's own top rows, smeared upward into a dark haze.
    edge = base.crop((0, 0, W, 32)).resize((W, 1), Image.BOX).resize((W, ext_total), Image.BICUBIC)
    edge = edge.filter(ImageFilter.GaussianBlur(48))
    darkest = min(base.resize((64, 36)).getdata(), key=sum)
    dark = Image.new("RGB", (W, ext_total), darkest)
    ramp = Image.new("L", (W, ext_total), 0)
    rd = ImageDraw.Draw(ramp)
    for y in range(ext_total):
        rd.line([(0, y), (W, y)], fill=int(255 * (y / ext_total) ** 0.9))
    ext = Image.composite(edge, dark, ramp)
    noise = Image.effect_noise((W // 16, ext_total // 16), 60).resize((W, ext_total), Image.BICUBIC)
    noise = noise.filter(ImageFilter.GaussianBlur(24))
    light = base.resize((1, 1), Image.BOX).getpixel((0, 0))
    fog = Image.new("RGB", (W, ext_total), tuple(min(255, int(c * 1.6) + 10) for c in light))
    ext = Image.composite(fog, ext, noise.point(lambda v: max(0, v - 118) // 3))
    shafts = Image.new("L", (W, ext_total), 0)
    sd = ImageDraw.Draw(shafts)
    for _ in range(4):
        x = rng.randint(0, W)
        sd.polygon([(x, 0), (x + 60, 0), (x + 200, ext_total), (x + 80, ext_total)], fill=14)
    shafts = shafts.filter(ImageFilter.GaussianBlur(50))
    ext = Image.composite(fog, ext, shafts)
    canvas = Image.new("RGB", (W, total), darkest)
    canvas.paste(ext, (0, 0))
    mask = Image.new("L", base.size, 255)
    md = ImageDraw.Draw(mask)
    for y in range(FEATHER):
        md.line([(0, y), (W, y)], fill=int(255 * y / FEATHER))
    canvas.paste(base, (0, ext_h), mask)
    return canvas


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, spec in REGIONS.items():
        out = OUT / f"{name}.webp"
        build(name, spec).save(out, quality=88, method=6)
        print("wrote", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
