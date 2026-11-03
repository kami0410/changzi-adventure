"""Normalize a generated or high-resolution source image into a game sprite.

Pipeline (see docs/memory/decisions/2026-11-02-art-spec.md):
  crop to opaque bounds -> premultiplied LANCZOS fit into the canvas ->
  binary alpha -> palette from opaque pixels only -> no dithering ->
  drop orphan pixels -> optional 1 px outline -> bottom-centre placement.

Usage (from the game folder):
  python -I tools/normalize_sprite.py SRC OUT --canvas 96 [--colors 24]
      [--height 92] [--alpha 128] [--outline 101820] [--matte 000000]
  python -I tools/normalize_sprite.py --batch   # re-run every entry in BATCH

--matte removes a solid background colour (for sources without alpha).
"""

from __future__ import annotations

import argparse
import pathlib
import sys

import numpy as np
from PIL import Image

GAME = pathlib.Path(__file__).resolve().parents[1]

OUTLINE = (16, 24, 32)

# Every sprite rebuilt from a high-resolution source. height = opaque art
# height in px (None = fill the canvas); alpha = cut for binary alpha.
BATCH = [
    {"out": "assets/sprites/bosses/last_reader.png", "src": "assets/concept/characters/last_reader_source.png", "canvas": 256, "colors": 44, "height": 250, "alpha": 80},
    {"out": "assets/sprites/bosses/smiling_archivist.png", "src": "assets/concept/characters/smiling_archivist_sprite_source.png", "canvas": 256, "colors": 44, "height": 252, "alpha": 80},
    {"out": "assets/sprites/bosses/lung_bell_guardian.png", "src": "assets/concept/characters/lung_bell_guardian_source.png", "canvas": 256, "colors": 44, "height": 250, "alpha": 80},
    {"out": "assets/sprites/enemies/mask_enemy.png", "src": "assets/concept/characters/mask_enemy_source.png", "canvas": 96, "height": 90},
    {"out": "assets/sprites/enemies/seat_husk.png", "src": "assets/concept/characters/seat_husk_source.png", "canvas": 96, "height": 90},
    {"out": "assets/sprites/enemies/choir_summoner.png", "src": "assets/concept/enemies/choir_summoner_raw.png", "canvas": 96, "height": 94},
    {"out": "assets/sprites/enemies/ink_bomber.png", "src": "assets/concept/enemies/ink_bomber_raw.png", "canvas": 96, "height": 84},
    {"out": "assets/sprites/enemies/mirror_sniper.png", "src": "assets/concept/enemies/mirror_sniper_raw.png", "canvas": 96, "height": 70, "alpha": 96},
    # Loose pages must stay separate: no outline, and the art is not grounded.
    {"out": "assets/sprites/enemies/page_swarm.png", "src": "assets/concept/enemies/page_swarm_raw.png", "canvas": 96, "height": 64, "alpha": 150, "outline": None, "min_cluster": 6},
]


def crop_opaque(image: Image.Image, threshold: int = 24) -> Image.Image:
    alpha = image.getchannel("A").point(lambda v: 255 if v > threshold else 0)
    box = alpha.getbbox()
    return image.crop(box) if box else image


def remove_matte(image: Image.Image, matte: tuple[int, int, int], tolerance: int = 18) -> Image.Image:
    arr = np.asarray(image.convert("RGBA")).copy()
    diff = np.abs(arr[..., :3].astype(np.int32) - np.array(matte)).max(axis=2)
    arr[..., 3] = np.where(diff <= tolerance, 0, arr[..., 3])
    return Image.fromarray(arr, "RGBA")


def fit(image: Image.Image, canvas: int, height: int | None) -> Image.Image:
    max_w = canvas - 2
    max_h = (height if height else canvas - 1)
    scale = min(max_w / image.width, max_h / image.height)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    # Premultiplied resize: no dark halo from transparent black pixels.
    return image.convert("RGBa").resize(size, Image.LANCZOS).convert("RGBA")


def _median_cut(pixels: np.ndarray, count: int) -> np.ndarray:
    if count <= 0 or len(pixels) == 0:
        return np.zeros((0, 3), dtype=np.int32)
    strip = Image.fromarray(pixels.astype(np.uint8).reshape(1, -1, 3), "RGB")
    palette = strip.quantize(colors=count, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).getpalette()
    used = min(count, len(pixels))
    return np.array(palette[: used * 3], dtype=np.int32).reshape(-1, 3)


def quantize(image: Image.Image, colors: int, alpha_cut: int) -> Image.Image:
    """Palette from opaque pixels only, with reserved slots for accents.

    Saturated accents (cyan eyes, blood-red ribbons, magic glow) cover a few
    pixels each, so a plain median cut spends every entry on dark cloth and
    the eyes go grey. A quarter of the palette is cut from accent pixels
    alone; the rest from everything else. Pixels map to the nearest entry
    (no dithering), so clusters stay flat."""
    arr = np.asarray(image).copy()
    opaque = arr[..., 3] >= alpha_cut
    if not opaque.any():
        return image
    rgb = arr[opaque][:, :3].astype(np.int32)
    high = rgb.max(axis=1)
    low = rgb.min(axis=1)
    saturation = (high - low) / np.maximum(high, 1)
    accent = (saturation > 0.4) & (high > 80)
    reserve = min(max(colors // 4, 2), int(accent.sum()) // 6) if accent.sum() >= 12 else 0
    palette = np.concatenate([
        _median_cut(rgb[accent], reserve),
        _median_cut(rgb[~accent] if (~accent).any() else rgb, colors - reserve),
    ])
    flat = arr[..., :3].reshape(-1, 3).astype(np.int32)
    # Perceptual-ish weights: green matters most, blue least.
    weights = np.array([2, 4, 3])
    distance = (((flat[:, None, :] - palette[None, :, :]) ** 2) * weights).sum(axis=2)
    mapped = palette[distance.argmin(axis=1)].reshape(arr.shape[0], arr.shape[1], 3)
    rgba = np.zeros_like(arr)
    rgba[..., :3] = mapped
    rgba[..., 3] = np.where(opaque, 255, 0)
    return Image.fromarray(rgba, "RGBA")


def drop_small_clusters(image: Image.Image, min_size: int = 3) -> Image.Image:
    """Removes opaque islands smaller than min_size pixels (4-connected)."""
    arr = np.asarray(image).copy()
    alpha = arr[..., 3] > 0
    seen = np.zeros_like(alpha)
    h, w = alpha.shape
    for y in range(h):
        for x in range(w):
            if not alpha[y, x] or seen[y, x]:
                continue
            stack = [(y, x)]
            seen[y, x] = True
            cluster = []
            while stack:
                cy, cx = stack.pop()
                cluster.append((cy, cx))
                for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                    if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
            if len(cluster) < min_size:
                for cy, cx in cluster:
                    arr[cy, cx, 3] = 0
    return Image.fromarray(arr, "RGBA")


def add_outline(image: Image.Image, color: tuple[int, int, int]) -> Image.Image:
    arr = np.asarray(image).copy()
    alpha = arr[..., 3] > 0
    padded = np.pad(alpha, 1)
    near = padded[:-2, 1:-1] | padded[2:, 1:-1] | padded[1:-1, :-2] | padded[1:-1, 2:]
    edge = near & ~alpha
    arr[edge, :3] = color
    arr[edge, 3] = 255
    return Image.fromarray(arr, "RGBA")


def place(image: Image.Image, canvas: int) -> Image.Image:
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    x = (canvas - image.width) // 2
    y = canvas - image.height
    out.alpha_composite(image, (x, max(y, 0)))
    return out


def normalize(src: pathlib.Path, out: pathlib.Path, canvas: int, colors: int = 24, height: int | None = None,
              alpha_cut: int = 128, outline: tuple[int, int, int] | None = OUTLINE,
              matte: tuple[int, int, int] | None = None, min_cluster: int = 4) -> dict:
    image = Image.open(src).convert("RGBA")
    if matte is not None:
        image = remove_matte(image, matte)
    image = crop_opaque(image)
    if outline is not None:
        height = (height or canvas) - 2
    image = fit(image, canvas, height)
    image = quantize(image, colors, alpha_cut)
    image = drop_small_clusters(image, min_cluster)
    image = crop_opaque(image, 0)
    if outline is not None:
        padded = Image.new("RGBA", (image.width + 2, image.height + 2), (0, 0, 0, 0))
        padded.alpha_composite(image, (1, 1))
        image = add_outline(padded, outline)
    final = place(image, canvas)
    out.parent.mkdir(parents=True, exist_ok=True)
    final.save(out)
    arr = np.asarray(final)
    opaque = arr[..., 3] == 255
    semi = (arr[..., 3] > 0) & (arr[..., 3] < 255)
    return {
        "out": str(out.relative_to(GAME)).replace("\\", "/"),
        "size": final.size,
        "colors": len({tuple(c) for c in arr[opaque][:, :3]}),
        "semi_alpha": int(semi.sum()),
        "art": image.size,
    }


def run_entry(entry: dict, out: pathlib.Path) -> dict:
    return normalize(GAME / entry["src"], out, entry["canvas"], entry.get("colors", 24), entry.get("height"),
                     entry.get("alpha", 128), entry.get("outline", OUTLINE), entry.get("matte"),
                     entry.get("min_cluster", 4))


def cleanup(path: pathlib.Path, out: pathlib.Path, alpha_cut: int = 128,
            outline: tuple[int, int, int] | None = OUTLINE, colors: int | None = None) -> dict:
    """In-place cleanup of a shipped sprite that has no source: binary alpha,
    optional requantize, small-cluster removal and a 1 px outline, without
    resizing (detail stays exactly as drawn)."""
    image = Image.open(path).convert("RGBA")
    canvas = image.size
    if colors is not None:
        image = quantize(image, colors, alpha_cut)
    else:
        arr = np.asarray(image).copy()
        arr[..., 3] = np.where(arr[..., 3] >= alpha_cut, 255, 0)
        image = Image.fromarray(arr, "RGBA")
    image = drop_small_clusters(image)
    if outline is not None:
        image = add_outline(image, outline)
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out)
    arr = np.asarray(image)
    opaque = arr[..., 3] == 255
    return {"out": str(out).replace("\\", "/"), "size": canvas,
            "colors": len({tuple(c) for c in arr[opaque][:, :3]}),
            "semi_alpha": int(((arr[..., 3] > 0) & (arr[..., 3] < 255)).sum())}


# Shipped sprites with no high-resolution source: cleaned in place (binary
# alpha + outline, no resize). Run with --cleanup after re-exporting any of them.
CLEANUP = [
    "assets/sprites/bosses/ink_archivist.png", "assets/sprites/enemies/blank_man.png",
    "assets/sprites/enemies/echo_enemy.png", "assets/sprites/enemies/hanging_scribe.png",
    "assets/sprites/enemies/ink_hound.png", "assets/sprites/enemies/scribe_bug.png",
    "assets/sprites/enemies/typo_beast.png", "assets/sprites/npcs/ayan.png",
    "assets/sprites/npcs/gulu.png", "assets/sprites/npcs/luchen.png",
    "assets/sprites/player/player_idle.png",
    "assets/sprites/npcs/baiyu.png", "assets/sprites/npcs/wenjin.png",
]


def hex_color(text: str) -> tuple[int, int, int]:
    text = text.lstrip("#")
    return tuple(int(text[i:i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser()
    parser.add_argument("src", nargs="?")
    parser.add_argument("out", nargs="?")
    parser.add_argument("--canvas", type=int, default=96)
    parser.add_argument("--colors", type=int, default=24)
    parser.add_argument("--height", type=int, default=None)
    parser.add_argument("--alpha", type=int, default=128)
    parser.add_argument("--outline", default=None)
    parser.add_argument("--matte", default=None)
    parser.add_argument("--batch", action="store_true")
    parser.add_argument("--cleanup", action="store_true")
    args = parser.parse_args()
    if args.batch:
        for entry in BATCH:
            print(run_entry(entry, GAME / entry["out"]))
        return
    if args.cleanup:
        for rel in CLEANUP:
            print(cleanup(GAME / rel, GAME / rel, alpha_cut=110))
        return
    if not args.src or not args.out:
        parser.error("SRC and OUT are required without --batch")
    print(normalize(pathlib.Path(args.src), pathlib.Path(args.out), args.canvas, args.colors, args.height,
                    args.alpha, hex_color(args.outline) if args.outline else OUTLINE,
                    hex_color(args.matte) if args.matte else None))


if __name__ == "__main__":
    main()
