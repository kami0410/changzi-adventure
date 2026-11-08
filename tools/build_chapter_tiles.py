"""Builds the per-chapter 16 px terrain atlases (assets/tiles/chN/tiles.png).

Atlas layout (4 x 2 tiles, 64 x 32 px), shared by every chapter so the
TileSets and room builders stay identical:

    row 0: ground_top   ground_fill   platform_top   platform_under
    row 1: ground_top2  ground_deep   platform_top2  platform_under2

Row 1 holds variants: the room builders alternate them by column so long
floors do not read as one stamped tile, and `ground_deep` darkens the fill
below the first rows so the ground has depth. Everything is drawn from a
small per-chapter palette with a fixed seed, so re-running is deterministic.

Usage: python tools/build_chapter_tiles.py
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
T = 16

PALETTES = {
    # Ink archive: blue-black masonry, parchment-gold trim, ink drips.
    1: dict(outline=(12, 16, 24), deep=(16, 21, 32), dark=(24, 32, 46), mid=(36, 47, 66),
            light=(58, 74, 98), mortar=(14, 19, 28), accent=(196, 160, 92),
            accent_hi=(236, 206, 140), drip=(18, 22, 40), under=(62, 52, 40)),
    # Breathing ruins: grey-green stone, moss, rust-red veins.
    2: dict(outline=(14, 16, 14), deep=(20, 24, 22), dark=(36, 42, 38), mid=(56, 64, 58),
            light=(86, 96, 86), mortar=(22, 26, 24), accent=(92, 128, 70),
            accent_hi=(140, 176, 98), drip=(122, 44, 40), under=(70, 100, 56)),
    # Lightless sea: wet slate, teal algae, pale foam.
    3: dict(outline=(8, 14, 20), deep=(12, 22, 32), dark=(20, 36, 50), mid=(32, 54, 72),
            light=(58, 88, 108), mortar=(10, 20, 30), accent=(50, 140, 136),
            accent_hi=(170, 220, 214), drip=(40, 110, 120), under=(46, 120, 116)),
    # Smiling theater: dark stage boards, red velvet edge, gold trim.
    4: dict(outline=(16, 10, 10), deep=(26, 16, 16), dark=(46, 28, 24), mid=(72, 44, 34),
            light=(104, 66, 48), mortar=(30, 18, 16), accent=(150, 34, 40),
            accent_hi=(222, 178, 92), drip=(120, 26, 34), under=(150, 34, 40)),
}


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def put(img, x, y, rgb, alpha=255):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), (*rgb, alpha))


def bricks(img, ox, oy, p, rng, darken=0.0, top=0):
    """Running-bond masonry; wood planks for the theater."""
    for y in range(top, T):
        for x in range(T):
            put(img, ox + x, oy + y, lerp(p["dark"], p["deep"], darken))
    rows = [(top, 4), (top + 4, 4), (top + 8, 4), (top + 12, 4)]
    for index, (y0, h) in enumerate(rows):
        if y0 >= T:
            continue
        shift = 0 if index % 2 == 0 else 4
        for bx in range(-8, T, 8):
            x0 = bx + shift
            shade = rng.choice([p["dark"], p["mid"], p["dark"], lerp(p["dark"], p["mid"], 0.5)])
            shade = lerp(shade, p["deep"], darken)
            for y in range(y0, min(y0 + h, T)):
                for x in range(x0, x0 + 8):
                    xx = x % T
                    if y == y0 or x == x0:
                        put(img, ox + xx, oy + y, lerp(p["mortar"], p["deep"], darken * 0.5))
                    else:
                        c = shade
                        if y == y0 + 1 and x != x0:
                            c = lerp(shade, p["light"], 0.25 * (1 - darken))
                        put(img, ox + xx, oy + y, c)
    # Speckles and the odd crack.
    for _ in range(5):
        x, y = rng.randrange(T), rng.randrange(top, T)
        put(img, ox + x, oy + y, lerp(p["light"], p["deep"], 0.4 + darken * 0.5))
    if rng.random() < 0.6:
        x, y = rng.randrange(2, T - 2), rng.randrange(top + 2, T - 2)
        for i in range(3):
            put(img, ox + x + i // 2, oy + y + i, p["mortar"])


def planks(img, ox, oy, p, rng, top=0, darken=0.0):
    for y in range(top, T):
        for x in range(T):
            base = p["mid"] if (x // 8) % 2 == 0 else lerp(p["mid"], p["dark"], 0.35)
            if (y - top) % 4 == 3:
                base = lerp(base, p["dark"], 0.4)
            put(img, ox + x, oy + y, lerp(base, p["deep"], darken))
        put(img, ox + (rng.randrange(T)), oy + y, lerp(p["light"], p["deep"], darken))
    for x in (0, 8):
        for y in range(top, T):
            put(img, ox + x, oy + y, lerp(p["outline"], p["deep"], darken))


def ground_top(img, ox, oy, p, rng, chapter, variant):
    if chapter == 4:
        planks(img, ox, oy, p, rng, top=4)
    else:
        bricks(img, ox, oy, p, rng, top=4)
    # Surface lip: a bright edge, the chapter accent, then a shadow line.
    for x in range(T):
        put(img, ox + x, oy + 0, p["outline"])
        put(img, ox + x, oy + 1, p["light"])
        put(img, ox + x, oy + 2, p["accent"] if chapter != 3 else lerp(p["light"], p["accent"], 0.5))
        put(img, ox + x, oy + 3, p["outline"])
    if chapter == 1:
        # Gilded trim with rivets.
        for x in range(T):
            put(img, ox + x, oy + 2, p["accent"] if x % 4 else p["accent_hi"])
    elif chapter == 2:
        # Moss tufts over the lip.
        for x in range(T):
            if rng.random() < 0.45:
                put(img, ox + x, oy + 1, p["accent_hi"] if rng.random() < 0.4 else p["accent"])
            if rng.random() < 0.25:
                put(img, ox + x, oy + 4, p["accent"])
    elif chapter == 3:
        # Foam crest.
        for x in range(T):
            if (x + variant * 3) % 5 in (0, 1):
                put(img, ox + x, oy + 1, p["accent_hi"])
    else:
        # Red velvet band with a gold piping line.
        for x in range(T):
            put(img, ox + x, oy + 1, p["accent_hi"])
            put(img, ox + x, oy + 2, p["accent"])
    # Drips / roots hanging into the masonry.
    for _ in range(2 + variant):
        x = rng.randrange(T)
        length = rng.randrange(2, 5)
        for y in range(4, 4 + length):
            put(img, ox + x, oy + y, p["drip"])


def ground_fill(img, ox, oy, p, rng, chapter, darken):
    if chapter == 4:
        planks(img, ox, oy, p, rng, darken=darken)
    else:
        bricks(img, ox, oy, p, rng, darken=darken)


def platform_top(img, ox, oy, p, rng, chapter, variant):
    for y in range(T):
        for x in range(T):
            if y == 0 or y == T - 1:
                c = p["outline"]
            elif y == 1:
                c = p["light"]
            elif y == 2:
                c = p["accent"] if chapter in (1, 4) else lerp(p["light"], p["mid"], 0.5)
            elif y >= T - 4:
                c = p["dark"]
            else:
                c = p["mid"]
            put(img, ox + x, oy + y, c)
    # Seams: planks for wood, slab joints otherwise.
    seam = 8 if chapter == 4 else (0 if variant == 0 else 10)
    for y in range(3, T - 1):
        put(img, ox + seam, oy + y, p["outline"])
    for _ in range(4):
        put(img, ox + rng.randrange(T), oy + rng.randrange(4, T - 4), lerp(p["light"], p["mid"], 0.5))
    if chapter == 1:
        for x in (3, 12):
            put(img, ox + x, oy + 2, p["accent_hi"])
    if chapter == 2 and variant:
        for x in range(T):
            if rng.random() < 0.4:
                put(img, ox + x, oy + 1, p["accent"])
    if chapter == 3:
        for x in range(T):
            if (x + variant * 4) % 6 == 0:
                put(img, ox + x, oy + 1, p["accent_hi"])


def platform_under(img, ox, oy, p, rng, chapter, variant):
    """Hanging dressing under a platform; transparent elsewhere."""
    for x in range(T):
        put(img, ox + x, oy + 0, p["outline"], 255)
        put(img, ox + x, oy + 1, lerp(p["outline"], p["dark"], 0.5), 200)
    strands = 3 + variant
    for _ in range(strands):
        x = rng.randrange(1, T - 1)
        length = rng.randrange(3, 11)
        for y in range(2, 2 + length):
            alpha = 255 if y < 2 + length - 1 else 170
            put(img, ox + x, oy + y, p["under"], alpha)
        if chapter == 4:
            # Gold tassel tips on the curtain fringe.
            put(img, ox + x, oy + 2 + length, p["accent_hi"])
        elif chapter == 1:
            # Torn page scrap.
            put(img, ox + x + 1, oy + 2 + length // 2, (190, 176, 140), 220)
        elif chapter == 3:
            put(img, ox + x, oy + 2 + length, p["accent_hi"], 200)


def build(chapter: int) -> Image.Image:
    p = PALETTES[chapter]
    img = Image.new("RGBA", (T * 4, T * 2), (0, 0, 0, 0))
    for variant in (0, 1):
        rng = random.Random(chapter * 1000 + variant)
        oy = variant * T
        ground_top(img, 0, oy, p, rng, chapter, variant)
        ground_fill(img, T, oy, p, rng, chapter, 0.0 if variant == 0 else 0.55)
        platform_top(img, T * 2, oy, p, rng, chapter, variant)
        platform_under(img, T * 3, oy, p, rng, chapter, variant)
    return img


def main() -> None:
    for chapter in PALETTES:
        out = ROOT / "assets" / "tiles" / f"ch{chapter}" / "tiles.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        build(chapter).save(out)
        print("wrote", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
