"""Generates room dressing art: mid-ground silhouette layers and prop atlases.

- assets/backgrounds/layers/ch{1..4}_mid_{a,b}.png  (1536x864, alpha)
  Dark silhouettes in the lower part of the frame with a thin rim light, drawn
  at half resolution and upscaled 2x so they read as chunky pixel art. Used as
  a parallax layer between the painted backdrop and the terrain.
- assets/sprites/props/dressing_ch{1..4}.png  (6 props x 64x64, alpha)
  Small floor props with a 1 px dark outline, feet on the bottom row.

Deterministic (fixed seeds). Usage: python tools/build_dressing.py
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
LW, LH = 768, 432  # layer drawn at half size, saved at 2x
PROP = 64

THEMES = {
    1: dict(fill=(10, 14, 24), rim=(120, 150, 190), fog=(40, 60, 90)),
    2: dict(fill=(9, 15, 15), rim=(110, 150, 138), fog=(40, 64, 62)),
    3: dict(fill=(4, 12, 20), rim=(70, 170, 170), fog=(20, 60, 80)),
    4: dict(fill=(16, 7, 8), rim=(200, 130, 80), fog=(70, 24, 26)),
}


# ---------------------------------------------------------------- silhouettes

def column(d, x, base, height, width, rng, broken=True):
    top = base - height
    d.rectangle([x, top, x + width, base], fill=1)
    d.rectangle([x - 3, base - 6, x + width + 3, base], fill=1)  # plinth
    if broken:
        pts = [(x, top)]
        steps = 5
        for i in range(1, steps):
            pts.append((x + width * i / steps, top - rng.randint(0, 14)))
        pts.append((x + width, top))
        d.polygon(pts + [(x + width, top + 2), (x, top + 2)], fill=1)
    else:
        d.rectangle([x - 4, top - 6, x + width + 4, top], fill=1)  # capital


def arch(d, x0, x1, top, thickness=7):
    w = x1 - x0
    d.arc([x0, top, x1, top + w], 180, 360, fill=1, width=thickness)


def rubble(d, x, base, rng, n=6):
    for _ in range(n):
        w, h = rng.randint(6, 22), rng.randint(4, 12)
        px = x + rng.randint(-30, 30)
        d.polygon([(px, base), (px + w * 0.2, base - h), (px + w, base - h * 0.7), (px + w, base)], fill=1)


def vine(d, x, top, length, rng):
    y = top
    while y < top + length:
        x += rng.choice([-1, 0, 0, 1])
        d.rectangle([x, y, x + 1, y + 2], fill=1)
        if rng.random() < 0.15:
            d.rectangle([x - 2, y, x + 3, y + 1], fill=1)
        y += 2


def rib(d, x, base, height, flip):
    for i in range(height):
        t = i / height
        dx = math.sin(t * math.pi * 0.9) * height * 0.35 * (-1 if flip else 1)
        d.rectangle([x + dx, base - i, x + dx + 3, base - i + 1], fill=1)


def kelp(d, x, base, height, rng):
    phase = rng.random() * 6
    for i in range(0, height, 2):
        sway = math.sin(i * 0.06 + phase) * 6
        w = 3 if i < height * 0.8 else 2
        d.rectangle([x + sway, base - i, x + sway + w, base - i + 2], fill=1)
        if i % 14 == 0 and i > 10:
            side = 1 if (i // 14) % 2 else -1
            d.polygon([(x + sway, base - i), (x + sway + side * 10, base - i - 6), (x + sway + side * 3, base - i - 2)], fill=1)


def coral(d, x, base, length, angle, depth, rng):
    if depth == 0 or length < 3:
        return
    ex = x + math.cos(angle) * length
    ey = base - math.sin(angle) * length
    d.line([(x, base), (ex, ey)], fill=1, width=max(1, depth))
    for da in (-0.5, 0.45):
        coral(d, ex, ey, length * 0.72, angle + da + rng.uniform(-0.15, 0.15), depth - 1, rng)


def mast(d, x, base, height, rng):
    d.rectangle([x, base - height, x + 4, base], fill=1)
    for yy in (base - height * 0.8, base - height * 0.5):
        d.rectangle([x - 26, yy, x + 30, yy + 2], fill=1)
        # Torn sail.
        d.polygon([(x - 22, yy + 3), (x + 26, yy + 3), (x + 20, yy + 26 + rng.randint(0, 10)),
                   (x + 4, yy + 18), (x - 14, yy + 30)], fill=1)
    d.line([(x + 2, base - height), (x + 60, base)], fill=1, width=1)


def rope_bag(d, x, top, length):
    d.line([(x, top), (x, top + length)], fill=1, width=1)
    d.rectangle([x - 6, top + length, x + 6, top + length + 14], fill=1)


def flat(d, x, base, w, h, rng, kind):
    if kind == 0:  # castle flat
        d.rectangle([x, base - h, x + w, base], fill=1)
        for i in range(0, w, 10):
            d.rectangle([x + i, base - h - 8, x + i + 5, base - h], fill=1)
        d.rectangle([x + w * 0.4, base - h * 0.5, x + w * 0.6, base], fill=0)
    else:  # tree flat
        d.rectangle([x + w * 0.45, base - h * 0.6, x + w * 0.55, base], fill=1)
        d.ellipse([x, base - h, x + w, base - h * 0.45], fill=1)
    d.rectangle([x + w * 0.2, base - 3, x + w * 0.8, base], fill=1)  # brace foot


def seats(d, x0, x1, base):
    for x in range(x0, x1, 9):
        d.rectangle([x, base - 10, x + 7, base], fill=1)
        d.rectangle([x, base - 14, x + 7, base - 12], fill=1)


def bookshelf(d, x, base, w, h):
    d.rectangle([x, base - h, x + w, base], fill=1)
    d.rectangle([x - 3, base - h - 4, x + w + 3, base - h], fill=1)


def draw_layer(chapter: int, variant: int) -> Image.Image:
    rng = random.Random(chapter * 31 + variant * 7)
    mask = Image.new("L", (LW, LH), 0)
    d = ImageDraw.Draw(mask)
    base = LH
    if chapter in (1, 2):
        x = rng.randint(-20, 30)
        while x < LW + 40:
            w = rng.randint(14, 24)
            h = rng.randint(140, 300)
            column(d, x, base, h, w, rng, broken=rng.random() < 0.6)
            nxt = x + rng.randint(110, 190)
            if rng.random() < 0.55:
                arch(d, x + w, nxt, base - h + 10)
                vine(d, (x + nxt) // 2, base - h + 40, rng.randint(40, 120), rng)
            if chapter == 1 and rng.random() < 0.5:
                bookshelf(d, x + w + 12, base, rng.randint(30, 60), rng.randint(60, 120))
            if chapter == 2 and rng.random() < 0.4:
                rib(d, x + w + 30, base, rng.randint(80, 150), rng.random() < 0.5)
            rubble(d, x + 40, base, rng)
            x = nxt
    elif chapter == 3:
        for _ in range(26):
            kelp(d, rng.randint(0, LW), base, rng.randint(80, 260), rng)
        for _ in range(9):
            coral(d, rng.randint(0, LW), base, rng.randint(18, 34), math.pi / 2, 4, rng)
        mast(d, rng.randint(150, 600), base, rng.randint(220, 320), rng)
        for _ in range(7):
            cx, r = rng.randint(0, LW), rng.randint(20, 60)
            d.ellipse([cx - r * 1.6, base - r, cx + r * 1.6, base + r], fill=1)
    else:
        for _ in range(9):
            rope_bag(d, rng.randint(0, LW), 0, rng.randint(80, 220))
        x = rng.randint(-10, 40)
        while x < LW:
            w, h = rng.randint(70, 140), rng.randint(110, 220)
            flat(d, x, base - 40, w, h, rng, rng.randint(0, 1))
            x += w + rng.randint(40, 120)
        seats(d, 0, LW, base)
        # Lighting truss across the top.
        d.rectangle([0, 18, LW, 22], fill=1)
        for xx in range(0, LW, 16):
            d.line([(xx, 18), (xx + 8, 22)], fill=1)
    # Seamless horizontal tiling: blend the outer columns.
    theme = THEMES[chapter]
    layer = Image.new("RGBA", (LW, LH), (0, 0, 0, 0))
    fill = Image.new("RGBA", (LW, LH), (*theme["fill"], 238))
    solid = mask.point(lambda v: 255 if v else 0)
    layer.paste(fill, (0, 0), solid)
    # Rim light: pixels whose upper-left neighbour is empty.
    px = layer.load()
    m = mask.load()
    for y in range(1, LH):
        for x in range(1, LW):
            if m[x, y] and (not m[x - 1, y] or not m[x, y - 1]):
                px[x, y] = (*theme["rim"], 200)
    # A low fog band in front of the silhouettes' feet.
    fog = Image.new("RGBA", (LW, LH), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    for y in range(LH - 70, LH):
        a = int(90 * (y - (LH - 70)) / 70)
        fd.line([(0, y), (LW, y)], fill=(*theme["fog"], a))
    layer = Image.alpha_composite(layer, fog)
    return layer.resize((LW * 2, LH * 2), Image.NEAREST)


# ---------------------------------------------------------------- props

def outline(img: Image.Image, color=(11, 15, 20, 255)) -> Image.Image:
    a = img.split()[3]
    grown = a.filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", img.size, color)
    out.putalpha(grown.point(lambda v: 255 if v > 0 else 0))
    return Image.alpha_composite(out, img)


def prop_canvas():
    img = Image.new("RGBA", (PROP, PROP), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


def p_rubble(stone):
    img, d = prop_canvas()
    rng = random.Random(1)
    for _ in range(7):
        w, h = rng.randint(8, 18), rng.randint(5, 12)
        x, y = rng.randint(8, 40), PROP - 2 - rng.randint(0, 10)
        d.polygon([(x, y), (x + 3, y - h), (x + w, y - h + 2), (x + w, y)], fill=shade(stone, rng.uniform(0.8, 1.2)))
        d.line([(x + 3, y - h), (x + w, y - h + 2)], fill=shade(stone, 1.45))
    return img


def p_column(stone, accent):
    img, d = prop_canvas()
    d.rectangle([22, 26, 40, 61], fill=shade(stone, 1.0))
    d.rectangle([22, 26, 25, 61], fill=shade(stone, 1.35))
    d.rectangle([37, 26, 40, 61], fill=shade(stone, 0.7))
    d.polygon([(22, 26), (27, 20), (31, 25), (35, 18), (40, 26)], fill=shade(stone, 1.0))
    d.rectangle([18, 58, 44, 62], fill=shade(stone, 0.85))
    for y in range(30, 58, 6):
        d.line([(28, y), (34, y + 3)], fill=accent)
    return img


def p_urn(body, accent):
    img, d = prop_canvas()
    d.ellipse([18, 26, 46, 58], fill=shade(body, 1.0))
    d.rectangle([24, 18, 40, 28], fill=shade(body, 0.9))
    d.rectangle([20, 16, 44, 19], fill=shade(body, 1.3))
    d.rectangle([22, 58, 42, 62], fill=shade(body, 0.7))
    d.arc([18, 26, 46, 58], 200, 260, fill=shade(body, 1.5), width=2)
    for i in range(3):
        d.line([(26 + i * 6, 30), (24 + i * 7, 54)], fill=accent, width=1)
    return img


def p_books(paper, cover):
    img, d = prop_canvas()
    y = 62
    rng = random.Random(4)
    for i in range(5):
        w = rng.randint(22, 34)
        x = 32 - w // 2 + rng.randint(-4, 4)
        col = cover if i % 2 else shade(cover, 0.7)
        d.rectangle([x, y - 6, x + w, y], fill=col)
        d.rectangle([x + 2, y - 5, x + w - 2, y - 4], fill=paper)
        y -= 6
    d.polygon([(40, y + 2), (50, y - 6), (52, y - 4), (44, y + 4)], fill=paper)
    return img


def p_candles(wax, flame):
    img, d = prop_canvas()
    for x, h in ((20, 18), (28, 26), (36, 14), (44, 22)):
        d.rectangle([x, 62 - h, x + 4, 62], fill=wax)
        d.rectangle([x, 62 - h, x + 1, 62], fill=shade(wax, 1.2))
        d.ellipse([x, 62 - h - 6, x + 4, 62 - h], fill=flame)
    d.rectangle([16, 60, 50, 62], fill=shade(wax, 0.6))
    return img


def p_coral(a, b):
    img, d = prop_canvas()
    rng = random.Random(9)

    def branch(x, y, length, ang, depth, col):
        if depth == 0:
            d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=shade(col, 1.4))
            return
        ex, ey = x + math.cos(ang) * length, y - math.sin(ang) * length
        d.line([(x, y), (ex, ey)], fill=col, width=depth)
        for da in (-0.55, 0.5):
            branch(ex, ey, length * 0.7, ang + da + rng.uniform(-0.2, 0.2), depth - 1, col)

    branch(24, 62, 14, math.pi / 2 + 0.2, 4, a)
    branch(40, 62, 12, math.pi / 2 - 0.2, 3, b)
    return img


def p_rock(stone, shell):
    img, d = prop_canvas()
    d.ellipse([10, 36, 54, 70], fill=shade(stone, 1.0))
    d.arc([10, 36, 54, 70], 190, 300, fill=shade(stone, 1.4), width=2)
    rng = random.Random(5)
    for _ in range(9):
        x, y = rng.randint(16, 46), rng.randint(42, 58)
        d.polygon([(x, y), (x + 3, y - 4), (x + 6, y)], fill=shell)
    d.rectangle([0, 62, 63, 63], fill=(0, 0, 0, 0))
    return img


def p_kelp(col):
    img, d = prop_canvas()
    for x0, h, ph in ((24, 50, 0.0), (34, 58, 1.7), (42, 40, 3.1)):
        for i in range(0, h, 2):
            sx = x0 + math.sin(i * 0.15 + ph) * 3
            d.rectangle([sx, 62 - i, sx + 2, 63 - i], fill=shade(col, 0.8 + 0.4 * i / h))
    return img


def p_anemone(body, glow):
    img, d = prop_canvas()
    d.ellipse([22, 48, 42, 62], fill=body)
    for i in range(9):
        ang = math.pi * (0.1 + 0.8 * i / 8)
        x, y = 32 + math.cos(ang) * 4, 52
        ex, ey = 32 + math.cos(ang) * 16, 52 - math.sin(ang) * 18
        d.line([(x, y), (ex, ey)], fill=glow, width=2)
        d.ellipse([ex - 1, ey - 1, ex + 1, ey + 1], fill=shade(glow, 1.3))
    return img


def p_lantern(metal, light):
    img, d = prop_canvas()
    d.rectangle([24, 30, 40, 54], fill=light)
    d.rectangle([22, 28, 42, 30], fill=metal)
    d.rectangle([22, 54, 42, 58], fill=metal)
    for x in (24, 31, 38):
        d.line([(x, 30), (x, 54)], fill=metal)
    d.arc([26, 18, 38, 32], 180, 360, fill=metal, width=2)
    d.rectangle([28, 58, 36, 62], fill=metal)
    return img


def p_plank(wood):
    img, d = prop_canvas()
    d.polygon([(6, 62), (10, 54), (56, 48), (58, 56)], fill=wood)
    d.line([(10, 54), (56, 48)], fill=shade(wood, 1.4))
    d.polygon([(30, 62), (34, 40), (40, 40), (38, 62)], fill=shade(wood, 0.8))
    for x in (16, 44):
        d.rectangle([x, 51, x + 1, 52], fill=(30, 30, 30, 255))
    return img


def p_footlight(metal, light):
    img, d = prop_canvas()
    d.polygon([(18, 62), (22, 48), (42, 48), (46, 62)], fill=metal)
    d.rectangle([24, 44, 40, 48], fill=light)
    d.line([(22, 48), (42, 48)], fill=shade(metal, 1.5))
    return img


def p_chair(wood, velvet):
    img, d = prop_canvas()
    d.rectangle([20, 22, 44, 30], fill=wood)
    d.rectangle([22, 30, 42, 44], fill=velvet)
    d.rectangle([20, 44, 44, 48], fill=velvet)
    for x in (20, 41):
        d.rectangle([x, 48, x + 3, 62], fill=wood)
    d.rectangle([20, 14, 44, 22], fill=velvet)
    return img


def p_mask(stand, face, accent):
    img, d = prop_canvas()
    d.rectangle([31, 38, 33, 62], fill=stand)
    d.rectangle([24, 60, 40, 62], fill=stand)
    d.ellipse([20, 10, 44, 40], fill=face)
    d.arc([25, 22, 39, 34], 20, 160, fill=accent, width=2)  # smile
    d.ellipse([25, 18, 29, 22], fill=(20, 10, 10, 255))
    d.ellipse([35, 18, 39, 22], fill=(20, 10, 10, 255))
    return img


def p_sandbags(cloth):
    img, d = prop_canvas()
    for x, y in ((12, 52), (30, 52), (21, 42), (40, 54)):
        d.ellipse([x, y, x + 20, y + 11], fill=shade(cloth, 1.0))
        d.arc([x, y, x + 20, y + 11], 190, 280, fill=shade(cloth, 1.35), width=1)
    return img


def p_rope(rope):
    img, d = prop_canvas()
    for r in range(14, 2, -3):
        d.ellipse([32 - r * 1.4, 56 - r * 0.45, 32 + r * 1.4, 56 + r * 0.45], outline=rope, width=2)
    d.line([(44, 56), (54, 62)], fill=rope, width=2)
    return img


def p_puppet(paper, ink):
    img, d = prop_canvas()
    d.line([(32, 0), (32, 14)], fill=(200, 200, 200, 180))
    d.ellipse([26, 14, 38, 26], fill=paper)
    d.polygon([(24, 28), (40, 28), (44, 50), (20, 50)], fill=paper)
    d.line([(20, 30), (12, 42)], fill=paper, width=3)
    d.line([(44, 30), (52, 40)], fill=paper, width=3)
    d.line([(28, 50), (26, 62)], fill=paper, width=3)
    d.line([(36, 50), (38, 62)], fill=paper, width=3)
    d.arc([28, 18, 36, 24], 20, 160, fill=ink, width=1)
    return img


def props_for(chapter: int) -> list[Image.Image]:
    if chapter == 1:
        stone, accent = (64, 74, 96, 255), (196, 160, 92, 255)
        return [p_books((210, 196, 160, 255), (70, 40, 46, 255)), p_candles((200, 190, 160, 255), (250, 200, 110, 255)),
                p_rubble(stone), p_column(stone, accent), p_books((220, 210, 180, 255), (40, 54, 80, 255)),
                p_urn((60, 66, 90, 255), accent)]
    if chapter == 2:
        stone, vein = (88, 98, 90, 255), (140, 40, 38, 255)
        return [p_rubble(stone), p_column(stone, vein), p_urn((76, 86, 76, 255), vein),
                p_books((190, 180, 150, 255), (70, 60, 50, 255)), p_candles((170, 160, 130, 255), (240, 180, 90, 255)),
                p_kelp((70, 100, 56, 255))]
    if chapter == 3:
        return [p_coral((200, 90, 110, 255), (70, 170, 160, 255)), p_rock((50, 70, 86, 255), (200, 210, 200, 255)),
                p_kelp((40, 120, 100, 255)), p_anemone((40, 60, 80, 255), (110, 240, 220, 255)),
                p_lantern((40, 50, 56, 255), (140, 230, 210, 255)), p_plank((90, 70, 54, 255))]
    return [p_footlight((60, 40, 30, 255), (255, 214, 140, 255)), p_chair((70, 40, 30, 255), (150, 34, 40, 255)),
            p_mask((70, 50, 40, 255), (230, 220, 200, 255), (160, 30, 40, 255)), p_sandbags((140, 116, 86, 255)),
            p_rope((170, 140, 100, 255)), p_puppet((226, 216, 196, 255), (30, 20, 20, 255))]


# Mid layers cut from the paintings themselves (the hand-drawn silhouettes
# above clashed with the painted art): the lower band of another painting,
# gradient-mapped to near-black in the chapter palette, fading out at the top.
MID_SOURCES = {
    (2, "a"): ("breathing_ruins", 0.0, 0.42, False, [(2, 4, 4), (12, 20, 20), (40, 56, 54), (90, 110, 104)]),
    (2, "b"): ("ink_archive", 0.1, 0.45, True, [(2, 4, 4), (12, 20, 20), (40, 56, 54), (90, 110, 104)]),
    (3, "a"): ("breathing_ruins", 0.3, 0.42, True, [(1, 4, 8), (6, 18, 28), (20, 60, 70), (60, 130, 130)]),
    (3, "b"): ("ink_archive", 0.0, 0.45, False, [(1, 4, 8), (6, 18, 28), (20, 60, 70), (60, 130, 130)]),
    (4, "a"): ("smiling_theater", 0.0, 0.5, False, [(4, 1, 2), (22, 6, 8), (60, 22, 22), (130, 70, 50)]),
    (4, "b"): ("ink_archive", 0.2, 0.45, True, [(4, 1, 2), (22, 6, 8), (60, 22, 22), (130, 70, 50)]),
}


def painted_mid(chapter: int, tag: str) -> Image.Image:
    import sys
    sys.path.insert(0, str(ROOT / "tools"))
    from build_region_backdrops import gradient_map  # noqa: E402
    source, x0, top_frac, flip, palette = MID_SOURCES[(chapter, tag)]
    img = Image.open(ROOT / "assets" / "backgrounds" / f"{source}.png").convert("RGB")
    w, h = img.size
    band = img.crop((int(x0 * w * 0.5), int(h * (1 - top_frac)), int(x0 * w * 0.5 + w * 0.8), h))
    target_h = int(864 * 0.62)
    band = band.resize((1536, target_h), Image.LANCZOS)
    if flip:
        band = band.transpose(Image.FLIP_LEFT_RIGHT)
    band = gradient_map(band, palette)
    out = Image.new("RGBA", (1536, 864), (0, 0, 0, 0))
    alpha = Image.new("L", band.size, 255)
    ad = ImageDraw.Draw(alpha)
    fade = int(target_h * 0.45)
    for y in range(fade):
        ad.line([(0, y), (band.width, y)], fill=int(255 * (y / fade) ** 1.6))
    # Soft horizontal edge fade so the 1536 px repeat has no hard seam.
    edge = Image.new("L", band.size, 255)
    ed = ImageDraw.Draw(edge)
    for x in range(48):
        v = int(255 * x / 48)
        ed.line([(x, 0), (x, band.height)], fill=v)
        ed.line([(band.width - 1 - x, 0), (band.width - 1 - x, band.height)], fill=v)
    from PIL import ImageChops
    alpha = ImageChops.multiply(alpha, edge).point(lambda v: int(v * 0.92))
    band.putalpha(alpha)
    out.alpha_composite(band, (0, 864 - target_h))
    return out


def main() -> None:
    layers = ROOT / "assets" / "backgrounds" / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    props_dir = ROOT / "assets" / "sprites" / "props"
    for chapter in THEMES:
        for variant, tag in ((0, "a"), (1, "b")):
            if (chapter, tag) in MID_SOURCES:
                painted_mid(chapter, tag).save(layers / f"ch{chapter}_mid_{tag}.png", optimize=True)
        atlas = Image.new("RGBA", (PROP * 6, PROP), (0, 0, 0, 0))
        for i, prop in enumerate(props_for(chapter)):
            atlas.alpha_composite(outline(prop), (i * PROP, 0))
        # Binary alpha (art spec): no soft edges.
        alpha = atlas.split()[3].point(lambda v: 255 if v >= 128 else 0)
        atlas.putalpha(alpha)
        atlas.save(props_dir / f"dressing_ch{chapter}.png", optimize=True)
        print("chapter", chapter, "done")


if __name__ == "__main__":
    main()
